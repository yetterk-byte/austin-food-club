const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const { requireAuth, optionalAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/adminAuth');
const pushNotificationService = require('../services/pushNotificationService');
const subscriptionManager = require('../services/subscriptionManager');

const prisma = new PrismaClient();

/**
 * Push Notification API Routes
 */

/**
 * Subscription Management
 */

// Handle OPTIONS requests for CORS preflight
router.options('/subscribe', (req, res) => {
  console.log('🔄 OPTIONS request received for /subscribe');
  res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
  res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, X-City-Slug');
  res.header('Access-Control-Allow-Credentials', 'true');
  res.sendStatus(200);
});

// Subscribe to push notifications (public endpoint for testing)
router.post('/subscribe', optionalAuth, async (req, res) => {
  try {
    console.log('📥 Subscription request received:');
    console.log('  Origin:', req.headers.origin);
    console.log('  User-Agent:', req.headers['user-agent']);
    console.log('  Headers:', JSON.stringify(req.headers, null, 2));
    console.log('  Body:', JSON.stringify(req.body, null, 2));
    
    // Set CORS headers for the response
    res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.header('Access-Control-Allow-Credentials', 'true');
    
    const { subscription, platform, deviceInfo } = req.body;
    
    // For testing, use a demo user ID if no authenticated user
    const userId = req.user?.id || 'demo-user-123';

    const result = await subscriptionManager.subscribe(
      userId, 
      subscription, 
      platform, 
      deviceInfo
    );

    res.status(201).json({
      success: true,
      subscription: {
        id: result.id,
        platform: result.platform,
        createdAt: result.createdAt
      },
      message: 'Successfully subscribed to push notifications'
    });
  } catch (error) {
    console.error('❌ Error subscribing to notifications:', error);
    res.status(500).json({
      error: 'Failed to subscribe to notifications',
      details: error.message
    });
  }
});

// Unsubscribe from push notifications
router.delete('/unsubscribe', requireAuth, async (req, res) => {
  try {
    const { subscriptionId } = req.body;
    const userId = req.user.id;

    await subscriptionManager.unsubscribe(userId, subscriptionId);

    res.json({
      success: true,
      message: 'Successfully unsubscribed from push notifications'
    });
  } catch (error) {
    console.error('❌ Error unsubscribing:', error);
    res.status(500).json({
      error: 'Failed to unsubscribe from notifications',
      details: error.message
    });
  }
});

// Get subscription status
router.get('/subscription-status', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const status = await subscriptionManager.getSubscriptionStatus(userId);

    res.json({
      success: true,
      ...status
    });
  } catch (error) {
    console.error('❌ Error getting subscription status:', error);
    res.status(500).json({
      error: 'Failed to get subscription status',
      details: error.message
    });
  }
});

/**
 * Notification Preferences
 */

// Get user notification preferences
router.get('/preferences', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    
    let preferences = await subscriptionManager.getUserPreferences(userId);
    if (!preferences) {
      preferences = await subscriptionManager.ensureNotificationPreferences(userId);
    }

    res.json({
      success: true,
      preferences
    });
  } catch (error) {
    console.error('❌ Error getting preferences:', error);
    res.status(500).json({
      error: 'Failed to get notification preferences',
      details: error.message
    });
  }
});

// Update user notification preferences
router.put('/preferences', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const preferences = req.body;

    const updated = await subscriptionManager.updatePreferences(userId, preferences);

    res.json({
      success: true,
      preferences: updated,
      message: 'Notification preferences updated successfully'
    });
  } catch (error) {
    console.error('❌ Error updating preferences:', error);
    res.status(500).json({
      error: 'Failed to update notification preferences',
      details: error.message
    });
  }
});

/**
 * Testing & Development
 */

// Send test notification
router.post('/test', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { platform } = req.body;

    const result = await pushNotificationService.sendTestNotification(userId, platform);

    res.json({
      success: true,
      result,
      message: 'Test notification sent'
    });
  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    res.status(500).json({
      error: 'Failed to send test notification',
      details: error.message
    });
  }
});

// Get notification logs for user
router.get('/logs', requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const logs = await prisma.notificationLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: parseInt(limit),
      skip: parseInt(offset)
    });

    res.json({
      success: true,
      logs,
      total: logs.length
    });
  } catch (error) {
    console.error('❌ Error getting notification logs:', error);
    res.status(500).json({
      error: 'Failed to get notification logs',
      details: error.message
    });
  }
});

/**
 * Admin Routes
 */

// Send broadcast notification
router.post('/admin/broadcast', requireAdmin, async (req, res) => {
  try {
    const { title, body, data, targetUsers } = req.body;

    const notification = {
      title,
      body,
      data: data || {},
      type: 'admin_broadcast'
    };

    const results = await pushNotificationService.sendBroadcast(notification, targetUsers);

    res.json({
      success: true,
      results,
      message: `Broadcast sent to ${results.filter(r => r.sent).length} users`
    });
  } catch (error) {
    console.error('❌ Error sending broadcast:', error);
    res.status(500).json({
      error: 'Failed to send broadcast notification',
      details: error.message
    });
  }
});

// Get notification statistics
router.get('/admin/stats', requireAdmin, async (req, res) => {
  try {
    const { days = 7 } = req.query;
    const stats = await pushNotificationService.getNotificationStats(parseInt(days));
    const subscriptionStats = await subscriptionManager.getSubscriptionStats();

    res.json({
      success: true,
      notificationStats: stats,
      subscriptionStats
    });
  } catch (error) {
    console.error('❌ Error getting notification stats:', error);
    res.status(500).json({
      error: 'Failed to get notification statistics',
      details: error.message
    });
  }
});

// Get all notification logs (admin)
router.get('/admin/logs', requireAdmin, async (req, res) => {
  try {
    const { limit = 50, offset = 0, type, status } = req.query;
    
    const where = {};
    if (type) where.type = type;
    if (status) where.status = status;

    const logs = await prisma.notificationLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: parseInt(limit),
      skip: parseInt(offset)
    });

    const total = await prisma.notificationLog.count({ where });

    res.json({
      success: true,
      logs,
      total,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: total > parseInt(offset) + parseInt(limit)
      }
    });
  } catch (error) {
    console.error('❌ Error getting admin notification logs:', error);
    res.status(500).json({
      error: 'Failed to get notification logs',
      details: error.message
    });
  }
});

// Test subscription by ID
router.post('/admin/test-subscription/:subscriptionId', requireAdmin, async (req, res) => {
  try {
    const { subscriptionId } = req.params;
    const result = await subscriptionManager.testSubscription(subscriptionId);

    res.json({
      success: true,
      result,
      message: 'Test notification sent to subscription'
    });
  } catch (error) {
    console.error('❌ Error testing subscription:', error);
    res.status(500).json({
      error: 'Failed to test subscription',
      details: error.message
    });
  }
});

// Clean up inactive subscriptions
router.post('/admin/cleanup', requireAdmin, async (req, res) => {
  try {
    const result = await subscriptionManager.cleanupSubscriptions();

    res.json({
      success: true,
      cleaned: result.count,
      message: `Cleaned up ${result.count} inactive subscriptions`
    });
  } catch (error) {
    console.error('❌ Error cleaning up subscriptions:', error);
    res.status(500).json({
      error: 'Failed to cleanup subscriptions',
      details: error.message
    });
  }
});

/**
 * Public notification status (for debugging)
 */
router.get('/status', (req, res) => {
  const hasVapidKeys = !!(process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY);
  const hasFirebaseConfig = !!(process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY);

  res.json({
    success: true,
    status: {
      webPushEnabled: hasVapidKeys,
      mobilePushEnabled: hasFirebaseConfig,
      serviceInitialized: pushNotificationService.isInitialized
    },
    vapidPublicKey: process.env.VAPID_PUBLIC_KEY || null
  });
});

module.exports = router;
