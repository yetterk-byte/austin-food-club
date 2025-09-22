const { PrismaClient } = require('@prisma/client');
const yelpService = require('./yelpService');

const prisma = new PrismaClient();

// Categories to search for variety - weighted by popularity
const SEARCH_CATEGORIES = [
  { category: 'bbq', weight: 3 },
  { category: 'mexican', weight: 3 },
  { category: 'italian', weight: 2 },
  { category: 'japanese', weight: 2 },
  { category: 'thai', weight: 2 },
  { category: 'indian', weight: 2 },
  { category: 'chinese', weight: 2 },
  { category: 'american', weight: 2 },
  { category: 'steakhouses', weight: 1 },
  { category: 'seafood', weight: 2 },
  { category: 'pizza', weight: 1 },
  { category: 'burgers', weight: 1 },
  { category: 'breakfast_brunch', weight: 1 },
  { category: 'cafes', weight: 1 },
  { category: 'sandwiches', weight: 1 },
  { category: 'vegetarian', weight: 1 },
  { category: 'mediterranean', weight: 1 },
  { category: 'french', weight: 1 },
  { category: 'korean', weight: 1 },
  { category: 'vietnamese', weight: 1 },
  { category: 'sushi', weight: 2 },
  { category: 'tex-mex', weight: 3 },
  { category: 'food_trucks', weight: 2 },
  { category: 'gastropubs', weight: 1 },
  { category: 'wine_bars', weight: 1 },
  { category: 'cocktailbars', weight: 1 }
];

class AutoQueueService {
  constructor() {
    this.maxRetries = 5;
    this.minRating = 4.0; // Only add highly rated restaurants
    this.excludeChains = true; // Avoid chain restaurants when possible
  }

  /**
   * Get a weighted random category based on Austin food preferences
   */
  getRandomCategory() {
    const totalWeight = SEARCH_CATEGORIES.reduce((sum, cat) => sum + cat.weight, 0);
    let random = Math.random() * totalWeight;
    
    for (const cat of SEARCH_CATEGORIES) {
      random -= cat.weight;
      if (random <= 0) {
        return cat.category;
      }
    }
    
    // Fallback
    return SEARCH_CATEGORIES[0].category;
  }

  /**
   * Get all restaurant IDs currently in the system (featured + queue)
   */
  async getExistingRestaurantIds() {
    const [queueRestaurants, allRestaurants] = await Promise.all([
      prisma.restaurantQueue.findMany({
        select: { restaurant: { select: { yelpId: true } } }
      }),
      prisma.restaurant.findMany({
        select: { yelpId: true }
      })
    ]);

    const existingIds = new Set();
    
    // Add queue restaurant IDs
    queueRestaurants.forEach(item => {
      if (item.restaurant?.yelpId) {
        existingIds.add(item.restaurant.yelpId);
      }
    });
    
    // Add all restaurant IDs
    allRestaurants.forEach(restaurant => {
      existingIds.add(restaurant.yelpId);
    });

    return existingIds;
  }

  /**
   * Find a new restaurant that's not already in our system
   */
  async findNewRestaurant(retryCount = 0) {
    if (retryCount >= this.maxRetries) {
      throw new Error('Could not find a new restaurant after maximum retries');
    }

    try {
      const category = this.getRandomCategory();
      console.log(`🔍 Auto-queue: Searching for ${category} restaurants (attempt ${retryCount + 1})`);

      // Search Yelp for restaurants in this category
      const searchResults = await yelpService.searchRestaurants(
        'Austin, TX',
        category,
        null,
        20, // Get more results to have better selection
        null // No specific search term
      );

      if (!searchResults || !searchResults.businesses || searchResults.businesses.length === 0) {
        console.log(`❌ No results for ${category}, trying different category...`);
        return this.findNewRestaurant(retryCount + 1);
      }

      // Get existing restaurant IDs
      const existingIds = await this.getExistingRestaurantIds();

      // Filter for new, highly-rated restaurants
      const newRestaurants = searchResults.businesses.filter(business => {
        return !existingIds.has(business.id) && 
               business.rating >= this.minRating &&
               business.review_count >= 5; // At least 5 reviews
      });

      if (newRestaurants.length === 0) {
        console.log(`❌ No new restaurants found in ${category}, trying different category...`);
        return this.findNewRestaurant(retryCount + 1);
      }

      // Sort by rating and review count, pick the best one
      const bestRestaurant = newRestaurants.sort((a, b) => {
        const scoreA = a.rating * Math.log(a.review_count + 1);
        const scoreB = b.rating * Math.log(b.review_count + 1);
        return scoreB - scoreA;
      })[0];

      console.log(`✅ Found new restaurant: ${bestRestaurant.name} (${bestRestaurant.rating}⭐, ${bestRestaurant.review_count} reviews)`);
      return bestRestaurant;

    } catch (error) {
      console.error(`❌ Error searching for new restaurant:`, error.message);
      if (retryCount < this.maxRetries - 1) {
        return this.findNewRestaurant(retryCount + 1);
      }
      throw error;
    }
  }

  /**
   * Add a new restaurant to the queue
   */
  async addNewRestaurantToQueue() {
    try {
      console.log('🎯 Auto-queue: Starting weekly restaurant addition...');

      // Find a new restaurant
      const newBusiness = await this.findNewRestaurant();

      // Create restaurant data
      const categories = newBusiness.categories ? newBusiness.categories.map(cat => ({
        alias: cat.alias,
        title: cat.title
      })) : [];

      const hours = newBusiness.hours && newBusiness.hours.length > 0 ? newBusiness.hours[0].open.map(day => ({
        day: day.day,
        start: day.start,
        end: day.end,
        is_overnight: day.is_overnight
      })) : [];

      // Create a unique slug from name and ID
      const slug = `${newBusiness.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${newBusiness.id}`.substring(0, 50);

      const restaurantData = {
        yelpId: newBusiness.id,
        name: newBusiness.name,
        slug: slug,
        address: newBusiness.location.address1 || newBusiness.location.display_address?.[0] || '',
        city: newBusiness.location.city || 'Austin',
        state: newBusiness.location.state || 'TX',
        zipCode: newBusiness.location.zip_code || '78701',
        latitude: newBusiness.coordinates?.latitude || 30.2672,
        longitude: newBusiness.coordinates?.longitude || -97.7431,
        phone: newBusiness.display_phone || null,
        imageUrl: newBusiness.image_url || null,
        yelpUrl: newBusiness.url || null,
        price: newBusiness.price || null,
        rating: newBusiness.rating || null,
        reviewCount: newBusiness.review_count || null,
        categories: JSON.stringify(categories),
        hours: JSON.stringify(hours),
        lastSyncedAt: new Date()
      };

      // Create restaurant in database
      const restaurant = await prisma.restaurant.create({
        data: restaurantData
      });

      console.log(`✅ Created restaurant: ${restaurant.name}`);

      // Get next queue position
      const lastPosition = await prisma.restaurantQueue.findFirst({
        orderBy: { position: 'desc' },
        select: { position: true }
      });
      const nextPosition = (lastPosition?.position || 0) + 1;

      // Get system admin user (or create one)
      let systemAdmin = await prisma.user.findFirst({
        where: { email: 'system@austinfoodclub.com' }
      });

      if (!systemAdmin) {
        systemAdmin = await prisma.user.create({
          data: {
            supabaseId: 'system-auto-queue-' + Date.now(),
            email: 'system@austinfoodclub.com',
            name: 'Austin Food Club System',
            isAdmin: true,
            emailVerified: true,
            provider: 'system'
          }
        });
        console.log('👤 Created system admin user for auto-queue');
      }

      // Add to queue
      const queueItem = await prisma.restaurantQueue.create({
        data: {
          restaurantId: restaurant.id,
          position: nextPosition,
          addedBy: systemAdmin.id,
          notes: `Auto-discovered ${categories.map(c => c.title).join(', ')} restaurant - ${newBusiness.rating}⭐ (${newBusiness.review_count} reviews)`,
          status: 'PENDING'
        }
      });

      console.log(`📍 Added to queue at position ${nextPosition}: ${restaurant.name}`);

      return {
        restaurant: {
          id: restaurant.id,
          name: restaurant.name,
          rating: restaurant.rating,
          reviewCount: restaurant.reviewCount,
          categories: categories.map(c => c.title).join(', '),
          address: restaurant.address
        },
        queuePosition: nextPosition,
        queueItemId: queueItem.id
      };

    } catch (error) {
      console.error('❌ Auto-queue error:', error);
      throw error;
    }
  }

  /**
   * Check if queue needs refilling and add restaurant if needed
   */
  async checkAndRefillQueue(minQueueSize = 15) {
    try {
      const queueCount = await prisma.restaurantQueue.count({
        where: { status: 'PENDING' }
      });

      console.log(`📊 Current queue size: ${queueCount}, minimum: ${minQueueSize}`);

      if (queueCount < minQueueSize) {
        console.log('🔄 Queue below minimum size, adding new restaurant...');
        const result = await this.addNewRestaurantToQueue();
        
        return {
          added: true,
          restaurant: result.restaurant,
          queuePosition: result.queuePosition,
          newQueueSize: queueCount + 1
        };
      } else {
        console.log('✅ Queue size sufficient, no action needed');
        return {
          added: false,
          currentQueueSize: queueCount,
          message: 'Queue size sufficient'
        };
      }

    } catch (error) {
      console.error('❌ Queue refill check error:', error);
      throw error;
    }
  }

  /**
   * Weekly queue maintenance - always add one new restaurant
   */
  async weeklyQueueMaintenance() {
    try {
      console.log('🗓️ Running weekly queue maintenance...');
      
      const result = await this.addNewRestaurantToQueue();
      
      // Log the addition
      console.log(`🎉 Weekly restaurant added: ${result.restaurant.name} at position ${result.queuePosition}`);
      
      return result;
      
    } catch (error) {
      console.error('❌ Weekly queue maintenance error:', error);
      throw error;
    }
  }

  /**
   * Get queue statistics
   */
  async getQueueStats() {
    try {
      const [totalQueue, pendingQueue, categoryStats] = await Promise.all([
        prisma.restaurantQueue.count(),
        prisma.restaurantQueue.count({ where: { status: 'PENDING' } }),
        prisma.restaurant.findMany({
          where: {
            queueItems: {
              some: { status: 'PENDING' }
            }
          },
          select: { categories: true }
        })
      ]);

      // Parse categories and count them
      const categoryCount = {};
      categoryStats.forEach(restaurant => {
        if (restaurant.categories) {
          try {
            const cats = JSON.parse(restaurant.categories);
            cats.forEach(cat => {
              categoryCount[cat.title] = (categoryCount[cat.title] || 0) + 1;
            });
          } catch (e) {
            // Skip invalid JSON
          }
        }
      });

      return {
        totalQueue,
        pendingQueue,
        categoryDistribution: categoryCount
      };

    } catch (error) {
      console.error('❌ Queue stats error:', error);
      throw error;
    }
  }
}

module.exports = new AutoQueueService();
