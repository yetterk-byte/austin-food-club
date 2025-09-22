const webpush = require('web-push');
const admin = require('firebase-admin');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

/**
 * Push Notification Service for Austin Food Club
 * Supports both web push notifications and mobile FCM
 */
class PushNotificationService {
  constructor() {
    this.isInitialized = false;
    this.initializeServices();
  }

  initializeServices() {
    try {
      // Initialize Web Push (VAPID)
      if (process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY) {
        webpush.setVapidDetails(
          'mailto:admin@austinfoodclub.com',
          process.env.VAPID_PUBLIC_KEY,
          process.env.VAPID_PRIVATE_KEY
        );
        console.log('✅ Web Push initialized');
      } else {
        console.warn('⚠️ VAPID keys not found - Web push disabled');
      }

      // Initialize Firebase Admin for mobile push
      if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert({
              projectId: process.env.FIREBASE_PROJECT_ID,
              clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
              privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
            })
          });
        }
        this.messaging = admin.messaging();
        console.log('✅ Firebase messaging initialized');
      } else {
        console.warn('⚠️ Firebase config not found - Mobile push disabled');
      }

      this.isInitialized = true;
    } catch (error) {
      console.error('❌ Error initializing push notification service:', error);
    }
  }

  /**
   * Send push notification to a user
   */
  async sendPushNotification(userId, notification) {
    try {
      // Check user preferences and quiet hours
      const preferences = await this.getUserPreferences(userId);
      if (!preferences || !preferences.pushEnabled) {
        console.log(`🔕 Push notifications disabled for user ${userId}`);
        return { sent: false, reason: 'disabled' };
      }

      if (this.isQuietHours(preferences)) {
        console.log(`🌙 Quiet hours - skipping notification for user ${userId}`);
        return { sent: false, reason: 'quiet_hours' };
      }

      // Check notification type preference
      if (!this.isNotificationTypeEnabled(notification.type, preferences)) {
        console.log(`🔕 Notification type ${notification.type} disabled for user ${userId}`);
        return { sent: false, reason: 'type_disabled' };
      }

      // Get user's active push subscriptions
      const subscriptions = await this.getActiveSubscriptions(userId);
      if (subscriptions.length === 0) {
        console.log(`📱 No active subscriptions for user ${userId}`);
        return { sent: false, reason: 'no_subscriptions' };
      }

      const results = [];

      // Send to all user devices
      for (const subscription of subscriptions) {
        try {
          if (subscription.platform === 'web') {
            await this.sendWebPush(subscription, notification);
          } else {
            await this.sendMobilePush(subscription, notification);
          }
          results.push({ platform: subscription.platform, status: 'sent' });
        } catch (error) {
          console.error(`❌ Failed to send to ${subscription.platform}:`, error);
          results.push({ platform: subscription.platform, status: 'failed', error: error.message });
        }
      }

      // Log notification
      await this.logNotification(userId, notification, results);

      return { sent: true, results };
    } catch (error) {
      console.error('❌ Error sending push notification:', error);
      await this.logNotification(userId, notification, [], error.message);
      return { sent: false, error: error.message };
    }
  }

  /**
   * Send web push notification
   */
  async sendWebPush(subscription, notification) {
    const payload = JSON.stringify({
      title: notification.title,
      body: notification.body,
      icon: '/icon-192x192.png',
      badge: '/badge-72x72.png',
      data: notification.data || {},
      actions: notification.actions || [],
      tag: notification.data?.type || 'default',
      requireInteraction: notification.data?.type === 'rsvp_reminder'
    });

    try {
      await webpush.sendNotification({
        endpoint: subscription.endpoint,
        keys: {
          p256dh: subscription.p256dh,
          auth: subscription.auth
        }
      }, payload);

      console.log(`📧 Web push sent to user ${subscription.userId}`);
    } catch (error) {
      if (error.statusCode === 410 || error.statusCode === 404) {
        // Subscription expired or invalid
        await this.deactivateSubscription(subscription.id);
        console.log(`🗑️ Deactivated expired web subscription ${subscription.id}`);
      }
      throw error;
    }
  }

  /**
   * Send mobile push notification via FCM
   */
  async sendMobilePush(subscription, notification) {
    if (!this.messaging) {
      throw new Error('Firebase messaging not initialized');
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: {
        ...notification.data,
        type: notification.type || 'general'
      },
      token: subscription.fcmToken,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#20b2aa',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    try {
      const response = await this.messaging.send(message);
      console.log(`📱 Mobile push sent to user ${subscription.userId}:`, response);
    } catch (error) {
      if (error.code === 'messaging/invalid-registration-token' || 
          error.code === 'messaging/registration-token-not-registered') {
        // Token invalid, deactivate subscription
        await this.deactivateSubscription(subscription.id);
        console.log(`🗑️ Deactivated invalid mobile subscription ${subscription.id}`);
      }
      throw error;
    }
  }

  /**
   * Notification type methods
   */
  async sendWeeklyAnnouncement(restaurantData) {
    console.log(`📢 Sending weekly announcement for ${restaurantData.name}`);
    
    const users = await this.getUsersWithPreference('weeklyAnnouncement');
    const results = [];

    for (const user of users) {
      const result = await this.sendPushNotification(user.id, {
        type: 'weekly_announcement',
        title: `🍽️ This Week: ${restaurantData.name}`,
        body: `Join us at ${restaurantData.name} - ${this.formatCategories(restaurantData.categories)} in Austin`,
        data: {
          type: 'weekly_announcement',
          restaurantId: restaurantData.id,
          action: 'view_restaurant'
        },
        actions: [
          { action: 'rsvp', title: 'RSVP Now' },
          { action: 'details', title: 'View Details' }
        ]
      });
      results.push({ userId: user.id, ...result });
    }

    console.log(`📊 Weekly announcement sent to ${results.filter(r => r.sent).length}/${users.length} users`);
    return results;
  }

  async sendRSVPReminder(rsvpData) {
    const hoursUntil = Math.round((new Date(rsvpData.date) - new Date()) / (1000 * 60 * 60));
    const timeText = hoursUntil > 0 ? `in ${hoursUntil} hours` : 'soon';

    return await this.sendPushNotification(rsvpData.userId, {
      type: 'rsvp_reminder',
      title: `⏰ Reminder: ${rsvpData.restaurantName}`,
      body: `You're going to ${rsvpData.restaurantName} ${timeText}!`,
      data: {
        type: 'rsvp_reminder',
        rsvpId: rsvpData.id,
        restaurantId: rsvpData.restaurantId,
        address: rsvpData.address
      },
      actions: [
        { action: 'directions', title: 'Get Directions' },
        { action: 'cancel', title: 'Cancel RSVP' }
      ]
    });
  }

  async sendFriendNotification(userId, friendData) {
    return await this.sendPushNotification(userId, {
      type: 'friend_activity',
      title: '👥 Friend Activity',
      body: `${friendData.friendName} is going to ${friendData.restaurantName} on ${friendData.day}`,
      data: {
        type: 'friend_activity',
        friendId: friendData.friendId,
        restaurantId: friendData.restaurantId
      }
    });
  }

  async sendVisitReminder(userId, visitData) {
    return await this.sendPushNotification(userId, {
      type: 'visit_reminder',
      title: `📸 Don't forget to verify your visit!`,
      body: `Upload a photo from your visit to ${visitData.restaurantName}`,
      data: {
        type: 'visit_reminder',
        restaurantId: visitData.restaurantId
      },
      actions: [
        { action: 'verify', title: 'Verify Visit' },
        { action: 'skip', title: 'Skip' }
      ]
    });
  }

  /**
   * Admin broadcast notifications
   */
  async sendBroadcast(notification, targetUsers = null) {
    console.log(`📢 Sending broadcast: ${notification.title}`);
    
    let users;
    if (targetUsers) {
      users = await prisma.user.findMany({
        where: { id: { in: targetUsers } },
        include: { notificationPreferences: true }
      });
    } else {
      users = await prisma.user.findMany({
        include: { notificationPreferences: true }
      });
    }

    const results = [];
    for (const user of users) {
      const result = await this.sendPushNotification(user.id, {
        ...notification,
        type: 'admin_broadcast'
      });
      results.push({ userId: user.id, ...result });
    }

    console.log(`📊 Broadcast sent to ${results.filter(r => r.sent).length}/${users.length} users`);
    return results;
  }

  /**
   * Helper methods
   */
  async getUserPreferences(userId) {
    return await prisma.notificationPreferences.findUnique({
      where: { userId }
    });
  }

  async getActiveSubscriptions(userId) {
    return await prisma.pushSubscription.findMany({
      where: {
        userId,
        isActive: true
      }
    });
  }

  async getUsersWithPreference(preferenceType) {
    return await prisma.user.findMany({
      where: {
        notificationPreferences: {
          [preferenceType]: true,
          pushEnabled: true
        }
      },
      include: {
        notificationPreferences: true
      }
    });
  }

  isQuietHours(preferences) {
    const now = new Date();
    const currentTime = now.getHours().toString().padStart(2, '0') + ':' + 
                       now.getMinutes().toString().padStart(2, '0');
    
    const start = preferences.quietHoursStart;
    const end = preferences.quietHoursEnd;
    
    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (start > end) {
      return currentTime >= start || currentTime <= end;
    }
    
    return currentTime >= start && currentTime <= end;
  }

  isNotificationTypeEnabled(type, preferences) {
    const typeMap = {
      'weekly_announcement': preferences.weeklyAnnouncement,
      'rsvp_reminder': preferences.rsvpReminders,
      'friend_activity': preferences.friendActivity,
      'visit_reminder': preferences.visitReminders,
      'admin_broadcast': preferences.adminAlerts
    };
    
    return typeMap[type] !== false; // Default to true if not specified
  }

  async deactivateSubscription(subscriptionId) {
    await prisma.pushSubscription.update({
      where: { id: subscriptionId },
      data: { isActive: false }
    });
  }

  async logNotification(userId, notification, results = [], error = null) {
    await prisma.notificationLog.create({
      data: {
        userId,
        type: notification.type || 'general',
        title: notification.title,
        body: notification.body,
        data: notification.data || {},
        status: error ? 'failed' : 'sent',
        error,
        sentAt: error ? null : new Date()
      }
    });
  }

  formatCategories(categories) {
    if (!categories) return 'Restaurant';
    try {
      const parsed = JSON.parse(categories);
      return parsed[0]?.title || 'Restaurant';
    } catch {
      return categories.split(',')[0] || 'Restaurant';
    }
  }

  /**
   * Test notification
   */
  async sendTestNotification(userId, platform = 'all') {
    return await this.sendPushNotification(userId, {
      type: 'test',
      title: '🧪 Test Notification',
      body: 'Austin Food Club push notifications are working!',
      data: {
        type: 'test',
        timestamp: new Date().toISOString()
      }
    });
  }

  /**
   * Get notification statistics
   */
  async getNotificationStats(days = 7) {
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    
    const stats = await prisma.notificationLog.groupBy({
      by: ['type', 'status'],
      where: {
        createdAt: { gte: since }
      },
      _count: true
    });

    const totalUsers = await prisma.user.count();
    const enabledUsers = await prisma.notificationPreferences.count({
      where: { pushEnabled: true }
    });

    return {
      totalUsers,
      enabledUsers,
      enabledPercentage: Math.round((enabledUsers / totalUsers) * 100),
      stats: stats.reduce((acc, stat) => {
        const key = `${stat.type}_${stat.status}`;
        acc[key] = stat._count;
        return acc;
      }, {}),
      period: `${days} days`
    };
  }
}

module.exports = new PushNotificationService();
