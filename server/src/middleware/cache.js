const NodeCache = require('node-cache');

// Create cache instances with different TTLs
const restaurantCache = new NodeCache({ 
  stdTTL: 3600, // 1 hour for restaurant details
  checkperiod: 600, // Check for expired keys every 10 minutes
  useClones: false // Don't clone objects for better performance
});

const searchCache = new NodeCache({ 
  stdTTL: 86400, // 24 hours for search results
  checkperiod: 1800, // Check for expired keys every 30 minutes
  useClones: false
});

const reviewsCache = new NodeCache({ 
  stdTTL: 7200, // 2 hours for reviews
  checkperiod: 600,
  useClones: false
});

// Cache statistics
let cacheStats = {
  hits: 0,
  misses: 0,
  sets: 0,
  deletes: 0,
  errors: 0
};

/**
 * Generate cache key from request parameters
 */
const generateCacheKey = (endpoint, params = {}) => {
  const sortedParams = Object.keys(params)
    .sort()
    .map(key => `${key}=${params[key]}`)
    .join('&');
  
  return `${endpoint}:${sortedParams}`;
};

/**
 * Get cached data
 */
const getCachedData = (cache, key) => {
  try {
    const data = cache.get(key);
    if (data) {
      cacheStats.hits++;
      return data;
    }
    cacheStats.misses++;
    return null;
  } catch (error) {
    console.error('Cache get error:', error);
    cacheStats.errors++;
    return null;
  }
};

/**
 * Set cached data
 */
const setCachedData = (cache, key, data, ttl = null) => {
  try {
    const success = cache.set(key, data, ttl);
    if (success) {
      cacheStats.sets++;
    }
    return success;
  } catch (error) {
    console.error('Cache set error:', error);
    cacheStats.errors++;
    return false;
  }
};

/**
 * Middleware for restaurant details caching
 */
const cacheRestaurantDetails = (req, res, next) => {
  const { restaurantId, yelpId } = req.params;
  const fresh = req.query.fresh === 'true';
  
  if (fresh) {
    console.log('Bypassing cache for fresh data');
    return next();
  }

  const cacheKey = generateCacheKey('restaurant', { 
    id: restaurantId || yelpId,
    type: yelpId ? 'yelp' : 'local'
  });

  const cachedData = getCachedData(restaurantCache, cacheKey);
  
  if (cachedData) {
    console.log(`Cache hit for restaurant: ${cacheKey}`);
    return res.json({
      ...cachedData,
      cached: true,
      cacheTimestamp: new Date().toISOString()
    });
  }

  // Store original res.json to intercept response
  const originalJson = res.json;
  res.json = function(data) {
    // Cache successful responses
    if (data && !data.error) {
      setCachedData(restaurantCache, cacheKey, data);
      console.log(`Cached restaurant data: ${cacheKey}`);
    }
    return originalJson.call(this, data);
  };

  next();
};

/**
 * Middleware for search results caching
 */
const cacheSearchResults = (req, res, next) => {
  const fresh = req.query.fresh === 'true';
  
  if (fresh) {
    console.log('Bypassing search cache for fresh data');
    return next();
  }

  const searchParams = {
    location: req.query.location,
    term: req.query.term,
    categories: req.query.categories,
    price: req.query.price,
    radius: req.query.radius,
    sort_by: req.query.sort_by,
    limit: req.query.limit,
    offset: req.query.offset
  };

  const cacheKey = generateCacheKey('search', searchParams);
  const cachedData = getCachedData(searchCache, cacheKey);
  
  if (cachedData) {
    console.log(`Cache hit for search: ${cacheKey}`);
    return res.json({
      ...cachedData,
      cached: true,
      cacheTimestamp: new Date().toISOString()
    });
  }

  // Store original res.json to intercept response
  const originalJson = res.json;
  res.json = function(data) {
    // Cache successful responses
    if (data && !data.error && data.restaurants) {
      setCachedData(searchCache, cacheKey, data);
      console.log(`Cached search results: ${cacheKey}`);
    }
    return originalJson.call(this, data);
  };

  next();
};

/**
 * Middleware for reviews caching
 */
const cacheReviews = (req, res, next) => {
  const { yelpId } = req.params;
  const fresh = req.query.fresh === 'true';
  
  if (fresh) {
    console.log('Bypassing reviews cache for fresh data');
    return next();
  }

  const cacheKey = generateCacheKey('reviews', { yelpId });
  const cachedData = getCachedData(reviewsCache, cacheKey);
  
  if (cachedData) {
    console.log(`Cache hit for reviews: ${cacheKey}`);
    return res.json({
      ...cachedData,
      cached: true,
      cacheTimestamp: new Date().toISOString()
    });
  }

  // Store original res.json to intercept response
  const originalJson = res.json;
  res.json = function(data) {
    // Cache successful responses
    if (data && !data.error) {
      setCachedData(reviewsCache, cacheKey, data);
      console.log(`Cached reviews data: ${cacheKey}`);
    }
    return originalJson.call(this, data);
  };

  next();
};

/**
 * Clear cache by pattern
 */
const clearCacheByPattern = (pattern) => {
  try {
    const restaurantKeys = restaurantCache.keys().filter(key => key.includes(pattern));
    const searchKeys = searchCache.keys().filter(key => key.includes(pattern));
    const reviewKeys = reviewsCache.keys().filter(key => key.includes(pattern));
    
    restaurantKeys.forEach(key => restaurantCache.del(key));
    searchKeys.forEach(key => searchCache.del(key));
    reviewKeys.forEach(key => reviewsCache.del(key));
    
    cacheStats.deletes += restaurantKeys.length + searchKeys.length + reviewKeys.length;
    
    console.log(`Cleared ${restaurantKeys.length + searchKeys.length + reviewKeys.length} cache entries for pattern: ${pattern}`);
    return true;
  } catch (error) {
    console.error('Cache clear error:', error);
    cacheStats.errors++;
    return false;
  }
};

/**
 * Clear all caches
 */
const clearAllCaches = () => {
  try {
    restaurantCache.flushAll();
    searchCache.flushAll();
    reviewsCache.flushAll();
    
    console.log('All caches cleared');
    return true;
  } catch (error) {
    console.error('Cache clear all error:', error);
    cacheStats.errors++;
    return false;
  }
};

/**
 * Get cache statistics
 */
const getCacheStats = () => {
  return {
    ...cacheStats,
    restaurantCache: {
      keys: restaurantCache.keys().length,
      stats: restaurantCache.getStats()
    },
    searchCache: {
      keys: searchCache.keys().length,
      stats: searchCache.getStats()
    },
    reviewsCache: {
      keys: reviewsCache.keys().length,
      stats: reviewsCache.getStats()
    }
  };
};

/**
 * Warm up cache with popular searches
 */
const warmUpCache = async (yelpService) => {
  try {
    console.log('Warming up cache with popular Austin searches...');
    
    const popularSearches = [
      { location: 'Austin, TX', cuisine: 'bbq', limit: 10 },
      { location: 'Austin, TX', cuisine: 'mexican', limit: 10 },
      { location: 'Austin, TX', cuisine: 'japanese', limit: 10 },
      { location: 'Austin, TX', cuisine: 'italian', limit: 10 }
    ];

    for (const search of popularSearches) {
      try {
        const results = await yelpService.searchRestaurants(search.location, search.cuisine, search.price, search.limit);
        if (results && results.restaurants) {
          const cacheKey = generateCacheKey('search', search);
          setCachedData(searchCache, cacheKey, results);
          console.log(`Warmed up cache for: ${search.cuisine}`);
        }
      } catch (error) {
        console.error(`Failed to warm up cache for ${search.cuisine}:`, error);
      }
    }
    
    console.log('Cache warm-up completed');
  } catch (error) {
    console.error('Cache warm-up error:', error);
  }
};

module.exports = {
  cacheRestaurantDetails,
  cacheSearchResults,
  cacheReviews,
  clearCacheByPattern,
  clearAllCaches,
  getCacheStats,
  warmUpCache,
  generateCacheKey,
  restaurantCache,
  searchCache,
  reviewsCache
};
