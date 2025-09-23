const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { requireAdmin, logAdminActionMiddleware } = require('../middleware/adminAuth');
const analyticsService = require('../services/analyticsService');
const websocketService = require('../services/websocketService');

const router = express.Router();
const prisma = new PrismaClient();

// Apply admin authentication to all routes
router.use(requireAdmin);

/**
 * GET /api/admin/analytics/:cityId
 * Get comprehensive analytics for a specific city
 */
router.get('/:cityId', logAdminActionMiddleware('view_analytics', 'analytics'), async (req, res) => {
  try {
    const { cityId } = req.params;
    const { timeRange = '30d' } = req.query;

    // Verify city exists
    const city = await prisma.city.findUnique({
      where: { id: cityId }
    });

    if (!city) {
      return res.status(404).json({ error: 'City not found' });
    }

    // For now, return mock data to test frontend functionality
    const analytics = {
      overview: {
        totalRestaurants: 29,
        activeRestaurants: 25,
        totalUsers: 150,
        totalRsvps: 45,
        totalVisits: 32,
        queueLength: 20,
        avgRating: 4.2
      },
      trends: {
        userGrowth: 12.5,
        rsvpTrends: {},
        visitTrends: {},
        restaurantPerformance: {}
      },
      engagement: {
        engagementRate: 75.5,
        retentionRate: 85.2,
        activeUsers: 112,
        totalUsers: 150
      },
      performance: {
        topRestaurants: [],
        rotationEfficiency: { status: 'good', score: 80 },
        queueHealth: { status: 'healthy', score: 100 },
        systemMetrics: {}
      },
      insights: [
        {
          type: 'success',
          category: 'restaurant_performance',
          title: 'Top Performing Restaurant',
          message: 'Sundance BBQ leads with 15 total engagements',
          value: 15
        },
        {
          type: 'success',
          category: 'user_growth',
          title: 'Growing User Base',
          message: 'User base grew by 12.5% this period',
          value: 12.5
        }
      ],
      timeRange,
      generatedAt: new Date().toISOString()
    };
    
    // TODO: Uncomment when Prisma issue is fixed
    // const analytics = await analyticsService.getCityAnalytics(cityId, timeRange);

    res.json({
      success: true,
      city: {
        id: city.id,
        name: city.name,
        displayName: city.displayName
      },
      analytics
    });

  } catch (error) {
    console.error('❌ Error fetching analytics:', error);
    res.status(500).json({ error: 'Failed to fetch analytics: ' + error.message });
  }
});

/**
 * GET /api/admin/analytics/:cityId/realtime
 * Get real-time metrics for a specific city
 */
router.get('/:cityId/realtime', async (req, res) => {
  try {
    const { cityId } = req.params;

    // Verify city exists
    const city = await prisma.city.findUnique({
      where: { id: cityId }
    });

    if (!city) {
      return res.status(404).json({ error: 'City not found' });
    }

    console.log('🔍 Analytics Route: Prisma client available:', !!prisma);
    console.log('🔍 Analytics Route: RSVP model available:', !!prisma.rsvp);
    
    // For now, return mock data to test frontend functionality
    const realTimeMetrics = {
      rsvps24h: 12,
      visits24h: 8,
      activeUsers24h: 15,
      timestamp: new Date().toISOString()
    };
    
    // TODO: Uncomment when Prisma issue is fixed
    // const realTimeMetrics = await analyticsService.getRealTimeMetrics(cityId, prisma);

    res.json({
      success: true,
      city: {
        id: city.id,
        name: city.name,
        displayName: city.displayName
      },
      metrics: realTimeMetrics
    });

  } catch (error) {
    console.error('❌ Error fetching real-time metrics:', error);
    res.status(500).json({ error: 'Failed to fetch real-time metrics: ' + error.message });
  }
});

/**
 * GET /api/admin/analytics/:cityId/restaurants
 * Get detailed restaurant analytics
 */
router.get('/:cityId/restaurants', async (req, res) => {
  try {
    const { cityId } = req.params;
    const { timeRange = '30d' } = req.query;

    // Verify city exists
    const city = await prisma.city.findUnique({
      where: { id: cityId }
    });

    if (!city) {
      return res.status(404).json({ error: 'City not found' });
    }

    const dateRange = analyticsService.getDateRange(timeRange);

    const restaurants = await prisma.restaurant.findMany({
      where: {
        cityId,
        createdAt: { gte: dateRange.start }
      },
      include: {
        rsvps: {
          where: { createdAt: { gte: dateRange.start } },
          include: { user: true }
        },
        verifiedVisits: {
          where: { createdAt: { gte: dateRange.start } },
          include: { user: true }
        },
        rotationHistory: {
          where: { createdAt: { gte: dateRange.start } }
        }
      }
    });

    const restaurantAnalytics = restaurants.map(restaurant => {
      const totalRsvps = restaurant.rsvps.length;
      const totalVisits = restaurant.verifiedVisits.length;
      const avgRating = restaurant.verifiedVisits.length > 0 
        ? restaurant.verifiedVisits.reduce((sum, v) => sum + (v.rating || 0), 0) / restaurant.verifiedVisits.length
        : restaurant.rating || 0;

      const engagementScore = analyticsService.calculateEngagementScore(totalRsvps, totalVisits);
      const satisfactionScore = analyticsService.calculateSatisfactionScore(restaurant.verifiedVisits);
      const popularityScore = analyticsService.calculatePopularityScore(totalRsvps, restaurant.rating);

      return {
        id: restaurant.id,
        name: restaurant.name,
        address: restaurant.address,
        rating: restaurant.rating,
        price: restaurant.price,
        imageUrl: restaurant.imageUrl,
        isFeatured: restaurant.isFeatured,
        metrics: {
          totalRsvps,
          totalVisits,
          avgRating: Math.round(avgRating * 10) / 10,
          engagementScore,
          satisfactionScore,
          popularityScore,
          totalScore: Math.round((engagementScore + satisfactionScore + popularityScore) / 3)
        },
        trends: {
          rsvpsByDay: analyticsService.groupByDay(restaurant.rsvps, 'createdAt'),
          visitsByDay: analyticsService.groupByDay(restaurant.verifiedVisits, 'createdAt')
        },
        rotationHistory: restaurant.rotationHistory.map(rh => ({
          startDate: rh.startDate,
          endDate: rh.endDate,
          totalRsvps: rh.totalRsvps,
          totalVisits: rh.totalVisits,
          averageRating: rh.averageRating
        }))
      };
    });

    // Sort by total score
    restaurantAnalytics.sort((a, b) => b.metrics.totalScore - a.metrics.totalScore);

    res.json({
      success: true,
      city: {
        id: city.id,
        name: city.name,
        displayName: city.displayName
      },
      restaurants: restaurantAnalytics,
      timeRange
    });

  } catch (error) {
    console.error('❌ Error fetching restaurant analytics:', error);
    res.status(500).json({ error: 'Failed to fetch restaurant analytics: ' + error.message });
  }
});

/**
 * GET /api/admin/analytics/:cityId/users
 * Get user engagement analytics
 */
router.get('/:cityId/users', async (req, res) => {
  try {
    const { cityId } = req.params;
    const { timeRange = '30d' } = req.query;

    // Verify city exists
    const city = await prisma.city.findUnique({
      where: { id: cityId }
    });

    if (!city) {
      return res.status(404).json({ error: 'City not found' });
    }

    const dateRange = analyticsService.getDateRange(timeRange);

    const users = await prisma.user.findMany({
      include: {
        rsvps: {
          where: {
            createdAt: { gte: dateRange.start },
            restaurant: { cityId }
          },
          include: { restaurant: true }
        },
        verifiedVisits: {
          where: {
            createdAt: { gte: dateRange.start },
            restaurant: { cityId }
          },
          include: { restaurant: true }
        }
      }
    });

    const userAnalytics = users.map(user => {
      const totalRsvps = user.rsvps.length;
      const totalVisits = user.verifiedVisits.length;
      const avgRating = user.verifiedVisits.length > 0 
        ? user.verifiedVisits.reduce((sum, v) => sum + (v.rating || 0), 0) / user.verifiedVisits.length
        : 0;

      const engagementLevel = totalRsvps + totalVisits >= 10 ? 'high' : 
                            totalRsvps + totalVisits >= 5 ? 'medium' : 'low';

      return {
        id: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        createdAt: user.createdAt,
        metrics: {
          totalRsvps,
          totalVisits,
          avgRating: Math.round(avgRating * 10) / 10,
          engagementLevel,
          totalEngagement: totalRsvps + totalVisits
        },
        recentActivity: {
          rsvps: user.rsvps.slice(-5).map(rsvp => ({
            restaurant: rsvp.restaurant.name,
            date: rsvp.createdAt
          })),
          visits: user.verifiedVisits.slice(-5).map(visit => ({
            restaurant: visit.restaurant.name,
            rating: visit.rating,
            date: visit.createdAt
          }))
        }
      };
    });

    // Sort by total engagement
    userAnalytics.sort((a, b) => b.metrics.totalEngagement - a.metrics.totalEngagement);

    // Calculate engagement distribution
    const engagementDistribution = {
      high: userAnalytics.filter(u => u.metrics.engagementLevel === 'high').length,
      medium: userAnalytics.filter(u => u.metrics.engagementLevel === 'medium').length,
      low: userAnalytics.filter(u => u.metrics.engagementLevel === 'low').length
    };

    res.json({
      success: true,
      city: {
        id: city.id,
        name: city.name,
        displayName: city.displayName
      },
      users: userAnalytics,
      engagementDistribution,
      timeRange
    });

  } catch (error) {
    console.error('❌ Error fetching user analytics:', error);
    res.status(500).json({ error: 'Failed to fetch user analytics: ' + error.message });
  }
});

/**
 * GET /api/admin/analytics/:cityId/trends
 * Get trend data for charts
 */
router.get('/:cityId/trends', async (req, res) => {
  try {
    const { cityId } = req.params;
    const { timeRange = '30d', metric = 'all' } = req.query;

    // Verify city exists
    const city = await prisma.city.findUnique({
      where: { id: cityId }
    });

    if (!city) {
      return res.status(404).json({ error: 'City not found' });
    }

    const dateRange = analyticsService.getDateRange(timeRange);

    const trends = {};

    if (metric === 'all' || metric === 'rsvps') {
      const rsvps = await prisma.rsvp.findMany({
        where: {
          createdAt: { gte: dateRange.start },
          restaurant: { cityId }
        }
      });
      trends.rsvps = analyticsService.groupByDay(rsvps, 'createdAt');
    }

    if (metric === 'all' || metric === 'visits') {
      const visits = await prisma.verifiedVisit.findMany({
        where: {
          createdAt: { gte: dateRange.start },
          restaurant: { cityId }
        }
      });
      trends.visits = analyticsService.groupByDay(visits, 'createdAt');
    }

    if (metric === 'all' || metric === 'users') {
      const users = await prisma.user.findMany({
        where: {
          createdAt: { gte: dateRange.start }
        }
      });
      trends.users = analyticsService.groupByDay(users, 'createdAt');
    }

    res.json({
      success: true,
      city: {
        id: city.id,
        name: city.name,
        displayName: city.displayName
      },
      trends,
      timeRange
    });

  } catch (error) {
    console.error('❌ Error fetching trend data:', error);
    res.status(500).json({ error: 'Failed to fetch trend data: ' + error.message });
  }
});

/**
 * POST /api/admin/analytics/clear-cache
 * Clear analytics cache
 */
router.post('/clear-cache', async (req, res) => {
  try {
    analyticsService.clearCache();
    
    // Broadcast cache clear to admin dashboard
    websocketService.broadcastToAdmin('analytics_cache_cleared', {
      timestamp: new Date().toISOString()
    });

    res.json({
      success: true,
      message: 'Analytics cache cleared successfully'
    });

  } catch (error) {
    console.error('❌ Error clearing analytics cache:', error);
    res.status(500).json({ error: 'Failed to clear analytics cache: ' + error.message });
  }
});

module.exports = router;
