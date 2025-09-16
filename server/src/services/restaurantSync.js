const { PrismaClient } = require('@prisma/client');
const yelpService = require('./yelpService');

class RestaurantSyncService {
  constructor() {
    this.prisma = new PrismaClient();
    this.syncCache = new Map();
    this.cacheTimeout = 24 * 60 * 60 * 1000; // 24 hours
  }

  // Check if service is configured
  isConfigured() {
    return yelpService.isConfigured();
  }

  // Sync a single restaurant from Yelp to database
  async syncRestaurant(yelpId, options = {}) {
    try {
      if (!this.isConfigured()) {
        throw new Error('Yelp API not configured');
      }

      console.log(`Syncing restaurant with Yelp ID: ${yelpId}`);

      // Get restaurant details from Yelp
      const yelpData = await yelpService.getRestaurantDetails(yelpId);
      const formattedData = yelpService.formatRestaurantForApp(yelpData);

      // Check if restaurant already exists
      const existingRestaurant = await this.prisma.restaurant.findUnique({
        where: { yelpId: yelpId }
      });

      const restaurantData = {
        name: formattedData.name,
        cuisine: formattedData.cuisine,
        price: formattedData.priceRange || 'Unknown',
        area: formattedData.area || 'Austin',
        description: formattedData.description,
        address: formattedData.address,
        imageUrl: formattedData.imageUrl,
        yelpId: formattedData.yelpId,
        rating: formattedData.rating,
        reviewCount: formattedData.reviewCount,
        photos: formattedData.photos || [],
        categories: formattedData.categories || [],
        priceRange: formattedData.priceRange,
        coordinates: formattedData.coordinates,
        hours: formattedData.hours,
        isClaimed: formattedData.isClaimed,
        yelpUrl: formattedData.yelpUrl,
        lastSynced: new Date()
      };

      let restaurant;
      if (existingRestaurant) {
        // Update existing restaurant
        restaurant = await this.prisma.restaurant.update({
          where: { yelpId: yelpId },
          data: restaurantData
        });
        console.log(`Updated restaurant: ${restaurant.name}`);
      } else {
        // Create new restaurant
        restaurant = await this.prisma.restaurant.create({
          data: {
            ...restaurantData,
            weekOf: new Date() // Set current week as default
          }
        });
        console.log(`Created new restaurant: ${restaurant.name}`);
      }

      // Cache the result
      this.syncCache.set(yelpId, {
        data: restaurant,
        timestamp: Date.now()
      });

      return restaurant;
    } catch (error) {
      console.error(`Error syncing restaurant ${yelpId}:`, error);
      throw error;
    }
  }

  // Sync multiple restaurants
  async syncRestaurants(yelpIds, options = {}) {
    const results = {
      successful: [],
      failed: [],
      total: yelpIds.length
    };

    console.log(`Syncing ${yelpIds.length} restaurants...`);

    for (const yelpId of yelpIds) {
      try {
        const restaurant = await this.syncRestaurant(yelpId, options);
        results.successful.push(restaurant);
      } catch (error) {
        console.error(`Failed to sync restaurant ${yelpId}:`, error.message);
        results.failed.push({ yelpId, error: error.message });
      }
    }

    console.log(`Sync complete: ${results.successful.length} successful, ${results.failed.length} failed`);
    return results;
  }

  // Sync featured restaurants for the current week
  async syncFeaturedRestaurants(limit = 5) {
    try {
      console.log('Syncing featured restaurants for current week...');
      
      const featured = await yelpService.getFeaturedRestaurants(limit);
      const yelpIds = featured.businesses.map(restaurant => restaurant.id);
      
      const results = await this.syncRestaurants(yelpIds);
      
      // Mark the first successful restaurant as current pick
      if (results.successful.length > 0) {
        await this.setCurrentPick(results.successful[0].id);
      }

      return {
        ...results,
        category: featured.category,
        criteria: featured.criteria
      };
    } catch (error) {
      console.error('Error syncing featured restaurants:', error);
      throw error;
    }
  }

  // Sync restaurants by category
  async syncRestaurantsByCategory(category, limit = 10) {
    try {
      console.log(`Syncing ${category} restaurants...`);
      
      const results = await yelpService.searchByCuisine(category, null, limit);
      const yelpIds = results.businesses.map(restaurant => restaurant.id);
      
      return await this.syncRestaurants(yelpIds);
    } catch (error) {
      console.error(`Error syncing ${category} restaurants:`, error);
      throw error;
    }
  }

  // Set current week's featured restaurant
  async setCurrentPick(restaurantId) {
    try {
      // Clear all current picks
      await this.prisma.restaurant.updateMany({
        where: { isCurrentPick: true },
        data: { isCurrentPick: false }
      });

      // Set new current pick
      const restaurant = await this.prisma.restaurant.update({
        where: { id: restaurantId },
        data: { 
          isCurrentPick: true,
          weekOf: new Date()
        }
      });

      console.log(`Set current pick: ${restaurant.name}`);
      return restaurant;
    } catch (error) {
      console.error('Error setting current pick:', error);
      throw error;
    }
  }

  // Get restaurants that need syncing (older than 24 hours)
  async getRestaurantsNeedingSync() {
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    return await this.prisma.restaurant.findMany({
      where: {
        yelpId: { not: null },
        OR: [
          { lastSynced: null },
          { lastSynced: { lt: oneDayAgo } }
        ]
      },
      select: {
        id: true,
        yelpId: true,
        name: true,
        lastSynced: true
      }
    });
  }

  // Sync all restaurants that need updating
  async syncStaleRestaurants() {
    try {
      const staleRestaurants = await this.getRestaurantsNeedingSync();
      
      if (staleRestaurants.length === 0) {
        console.log('No restaurants need syncing');
        return { message: 'No restaurants need syncing', count: 0 };
      }

      console.log(`Found ${staleRestaurants.length} restaurants needing sync`);
      
      const yelpIds = staleRestaurants.map(r => r.yelpId).filter(Boolean);
      const results = await this.syncRestaurants(yelpIds);
      
      return {
        message: `Synced ${results.successful.length} restaurants`,
        count: results.successful.length,
        failed: results.failed.length
      };
    } catch (error) {
      console.error('Error syncing stale restaurants:', error);
      throw error;
    }
  }

  // Get restaurant by Yelp ID (with caching)
  async getRestaurantByYelpId(yelpId) {
    // Check cache first
    const cached = this.syncCache.get(yelpId);
    if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
      return cached.data;
    }

    // Get from database
    const restaurant = await this.prisma.restaurant.findUnique({
      where: { yelpId: yelpId }
    });

    if (restaurant) {
      // Cache the result
      this.syncCache.set(yelpId, {
        data: restaurant,
        timestamp: Date.now()
      });
    }

    return restaurant;
  }

  // Search restaurants in database with Yelp data
  async searchRestaurants(query = {}) {
    const {
      cuisine,
      area,
      minRating,
      maxPrice,
      limit = 20,
      offset = 0
    } = query;

    const where = {};

    if (cuisine) {
      where.cuisine = { contains: cuisine, mode: 'insensitive' };
    }

    if (area) {
      where.area = { contains: area, mode: 'insensitive' };
    }

    if (minRating) {
      where.rating = { gte: parseFloat(minRating) };
    }

    if (maxPrice) {
      where.priceRange = { lte: maxPrice };
    }

    const restaurants = await this.prisma.restaurant.findMany({
      where,
      orderBy: [
        { rating: 'desc' },
        { reviewCount: 'desc' }
      ],
      take: limit,
      skip: offset
    });

    const total = await this.prisma.restaurant.count({ where });

    return {
      restaurants,
      total,
      limit,
      offset
    };
  }

  // Get restaurant statistics
  async getRestaurantStats() {
    const [
      totalRestaurants,
      syncedRestaurants,
      currentPick,
      topRated,
      categoryStats
    ] = await Promise.all([
      this.prisma.restaurant.count(),
      this.prisma.restaurant.count({ where: { yelpId: { not: null } } }),
      this.prisma.restaurant.findFirst({ where: { isCurrentPick: true } }),
      this.prisma.restaurant.findFirst({ 
        where: { rating: { not: null } },
        orderBy: { rating: 'desc' }
      }),
      this.prisma.restaurant.groupBy({
        by: ['cuisine'],
        _count: { cuisine: true },
        _avg: { rating: true },
        orderBy: { _count: { cuisine: 'desc' } },
        take: 10
      })
    ]);

    return {
      totalRestaurants,
      syncedRestaurants,
      syncPercentage: totalRestaurants > 0 ? (syncedRestaurants / totalRestaurants * 100).toFixed(1) : 0,
      currentPick: currentPick ? {
        name: currentPick.name,
        cuisine: currentPick.cuisine,
        rating: currentPick.rating
      } : null,
      topRated: topRated ? {
        name: topRated.name,
        rating: topRated.rating,
        reviewCount: topRated.reviewCount
      } : null,
      categoryStats: categoryStats.map(stat => ({
        cuisine: stat.cuisine,
        count: stat._count.cuisine,
        averageRating: stat._avg.rating ? stat._avg.rating.toFixed(1) : null
      }))
    };
  }

  // Clear sync cache
  clearCache() {
    this.syncCache.clear();
    console.log('Restaurant sync cache cleared');
  }

  // Get cache statistics
  getCacheStats() {
    return {
      size: this.syncCache.size,
      keys: Array.from(this.syncCache.keys()),
      timeout: this.cacheTimeout
    };
  }

  // Cleanup old cache entries
  cleanupCache() {
    const now = Date.now();
    let cleaned = 0;
    
    for (const [key, value] of this.syncCache.entries()) {
      if (now - value.timestamp >= this.cacheTimeout) {
        this.syncCache.delete(key);
        cleaned++;
      }
    }
    
    if (cleaned > 0) {
      console.log(`Cleaned up ${cleaned} expired cache entries`);
    }
    
    return cleaned;
  }
}

module.exports = new RestaurantSyncService();
