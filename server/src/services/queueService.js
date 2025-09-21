const { PrismaClient } = require('@prisma/client');
const { logAdminAction } = require('../middleware/adminAuth');

const prisma = new PrismaClient();

class QueueService {
  /**
   * Add restaurant to queue
   */
  async addToQueue(restaurantData, adminId, position = null) {
    try {
      const { restaurantId, notes, scheduledWeek } = restaurantData;

      // Validate restaurant exists
      const restaurant = await prisma.restaurant.findUnique({
        where: { id: restaurantId }
      });

      if (!restaurant) {
        throw new Error('Restaurant not found');
      }

      // Check if restaurant is already in queue
      const existingQueueItem = await prisma.restaurantQueue.findFirst({
        where: {
          restaurantId,
          status: { in: ['PENDING', 'ACTIVE'] }
        }
      });

      if (existingQueueItem) {
        throw new Error('Restaurant is already in the queue');
      }

      // Determine position
      let targetPosition;
      if (position && position > 0) {
        // Insert at specific position
        targetPosition = position;
        
        // Shift existing items down
        await prisma.restaurantQueue.updateMany({
          where: {
            position: { gte: position },
            status: 'PENDING'
          },
          data: { position: { increment: 1 } }
        });
      } else {
        // Add to end of queue
        const lastItem = await prisma.restaurantQueue.findFirst({
          where: { status: 'PENDING' },
          orderBy: { position: 'desc' }
        });
        targetPosition = (lastItem?.position || 0) + 1;
      }

      // Create queue item
      const queueItem = await prisma.restaurantQueue.create({
        data: {
          restaurantId,
          position: targetPosition,
          addedBy: adminId,
          notes,
          scheduledWeek: scheduledWeek ? new Date(scheduledWeek) : null,
          status: 'PENDING'
        },
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              address: true,
              imageUrl: true,
              rating: true,
              price: true,
              categories: true
            }
          },
          admin: {
            select: { name: true, email: true }
          }
        }
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'add_to_queue',
        restaurantId,
        'restaurant',
        {
          restaurantName: restaurant.name,
          position: targetPosition,
          notes
        }
      );

      return queueItem;
    } catch (error) {
      console.error('❌ Error adding to queue:', error);
      throw error;
    }
  }

  /**
   * Remove restaurant from queue
   */
  async removeFromQueue(queueId, adminId) {
    try {
      const queueItem = await prisma.restaurantQueue.findUnique({
        where: { id: queueId },
        include: {
          restaurant: { select: { name: true } }
        }
      });

      if (!queueItem) {
        throw new Error('Queue item not found');
      }

      if (queueItem.status === 'ACTIVE') {
        throw new Error('Cannot remove currently active restaurant');
      }

      await prisma.$transaction(async (tx) => {
        // Remove queue item
        await tx.restaurantQueue.delete({
          where: { id: queueId }
        });

        // Reorder remaining items
        await tx.restaurantQueue.updateMany({
          where: {
            position: { gt: queueItem.position },
            status: 'PENDING'
          },
          data: { position: { decrement: 1 } }
        });
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'remove_from_queue',
        queueItem.restaurantId,
        'restaurant',
        {
          restaurantName: queueItem.restaurant.name,
          position: queueItem.position
        }
      );

      return {
        message: 'Restaurant removed from queue',
        restaurantName: queueItem.restaurant.name
      };
    } catch (error) {
      console.error('❌ Error removing from queue:', error);
      throw error;
    }
  }

  /**
   * Reorder queue items
   */
  async reorderQueue(newOrder, adminId) {
    try {
      if (!Array.isArray(newOrder)) {
        throw new Error('newOrder must be an array');
      }

      // Validate all queue items exist and are pending
      const queueIds = newOrder.map(item => item.id);
      const existingItems = await prisma.restaurantQueue.findMany({
        where: {
          id: { in: queueIds },
          status: 'PENDING'
        },
        include: {
          restaurant: { select: { name: true } }
        }
      });

      if (existingItems.length !== newOrder.length) {
        throw new Error('Some queue items not found or not in pending status');
      }

      // Update positions in transaction
      await prisma.$transaction(async (tx) => {
        for (let i = 0; i < newOrder.length; i++) {
          await tx.restaurantQueue.update({
            where: { id: newOrder[i].id },
            data: { position: newOrder[i].position }
          });
        }
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'reorder_queue',
        null,
        'queue',
        {
          reorderedItems: existingItems.map((item, index) => ({
            restaurantName: item.restaurant.name,
            oldPosition: item.position,
            newPosition: newOrder.find(o => o.id === item.id)?.position
          }))
        }
      );

      return { message: 'Queue reordered successfully' };
    } catch (error) {
      console.error('❌ Error reordering queue:', error);
      throw error;
    }
  }

  /**
   * Get next restaurant in queue
   */
  async getNextInQueue() {
    try {
      const nextItem = await prisma.restaurantQueue.findFirst({
        where: { status: 'PENDING' },
        orderBy: { position: 'asc' },
        include: {
          restaurant: {
            include: {
              _count: {
                select: {
                  rsvps: true,
                  verifiedVisits: true,
                  wishlists: true
                }
              }
            }
          },
          admin: {
            select: { name: true, email: true }
          }
        }
      });

      return nextItem;
    } catch (error) {
      console.error('❌ Error getting next in queue:', error);
      throw error;
    }
  }

  /**
   * Skip restaurant in queue (move to end or remove)
   */
  async skipRestaurant(queueId, reason, adminId, action = 'move_to_end') {
    try {
      const queueItem = await prisma.restaurantQueue.findUnique({
        where: { id: queueId },
        include: {
          restaurant: { select: { name: true } }
        }
      });

      if (!queueItem) {
        throw new Error('Queue item not found');
      }

      if (queueItem.status !== 'PENDING') {
        throw new Error('Can only skip pending restaurants');
      }

      await prisma.$transaction(async (tx) => {
        if (action === 'remove') {
          // Remove from queue entirely
          await tx.restaurantQueue.delete({
            where: { id: queueId }
          });

          // Reorder remaining items
          await tx.restaurantQueue.updateMany({
            where: {
              position: { gt: queueItem.position },
              status: 'PENDING'
            },
            data: { position: { decrement: 1 } }
          });
        } else {
          // Move to end of queue
          const lastItem = await tx.restaurantQueue.findFirst({
            where: { status: 'PENDING' },
            orderBy: { position: 'desc' }
          });

          const newPosition = (lastItem?.position || 0) + 1;

          // Update positions of items that come after current item
          await tx.restaurantQueue.updateMany({
            where: {
              position: { gt: queueItem.position },
              status: 'PENDING'
            },
            data: { position: { decrement: 1 } }
          });

          // Move current item to end
          await tx.restaurantQueue.update({
            where: { id: queueId },
            data: {
              position: newPosition,
              notes: queueItem.notes 
                ? `${queueItem.notes} | Skipped: ${reason}`
                : `Skipped: ${reason}`
            }
          });
        }
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'skip_restaurant',
        queueItem.restaurantId,
        'restaurant',
        {
          restaurantName: queueItem.restaurant.name,
          reason,
          action,
          originalPosition: queueItem.position
        }
      );

      return {
        message: action === 'remove' 
          ? 'Restaurant removed from queue'
          : 'Restaurant moved to end of queue',
        restaurantName: queueItem.restaurant.name,
        action
      };
    } catch (error) {
      console.error('❌ Error skipping restaurant:', error);
      throw error;
    }
  }

  /**
   * Insert restaurant as urgent (next in line)
   */
  async insertUrgent(restaurantId, adminId, notes = null) {
    try {
      const restaurant = await prisma.restaurant.findUnique({
        where: { id: restaurantId }
      });

      if (!restaurant) {
        throw new Error('Restaurant not found');
      }

      // Check if restaurant is already in queue
      const existingQueueItem = await prisma.restaurantQueue.findFirst({
        where: {
          restaurantId,
          status: { in: ['PENDING', 'ACTIVE'] }
        }
      });

      if (existingQueueItem) {
        if (existingQueueItem.position === 1) {
          throw new Error('Restaurant is already next in queue');
        }
        
        // Remove from current position and reorder
        await this.removeFromQueue(existingQueueItem.id, adminId);
      }

      // Shift all pending items down by 1
      await prisma.restaurantQueue.updateMany({
        where: { status: 'PENDING' },
        data: { position: { increment: 1 } }
      });

      // Insert at position 1
      const queueItem = await prisma.restaurantQueue.create({
        data: {
          restaurantId,
          position: 1,
          addedBy: adminId,
          notes: notes || 'Inserted as urgent',
          status: 'PENDING'
        },
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              address: true,
              imageUrl: true,
              rating: true,
              price: true
            }
          }
        }
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'insert_urgent',
        restaurantId,
        'restaurant',
        {
          restaurantName: restaurant.name,
          notes
        }
      );

      return queueItem;
    } catch (error) {
      console.error('❌ Error inserting urgent restaurant:', error);
      throw error;
    }
  }

  /**
   * Get queue with enhanced insights
   */
  async getQueueWithInsights() {
    try {
      const queue = await prisma.restaurantQueue.findMany({
        where: { status: 'PENDING' },
        orderBy: { position: 'asc' },
        include: {
          restaurant: {
            include: {
              _count: {
                select: {
                  rsvps: true,
                  verifiedVisits: true,
                  wishlists: true
                }
              }
            }
          },
          admin: {
            select: { name: true, email: true }
          }
        }
      });

      // Add insights to each queue item
      const queueWithInsights = queue.map(item => {
        const daysSinceAdded = Math.floor(
          (new Date() - new Date(item.addedAt)) / (1000 * 60 * 60 * 24)
        );

        const estimatedWeek = this.calculateEstimatedWeek(item.position);
        
        const popularity = item.restaurant._count.rsvps + 
                          item.restaurant._count.wishlists + 
                          item.restaurant._count.verifiedVisits;

        return {
          ...item,
          insights: {
            daysSinceAdded,
            estimatedWeek,
            popularity,
            hasBeenFeatured: !!item.restaurant.lastFeaturedDate,
            timesFeatures: item.restaurant.timesFeatures || 0,
            averageRating: item.restaurant.averageRating
          }
        };
      });

      return queueWithInsights;
    } catch (error) {
      console.error('❌ Error getting queue with insights:', error);
      throw error;
    }
  }

  /**
   * Calculate estimated week for queue position
   */
  calculateEstimatedWeek(position) {
    const now = new Date();
    const estimatedDate = new Date(now.getTime() + (position * 7 * 24 * 60 * 60 * 1000));
    return estimatedDate.toISOString().split('T')[0];
  }

  /**
   * Get queue statistics
   */
  async getQueueStats() {
    try {
      const [
        totalPending,
        totalActive,
        totalCompleted,
        avgTimeInQueue,
        popularRestaurants
      ] = await Promise.all([
        prisma.restaurantQueue.count({ where: { status: 'PENDING' } }),
        prisma.restaurantQueue.count({ where: { status: 'ACTIVE' } }),
        prisma.restaurantQueue.count({ where: { status: 'COMPLETED' } }),
        this.calculateAverageTimeInQueue(),
        this.getMostPopularQueuedRestaurants()
      ]);

      return {
        totalPending,
        totalActive,
        totalCompleted,
        avgTimeInQueue,
        popularRestaurants,
        queueHealth: totalPending > 3 ? 'healthy' : totalPending > 1 ? 'low' : 'critical'
      };
    } catch (error) {
      console.error('❌ Error getting queue stats:', error);
      throw error;
    }
  }

  /**
   * Calculate average time restaurants spend in queue
   */
  async calculateAverageTimeInQueue() {
    try {
      const completedItems = await prisma.restaurantQueue.findMany({
        where: { status: 'COMPLETED' },
        select: { addedAt: true, updatedAt: true }
      });

      if (completedItems.length === 0) {
        return 0;
      }

      const totalDays = completedItems.reduce((sum, item) => {
        const days = Math.floor(
          (new Date(item.updatedAt) - new Date(item.addedAt)) / (1000 * 60 * 60 * 24)
        );
        return sum + days;
      }, 0);

      return Math.round(totalDays / completedItems.length);
    } catch (error) {
      console.error('❌ Error calculating average time in queue:', error);
      return 0;
    }
  }

  /**
   * Get most popular queued restaurants
   */
  async getMostPopularQueuedRestaurants() {
    try {
      const queuedRestaurants = await prisma.restaurantQueue.findMany({
        where: { status: 'PENDING' },
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              rating: true,
              _count: {
                select: {
                  rsvps: true,
                  verifiedVisits: true,
                  wishlists: true
                }
              }
            }
          }
        }
      });

      return queuedRestaurants
        .map(item => ({
          ...item.restaurant,
          popularity: item.restaurant._count.rsvps + 
                     item.restaurant._count.verifiedVisits + 
                     item.restaurant._count.wishlists
        }))
        .sort((a, b) => b.popularity - a.popularity)
        .slice(0, 5);
    } catch (error) {
      console.error('❌ Error getting popular queued restaurants:', error);
      return [];
    }
  }

  /**
   * Validate queue integrity
   */
  async validateQueueIntegrity() {
    try {
      const pendingItems = await prisma.restaurantQueue.findMany({
        where: { status: 'PENDING' },
        orderBy: { position: 'asc' }
      });

      const issues = [];

      // Check for position gaps
      for (let i = 0; i < pendingItems.length; i++) {
        const expectedPosition = i + 1;
        if (pendingItems[i].position !== expectedPosition) {
          issues.push({
            type: 'position_gap',
            queueItemId: pendingItems[i].id,
            expected: expectedPosition,
            actual: pendingItems[i].position
          });
        }
      }

      // Check for duplicate positions
      const positions = pendingItems.map(item => item.position);
      const duplicates = positions.filter((pos, index) => positions.indexOf(pos) !== index);
      if (duplicates.length > 0) {
        issues.push({
          type: 'duplicate_positions',
          positions: [...new Set(duplicates)]
        });
      }

      return {
        isValid: issues.length === 0,
        issues,
        totalItems: pendingItems.length
      };
    } catch (error) {
      console.error('❌ Error validating queue integrity:', error);
      throw error;
    }
  }

  /**
   * Fix queue integrity issues
   */
  async fixQueueIntegrity(adminId) {
    try {
      const validation = await this.validateQueueIntegrity();
      
      if (validation.isValid) {
        return { message: 'Queue integrity is already valid' };
      }

      // Get all pending items and reorder them
      const pendingItems = await prisma.restaurantQueue.findMany({
        where: { status: 'PENDING' },
        orderBy: { position: 'asc' }
      });

      // Fix positions in transaction
      await prisma.$transaction(async (tx) => {
        for (let i = 0; i < pendingItems.length; i++) {
          await tx.restaurantQueue.update({
            where: { id: pendingItems[i].id },
            data: { position: i + 1 }
          });
        }
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'fix_queue_integrity',
        null,
        'queue',
        {
          issuesFixed: validation.issues.length,
          totalItems: pendingItems.length
        }
      );

      return {
        message: 'Queue integrity fixed successfully',
        issuesFixed: validation.issues.length,
        totalItems: pendingItems.length
      };
    } catch (error) {
      console.error('❌ Error fixing queue integrity:', error);
      throw error;
    }
  }
}

module.exports = new QueueService();
