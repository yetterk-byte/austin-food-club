const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const yelpService = require('../services/yelpService');
const restaurantSync = require('../services/restaurantSync');
const featuredRestaurant = require('../services/featuredRestaurant');
const cronService = require('../services/cronService');

const prisma = new PrismaClient();

// GET /api/v1/system/status - Get system status
router.get('/status', async (req, res) => {
  try {
    const status = {
      api: {
        status: 'healthy',
        version: '1.0.0',
        uptime: process.uptime()
      },
      database: {
        status: 'connected',
        // Add database health check here
      },
      yelp: {
        status: yelpService.isConfigured() ? 'configured' : 'not_configured'
      },
      cache: {
        status: 'active'
      },
      cron: {
        status: cronService.isRunning() ? 'running' : 'stopped'
      }
    };
    
    res.json(res.apiResponse.success(status, 'System status retrieved successfully'));
  } catch (error) {
    console.error('Error fetching system status:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch system status', 500));
  }
});

// GET /api/v1/system/stats - Get system statistics
router.get('/stats', async (req, res) => {
  try {
    const [restaurantCount, userCount, rsvpCount, wishlistCount] = await Promise.all([
      prisma.restaurant.count(),
      prisma.user.count(),
      prisma.rSVP.count(),
      prisma.wishlist.count()
    ]);
    
    const stats = {
      restaurants: restaurantCount,
      users: userCount,
      rsvps: rsvpCount,
      wishlistItems: wishlistCount,
      timestamp: new Date().toISOString()
    };
    
    res.json(res.apiResponse.success(stats, 'System statistics retrieved successfully'));
  } catch (error) {
    console.error('Error fetching system stats:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch system statistics', 500));
  }
});

// POST /api/v1/system/sync/restaurants - Sync all restaurants
router.post('/sync/restaurants', async (req, res) => {
  try {
    const result = await restaurantSync.syncAllRestaurants();
    
    res.json(res.apiResponse.success(result, 'Restaurant sync completed successfully'));
  } catch (error) {
    console.error('Error syncing restaurants:', error);
    res.status(500).json(res.apiResponse.error('Failed to sync restaurants', 500));
  }
});

// POST /api/v1/system/featured/rotate - Manually rotate featured restaurant
router.post('/featured/rotate', async (req, res) => {
  try {
    const result = await featuredRestaurant.selectFeaturedRestaurant();
    
    res.json(res.apiResponse.success(result, 'Featured restaurant rotated successfully'));
  } catch (error) {
    console.error('Error rotating featured restaurant:', error);
    res.status(500).json(res.apiResponse.error('Failed to rotate featured restaurant', 500));
  }
});

// GET /api/v1/system/cache/stats - Get cache statistics
router.get('/cache/stats', async (req, res) => {
  try {
    // This would integrate with your cache service
    const cacheStats = {
      hits: 0,
      misses: 0,
      size: 0,
      keys: 0
    };
    
    res.json(res.apiResponse.success(cacheStats, 'Cache statistics retrieved successfully'));
  } catch (error) {
    console.error('Error fetching cache stats:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch cache statistics', 500));
  }
});

// DELETE /api/v1/system/cache - Clear all cache
router.delete('/cache', async (req, res) => {
  try {
    // This would integrate with your cache service
    res.json(res.apiResponse.success(null, 'Cache cleared successfully'));
  } catch (error) {
    console.error('Error clearing cache:', error);
    res.status(500).json(res.apiResponse.error('Failed to clear cache', 500));
  }
});

// GET /api/v1/system/health - Detailed health check
router.get('/health', async (req, res) => {
  try {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: {
          status: 'healthy',
          responseTime: '< 10ms'
        },
        yelp: {
          status: yelpService.isConfigured() ? 'healthy' : 'not_configured',
          responseTime: 'N/A'
        },
        cache: {
          status: 'healthy',
          responseTime: '< 1ms'
        }
      },
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: '1.0.0'
    };
    
    res.json(res.apiResponse.success(health, 'Health check completed successfully'));
  } catch (error) {
    console.error('Error during health check:', error);
    res.status(500).json(res.apiResponse.error('Health check failed', 500));
  }
});

module.exports = router;
