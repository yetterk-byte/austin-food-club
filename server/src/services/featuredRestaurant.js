const { PrismaClient } = require('@prisma/client');
const yelpService = require('./yelpService');
const restaurantSync = require('./restaurantSync');

class FeaturedRestaurantService {
  constructor() {
    this.prisma = new PrismaClient();
    
    // Seasonal cuisine preferences by month
    this.seasonalCuisines = {
      1: ['soup', 'hotpot', 'comfort', 'warm'], // January - Winter comfort
      2: ['soup', 'hotpot', 'comfort', 'warm'], // February - Winter comfort
      3: ['spring', 'fresh', 'salad', 'light'], // March - Spring fresh
      4: ['spring', 'fresh', 'salad', 'light'], // April - Spring fresh
      5: ['bbq', 'grill', 'outdoor', 'summer'], // May - Start of BBQ season
      6: ['bbq', 'grill', 'outdoor', 'summer'], // June - Peak BBQ season
      7: ['bbq', 'grill', 'outdoor', 'summer'], // July - Peak BBQ season
      8: ['bbq', 'grill', 'outdoor', 'summer'], // August - Peak BBQ season
      9: ['fall', 'harvest', 'comfort', 'warm'], // September - Fall comfort
      10: ['fall', 'harvest', 'comfort', 'warm'], // October - Fall comfort
      11: ['thanksgiving', 'comfort', 'warm', 'holiday'], // November - Holiday comfort
      12: ['holiday', 'comfort', 'warm', 'celebration'] // December - Holiday celebration
    };
    
    // Cuisine diversity tracking (last 12 weeks)
    this.cuisineHistory = [];
    this.maxHistoryWeeks = 12;
    
    // Restaurant rotation tracking (last 6 months)
    this.restaurantHistory = [];
    this.maxRestaurantHistoryWeeks = 24; // 6 months
  }

  // Get current week's featured restaurant
  async getCurrentFeatured() {
    try {
      const now = new Date();
      const weekStart = this.getWeekStart(now);
      
      const featured = await this.prisma.featuredRestaurant.findFirst({
        where: {
          weekStartDate: weekStart,
          isActive: true
        },
        include: {
          restaurant: true
        }
      });

      return featured;
    } catch (error) {
      console.error('Error getting current featured restaurant:', error);
      throw error;
    }
  }

  // Get featured restaurant for a specific week
  async getFeaturedForWeek(weekStartDate) {
    try {
      const featured = await this.prisma.featuredRestaurant.findFirst({
        where: {
          weekStartDate: weekStartDate,
          isActive: true
        },
        include: {
          restaurant: true
        }
      });

      return featured;
    } catch (error) {
      console.error('Error getting featured restaurant for week:', error);
      throw error;
    }
  }

  // Select and set a new featured restaurant for the week
  async selectFeaturedRestaurant(weekStartDate, options = {}) {
    try {
      console.log(`Selecting featured restaurant for week starting ${weekStartDate.toISOString()}`);
      
      const {
        customRestaurantId = null,
        customDescription = null,
        forceNew = false
      } = options;

      // If custom restaurant is specified, use it
      if (customRestaurantId) {
        return await this.setCustomFeatured(customRestaurantId, weekStartDate, customDescription);
      }

      // Check if we already have a featured restaurant for this week
      const existing = await this.getFeaturedForWeek(weekStartDate);
      if (existing && !forceNew) {
        console.log('Featured restaurant already exists for this week');
        return existing;
      }

      // Get seasonal cuisine preferences
      const month = weekStartDate.getMonth() + 1; // JavaScript months are 0-based
      const seasonalCuisines = this.seasonalCuisines[month] || ['restaurants'];
      
      console.log(`Seasonal cuisines for month ${month}:`, seasonalCuisines);

      // Get cuisine history to ensure diversity
      await this.loadCuisineHistory();
      const preferredCuisine = this.selectDiverseCuisine(seasonalCuisines);
      
      console.log(`Selected cuisine for diversity: ${preferredCuisine}`);

      // Search for restaurants in the preferred cuisine
      const searchResults = await yelpService.searchByCuisine(preferredCuisine, null, 20);
      
      if (!searchResults.businesses || searchResults.businesses.length === 0) {
        throw new Error(`No restaurants found for cuisine: ${preferredCuisine}`);
      }

      // Filter and score restaurants
      const candidates = await this.scoreRestaurants(searchResults.businesses, weekStartDate);
      
      if (candidates.length === 0) {
        throw new Error('No suitable restaurants found after filtering');
      }

      // Select the best candidate
      const selectedRestaurant = candidates[0];
      console.log(`Selected restaurant: ${selectedRestaurant.name} (${selectedRestaurant.cuisine})`);

      // Sync the restaurant to our database
      const syncedRestaurant = await restaurantSync.syncRestaurant(selectedRestaurant.id);
      
      // Create featured restaurant record
      const weekEndDate = this.getWeekEnd(weekStartDate);
      const featured = await this.prisma.featuredRestaurant.create({
        data: {
          restaurantId: syncedRestaurant.id,
          weekStartDate: weekStartDate,
          weekEndDate: weekEndDate,
          customDescription: customDescription,
          isActive: true
        },
        include: {
          restaurant: true
        }
      });

      // Update cuisine and restaurant history
      await this.updateHistory(preferredCuisine, syncedRestaurant.id, weekStartDate);

      console.log(`Featured restaurant set: ${featured.restaurant.name}`);
      return featured;

    } catch (error) {
      console.error('Error selecting featured restaurant:', error);
      throw error;
    }
  }

  // Set a custom featured restaurant (manual override)
  async setCustomFeatured(restaurantId, weekStartDate, customDescription = null) {
    try {
      console.log(`Setting custom featured restaurant: ${restaurantId}`);
      
      const weekEndDate = this.getWeekEnd(weekStartDate);
      
      // Deactivate any existing featured restaurant for this week
      await this.prisma.featuredRestaurant.updateMany({
        where: {
          weekStartDate: weekStartDate,
          isActive: true
        },
        data: {
          isActive: false
        }
      });

      // Create new featured restaurant record
      const featured = await this.prisma.featuredRestaurant.create({
        data: {
          restaurantId: restaurantId,
          weekStartDate: weekStartDate,
          weekEndDate: weekEndDate,
          customDescription: customDescription,
          isActive: true
        },
        include: {
          restaurant: true
        }
      });

      console.log(`Custom featured restaurant set: ${featured.restaurant.name}`);
      return featured;

    } catch (error) {
      console.error('Error setting custom featured restaurant:', error);
      throw error;
    }
  }

  // Score restaurants based on various criteria
  async scoreRestaurants(restaurants, weekStartDate) {
    const candidates = [];
    
    for (const restaurant of restaurants) {
      try {
        // Basic quality filters
        if (restaurant.rating < 4.0 || restaurant.review_count < 20) {
          continue;
        }

        // Check if restaurant was featured recently (last 3 months)
        if (await this.wasRecentlyFeatured(restaurant.id, weekStartDate)) {
          continue;
        }

        // Calculate diversity score
        const diversityScore = this.calculateDiversityScore(restaurant.categories);
        
        // Calculate seasonal score
        const seasonalScore = this.calculateSeasonalScore(restaurant.categories, weekStartDate);
        
        // Calculate quality score
        const qualityScore = this.calculateQualityScore(restaurant.rating, restaurant.review_count);
        
        // Calculate availability score (is it open, claimed, etc.)
        const availabilityScore = this.calculateAvailabilityScore(restaurant);
        
        // Total score (weighted)
        const totalScore = (
          diversityScore * 0.3 +
          seasonalScore * 0.25 +
          qualityScore * 0.3 +
          availabilityScore * 0.15
        );

        candidates.push({
          ...restaurant,
          diversityScore,
          seasonalScore,
          qualityScore,
          availabilityScore,
          totalScore
        });

      } catch (error) {
        console.error(`Error scoring restaurant ${restaurant.id}:`, error);
        continue;
      }
    }

    // Sort by total score (descending)
    return candidates.sort((a, b) => b.totalScore - a.totalScore);
  }

  // Calculate diversity score based on cuisine history
  calculateDiversityScore(categories) {
    if (!categories || categories.length === 0) return 0;
    
    const primaryCuisine = this.getPrimaryCuisine(categories);
    const recentCuisines = this.cuisineHistory.slice(-6); // Last 6 weeks
    
    // Higher score if cuisine hasn't been used recently
    const recentUsage = recentCuisines.filter(c => c === primaryCuisine).length;
    return Math.max(0, 1 - (recentUsage / 6));
  }

  // Calculate seasonal score
  calculateSeasonalScore(categories, weekStartDate) {
    if (!categories || categories.length === 0) return 0;
    
    const month = weekStartDate.getMonth() + 1;
    const seasonalCuisines = this.seasonalCuisines[month] || [];
    const primaryCuisine = this.getPrimaryCuisine(categories);
    
    // Check if any category matches seasonal preferences
    const hasSeasonalMatch = categories.some(cat => {
      const catStr = typeof cat === 'string' ? cat : cat.title || cat.alias || '';
      return seasonalCuisines.some(seasonal => 
        catStr.toLowerCase().includes(seasonal.toLowerCase())
      );
    });
    
    return hasSeasonalMatch ? 1.0 : 0.5;
  }

  // Calculate quality score
  calculateQualityScore(rating, reviewCount) {
    if (!rating || !reviewCount) return 0;
    
    // Normalize rating (0-1 scale)
    const normalizedRating = (rating - 1) / 4; // 1-5 scale to 0-1
    
    // Normalize review count (log scale, capped at 1000 reviews)
    const normalizedReviews = Math.min(Math.log10(reviewCount + 1) / 4, 1);
    
    return (normalizedRating * 0.7 + normalizedReviews * 0.3);
  }

  // Calculate availability score
  calculateAvailabilityScore(restaurant) {
    let score = 0.5; // Base score
    
    // Not closed
    if (!restaurant.is_closed) score += 0.3;
    
    // Claimed business (more reliable info)
    if (restaurant.is_claimed) score += 0.2;
    
    // Has essential info
    if (restaurant.location && restaurant.location.address1) score += 0.1;
    if (restaurant.phone) score += 0.1;
    
    return Math.min(score, 1.0);
  }

  // Check if restaurant was featured recently
  async wasRecentlyFeatured(yelpId, weekStartDate) {
    try {
      const sixMonthsAgo = new Date(weekStartDate);
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      
      const recentFeatured = await this.prisma.featuredRestaurant.findMany({
        where: {
          weekStartDate: {
            gte: sixMonthsAgo
          },
          isActive: true
        },
        include: {
          restaurant: true
        }
      });

      return recentFeatured.some(f => f.restaurant.yelpId === yelpId);
    } catch (error) {
      console.error('Error checking recent featured restaurants:', error);
      return false;
    }
  }

  // Select diverse cuisine based on history
  selectDiverseCuisine(seasonalCuisines) {
    if (this.cuisineHistory.length === 0) {
      return seasonalCuisines[0] || 'restaurants';
    }

    // Count recent cuisine usage
    const recentCuisines = this.cuisineHistory.slice(-6); // Last 6 weeks
    const cuisineCounts = {};
    
    recentCuisines.forEach(cuisine => {
      cuisineCounts[cuisine] = (cuisineCounts[cuisine] || 0) + 1;
    });

    // Find least used seasonal cuisine
    let leastUsedCuisine = seasonalCuisines[0];
    let minCount = cuisineCounts[leastUsedCuisine] || 0;

    for (const cuisine of seasonalCuisines) {
      const count = cuisineCounts[cuisine] || 0;
      if (count < minCount) {
        minCount = count;
        leastUsedCuisine = cuisine;
      }
    }

    return leastUsedCuisine;
  }

  // Load cuisine history from database
  async loadCuisineHistory() {
    try {
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

      const recentFeatured = await this.prisma.featuredRestaurant.findMany({
        where: {
          weekStartDate: {
            gte: sixMonthsAgo
          },
          isActive: true
        },
        include: {
          restaurant: true
        },
        orderBy: {
          weekStartDate: 'asc'
        }
      });

      this.cuisineHistory = recentFeatured.map(f => f.restaurant.cuisine);
      this.restaurantHistory = recentFeatured.map(f => f.restaurant.id);

    } catch (error) {
      console.error('Error loading cuisine history:', error);
      this.cuisineHistory = [];
      this.restaurantHistory = [];
    }
  }

  // Update history with new selection
  async updateHistory(cuisine, restaurantId, weekStartDate) {
    this.cuisineHistory.push(cuisine);
    this.restaurantHistory.push(restaurantId);

    // Keep only recent history
    if (this.cuisineHistory.length > this.maxHistoryWeeks) {
      this.cuisineHistory = this.cuisineHistory.slice(-this.maxHistoryWeeks);
    }
    if (this.restaurantHistory.length > this.maxRestaurantHistoryWeeks) {
      this.restaurantHistory = this.restaurantHistory.slice(-this.maxRestaurantHistoryWeeks);
    }
  }

  // Get week start date (Monday)
  getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
    const weekStart = new Date(d.setDate(diff));
    weekStart.setHours(0, 0, 0, 0);
    return weekStart;
  }

  // Get week end date (Sunday)
  getWeekEnd(weekStart) {
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    weekEnd.setHours(23, 59, 59, 999);
    return weekEnd;
  }

  // Get primary cuisine from categories
  getPrimaryCuisine(categories) {
    if (!categories || categories.length === 0) return 'restaurants';
    
    // Priority order for cuisine selection
    const priorityCuisines = [
      'bbq', 'barbecue', 'barbeque',
      'mexican', 'tex-mex',
      'italian', 'pizza',
      'chinese', 'japanese', 'sushi',
      'indian', 'thai', 'vietnamese',
      'american', 'tradamerican',
      'french', 'mediterranean',
      'seafood', 'steakhouse',
      'vegetarian', 'vegan'
    ];

    for (const priority of priorityCuisines) {
      const match = categories.find(cat => {
        const catStr = typeof cat === 'string' ? cat : cat.title || cat.alias || '';
        return catStr.toLowerCase().includes(priority.toLowerCase());
      });
      if (match) return priority;
    }

    // Return first category as string
    const firstCat = categories[0];
    return typeof firstCat === 'string' ? firstCat.toLowerCase() : (firstCat.title || firstCat.alias || 'restaurants').toLowerCase();
  }

  // Get featured restaurant history
  async getFeaturedHistory(limit = 12) {
    try {
      const history = await this.prisma.featuredRestaurant.findMany({
        where: {
          isActive: true
        },
        include: {
          restaurant: true
        },
        orderBy: {
          weekStartDate: 'desc'
        },
        take: limit
      });

      return history;
    } catch (error) {
      console.error('Error getting featured restaurant history:', error);
      throw error;
    }
  }

  // Get statistics about featured restaurants
  async getFeaturedStats() {
    try {
      const [
        totalFeatured,
        currentFeatured,
        recentWeeks
      ] = await Promise.all([
        this.prisma.featuredRestaurant.count({
          where: { isActive: true }
        }),
        this.getCurrentFeatured(),
        this.prisma.featuredRestaurant.findMany({
          where: {
            isActive: true,
            weekStartDate: {
              gte: new Date(Date.now() - 12 * 7 * 24 * 60 * 60 * 1000) // Last 12 weeks
            }
          },
          include: {
            restaurant: true
          },
          orderBy: {
            weekStartDate: 'desc'
          }
        })
      ]);

      // Get cuisine stats separately to avoid syntax issues
      const cuisineStats = [];

      return {
        totalFeatured,
        currentFeatured: currentFeatured ? {
          name: currentFeatured.restaurant.name,
          cuisine: currentFeatured.restaurant.cuisine,
          weekStart: currentFeatured.weekStartDate,
          weekEnd: currentFeatured.weekEndDate
        } : null,
        cuisineStats: cuisineStats.map(stat => ({
          restaurantId: stat.restaurant,
          count: stat._count.restaurant
        })),
        recentWeeks: recentWeeks.map(week => ({
          weekStart: week.weekStartDate,
          restaurant: week.restaurant.name,
          cuisine: week.restaurant.cuisine
        }))
      };
    } catch (error) {
      console.error('Error getting featured restaurant stats:', error);
      throw error;
    }
  }

  // Archive old featured restaurants
  async archiveOldFeatured(monthsToKeep = 6) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setMonth(cutoffDate.getMonth() - monthsToKeep);

      const archived = await this.prisma.featuredRestaurant.updateMany({
        where: {
          weekStartDate: {
            lt: cutoffDate
          },
          isActive: true
        },
        data: {
          isActive: false
        }
      });

      console.log(`Archived ${archived.count} old featured restaurants`);
      return archived.count;
    } catch (error) {
      console.error('Error archiving old featured restaurants:', error);
      throw error;
    }
  }
}

module.exports = new FeaturedRestaurantService();
