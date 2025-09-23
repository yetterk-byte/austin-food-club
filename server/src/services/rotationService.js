const { PrismaClient } = require('@prisma/client');
const { logAdminAction } = require('../middleware/adminAuth');
const notificationService = require('./notificationService');
const websocketService = require('./websocketService');
const cron = require('node-cron');

const prisma = new PrismaClient();

class RotationService {
  constructor() {
    this.isRotationRunning = false;
    this.cronJob = null;
    this.initializeRotationConfig();
  }

  /**
   * Initialize rotation configuration if it doesn't exist
   */
  async initializeRotationConfig() {
    try {
      const config = await prisma.rotationConfig.findFirst();
      if (!config) {
        await prisma.rotationConfig.create({
          data: {
            rotationDay: 'tuesday',
            rotationTime: '10:00',
            isActive: true,
            nextRotationDate: this.calculateNextRotationDate('tuesday', '10:00'),
            notifyAdmins: true,
            notifyUsers: false,
            skipWeekends: false,
            minQueueSize: 20
          }
        });
        console.log('✅ Rotation configuration initialized for Tuesday 10:00am');
      }
      
      // Start cron job for automatic rotation
      await this.updateCronJob();
    } catch (error) {
      console.error('❌ Error initializing rotation config:', error);
    }
  }

  /**
   * Get current rotation configuration
   */
  async getRotationConfig() {
    return await prisma.rotationConfig.findFirst();
  }

  /**
   * Update rotation configuration
   */
  async updateRotationConfig(updates, adminId = null) {
    try {
      const config = await prisma.rotationConfig.findFirst();
      
      if (!config) {
        throw new Error('Rotation configuration not found');
      }

      // Calculate next rotation date if schedule changed
      let nextRotationDate = config.nextRotationDate;
      if (updates.rotationDay || updates.rotationTime) {
        const day = updates.rotationDay || config.rotationDay;
        const time = updates.rotationTime || config.rotationTime;
        nextRotationDate = this.calculateNextRotationDate(day, time);
      }

      const updatedConfig = await prisma.rotationConfig.update({
        where: { id: config.id },
        data: {
          ...updates,
          nextRotationDate,
          updatedAt: new Date()
        }
      });

      // Update cron job
      await this.updateCronJob();

      // Log admin action
      if (adminId) {
        await logAdminAction(
          adminId,
          'update_rotation_config',
          config.id,
          'rotation_config',
          { updates, previousConfig: config }
        );
      }

      return updatedConfig;
    } catch (error) {
      console.error('❌ Error updating rotation config:', error);
      throw error;
    }
  }

  /**
   * Calculate next rotation date based on day and time
   */
  calculateNextRotationDate(dayOfWeek, timeString) {
    const days = {
      'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6
    };

    const targetDay = days[dayOfWeek.toLowerCase()];
    const [hours, minutes] = timeString.split(':').map(Number);

    const now = new Date();
    const nextDate = new Date();
    
    // Set target time
    nextDate.setHours(hours, minutes, 0, 0);
    
    // Calculate days until target day
    let daysUntilTarget = targetDay - now.getDay();
    
    // If target day has passed this week, or it's today but time has passed
    if (daysUntilTarget < 0 || (daysUntilTarget === 0 && now > nextDate)) {
      daysUntilTarget += 7;
    }
    
    nextDate.setDate(now.getDate() + daysUntilTarget);
    return nextDate;
  }

  /**
   * Update cron job based on current configuration
   */
  async updateCronJob() {
    try {
      // Stop existing cron job
      if (this.cronJob) {
        this.cronJob.stop();
        this.cronJob.destroy();
        this.cronJob = null;
      }

      const config = await this.getRotationConfig();
      
      if (config && config.isActive) {
        // Run every hour to check if rotation is needed
        this.cronJob = cron.schedule('0 * * * *', async () => {
          await this.checkRotationSchedule();
        }, {
          scheduled: true,
          timezone: 'America/Chicago'
        });

        console.log('🕐 Automatic rotation cron job started for Tuesday 10:00am');
      } else {
        console.log('🕐 Automatic rotation disabled');
      }
    } catch (error) {
      console.error('❌ Error updating cron job:', error);
    }
  }

  /**
   * Check if rotation is needed and execute if so
   */
  async checkRotationSchedule() {
    if (this.isRotationRunning) {
      console.log('⏳ Rotation already in progress, skipping...');
      return;
    }

    try {
      const config = await this.getRotationConfig();
      
      if (!config || !config.isActive) {
        return;
      }

      const now = new Date();
      const nextRotation = new Date(config.nextRotationDate);

      // Check if it's time to rotate (within the current hour)
      if (now >= nextRotation && now.getTime() - nextRotation.getTime() < 60 * 60 * 1000) {
        console.log('🔄 Automatic rotation triggered');
        await this.rotateToNextRestaurant('automatic', null, 'Scheduled automatic rotation');
        
        // Update next rotation date
        const newNextRotation = this.calculateNextRotationDate(
          config.rotationDay,
          config.rotationTime
        );
        
        await prisma.rotationConfig.update({
          where: { id: config.id },
          data: { nextRotationDate: newNextRotation }
        });
      }
    } catch (error) {
      console.error('❌ Error checking rotation schedule:', error);
      await this.sendNotification('ROTATION_FAILED', {
        title: 'Automatic Rotation Failed',
        message: `Scheduled rotation failed: ${error.message}`,
        recipientType: 'admin'
      });
    }
  }

  /**
   * Core rotation logic - rotate to next restaurant
   */
  async rotateToNextRestaurant(rotationType = 'manual', adminId = null, notes = null) {
    if (this.isRotationRunning) {
      throw new Error('Rotation already in progress');
    }

    this.isRotationRunning = true;

    try {
      console.log(`🔄 Starting ${rotationType} rotation...`);

      // Get current featured restaurant
      const currentRestaurant = await prisma.restaurant.findFirst({
        where: { isFeatured: true },
        include: {
          rsvps: {
            where: {
              createdAt: {
                gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000)
              }
            }
          },
          verifiedVisits: {
            where: {
              createdAt: {
                gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000)
              }
            }
          }
        }
      });

      // Get next restaurant from queue
      const nextRestaurant = await this.getNextRestaurantFromQueue();

      if (!nextRestaurant) {
        throw new Error('No restaurants available in queue');
      }

      const rotationStartTime = new Date();

      // Execute rotation in transaction
      await prisma.$transaction(async (tx) => {
        // Archive current restaurant performance
        if (currentRestaurant) {
          const weeklyRsvps = currentRestaurant.rsvps.length;
          const weeklyVisits = currentRestaurant.verifiedVisits.length;
          const avgRating = weeklyVisits.length > 0 
            ? weeklyVisits.reduce((sum, visit) => sum + visit.rating, 0) / weeklyVisits.length
            : null;

          // Create rotation history entry
          await tx.rotationHistory.create({
            data: {
              restaurantId: currentRestaurant.id,
              startDate: currentRestaurant.featuredDate || currentRestaurant.featuredWeek || rotationStartTime,
              endDate: rotationStartTime,
              totalRsvps: weeklyRsvps,
              totalVisits: weeklyVisits,
              averageRating: avgRating,
              rotationType,
              triggeredBy: adminId,
              notes
            }
          });

          // Update restaurant stats
          await tx.restaurant.update({
            where: { id: currentRestaurant.id },
            data: {
              isFeatured: false,
              lastFeaturedDate: rotationStartTime,
              timesFeatures: { increment: 1 },
              totalRsvps: { increment: weeklyRsvps },
              averageRating: avgRating
            }
          });
        }

        // Feature new restaurant
        await tx.restaurant.update({
          where: { id: nextRestaurant.restaurantId },
          data: {
            isFeatured: true,
            featuredWeek: rotationStartTime,
            featuredDate: rotationStartTime
          }
        });

        // Update queue item status
        await tx.restaurantQueue.update({
          where: { id: nextRestaurant.id },
          data: { status: 'ACTIVE' }
        });

        // Reorder remaining queue items - decrement positions by 1
        const remainingItems = await tx.restaurantQueue.findMany({
          where: {
            position: { gt: nextRestaurant.position },
            status: 'PENDING'
          },
          orderBy: { position: 'asc' }
        });

        // Update each item's position
        for (const item of remainingItems) {
          await tx.restaurantQueue.update({
            where: { id: item.id },
            data: { position: item.position - 1 }
          });
        }

        // Also update the rotated restaurant's position to 0 (or remove it from queue)
        await tx.restaurantQueue.update({
          where: { id: nextRestaurant.id },
          data: { position: 0 }
        });
      });

      // Log admin action
      if (adminId) {
        await logAdminAction(
          adminId,
          rotationType === 'manual' ? 'manual_rotation' : 'automatic_rotation',
          nextRestaurant.restaurantId,
          'restaurant',
          {
            previousRestaurant: currentRestaurant?.name,
            newRestaurant: nextRestaurant.restaurant.name,
            rotationType,
            notes
          }
        );
      }

      // Send notifications
      await this.sendNotification('ROTATION_COMPLETE', {
        title: 'Restaurant Rotation Complete',
        message: `${nextRestaurant.restaurant.name} is now the featured restaurant!`,
        recipientType: 'admin',
        restaurantId: nextRestaurant.restaurantId
      });

      console.log(`✅ Rotation complete: ${nextRestaurant.restaurant.name} is now featured`);

      // Broadcast real-time updates via WebSocket
      const rotationData = {
        type: 'restaurant_rotation',
        previousRestaurant: currentRestaurant ? {
          id: currentRestaurant.id,
          name: currentRestaurant.name,
          cityId: currentRestaurant.cityId
        } : null,
        newRestaurant: {
          id: nextRestaurant.restaurant.id,
          name: nextRestaurant.restaurant.name,
          cityId: nextRestaurant.restaurant.cityId
        },
        rotationType,
        timestamp: new Date().toISOString(),
        adminId
      };

      // Broadcast to admin dashboard
      websocketService.broadcastToAdmin('restaurant_rotation', rotationData);

      // Broadcast to specific city if applicable
      if (nextRestaurant.restaurant.cityId) {
        websocketService.broadcastToCity(nextRestaurant.restaurant.cityId, 'restaurant_rotation', rotationData);
      }

      // Auto-add new restaurant to queue after successful rotation
      try {
        const autoQueueService = require('./autoQueueService');
        console.log('🎯 Auto-queue: Adding new restaurant after rotation...');
        
        const autoQueueResult = await autoQueueService.addNewRestaurantToQueue();
        console.log(`🎉 Auto-added to queue: ${autoQueueResult.restaurant.name} at position ${autoQueueResult.queuePosition}`);
        
        // Send notification about new restaurant added
        await this.sendNotification('QUEUE_UPDATED', {
          title: 'New Restaurant Added to Queue',
          message: `${autoQueueResult.restaurant.name} has been automatically added to the queue at position ${autoQueueResult.queuePosition}`,
          recipientType: 'admin',
          restaurantId: autoQueueResult.restaurant.id
        });
        
      } catch (autoQueueError) {
        console.error('❌ Auto-queue failed after rotation:', autoQueueError.message);
        // Don't fail the rotation if auto-queue fails
        await this.sendNotification('QUEUE_ERROR', {
          title: 'Auto-Queue Failed',
          message: `Failed to automatically add new restaurant after rotation: ${autoQueueError.message}`,
          recipientType: 'admin'
        });
      }

      return {
        previousRestaurant: currentRestaurant,
        newRestaurant: nextRestaurant.restaurant,
        rotationType,
        rotationTime: rotationStartTime
      };

    } catch (error) {
      console.error('❌ Rotation failed:', error);
      
      await this.sendNotification('ROTATION_FAILED', {
        title: 'Restaurant Rotation Failed',
        message: `Rotation failed: ${error.message}`,
        recipientType: 'admin'
      });

      throw error;
    } finally {
      this.isRotationRunning = false;
    }
  }

  /**
   * Manual rotation by admin
   */
  async manualRotate(restaurantId, adminId, notes = null) {
    try {
      // If specific restaurant provided, feature it directly
      if (restaurantId) {
        return await this.emergencyRotate(restaurantId, adminId, notes || 'Manual restaurant selection');
      }
      
      // Otherwise, rotate to next in queue
      return await this.rotateToNextRestaurant('manual', adminId, notes);
    } catch (error) {
      console.error('❌ Manual rotation failed:', error);
      throw error;
    }
  }

  /**
   * Emergency rotation to specific restaurant (bypasses queue)
   */
  async emergencyRotate(restaurantId, adminId, reason) {
    if (this.isRotationRunning) {
      throw new Error('Rotation already in progress');
    }

    this.isRotationRunning = true;

    try {
      console.log(`🚨 Emergency rotation to restaurant ${restaurantId}`);

      const targetRestaurant = await prisma.restaurant.findUnique({
        where: { id: restaurantId }
      });

      if (!targetRestaurant) {
        throw new Error('Target restaurant not found');
      }

      const currentRestaurant = await prisma.restaurant.findFirst({
        where: { isFeatured: true }
      });

      const rotationTime = new Date();

      await prisma.$transaction(async (tx) => {
        // Archive current restaurant if exists
        if (currentRestaurant) {
          await tx.rotationHistory.create({
            data: {
              restaurantId: currentRestaurant.id,
              startDate: currentRestaurant.featuredDate || currentRestaurant.featuredWeek || rotationTime,
              endDate: rotationTime,
              rotationType: 'emergency',
              triggeredBy: adminId,
              notes: reason
            }
          });

          await tx.restaurant.update({
            where: { id: currentRestaurant.id },
            data: {
              isFeatured: false,
              lastFeaturedDate: rotationTime
            }
          });
        }

        // Feature target restaurant
        await tx.restaurant.update({
          where: { id: restaurantId },
          data: {
            isFeatured: true,
            featuredWeek: rotationTime,
            featuredDate: rotationTime
          }
        });
      });

      // Log admin action
      await logAdminAction(
        adminId,
        'emergency_rotation',
        restaurantId,
        'restaurant',
        {
          previousRestaurant: currentRestaurant?.name,
          newRestaurant: targetRestaurant.name,
          reason
        }
      );

      // Send notifications
      await this.sendNotification('EMERGENCY_ROTATION', {
        title: 'Emergency Restaurant Change',
        message: `${targetRestaurant.name} has been set as the featured restaurant (Emergency override)`,
        recipientType: 'admin',
        restaurantId
      });

      return {
        previousRestaurant: currentRestaurant,
        newRestaurant: targetRestaurant,
        rotationType: 'emergency',
        reason
      };

    } catch (error) {
      console.error('❌ Emergency rotation failed:', error);
      throw error;
    } finally {
      this.isRotationRunning = false;
    }
  }

  /**
   * Get next restaurant from queue
   */
  async getNextRestaurantFromQueue() {
    const nextInQueue = await prisma.restaurantQueue.findFirst({
      where: { status: 'PENDING' },
      orderBy: { position: 'asc' },
      include: {
        restaurant: true
      }
    });

    return nextInQueue;
  }

  /**
   * Get rotation schedule preview
   */
  async getRotationPreview(weeks = 8) {
    try {
      const config = await this.getRotationConfig();
      const queue = await prisma.restaurantQueue.findMany({
        where: { status: 'PENDING' },
        orderBy: { position: 'asc' },
        take: weeks,
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              address: true,
              imageUrl: true,
              rating: true,
              categories: true
            }
          }
        }
      });

      const preview = [];
      let currentDate = config?.nextRotationDate ? new Date(config.nextRotationDate) : new Date();

      queue.forEach((queueItem, index) => {
        if (index > 0) {
          // Add 7 days for each subsequent restaurant
          currentDate = new Date(currentDate.getTime() + 7 * 24 * 60 * 60 * 1000);
        }

        preview.push({
          week: index + 1,
          estimatedDate: new Date(currentDate),
          restaurant: queueItem.restaurant,
          queuePosition: queueItem.position,
          notes: queueItem.notes
        });
      });

      return {
        rotationConfig: config,
        preview,
        totalWeeksPlanned: preview.length
      };
    } catch (error) {
      console.error('❌ Error generating rotation preview:', error);
      throw error;
    }
  }

  /**
   * Get rotation history and analytics
   */
  async getRotationHistory(limit = 20) {
    try {
      const history = await prisma.rotationHistory.findMany({
        take: limit,
        orderBy: { startDate: 'desc' },
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              address: true,
              imageUrl: true,
              rating: true
            }
          }
        }
      });

      // Calculate analytics
      const totalRotations = history.length;
      const avgRsvpsPerWeek = history.reduce((sum, h) => sum + h.totalRsvps, 0) / totalRotations || 0;
      const avgVisitsPerWeek = history.reduce((sum, h) => sum + h.totalVisits, 0) / totalRotations || 0;
      const avgRating = history.filter(h => h.averageRating).reduce((sum, h) => sum + h.averageRating, 0) / history.filter(h => h.averageRating).length || 0;

      return {
        history,
        analytics: {
          totalRotations,
          avgRsvpsPerWeek: Math.round(avgRsvpsPerWeek * 100) / 100,
          avgVisitsPerWeek: Math.round(avgVisitsPerWeek * 100) / 100,
          avgRating: Math.round(avgRating * 100) / 100
        }
      };
    } catch (error) {
      console.error('❌ Error getting rotation history:', error);
      throw error;
    }
  }

  /**
   * Send notification
   */
  async sendNotification(type, data) {
    try {
      await prisma.rotationNotification.create({
        data: {
          type,
          recipientType: data.recipientType,
          recipientId: data.recipientId || null,
          title: data.title,
          message: data.message,
          restaurantId: data.restaurantId || null,
          status: 'pending'
        }
      });

      // TODO: Integrate with actual notification service (email, push, etc.)
      console.log(`📱 Notification queued: ${data.title}`);
    } catch (error) {
      console.error('❌ Error sending notification:', error);
    }
  }

  /**
   * Check queue health and send alerts
   */
  async checkQueueHealth() {
    try {
      const config = await this.getRotationConfig();
      const queueCount = await prisma.restaurantQueue.count({
        where: { status: 'PENDING' }
      });

      // Auto-maintain queue size at 20 restaurants
      if (queueCount < 20) {
        console.log(`🏥 Queue health check: ${queueCount} restaurants, auto-adding to reach 20...`);
        
        try {
          const autoQueueService = require('./autoQueueService');
          const result = await autoQueueService.maintainQueueSize(20);
          
          if (result.success && result.restaurantsAdded > 0) {
            console.log(`✅ Auto-queue: Added ${result.restaurantsAdded} restaurants to maintain queue size`);
            
            await this.sendNotification('QUEUE_AUTO_FILLED', {
              title: 'Restaurant Queue Auto-Maintained',
              message: `Automatically added ${result.restaurantsAdded} restaurants to maintain queue size of 20.`,
              recipientType: 'admin'
            });
          }
        } catch (autoQueueError) {
          console.error('❌ Auto-queue failed during health check:', autoQueueError);
          
          // Fallback to manual notification
          await this.sendNotification('QUEUE_LOW', {
            title: 'Restaurant Queue Running Low',
            message: `Only ${queueCount} restaurants remaining in queue. Auto-fill failed, please add manually.`,
            recipientType: 'admin'
          });
        }
      } else if (queueCount === 0) {
        await this.sendNotification('QUEUE_EMPTY', {
          title: 'Restaurant Queue Empty',
          message: 'The restaurant queue is empty. Please add restaurants to maintain rotation.',
          recipientType: 'admin'
        });
      } else {
        console.log(`✅ Queue health check: ${queueCount} restaurants - healthy`);
      }
    } catch (error) {
      console.error('❌ Error checking queue health:', error);
    }
  }

  /**
   * Cleanup - stop cron jobs
   */
  destroy() {
    if (this.cronJob) {
      this.cronJob.stop();
      this.cronJob.destroy();
    }
  }
}

module.exports = new RotationService();
