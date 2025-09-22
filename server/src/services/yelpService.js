const axios = require('axios');
const fallbackService = require('./fallbackService');
const geocodingService = require('./geocodingService');

class YelpService {
  constructor() {
    this.apiKey = process.env.YELP_API_KEY;
    this.baseURL = 'https://api.yelp.com/v3';
    this.cache = new Map();
    this.cacheTimeout = 60 * 60 * 1000; // 1 hour in milliseconds
    this.fallbackService = fallbackService;
    
    // Austin-specific configuration
    this.austinConfig = {
      location: 'Austin, TX',
      radius: 24140, // 15 miles in meters
      downtownCoords: { latitude: 30.2672, longitude: -97.7431 },
      priceRanges: ['1', '2', '3', '4'], // $, $$, $$$, $$$$
      featuredCategories: [
        'bbq', 'mexican', 'tradamerican', 'italian', 'chinese', 
        'japanese', 'indian', 'thai', 'french', 'mediterranean',
        'seafood', 'pizza', 'sushi', 'steakhouses', 'vegetarian'
      ],
      chainCategories: [
        'fastfood', 'sandwiches', 'coffee', 'icecream', 'donuts',
        'pizza', 'burgers', 'chicken_wings', 'hotdogs'
      ]
    };
    
    if (!this.apiKey) {
      console.warn('YELP_API_KEY not found. Yelp integration will be disabled.');
    }
  }

  // Check if service is configured
  isConfigured() {
    return !!this.apiKey;
  }

  /**
   * Check if Yelp API is healthy
   */
  async checkHealth() {
    try {
      await this.searchRestaurants('Austin, TX', 'test', null, null, 1);
      return true;
    } catch (error) {
      console.error('Yelp API health check failed:', error.message);
      return false;
    }
  }

  /**
   * Make API request with fallback
   */
  async makeRequestWithFallback(endpoint, params, fallbackMethod) {
    try {
      // Check API health first
      const isHealthy = await this.fallbackService.checkYelpHealth(this);
      
      if (!isHealthy) {
        console.log('Yelp API is down, using fallback service');
        return await fallbackMethod();
      }

      // Make Yelp API request
      const response = await this.makeRequest(endpoint, params);
      return response;
    } catch (error) {
      console.error('Yelp API request failed, using fallback:', error.message);
      
      // Try fallback service
      try {
        return await fallbackMethod();
      } catch (fallbackError) {
        console.error('Fallback service also failed:', fallbackError.message);
        throw error; // Re-throw original error if fallback fails
      }
    }
  }

  // Get headers for Yelp API requests
  getHeaders() {
    return {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json'
    };
  }

  // Cache management
  getCacheKey(endpoint, params) {
    return `${endpoint}_${JSON.stringify(params)}`;
  }

  getFromCache(key) {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
      return cached.data;
    }
    this.cache.delete(key);
    return null;
  }

  setCache(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    });
  }

  // Clear old cache entries
  clearExpiredCache() {
    const now = Date.now();
    for (const [key, value] of this.cache.entries()) {
      if (now - value.timestamp >= this.cacheTimeout) {
        this.cache.delete(key);
      }
    }
  }

  // Search restaurants with Austin-specific parameters
  async searchRestaurants(location = null, cuisine = null, price = null, limit = 20, searchTerm = null) {
    if (!this.isConfigured()) {
      throw new Error('Yelp API not configured. Please set YELP_API_KEY in environment variables.');
    }

    // Use Austin config if no location specified
    const searchLocation = location || this.austinConfig.location;
    const searchRadius = this.austinConfig.radius;

    const cacheKey = this.getCacheKey('search', { location: searchLocation, cuisine, price, limit, searchTerm });
    const cached = this.getFromCache(cacheKey);
    if (cached) {
      console.log('Returning cached search results');
      return cached;
    }

    try {
      const params = {
        location: searchLocation,
        term: searchTerm || 'restaurants', // Use searchTerm if provided, otherwise default to 'restaurants'
        limit: Math.min(limit, 50), // Yelp API max is 50
        sort_by: 'rating',
        radius: searchRadius
      };

      // Add optional filters
      if (cuisine) {
        params.categories = cuisine;
      }
      if (price) {
        params.price = price;
      }

      console.log('Searching Yelp for restaurants:', params);

      const response = await axios.get(`${this.baseURL}/businesses/search`, {
        headers: this.getHeaders(),
        params
      });

      const yelpResponse = {
        businesses: response.data.businesses || [],
        total: response.data.total || 0,
        region: response.data.region || {}
      };

      const results = {
        businesses: yelpResponse.businesses || [],
        total: yelpResponse.total || 0,
        region: yelpResponse.region || {},
        searchParams: {
          location: searchLocation,
          cuisine,
          price,
          radius: searchRadius
        }
      };

      // Cache the results
      this.setCache(cacheKey, results);
      this.clearExpiredCache();

      return results;
    } catch (error) {
      console.error('Yelp search error:', error.response?.data || error.message);
      throw new Error(`Failed to search restaurants: ${error.response?.data?.error?.description || error.message}`);
    }
  }

  // Get detailed restaurant information
  async getRestaurantDetails(businessId) {
    if (!this.isConfigured()) {
      throw new Error('Yelp API not configured. Please set YELP_API_KEY in environment variables.');
    }

    const cacheKey = this.getCacheKey('details', { businessId });
    const cached = this.getFromCache(cacheKey);
    if (cached) {
      console.log('Returning cached restaurant details');
      return cached;
    }

    try {
      console.log('Fetching restaurant details for:', businessId);

      const response = await axios.get(`${this.baseURL}/businesses/${businessId}`, {
        headers: this.getHeaders()
      });

      const details = response.data;

      // Cache the results
      this.setCache(cacheKey, details);
      this.clearExpiredCache();

      return details;
    } catch (error) {
      console.error('Yelp details error:', error.response?.data || error.message);
      throw new Error(`Failed to get restaurant details: ${error.response?.data?.error?.description || error.message}`);
    }
  }

  // Get restaurant reviews
  async getRestaurantReviews(businessId, limit = 20) {
    if (!this.isConfigured()) {
      throw new Error('Yelp API not configured. Please set YELP_API_KEY in environment variables.');
    }

    const cacheKey = this.getCacheKey('reviews', { businessId, limit });
    const cached = this.getFromCache(cacheKey);
    if (cached) {
      console.log('Returning cached restaurant reviews');
      return cached;
    }

    try {
      console.log('Fetching restaurant reviews for:', businessId);

      const response = await axios.get(`${this.baseURL}/businesses/${businessId}/reviews`, {
        headers: this.getHeaders(),
        params: {
          limit: Math.min(limit, 3) // Yelp API max is 3 for reviews
        }
      });

      const reviews = {
        reviews: response.data.reviews || [],
        total: response.data.total || 0
      };

      // Cache the results
      this.setCache(cacheKey, reviews);
      this.clearExpiredCache();

      return reviews;
    } catch (error) {
      console.error('Yelp reviews error:', error.response?.data || error.message);
      throw new Error(`Failed to get restaurant reviews: ${error.response?.data?.error?.description || error.message}`);
    }
  }

  // Get current week's category for featured restaurant rotation
  getCurrentWeekCategory() {
    const weekNumber = Math.floor(Date.now() / (7 * 24 * 60 * 60 * 1000));
    const categoryIndex = weekNumber % this.austinConfig.featuredCategories.length;
    return this.austinConfig.featuredCategories[categoryIndex];
  }

  // Check if restaurant is a chain based on categories
  isChainRestaurant(restaurant) {
    if (!restaurant.categories) return false;
    
    const restaurantCategories = restaurant.categories.map(cat => cat.alias || cat.title.toLowerCase());
    return this.austinConfig.chainCategories.some(chainCat => 
      restaurantCategories.includes(chainCat)
    );
  }

  // Get featured restaurants with robust selection logic
  async getFeaturedRestaurants(limit = 5) {
    try {
      const currentCategory = this.getCurrentWeekCategory();
      console.log(`Featured restaurant category for this week: ${currentCategory}`);
      
      // Search for restaurants in the current week's category
      const results = await this.searchRestaurants(
        this.austinConfig.location, 
        currentCategory, 
        null, 
        Math.min(limit * 3, 50) // Get more results to filter from
      );
      
      // Apply robust filtering criteria
      const featured = results.businesses
        .filter(restaurant => {
          // Rating and review count criteria
          const hasGoodRating = restaurant.rating >= 4.0;
          const hasEnoughReviews = restaurant.review_count >= 50;
          
          // Exclude chains
          const isNotChain = !this.isChainRestaurant(restaurant);
          
          // Exclude closed restaurants
          const isOpen = !restaurant.is_closed;
          
          // Must have essential info
          const hasEssentialInfo = restaurant.name && 
                                 restaurant.location && 
                                 restaurant.location.address1;
          
          return hasGoodRating && hasEnoughReviews && isNotChain && isOpen && hasEssentialInfo;
        })
        .sort((a, b) => {
          // Sort by rating first, then by review count
          if (b.rating !== a.rating) {
            return b.rating - a.rating;
          }
          return b.review_count - a.review_count;
        })
        .slice(0, limit);

      console.log(`Found ${featured.length} featured restaurants in ${currentCategory} category`);
      
      return {
        businesses: featured,
        total: featured.length,
        category: currentCategory,
        criteria: {
          minRating: 4.0,
          minReviews: 50,
          excludedChains: true,
          onlyOpen: true
        }
      };
    } catch (error) {
      console.error('Error getting featured restaurants:', error);
      throw error;
    }
  }

  // Search by cuisine type with Austin-specific enhancements
  async searchByCuisine(cuisine, location = null, limit = 20) {
    const cuisineMap = {
      'barbecue': 'bbq',
      'bbq': 'bbq',
      'mexican': 'mexican',
      'tex-mex': 'mexican',
      'italian': 'italian',
      'chinese': 'chinese',
      'japanese': 'japanese',
      'indian': 'indian',
      'thai': 'thai',
      'american': 'tradamerican',
      'french': 'french',
      'mediterranean': 'mediterranean',
      'seafood': 'seafood',
      'pizza': 'pizza',
      'sushi': 'sushi',
      'steakhouse': 'steakhouses',
      'vegetarian': 'vegetarian',
      'vegan': 'vegan'
    };

    const yelpCuisine = cuisineMap[cuisine.toLowerCase()] || cuisine;
    const searchLocation = location || this.austinConfig.location;
    
    const results = await this.searchRestaurants(searchLocation, yelpCuisine, null, limit);
    
    // Filter out chains for better local results
    const localResults = results.businesses.filter(restaurant => !this.isChainRestaurant(restaurant));
    
    return {
      ...results,
      businesses: localResults,
      cuisine: yelpCuisine,
      location: searchLocation
    };
  }

  // Search by price range
  async searchByPrice(priceRange, location = 'Austin, TX', limit = 20) {
    const priceMap = {
      'budget': '1',
      'moderate': '2',
      'upscale': '3',
      'fine-dining': '4',
      '1': '1',
      '2': '2',
      '3': '3',
      '4': '4',
      '$': '1',
      '$$': '2',
      '$$$': '3',
      '$$$$': '4'
    };

    // Handle the price range parameter - it might come in as $$ from URL
    let normalizedPrice = priceRange;
    if (priceRange.includes('$')) {
      normalizedPrice = priceRange;
    }
    
    const yelpPrice = priceMap[normalizedPrice] || priceRange;
    console.log(`Price range mapping: ${priceRange} -> ${yelpPrice}`);
    return this.searchRestaurants(location, null, yelpPrice, limit);
  }

  // Get restaurant statistics
  getRestaurantStats(restaurant) {
    return {
      id: restaurant.id,
      name: restaurant.name,
      rating: restaurant.rating,
      reviewCount: restaurant.review_count,
      price: restaurant.price,
      categories: restaurant.categories?.map(cat => cat.title) || [],
      location: {
        address: restaurant.location?.address1,
        city: restaurant.location?.city,
        state: restaurant.location?.state,
        zipCode: restaurant.location?.zip_code,
        coordinates: {
          latitude: restaurant.coordinates?.latitude,
          longitude: restaurant.coordinates?.longitude
        }
      },
      phone: restaurant.phone,
      url: restaurant.url,
      imageUrl: restaurant.image_url,
      isClosed: restaurant.is_closed,
      distance: restaurant.distance
    };
  }

  // Format restaurant for our app with comprehensive data transformation
  formatRestaurantForApp(yelpRestaurant) {
    const location = yelpRestaurant.location || {};
    const coordinates = yelpRestaurant.coordinates || {};
    const categories = yelpRestaurant.categories || [];
    const hours = yelpRestaurant.hours?.[0]?.open || [];
    
    // Calculate distance from downtown Austin if not provided
    let distance = yelpRestaurant.distance;
    if (!distance && coordinates.latitude && coordinates.longitude) {
      distance = this.calculateDistance(
        this.austinConfig.downtownCoords.latitude,
        this.austinConfig.downtownCoords.longitude,
        coordinates.latitude,
        coordinates.longitude
      );
    }

    // Format hours for easier use
    const formattedHours = this.formatHours(hours);
    
    // Get primary cuisine category
    const primaryCuisine = this.getPrimaryCuisine(categories);
    
    // Get specialties from categories
    const specialties = this.getSpecialties(categories, yelpRestaurant.name);
    
    // Calculate wait time estimate based on rating and popularity
    const waitTime = this.estimateWaitTime(yelpRestaurant.rating, yelpRestaurant.review_count);

    // Select the best atmospheric photo for the hero image
    const atmosphericPhoto = this.selectAtmosphericPhoto(yelpRestaurant.photos || []);

    return {
      // Basic info
      id: yelpRestaurant.id,
      name: yelpRestaurant.name,
      description: this.generateDescription(yelpRestaurant),
      
      // Location
      address: location.address1 || '',
      city: location.city || 'Austin',
      state: location.state || 'TX',
      zipCode: location.zip_code || '',
      coordinates: {
        latitude: coordinates.latitude || this.austinConfig.downtownCoords.latitude,
        longitude: coordinates.longitude || this.austinConfig.downtownCoords.longitude
      },
      
      // Contact
      phone: yelpRestaurant.phone || '',
      website: yelpRestaurant.url || null,
      
      // Cuisine & Categories
      cuisine: primaryCuisine,
      categories: categories.map(cat => cat.title),
      specialties: specialties,
      
      // Ratings & Reviews
      rating: yelpRestaurant.rating || 0,
      reviewCount: yelpRestaurant.review_count || 0,
      priceRange: this.getPriceRange(yelpRestaurant.price),
      
      // Visual
      imageUrl: atmosphericPhoto || yelpRestaurant.image_url || null,
      photos: yelpRestaurant.photos || [],
      
      // Hours & Operations
      hours: formattedHours,
      isClosed: yelpRestaurant.is_closed || false,
      isClaimed: yelpRestaurant.is_claimed || false,
      
      // Location & Distance
      distance: distance ? Math.round(distance * 10) / 10 : null, // Round to 1 decimal
      area: this.getAreaFromAddress(location.address1, location.city),
      
      // Additional Info
      waitTime: waitTime,
      transactions: yelpRestaurant.transactions || [],
      attributes: yelpRestaurant.attributes || {},
      
      // Yelp-specific
      yelpUrl: yelpRestaurant.url,
      yelpId: yelpRestaurant.id,
      
      // Timestamps
      lastUpdated: new Date().toISOString()
    };
  }

  // Calculate distance between two coordinates (in miles)
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 3959; // Earth's radius in miles
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  // Format hours for easier display
  formatHours(hours) {
    if (!hours || hours.length === 0) return {};
    
    const dayMap = {
      0: 'monday', 1: 'tuesday', 2: 'wednesday', 3: 'thursday',
      4: 'friday', 5: 'saturday', 6: 'sunday'
    };
    
    const formatted = {};
    hours.forEach(day => {
      const dayName = dayMap[day.day];
      if (dayName) {
        const start = this.formatTime(day.start);
        const end = this.formatTime(day.end);
        formatted[dayName] = `${start} - ${end}`;
      }
    });
    
    return formatted;
  }

  // Format time from Yelp format (HHMM) to readable format
  formatTime(timeStr) {
    if (!timeStr) return 'Closed';
    const hour = parseInt(timeStr.substring(0, 2));
    const minute = timeStr.substring(2, 4);
    const period = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
    return `${displayHour}:${minute} ${period}`;
  }

  // Get primary cuisine category
  getPrimaryCuisine(categories) {
    if (!categories || categories.length === 0) return 'Restaurant';
    
    // Priority order for cuisine types
    const cuisinePriority = [
      'bbq', 'mexican', 'italian', 'chinese', 'japanese', 'indian', 
      'thai', 'french', 'mediterranean', 'seafood', 'pizza', 'sushi',
      'steakhouses', 'vegetarian', 'vegan', 'tradamerican'
    ];
    
    for (const priority of cuisinePriority) {
      const found = categories.find(cat => 
        cat.alias === priority || cat.title.toLowerCase().includes(priority)
      );
      if (found) return found.title;
    }
    
    return categories[0].title;
  }

  // Get specialties from categories and restaurant name
  getSpecialties(categories, restaurantName) {
    const specialties = [];
    
    // Add specialties based on categories
    categories.forEach(cat => {
      const title = cat.title.toLowerCase();
      if (title.includes('bbq')) specialties.push('Brisket', 'Ribs', 'Sausage');
      else if (title.includes('mexican')) specialties.push('Tacos', 'Queso', 'Margaritas');
      else if (title.includes('italian')) specialties.push('Pasta', 'Pizza', 'Wine');
      else if (title.includes('sushi')) specialties.push('Sashimi', 'Rolls', 'Sake');
      else if (title.includes('seafood')) specialties.push('Fresh Fish', 'Oysters', 'Crab');
    });
    
    // Add specialties based on restaurant name
    const name = restaurantName.toLowerCase();
    if (name.includes('bbq') || name.includes('barbecue')) {
      specialties.push('Brisket', 'Ribs', 'Sausage');
    }
    
    // Remove duplicates and limit to 5
    return [...new Set(specialties)].slice(0, 5);
  }

  // Estimate wait time based on rating and popularity
  estimateWaitTime(rating, reviewCount) {
    if (!rating || !reviewCount) return 'Unknown';
    
    const popularity = Math.min(reviewCount / 100, 10); // Scale 0-10
    const ratingFactor = Math.max(rating - 3, 0); // Higher rating = longer wait
    
    if (rating >= 4.5 && popularity >= 5) return '2-4 hours (very popular)';
    if (rating >= 4.0 && popularity >= 3) return '1-2 hours (popular)';
    if (rating >= 3.5) return '30-60 minutes (moderate)';
    return '15-30 minutes (quick)';
  }

  // Generate description based on restaurant data
  generateDescription(restaurant) {
    const categories = restaurant.categories || [];
    const rating = restaurant.rating || 0;
    const reviewCount = restaurant.review_count || 0;
    
    let description = '';
    
    if (categories.length > 0) {
      const primaryCategory = categories[0].title;
      description += `A ${primaryCategory.toLowerCase()} restaurant`;
    } else {
      description += 'A restaurant';
    }
    
    if (rating >= 4.5) {
      description += ' known for exceptional quality and outstanding reviews';
    } else if (rating >= 4.0) {
      description += ' with excellent ratings and great food';
    } else if (rating >= 3.5) {
      description += ' offering good food and service';
    }
    
    if (reviewCount >= 100) {
      description += `. Highly reviewed with ${reviewCount} reviews`;
    }
    
    return description + '.';
  }

  // Get area from address (simplified)
  getAreaFromAddress(address, city) {
    if (!address) return city || 'Austin';
    
    const addressLower = address.toLowerCase();
    if (addressLower.includes('east') || addressLower.includes('e ')) return 'East Austin';
    if (addressLower.includes('west') || addressLower.includes('w ')) return 'West Austin';
    if (addressLower.includes('north') || addressLower.includes('n ')) return 'North Austin';
    if (addressLower.includes('south') || addressLower.includes('s ')) return 'South Austin';
    if (addressLower.includes('downtown') || addressLower.includes('dt')) return 'Downtown';
    
    return city || 'Austin';
  }

  // Convert Yelp price to readable format
  getPriceRange(yelpPrice) {
    const priceMap = {
      '$': 'Budget',
      '$$': 'Moderate', 
      '$$$': 'Upscale',
      '$$$$': 'Fine Dining'
    };
    return priceMap[yelpPrice] || 'Unknown';
  }

  // Get cache statistics
  getCacheStats() {
    return {
      size: this.cache.size,
      keys: Array.from(this.cache.keys())
    };
  }

  // Clear all cache
  clearCache() {
    this.cache.clear();
  }

  // Austin-specific search methods
  
  // Search for BBQ restaurants (Austin specialty)
  async searchBBQ(limit = 10) {
    return this.searchByCuisine('bbq', null, limit);
  }

  // Search for Tex-Mex restaurants (Austin specialty)
  async searchTexMex(limit = 10) {
    return this.searchByCuisine('mexican', null, limit);
  }

  // Search for food trucks (Austin has many)
  async searchFoodTrucks(limit = 10) {
    const results = await this.searchRestaurants(null, 'foodtrucks', null, limit);
    return {
      ...results,
      category: 'foodtrucks',
      location: this.austinConfig.location
    };
  }

  // Search for restaurants near downtown Austin
  async searchDowntown(limit = 10) {
    const results = await this.searchRestaurants('Downtown Austin, TX', null, null, limit);
    return {
      ...results,
      area: 'Downtown',
      location: 'Downtown Austin, TX'
    };
  }

  // Search for highly-rated restaurants (4.5+ stars)
  async searchHighlyRated(limit = 10) {
    const results = await this.searchRestaurants(null, null, null, Math.min(limit * 2, 50));
    
    const highlyRated = results.businesses
      .filter(restaurant => restaurant.rating >= 4.5)
      .sort((a, b) => b.rating - a.rating)
      .slice(0, limit);

    return {
      ...results,
      businesses: highlyRated,
      criteria: 'highly-rated (4.5+ stars)'
    };
  }

  // Search for new restaurants (opened recently)
  async searchNewRestaurants(limit = 10) {
    // This would require additional Yelp API calls or different approach
    // For now, return recent highly-rated restaurants
    const results = await this.searchRestaurants(null, null, null, Math.min(limit * 2, 50));
    
    const newRestaurants = results.businesses
      .filter(restaurant => {
        // Filter for restaurants with fewer reviews (likely newer)
        return restaurant.review_count < 100 && restaurant.rating >= 4.0;
      })
      .sort((a, b) => b.rating - a.rating)
      .slice(0, limit);

    return {
      ...results,
      businesses: newRestaurants,
      criteria: 'new restaurants (low review count, high rating)'
    };
  }

  // Get Austin food scene statistics
  async getAustinFoodStats() {
    try {
      const categories = ['bbq', 'mexican', 'italian', 'chinese', 'japanese'];
      const stats = {};
      
      for (const category of categories) {
        const results = await this.searchByCuisine(category, null, 5);
        stats[category] = {
          total: results.total,
          averageRating: results.businesses.reduce((sum, r) => sum + r.rating, 0) / results.businesses.length,
          topRestaurant: results.businesses[0]?.name || 'N/A'
        };
      }
      
      return {
        location: this.austinConfig.location,
        radius: this.austinConfig.radius,
        categories: stats,
        lastUpdated: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error getting Austin food stats:', error);
      throw error;
    }
  }

  // Select the best atmospheric photo from available photos
  selectAtmosphericPhoto(photos) {
    if (!photos || photos.length === 0) {
      return null;
    }

    // Keywords that suggest atmospheric/interior/exterior photos
    const atmosphericKeywords = [
      'interior', 'exterior', 'inside', 'outside', 'dining', 'room', 'space',
      'atmosphere', 'ambiance', 'decor', 'setting', 'environment', 'vibe',
      'patio', 'terrace', 'garden', 'outdoor', 'indoor', 'seating', 'bar',
      'counter', 'kitchen', 'entrance', 'facade', 'building', 'restaurant'
    ];

    // Score photos based on how likely they are to show atmosphere
    const scoredPhotos = photos.map(photo => {
      let score = 0;
      const photoLower = photo.toLowerCase();
      
      // Check if photo URL contains atmospheric keywords
      atmosphericKeywords.forEach(keyword => {
        if (photoLower.includes(keyword)) {
          score += 2;
        }
      });

      // Prefer photos that are likely to be interior/exterior shots
      // (this is a heuristic - in a real app you might use image analysis)
      if (photoLower.includes('interior') || photoLower.includes('inside')) {
        score += 3;
      }
      if (photoLower.includes('exterior') || photoLower.includes('outside')) {
        score += 2;
      }
      if (photoLower.includes('dining') || photoLower.includes('room')) {
        score += 2;
      }

      // Prefer photos that don't look like food close-ups
      if (photoLower.includes('food') || photoLower.includes('dish') || photoLower.includes('plate')) {
        score -= 1;
      }

      return { photo, score };
    });

    // Sort by score (highest first) and return the best photo
    scoredPhotos.sort((a, b) => b.score - a.score);
    
    // Return the highest scoring photo, or the first photo if no clear winner
    return scoredPhotos[0]?.score > 0 ? scoredPhotos[0].photo : photos[0];
  }

  // Enhance coordinates using geocoding service if needed
  async enhanceCoordinates(restaurant) {
    try {
      // If coordinates are missing or default, try to geocode the address
      if (!restaurant.coordinates || 
          (restaurant.coordinates.latitude === this.austinConfig.downtownCoords.latitude &&
           restaurant.coordinates.longitude === this.austinConfig.downtownCoords.longitude)) {
        
        const fullAddress = `${restaurant.address}, Austin, TX`;
        const geocoded = await geocodingService.geocodeAddress(fullAddress);
        
        if (geocoded && !geocoded.fallback) {
          console.log(`Enhanced coordinates for ${restaurant.name}: ${geocoded.latitude}, ${geocoded.longitude}`);
          return {
            ...restaurant,
            coordinates: {
              latitude: geocoded.latitude,
              longitude: geocoded.longitude
            }
          };
        }
      }
      
      return restaurant;
    } catch (error) {
      console.error(`Error enhancing coordinates for ${restaurant.name}:`, error.message);
      return restaurant;
    }
  }
}

module.exports = new YelpService();
