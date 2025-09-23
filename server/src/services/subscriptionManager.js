const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Subscription Manager for Push Notifications
 * Handles subscription lifecycle and device management
 */
class SubscriptionManager {
  
  /**
   * Subscribe user to push notifications
   */
  async subscribe(userId, subscriptionData, platform, deviceInfo = null) {
    try {
      // Validate subscription data
      if (platform === 'web' && (!subscriptionData.endpoint || !subscriptionData.keys)) {
        throw new Error('Invalid web push subscription data');
      }
      
      if (platform !== 'web' && !subscriptionData.fcmToken) {
        throw new Error('Invalid mobile push subscription data');
      }

      // Check for existing subscription
      const whereClause = platform === 'web' 
        ? { endpoint: subscriptionData.endpoint }
        : { fcmToken: subscriptionData.fcmToken };

      const existing = await prisma.pushSubscription.findFirst({
        where: whereClause
      });

      let subscription;

      if (existing) {
        // Update existing subscription
        subscription = await prisma.pushSubscription.update({
          where: { id: existing.id },
          data: {
            userId,
            isActive: true,
            deviceInfo: deviceInfo || existing.deviceInfo,
            updatedAt: new Date()
          }
        });
        console.log(`🔄 Updated existing ${platform} subscription for user ${userId}`);
      } else {
        // Create new subscription
        subscription = await prisma.pushSubscription.create({
          data: {
            userId,
            platform,
            endpoint: subscriptionData.endpoint,
            p256dh: subscriptionData.keys?.p256dh,
            auth: subscriptionData.keys?.auth,
            fcmToken: subscriptionData.fcmToken,
            deviceInfo,
            isActive: true
          }
        });
        console.log(`✅ Created new ${platform} subscription for user ${userId}`);
      }

      // Ensure user has notification preferences
      await this.ensureNotificationPreferences(userId);

      return subscription;
    } catch (error) {
      console.error('❌ Error subscribing user:', error);
      throw error;
    }
  }

  /**
   * Unsubscribe user from push notifications
   */
  async unsubscribe(userId, subscriptionId = null) {
    try {
      const whereClause = subscriptionId 
        ? { id: subscriptionId, userId }
        : { userId };

      const result = await prisma.pushSubscription.updateMany({
        where: whereClause,
        data: { isActive: false }
      });

      console.log(`🔕 Unsubscribed ${result.count} subscriptions for user ${userId}`);
      return result;
    } catch (error) {
      console.error('❌ Error unsubscribing user:', error);
      throw error;
    }
  }

  /**
   * Get user's subscription status
   */
  async getSubscriptionStatus(userId) {
    const subscriptions = await prisma.pushSubscription.findMany({
      where: { userId, isActive: true }
    });

    const preferences = await prisma.notificationPreferences.findUnique({
      where: { userId }
    });

    return {
      hasSubscriptions: subscriptions.length > 0,
      subscriptions: subscriptions.map(sub => ({
        id: sub.id,
        platform: sub.platform,
        createdAt: sub.createdAt
      })),
      preferences: preferences || this.getDefaultPreferences(),
      pushEnabled: preferences?.pushEnabled || false
    };
  }

  /**
   * Update user notification preferences
   */
  async updatePreferences(userId, preferences) {
    try {
      const updated = await prisma.notificationPreferences.upsert({
        where: { userId },
        create: {
          userId,
          ...preferences
        },
        update: preferences
      });

      console.log(`⚙️ Updated notification preferences for user ${userId}`);
      return updated;
    } catch (error) {
      console.error('❌ Error updating preferences:', error);
      throw error;
    }
  }

  /**
   * Ensure user has notification preferences (create defaults if missing)
   */
  async ensureNotificationPreferences(userId) {
    const existing = await prisma.notificationPreferences.findUnique({
      where: { userId }
    });

    if (!existing) {
      return await prisma.notificationPreferences.create({
        data: {
          userId,
          ...this.getDefaultPreferences()
        }
      });
    }

    return existing;
  }

  /**
   * Clean up inactive subscriptions
   */
  async cleanupSubscriptions() {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    
    const result = await prisma.pushSubscription.deleteMany({
      where: {
        isActive: false,
        updatedAt: { lt: thirtyDaysAgo }
      }
    });

    console.log(`🧹 Cleaned up ${result.count} old push subscriptions`);
    return result;
  }

  /**
   * Get subscription statistics
   */
  async getSubscriptionStats() {
    const total = await prisma.pushSubscription.count();
    const active = await prisma.pushSubscription.count({
      where: { isActive: true }
    });
    
    const byPlatform = await prisma.pushSubscription.groupBy({
      by: ['platform'],
      where: { isActive: true },
      _count: true
    });

    const enabledUsers = await prisma.notificationPreferences.count({
      where: { pushEnabled: true }
    });

    return {
      total,
      active,
      inactive: total - active,
      byPlatform: byPlatform.reduce((acc, item) => {
        acc[item.platform] = item._count;
        return acc;
      }, {}),
      enabledUsers
    };
  }

  /**
   * Test subscription
   */
  async testSubscription(subscriptionId) {
    const subscription = await prisma.pushSubscription.findUnique({
      where: { id: subscriptionId },
      include: { user: true }
    });

    if (!subscription) {
      throw new Error('Subscription not found');
    }

    const pushService = require('./pushNotificationService');
    return await pushService.sendTestNotification(subscription.userId);
  }

  /**
   * Default notification preferences
   */
  getDefaultPreferences() {
    return {
      weeklyAnnouncement: true,
      rsvpReminders: true,
      friendActivity: true,
      visitReminders: true,
      adminAlerts: false,
      pushEnabled: false,
      quietHoursStart: "22:00",
      quietHoursEnd: "08:00",
      reminderHoursBefore: 2
    };
  }
}

module.exports = new SubscriptionManager();
