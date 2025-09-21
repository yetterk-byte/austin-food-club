const { PrismaClient } = require('@prisma/client');
const yelpService = require('./yelpService');
const { logAdminAction } = require('../middleware/adminAuth');

const prisma = new PrismaClient();

class AdminService {
  /**
   * Get comprehensive dashboard statistics
   */
  async getDashboardStats() {
    try {
      const now = new Date();
      const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

      const [
        totalUsers,
        newUsersThisWeek,
        totalRestaurants,
        queueLength,
        currentRestaurant,
        thisWeekRSVPs,
        totalVerifiedVisits,
        activeFriendships,
        popularDays
      ] = await Promise.all([
        prisma.user.count(),
        prisma.user.count({ where: { createdAt: { gte: weekAgo } } }),
        prisma.restaurant.count(),
        prisma.restaurantQueue.count({ where: { status: 'PENDING' } }),
        prisma.restaurant.findFirst({ 
          where: { isFeatured: true },
          include: {
            _count: {
              select: {
                rsvps: { where: { createdAt: { gte: weekAgo } } },
                verifiedVisits: { where: { createdAt: { gte: weekAgo } } }
              }
            }
          }
        }),
        prisma.rSVP.count({ where: { createdAt: { gte: weekAgo } } }),
        prisma.verifiedVisit.count(),
        prisma.friendship.count({ where: { status: 'accepted' } }),
        prisma.rSVP.groupBy({
          by: ['day'],
          _count: { day: true },
          where: { createdAt: { gte: weekAgo } }
        })
      ]);

      return {
        overview: {
          totalUsers,
          newUsersThisWeek,
          totalRestaurants,
          queueLength,
          thisWeekRSVPs,
          totalVerifiedVisits,
          activeFriendships
        },
        currentRestaurant,
        popularDays: popularDays.reduce((acc, day) => {
          acc[day.day] = day._count.day;
          return acc;
        }, {}),
        growth: {
          usersThisWeek: newUsersThisWeek,
          rsvpsThisWeek: thisWeekRSVPs
        }
      };
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      throw error;
    }
  }

  /**
   * Advanced restaurant queue management
   */
  async getQueueWithInsights() {
    try {
      const queue = await prisma.restaurantQueue.findMany({
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
      const queueWithInsights = queue.map(item => ({
        ...item,
        insights: {
          popularity: item.restaurant._count.rsvps + item.restaurant._count.wishlists,
          hasBeenFeatured: item.restaurant.featuredDate ? true : false,
          daysSinceAdded: Math.floor((new Date() - item.addedAt) / (1000 * 60 * 60 * 24)),
          estimatedWeek: this.calculateEstimatedWeek(item.position)
        }
      }));

      return queueWithInsights;
    } catch (error) {
      console.error('Error getting queue with insights:', error);
      throw error;
    }
  }

  /**
   * Calculate estimated week for queue position
   */
  calculateEstimatedWeek(position) {
    const now = new Date();
    const estimatedDate = new Date(now.getTime() + (position * 7 * 24 * 60 * 60 * 1000));
    return estimatedDate.toISOString().split('T')[0]; // Return YYYY-MM-DD format
  }

  /**
   * Auto-advance queue (called by cron job)
   */
  async advanceQueue(adminId) {
    try {
      // Get current featured restaurant
      const currentRestaurant = await prisma.restaurant.findFirst({
        where: { isFeatured: true }
      });

      // Get next restaurant in queue
      const nextInQueue = await prisma.restaurantQueue.findFirst({
        where: { status: 'PENDING' },
        orderBy: { position: 'asc' },
        include: { restaurant: true }
      });

      if (!nextInQueue) {
        throw new Error('No restaurants in queue');
      }

      await prisma.$transaction(async (tx) => {
        // Unfeature current restaurant
        if (currentRestaurant) {
          await tx.restaurant.update({
            where: { id: currentRestaurant.id },
            data: { isFeatured: false }
          });
        }

        // Feature next restaurant
        await tx.restaurant.update({
          where: { id: nextInQueue.restaurantId },
          data: {
            isFeatured: true,
            featuredWeek: new Date(),
            featuredDate: new Date()
          }
        });

        // Mark queue item as active
        await tx.restaurantQueue.update({
          where: { id: nextInQueue.id },
          data: { status: 'ACTIVE' }
        });

        // Move all other queue items up one position
        await tx.restaurantQueue.updateMany({
          where: { 
            position: { gt: nextInQueue.position },
            status: 'PENDING'
          },
          data: { position: { decrement: 1 } }
        });
      });

      // Log the action
      await logAdminAction(
        adminId,
        'auto_advance_queue',
        nextInQueue.restaurantId,
        'restaurant',
        {
          previousRestaurant: currentRestaurant?.name,
          newRestaurant: nextInQueue.restaurant.name,
          queuePosition: nextInQueue.position
        }
      );

      return {
        previousRestaurant: currentRestaurant,
        newRestaurant: nextInQueue.restaurant,
        message: 'Queue advanced successfully'
      };
    } catch (error) {
      console.error('Error advancing queue:', error);
      throw error;
    }
  }

  /**
   * Get user engagement metrics
   */
  async getUserEngagementMetrics(timeframe = '30d') {
    try {
      const daysBack = timeframe === '7d' ? 7 : timeframe === '30d' ? 30 : 90;
      const startDate = new Date(new Date().getTime() - daysBack * 24 * 60 * 60 * 1000);

      const [
        activeUsers,
        engagementByDay,
        topUsers,
        retentionMetrics
      ] = await Promise.all([
        // Users who have taken any action recently
        prisma.user.count({
          where: {
            OR: [
              { rsvps: { some: { createdAt: { gte: startDate } } } },
              { verifiedVisits: { some: { createdAt: { gte: startDate } } } },
              { friendships: { some: { createdAt: { gte: startDate } } } }
            ]
          }
        }),

        // Daily engagement metrics
        prisma.rSVP.groupBy({
          by: ['createdAt'],
          _count: { id: true },
          where: { createdAt: { gte: startDate } }
        }),

        // Most engaged users
        prisma.user.findMany({
          select: {
            id: true,
            name: true,
            email: true,
            _count: {
              select: {
                rsvps: { where: { createdAt: { gte: startDate } } },
                verifiedVisits: { where: { createdAt: { gte: startDate } } },
                friendships: { where: { createdAt: { gte: startDate } } }
              }
            }
          },
          take: 10
        }),

        // Retention metrics (users who joined and are still active)
        this.calculateRetentionMetrics(startDate)
      ]);

      return {
        activeUsers,
        engagementByDay,
        topUsers: topUsers.map(user => ({
          ...user,
          totalActions: user._count.rsvps + user._count.verifiedVisits + user._count.friendships
        })).sort((a, b) => b.totalActions - a.totalActions),
        retentionMetrics
      };
    } catch (error) {
      console.error('Error getting engagement metrics:', error);
      throw error;
    }
  }

  /**
   * Calculate user retention metrics
   */
  async calculateRetentionMetrics(startDate) {
    try {
      const newUsers = await prisma.user.findMany({
        where: { createdAt: { gte: startDate } },
        select: { id: true, createdAt: true }
      });

      const retentionData = await Promise.all(
        newUsers.map(async (user) => {
          const hasRecentActivity = await prisma.user.findFirst({
            where: {
              id: user.id,
              OR: [
                { rsvps: { some: { createdAt: { gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000) } } } },
                { verifiedVisits: { some: { createdAt: { gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000) } } } }
              ]
            }
          });
          return { userId: user.id, isRetained: !!hasRecentActivity };
        })
      );

      const retainedUsers = retentionData.filter(user => user.isRetained).length;
      const retentionRate = newUsers.length > 0 ? (retainedUsers / newUsers.length) * 100 : 0;

      return {
        newUsers: newUsers.length,
        retainedUsers,
        retentionRate: Math.round(retentionRate * 100) / 100
      };
    } catch (error) {
      console.error('Error calculating retention metrics:', error);
      return { newUsers: 0, retainedUsers: 0, retentionRate: 0 };
    }
  }

  /**
   * Emergency restaurant override
   */
  async emergencyOverride(restaurantId, adminId, reason) {
    try {
      await prisma.$transaction(async (tx) => {
        // Unfeature current restaurant
        await tx.restaurant.updateMany({
          where: { isFeatured: true },
          data: { isFeatured: false }
        });

        // Feature new restaurant
        const restaurant = await tx.restaurant.update({
          where: { id: restaurantId },
          data: {
            isFeatured: true,
            featuredWeek: new Date(),
            featuredDate: new Date(),
            specialNotes: `Emergency override: ${reason}`
          }
        });

        // Log the emergency action
        await logAdminAction(
          adminId,
          'emergency_override',
          restaurantId,
          'restaurant',
          {
            reason,
            restaurantName: restaurant.name,
            timestamp: new Date().toISOString()
          }
        );

        return restaurant;
      });
    } catch (error) {
      console.error('Error in emergency override:', error);
      throw error;
    }
  }
}

module.exports = new AdminService();
