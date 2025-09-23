const { PrismaClient } = require('@prisma/client');

class AnalyticsService {
  constructor() {
    this.cache = new Map();
    this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
  }

  // Initialize Prisma client
  async initialize() {
    if (!this.prisma) {
      this.prisma = new PrismaClient();
      await this.prisma.$connect();
    }
  }

  /**
   * Get comprehensive analytics for a specific city
   */
  async getCityAnalytics(cityId, timeRange = '30d') {
    const cacheKey = `city_analytics_${cityId}_${timeRange}`;
    
    // Check cache first
    if (this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey);
      if (Date.now() - cached.timestamp < this.cacheTimeout) {
        return cached.data;
      }
    }

    try {
      const dateRange = this.getDateRange(timeRange);
      
      // Parallel data fetching for better performance
      const [
        restaurantStats,
        userStats,
        rsvpStats,
        visitStats,
        queueStats,
        rotationStats,
        performanceMetrics,
        engagementMetrics
      ] = await Promise.all([
        this.getRestaurantStats(cityId, dateRange),
        this.getUserStats(cityId, dateRange),
        this.getRsvpStats(cityId, dateRange),
        this.getVisitStats(cityId, dateRange),
        this.getQueueStats(cityId),
        this.getRotationStats(cityId, dateRange),
        this.getPerformanceMetrics(cityId, dateRange),
        this.getEngagementMetrics(cityId, dateRange)
      ]);

      const analytics = {
        overview: {
          totalRestaurants: restaurantStats.total,
          activeRestaurants: restaurantStats.active,
          totalUsers: userStats.total,
          activeUsers: userStats.active,
          totalRsvps: rsvpStats.total,
          totalVisits: visitStats.total,
          queueLength: queueStats.length,
          avgRating: restaurantStats.avgRating
        },
        trends: {
          userGrowth: userStats.growth,
          rsvpTrends: rsvpStats.trends,
          visitTrends: visitStats.trends,
          restaurantPerformance: performanceMetrics
        },
        engagement: engagementMetrics,
        performance: {
          topRestaurants: restaurantStats.topPerformers,
          rotationEfficiency: rotationStats.efficiency,
          queueHealth: queueStats.health,
          systemMetrics: performanceMetrics.system
        },
        insights: await this.generateInsights({
          restaurantStats,
          userStats,
          rsvpStats,
          visitStats,
          queueStats,
          rotationStats
        }),
        timeRange,
        generatedAt: new Date().toISOString()
      };

      // Cache the results
      this.cache.set(cacheKey, {
        data: analytics,
        timestamp: Date.now()
      });

      return analytics;
    } catch (error) {
      console.error('❌ Error generating city analytics:', error);
      throw error;
    }
  }

  /**
   * Get restaurant statistics
   */
  async getRestaurantStats(cityId, dateRange) {
    const restaurants = await this.prisma.restaurant.findMany({
      where: {
        cityId,
        createdAt: { gte: dateRange.start }
      },
      include: {
        rsvps: {
          where: { createdAt: { gte: dateRange.start } }
        },
        verifiedVisits: {
          where: { createdAt: { gte: dateRange.start } }
        }
      }
    });

    const total = restaurants.length;
    const active = restaurants.filter(r => r.isActive).length;
    const avgRating = restaurants.length > 0 
      ? restaurants.reduce((sum, r) => sum + (r.rating || 0), 0) / restaurants.length 
      : 0;

    // Top performers by RSVPs
    const topPerformers = restaurants
      .map(r => ({
        id: r.id,
        name: r.name,
        rsvps: r.rsvps.length,
        visits: r.verifiedVisits.length,
        avgRating: r.rating || 0,
        totalEngagement: r.rsvps.length + r.verifiedVisits.length
      }))
      .sort((a, b) => b.totalEngagement - a.totalEngagement)
      .slice(0, 10);

    return {
      total,
      active,
      avgRating: Math.round(avgRating * 10) / 10,
      topPerformers
    };
  }

  /**
   * Get user statistics
   */
  async getUserStats(cityId, dateRange) {
    const users = await this.prisma.user.findMany({
      where: {
        createdAt: { gte: dateRange.start }
      },
      include: {
        rsvps: {
          where: {
            createdAt: { gte: dateRange.start },
            restaurant: { cityId }
          }
        },
        verifiedVisits: {
          where: {
            createdAt: { gte: dateRange.start },
            restaurant: { cityId }
          }
        }
      }
    });

    const total = users.length;
    const active = users.filter(u => u.rsvps.length > 0 || u.verifiedVisits.length > 0).length;

    // Calculate growth rate
    const previousPeriod = await this.getPreviousPeriodStats(dateRange);
    const growth = previousPeriod.users > 0 
      ? ((total - previousPeriod.users) / previousPeriod.users) * 100 
      : 0;

    return {
      total,
      active,
      growth: Math.round(growth * 10) / 10
    };
  }

  /**
   * Get RSVP statistics
   */
  async getRsvpStats(cityId, dateRange) {
    const rsvps = await this.prisma.rsvp.findMany({
      where: {
        createdAt: { gte: dateRange.start },
        restaurant: { cityId }
      },
      include: {
        restaurant: true,
        user: true
      }
    });

    const total = rsvps.length;
    
    // Group by day for trends
    const trends = this.groupByDay(rsvps, 'createdAt');
    
    // RSVP conversion rate (RSVPs that led to visits)
    const visits = await this.prisma.verifiedVisit.findMany({
      where: {
        createdAt: { gte: dateRange.start },
        restaurant: { cityId }
      }
    });

    const conversionRate = total > 0 ? (visits.length / total) * 100 : 0;

    return {
      total,
      trends,
      conversionRate: Math.round(conversionRate * 10) / 10
    };
  }

  /**
   * Get visit statistics
   */
  async getVisitStats(cityId, dateRange) {
    const visits = await this.prisma.verifiedVisit.findMany({
      where: {
        createdAt: { gte: dateRange.start },
        restaurant: { cityId }
      },
      include: {
        restaurant: true,
        user: true
      }
    });

    const total = visits.length;
    const trends = this.groupByDay(visits, 'createdAt');
    
    // Average rating from visits
    const avgRating = visits.length > 0 
      ? visits.reduce((sum, v) => sum + (v.rating || 0), 0) / visits.length 
      : 0;

    return {
      total,
      trends,
      avgRating: Math.round(avgRating * 10) / 10
    };
  }

  /**
   * Get queue statistics
   */
  async getQueueStats(cityId) {
    const queue = await this.prisma.restaurantQueue.findMany({
      where: {
        restaurant: { cityId },
        status: 'PENDING'
      },
      include: {
        restaurant: true
      },
      orderBy: { position: 'asc' }
    });

    const length = queue.length;
    
    // Queue health metrics
    const avgRating = queue.length > 0 
      ? queue.reduce((sum, q) => sum + (q.restaurant.rating || 0), 0) / queue.length 
      : 0;

    const health = this.calculateQueueHealth(length, avgRating);

    return {
      length,
      avgRating: Math.round(avgRating * 10) / 10,
      health,
      restaurants: queue.map(q => ({
        id: q.restaurant.id,
        name: q.restaurant.name,
        position: q.position,
        rating: q.restaurant.rating || 0
      }))
    };
  }

  /**
   * Get rotation statistics
   */
  async getRotationStats(cityId, dateRange) {
    const rotations = await this.prisma.rotationHistory.findMany({
      where: {
        createdAt: { gte: dateRange.start },
        restaurant: { cityId }
      },
      include: {
        restaurant: true
      }
    });

    const totalRotations = rotations.length;
    
    // Calculate efficiency metrics
    const avgRsvps = rotations.length > 0 
      ? rotations.reduce((sum, r) => sum + r.totalRsvps, 0) / rotations.length 
      : 0;

    const avgVisits = rotations.length > 0 
      ? rotations.reduce((sum, r) => sum + r.totalVisits, 0) / rotations.length 
      : 0;

    const efficiency = this.calculateRotationEfficiency(avgRsvps, avgVisits);

    return {
      totalRotations,
      avgRsvps: Math.round(avgRsvps * 10) / 10,
      avgVisits: Math.round(avgVisits * 10) / 10,
      efficiency
    };
  }

  /**
   * Get performance metrics
   */
  async getPerformanceMetrics(cityId, dateRange) {
    // System performance metrics
    const systemMetrics = {
      apiResponseTime: await this.getApiResponseTime(),
      databasePerformance: await this.getDatabasePerformance(),
      cacheHitRate: await this.getCacheHitRate(),
      errorRate: await this.getErrorRate(dateRange)
    };

    // Restaurant performance metrics
    const restaurants = await this.prisma.restaurant.findMany({
      where: { cityId },
      include: {
        rsvps: { where: { createdAt: { gte: dateRange.start } } },
        verifiedVisits: { where: { createdAt: { gte: dateRange.start } } }
      }
    });

    const performanceMetrics = restaurants.map(r => ({
      id: r.id,
      name: r.name,
      engagementScore: this.calculateEngagementScore(r.rsvps.length, r.verifiedVisits.length),
      satisfactionScore: this.calculateSatisfactionScore(r.verifiedVisits),
      popularityScore: this.calculatePopularityScore(r.rsvps.length, r.rating)
    }));

    return {
      system: systemMetrics,
      restaurants: performanceMetrics
    };
  }

  /**
   * Get engagement metrics
   */
  async getEngagementMetrics(cityId, dateRange) {
    const users = await this.prisma.user.findMany({
      include: {
        rsvps: {
          where: {
            createdAt: { gte: dateRange.start },
            restaurant: { cityId }
          }
        },
        verifiedVisits: {
          where: {
            createdAt: { gte: dateRange.start },
            restaurant: { cityId }
          }
        }
      }
    });

    const totalUsers = users.length;
    const activeUsers = users.filter(u => u.rsvps.length > 0 || u.verifiedVisits.length > 0).length;
    const engagementRate = totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;

    // User retention
    const retentionRate = await this.calculateRetentionRate(cityId, dateRange);

    return {
      engagementRate: Math.round(engagementRate * 10) / 10,
      retentionRate: Math.round(retentionRate * 10) / 10,
      activeUsers,
      totalUsers
    };
  }

  /**
   * Generate insights from analytics data
   */
  async generateInsights(data) {
    const insights = [];

    // Restaurant performance insights
    if (data.restaurantStats.topPerformers.length > 0) {
      const topRestaurant = data.restaurantStats.topPerformers[0];
      insights.push({
        type: 'success',
        category: 'restaurant_performance',
        title: 'Top Performing Restaurant',
        message: `${topRestaurant.name} leads with ${topRestaurant.totalEngagement} total engagements`,
        value: topRestaurant.totalEngagement
      });
    }

    // User growth insights
    if (data.userStats.growth > 0) {
      insights.push({
        type: 'success',
        category: 'user_growth',
        title: 'Growing User Base',
        message: `User base grew by ${data.userStats.growth}% this period`,
        value: data.userStats.growth
      });
    } else if (data.userStats.growth < 0) {
      insights.push({
        type: 'warning',
        category: 'user_growth',
        title: 'Declining User Base',
        message: `User base declined by ${Math.abs(data.userStats.growth)}% this period`,
        value: data.userStats.growth
      });
    }

    // Queue health insights
    if (data.queueStats.health.status === 'healthy') {
      insights.push({
        type: 'success',
        category: 'queue_health',
        title: 'Healthy Queue',
        message: `Queue is well-stocked with ${data.queueStats.length} restaurants`,
        value: data.queueStats.length
      });
    } else if (data.queueStats.health.status === 'low') {
      insights.push({
        type: 'warning',
        category: 'queue_health',
        title: 'Low Queue Stock',
        message: `Queue needs more restaurants (${data.queueStats.length} remaining)`,
        value: data.queueStats.length
      });
    }

    // RSVP conversion insights
    if (data.rsvpStats.conversionRate > 50) {
      insights.push({
        type: 'success',
        category: 'conversion',
        title: 'High Conversion Rate',
        message: `${data.rsvpStats.conversionRate}% of RSVPs convert to visits`,
        value: data.rsvpStats.conversionRate
      });
    } else if (data.rsvpStats.conversionRate < 30) {
      insights.push({
        type: 'warning',
        category: 'conversion',
        title: 'Low Conversion Rate',
        message: `Only ${data.rsvpStats.conversionRate}% of RSVPs convert to visits`,
        value: data.rsvpStats.conversionRate
      });
    }

    return insights;
  }

  /**
   * Helper methods
   */
  getDateRange(timeRange) {
    const now = new Date();
    let start;

    switch (timeRange) {
      case '7d':
        start = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case '30d':
        start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case '90d':
        start = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        break;
      default:
        start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    }

    return { start, end: now };
  }

  groupByDay(data, dateField) {
    const grouped = {};
    data.forEach(item => {
      const date = new Date(item[dateField]).toISOString().split('T')[0];
      grouped[date] = (grouped[date] || 0) + 1;
    });
    return grouped;
  }

  calculateQueueHealth(length, avgRating) {
    if (length >= 20 && avgRating >= 4.0) return { status: 'healthy', score: 100 };
    if (length >= 15 && avgRating >= 3.5) return { status: 'good', score: 80 };
    if (length >= 10 && avgRating >= 3.0) return { status: 'fair', score: 60 };
    if (length >= 5) return { status: 'low', score: 40 };
    return { status: 'critical', score: 20 };
  }

  calculateRotationEfficiency(avgRsvps, avgVisits) {
    const totalEngagement = avgRsvps + avgVisits;
    if (totalEngagement >= 50) return { status: 'excellent', score: 100 };
    if (totalEngagement >= 30) return { status: 'good', score: 80 };
    if (totalEngagement >= 15) return { status: 'fair', score: 60 };
    if (totalEngagement >= 5) return { status: 'poor', score: 40 };
    return { status: 'critical', score: 20 };
  }

  calculateEngagementScore(rsvps, visits) {
    return Math.min(100, (rsvps * 2 + visits * 3));
  }

  calculateSatisfactionScore(visits) {
    if (visits.length === 0) return 0;
    const avgRating = visits.reduce((sum, v) => sum + (v.rating || 0), 0) / visits.length;
    return Math.round(avgRating * 20); // Convert 5-star to 100-point scale
  }

  calculatePopularityScore(rsvps, rating) {
    const ratingScore = (rating || 0) * 20; // Convert 5-star to 100-point scale
    const rsvpScore = Math.min(60, rsvps * 2); // Cap RSVP score at 60
    return Math.round(ratingScore + rsvpScore);
  }

  async getPreviousPeriodStats(dateRange) {
    const periodLength = dateRange.end.getTime() - dateRange.start.getTime();
    const previousStart = new Date(dateRange.start.getTime() - periodLength);
    const previousEnd = dateRange.start;

    const users = await this.prisma.user.count({
      where: {
        createdAt: {
          gte: previousStart,
          lt: previousEnd
        }
      }
    });

    return { users };
  }

  async getApiResponseTime() {
    // Mock implementation - in production, this would come from monitoring
    return Math.random() * 100 + 50; // 50-150ms
  }

  async getDatabasePerformance() {
    // Mock implementation - in production, this would come from monitoring
    return Math.random() * 20 + 10; // 10-30ms
  }

  async getCacheHitRate() {
    // Mock implementation - in production, this would come from monitoring
    return Math.random() * 20 + 80; // 80-100%
  }

  async getErrorRate(dateRange) {
    // Mock implementation - in production, this would come from monitoring
    return Math.random() * 2; // 0-2%
  }

  async calculateRetentionRate(cityId, dateRange) {
    // Mock implementation - in production, this would be more sophisticated
    return Math.random() * 30 + 70; // 70-100%
  }

  /**
   * Clear analytics cache
   */
  clearCache() {
    this.cache.clear();
  }

  /**
   * Get real-time metrics
   */
  async getRealTimeMetrics(cityId, prismaClient) {
    try {
      const now = new Date();
      const last24Hours = new Date(now.getTime() - 24 * 60 * 60 * 1000);

      console.log('🔍 Analytics: Getting real-time metrics for city:', cityId);
      console.log('🔍 Analytics: Prisma client available:', !!prismaClient);
      console.log('🔍 Analytics: RSVP model available:', !!prismaClient.rsvp);

      // Test if Prisma client is working
      if (!prismaClient || !prismaClient.rsvp) {
        throw new Error('Prisma client not properly initialized');
      }

      const [recentRsvps, recentVisits, activeUsers] = await Promise.all([
        prismaClient.rsvp.count({
          where: {
            createdAt: { gte: last24Hours },
            restaurant: { cityId }
          }
        }),
        prismaClient.verifiedVisit.count({
          where: {
            createdAt: { gte: last24Hours },
            restaurant: { cityId }
          }
        }),
        prismaClient.user.count({
          where: {
            OR: [
              {
                rsvps: {
                  some: {
                    createdAt: { gte: last24Hours },
                    restaurant: { cityId }
                  }
                }
              },
              {
                verifiedVisits: {
                  some: {
                    createdAt: { gte: last24Hours },
                    restaurant: { cityId }
                  }
                }
              }
            ]
          }
        })
      ]);

      return {
        rsvps24h: recentRsvps,
        visits24h: recentVisits,
        activeUsers24h: activeUsers,
        timestamp: now.toISOString()
      };
    } catch (error) {
      console.error('❌ Analytics: Error in getRealTimeMetrics:', error);
      throw error;
    }
  }
}

module.exports = new AnalyticsService();
