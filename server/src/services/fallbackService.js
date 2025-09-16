const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

/**
 * Fallback service for when Yelp API is down
 */
class FallbackService {
  constructor() {
    this.isYelpDown = false;
    this.downtimeStart = null;
    this.lastHealthCheck = null;
  }

  /**
   * Check if Yelp API is healthy
   */
  async checkYelpHealth(yelpService) {
    try {
      // Try a simple search to test API health
      await yelpService.searchRestaurants('Austin, TX', 'test', null, null, 1);
      this.isYelpDown = false;
      this.downtimeStart = null;
      this.lastHealthCheck = new Date();
      return true;
    } catch (error) {
      console.error('Yelp API health check failed:', error.message);
      if (!this.isYelpDown) {
        this.isYelpDown = true;
        this.downtimeStart = new Date();
        console.log('Yelp API marked as down. Switching to fallback mode.');
      }
      this.lastHealthCheck = new Date();
      return false;
    }
  }

  /**
   * Get restaurants from local database as fallback
   */
  async getFallbackRestaurants(filters = {}) {
    try {
      const where = {};
      
      // Apply filters
      if (filters.categories) {
        where.categories = {
          array_contains: [filters.categories]
        };
      }
      
      if (filters.cuisine) {
        where.cuisine = filters.cuisine;
      }
      
      if (filters.priceRange) {
        where.priceRange = filters.priceRange;
      }
      
      if (filters.minRating) {
        where.rating = {
          gte: parseFloat(filters.minRating)
        };
      }

      const restaurants = await prisma.restaurant.findMany({
        where,
        orderBy: [
          { rating: 'desc' },
          { reviewCount: 'desc' }
        ],
        take: filters.limit || 20,
        skip: filters.offset || 0
      });

      return {
        success: true,
        source: 'fallback',
        restaurants: restaurants.map(restaurant => this.formatRestaurant(restaurant)),
        total: restaurants.length,
        message: 'Serving from local database due to Yelp API unavailability',
        fallback: true,
        downtimeStart: this.downtimeStart
      };
    } catch (error) {
      console.error('Fallback service error:', error);
      return {
        success: false,
        error: 'Fallback service unavailable',
        message: 'Unable to serve restaurant data'
      };
    }
  }

  /**
   * Get featured restaurant from local database
   */
  async getFallbackFeaturedRestaurant() {
    try {
      // Get the most recent featured restaurant from database
      const featuredRestaurant = await prisma.featuredRestaurant.findFirst({
        where: {
          isActive: true
        },
        include: {
          restaurant: true
        },
        orderBy: {
          weekStartDate: 'desc'
        }
      });

      if (featuredRestaurant) {
        return {
          success: true,
          source: 'fallback',
          restaurant: this.formatRestaurant(featuredRestaurant.restaurant),
          message: 'Serving featured restaurant from local database',
          fallback: true,
          downtimeStart: this.downtimeStart
        };
      }

      // If no featured restaurant, get a highly-rated one
      const topRestaurant = await prisma.restaurant.findFirst({
        where: {
          rating: {
            gte: 4.0
          }
        },
        orderBy: [
          { rating: 'desc' },
          { reviewCount: 'desc' }
        ]
      });

      if (topRestaurant) {
        return {
          success: true,
          source: 'fallback',
          restaurant: this.formatRestaurant(topRestaurant),
          message: 'Serving highly-rated restaurant from local database',
          fallback: true,
          downtimeStart: this.downtimeStart
        };
      }

      return {
        success: false,
        error: 'No restaurants available in fallback database',
        message: 'No restaurant data available'
      };
    } catch (error) {
      console.error('Fallback featured restaurant error:', error);
      return {
        success: false,
        error: 'Fallback service unavailable',
        message: 'Unable to serve featured restaurant'
      };
    }
  }

  /**
   * Get restaurant details from local database
   */
  async getFallbackRestaurantDetails(restaurantId) {
    try {
      const restaurant = await prisma.restaurant.findUnique({
        where: {
          id: restaurantId
        }
      });

      if (restaurant) {
        return {
          success: true,
          source: 'fallback',
          restaurant: this.formatRestaurant(restaurant),
          message: 'Serving restaurant details from local database',
          fallback: true,
          downtimeStart: this.downtimeStart
        };
      }

      return {
        success: false,
        error: 'Restaurant not found',
        message: 'Restaurant not available in local database'
      };
    } catch (error) {
      console.error('Fallback restaurant details error:', error);
      return {
        success: false,
        error: 'Fallback service unavailable',
        message: 'Unable to serve restaurant details'
      };
    }
  }

  /**
   * Get Austin-specific restaurants from local database
   */
  async getFallbackAustinRestaurants(category) {
    try {
      const categoryMap = {
        'bbq': 'BBQ',
        'tex-mex': 'Tex-Mex',
        'food-trucks': 'Food Trucks',
        'downtown': 'Downtown',
        'highly-rated': null // Will use rating filter
      };

      const where = {};
      
      if (categoryMap[category]) {
        where.cuisine = categoryMap[category];
      } else if (category === 'highly-rated') {
        where.rating = { gte: 4.5 };
      }

      const restaurants = await prisma.restaurant.findMany({
        where,
        orderBy: [
          { rating: 'desc' },
          { reviewCount: 'desc' }
        ],
        take: 20
      });

      return {
        success: true,
        source: 'fallback',
        restaurants: restaurants.map(restaurant => this.formatRestaurant(restaurant)),
        total: restaurants.length,
        category: category,
        location: 'Austin, TX',
        message: 'Serving Austin restaurants from local database',
        fallback: true,
        downtimeStart: this.downtimeStart
      };
    } catch (error) {
      console.error('Fallback Austin restaurants error:', error);
      return {
        success: false,
        error: 'Fallback service unavailable',
        message: 'Unable to serve Austin restaurants'
      };
    }
  }

  /**
   * Format restaurant data for consistent API response
   */
  formatRestaurant(restaurant) {
    return {
      id: restaurant.id,
      name: restaurant.name,
      description: restaurant.description || 'No description available',
      address: restaurant.address,
      city: restaurant.city,
      state: restaurant.state,
      zipCode: restaurant.zipCode,
      phone: restaurant.phone,
      website: restaurant.website,
      cuisine: restaurant.cuisine,
      categories: restaurant.categories || [],
      specialties: restaurant.specialties || [],
      rating: restaurant.rating,
      reviewCount: restaurant.reviewCount,
      priceRange: restaurant.priceRange,
      imageUrl: restaurant.imageUrl,
      photos: restaurant.photos || [],
      hours: restaurant.hours || {},
      coordinates: restaurant.coordinates,
      area: restaurant.area,
      isClaimed: restaurant.isClaimed,
      yelpUrl: restaurant.yelpUrl,
      yelpId: restaurant.yelpId,
      lastUpdated: restaurant.lastUpdated,
      fallback: true
    };
  }

  /**
   * Get fallback status
   */
  getFallbackStatus() {
    return {
      isYelpDown: this.isYelpDown,
      downtimeStart: this.downtimeStart,
      lastHealthCheck: this.lastHealthCheck,
      uptime: this.downtimeStart ? Date.now() - this.downtimeStart.getTime() : 0
    };
  }

  /**
   * Get fallback notice for users
   */
  getFallbackNotice() {
    if (!this.isYelpDown) {
      return null;
    }

    const downtimeMinutes = Math.floor((Date.now() - this.downtimeStart.getTime()) / (1000 * 60));
    
    return {
      type: 'warning',
      title: 'Limited Data Available',
      message: `Yelp API is currently unavailable. Showing cached data from ${downtimeMinutes} minutes ago. Some features may be limited.`,
      icon: '⚠️',
      action: 'We\'re working to restore full functionality. Please check back later.'
    };
  }

  /**
   * Sync fallback data with Yelp when API is back
   */
  async syncFallbackData(yelpService) {
    if (this.isYelpDown) {
      return;
    }

    try {
      console.log('Syncing fallback data with Yelp API...');
      
      // Get restaurants that need updating (older than 24 hours)
      const staleRestaurants = await prisma.restaurant.findMany({
        where: {
          lastUpdated: {
            lt: new Date(Date.now() - 24 * 60 * 60 * 1000)
          }
        },
        take: 10
      });

      for (const restaurant of staleRestaurants) {
        if (restaurant.yelpId) {
          try {
            const yelpData = await yelpService.getRestaurantDetails(restaurant.yelpId);
            if (yelpData) {
              // Update restaurant with fresh Yelp data
              await prisma.restaurant.update({
                where: { id: restaurant.id },
                data: {
                  rating: yelpData.rating,
                  reviewCount: yelpData.reviewCount,
                  photos: yelpData.photos,
                  hours: yelpData.hours,
                  lastUpdated: new Date()
                }
              });
              console.log(`Updated restaurant: ${restaurant.name}`);
            }
          } catch (error) {
            console.error(`Failed to sync restaurant ${restaurant.name}:`, error.message);
          }
        }
      }

      console.log('Fallback data sync completed');
    } catch (error) {
      console.error('Fallback data sync error:', error);
    }
  }
}

module.exports = new FallbackService();
