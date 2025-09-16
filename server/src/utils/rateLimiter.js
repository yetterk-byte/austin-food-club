const NodeCache = require('node-cache');

// Rate limiting configuration
const RATE_LIMITS = {
  // Yelp API free tier limits
  yelp: {
    daily: 5000, // 5000 requests per day
    hourly: 500, // 500 requests per hour (estimated)
    minute: 10   // 10 requests per minute (estimated)
  }
};

// Create cache for rate limiting (1 hour TTL for hourly limits, 24 hours for daily)
const rateLimitCache = new NodeCache({ 
  stdTTL: 3600, // 1 hour default
  checkperiod: 300, // Check every 5 minutes
  useClones: false
});

// Request queue for when rate limits are exceeded
const requestQueue = [];
let isProcessingQueue = false;

// Rate limiting statistics
let rateLimitStats = {
  totalRequests: 0,
  allowedRequests: 0,
  blockedRequests: 0,
  queuedRequests: 0,
  processedFromQueue: 0,
  dailyLimitReached: 0,
  hourlyLimitReached: 0,
  minuteLimitReached: 0
};

/**
 * Get current timestamp for different time windows
 */
const getTimeWindows = () => {
  const now = new Date();
  const minute = Math.floor(now.getTime() / (1000 * 60));
  const hour = Math.floor(now.getTime() / (1000 * 60 * 60));
  const day = Math.floor(now.getTime() / (1000 * 60 * 60 * 24));
  
  return { minute, hour, day };
};

/**
 * Get rate limit key for a specific time window
 */
const getRateLimitKey = (api, timeWindow, value) => {
  return `rate_limit:${api}:${timeWindow}:${value}`;
};

/**
 * Check if request is within rate limits
 */
const checkRateLimit = (api = 'yelp') => {
  const { minute, hour, day } = getTimeWindows();
  const limits = RATE_LIMITS[api];
  
  if (!limits) {
    console.error(`Unknown API: ${api}`);
    return { allowed: false, reason: 'unknown_api' };
  }

  // Check minute limit
  const minuteKey = getRateLimitKey(api, 'minute', minute);
  const minuteCount = rateLimitCache.get(minuteKey) || 0;
  if (minuteCount >= limits.minute) {
    rateLimitStats.minuteLimitReached++;
    return { 
      allowed: false, 
      reason: 'minute_limit',
      retryAfter: 60,
      currentCount: minuteCount,
      limit: limits.minute
    };
  }

  // Check hourly limit
  const hourKey = getRateLimitKey(api, 'hour', hour);
  const hourCount = rateLimitCache.get(hourKey) || 0;
  if (hourCount >= limits.hourly) {
    rateLimitStats.hourlyLimitReached++;
    return { 
      allowed: false, 
      reason: 'hourly_limit',
      retryAfter: 3600,
      currentCount: hourCount,
      limit: limits.hourly
    };
  }

  // Check daily limit
  const dayKey = getRateLimitKey(api, 'day', day);
  const dayCount = rateLimitCache.get(dayKey) || 0;
  if (dayCount >= limits.daily) {
    rateLimitStats.dailyLimitReached++;
    return { 
      allowed: false, 
      reason: 'daily_limit',
      retryAfter: 86400,
      currentCount: dayCount,
      limit: limits.daily
    };
  }

  return { allowed: true };
};

/**
 * Increment rate limit counters
 */
const incrementRateLimit = (api = 'yelp') => {
  const { minute, hour, day } = getTimeWindows();
  
  // Increment minute counter (1 minute TTL)
  const minuteKey = getRateLimitKey(api, 'minute', minute);
  const minuteCount = (rateLimitCache.get(minuteKey) || 0) + 1;
  rateLimitCache.set(minuteKey, minuteCount, 60);
  
  // Increment hour counter (1 hour TTL)
  const hourKey = getRateLimitKey(api, 'hour', hour);
  const hourCount = (rateLimitCache.get(hourKey) || 0) + 1;
  rateLimitCache.set(hourKey, hourCount, 3600);
  
  // Increment day counter (24 hour TTL)
  const dayKey = getRateLimitKey(api, 'day', day);
  const dayCount = (rateLimitCache.get(dayKey) || 0) + 1;
  rateLimitCache.set(dayKey, dayCount, 86400);
  
  rateLimitStats.totalRequests++;
  rateLimitStats.allowedRequests++;
};

/**
 * Add request to queue
 */
const queueRequest = (requestData) => {
  return new Promise((resolve, reject) => {
    const queuedRequest = {
      id: Date.now() + Math.random(),
      data: requestData,
      resolve,
      reject,
      timestamp: Date.now()
    };
    
    requestQueue.push(queuedRequest);
    rateLimitStats.queuedRequests++;
    
    console.log(`Request queued. Queue length: ${requestQueue.length}`);
  });
};

/**
 * Process queued requests
 */
const processQueue = async (yelpService, cacheMiddleware) => {
  if (isProcessingQueue || requestQueue.length === 0) {
    return;
  }
  
  isProcessingQueue = true;
  console.log(`Processing ${requestQueue.length} queued requests...`);
  
  while (requestQueue.length > 0) {
    const request = requestQueue.shift();
    
    try {
      // Check if we can make the request now
      const rateCheck = checkRateLimit();
      
      if (rateCheck.allowed) {
        // Process the request
        const result = await processYelpRequest(yelpService, request.data);
        request.resolve(result);
        incrementRateLimit();
        rateLimitStats.processedFromQueue++;
      } else {
        // Still rate limited, put back in queue
        requestQueue.unshift(request);
        
        // Wait before trying again
        const waitTime = Math.min(rateCheck.retryAfter * 1000, 60000); // Max 1 minute wait
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    } catch (error) {
      console.error('Error processing queued request:', error);
      request.reject(error);
    }
  }
  
  isProcessingQueue = false;
  console.log('Queue processing completed');
};

/**
 * Process a Yelp API request
 */
const processYelpRequest = async (yelpService, requestData) => {
  const { method, params } = requestData;
  
  switch (method) {
    case 'searchRestaurants':
      return await yelpService.searchRestaurants(
        params.location,
        params.term,
        params.categories,
        params.price,
        params.limit,
        params.radius,
        params.sort_by
      );
    
    case 'getRestaurantDetails':
      return await yelpService.getRestaurantDetails(params.yelpId);
    
    case 'getRestaurantReviews':
      return await yelpService.getRestaurantReviews(params.yelpId);
    
    default:
      throw new Error(`Unknown method: ${method}`);
  }
};

/**
 * Rate limiting middleware
 */
const rateLimitMiddleware = (api = 'yelp') => {
  return async (req, res, next) => {
    try {
      const rateCheck = checkRateLimit(api);
      
      if (rateCheck.allowed) {
        // Request is allowed, increment counters
        incrementRateLimit(api);
        next();
      } else {
        // Request is blocked
        rateLimitStats.blockedRequests++;
        
        const errorResponse = {
          error: 'Rate limit exceeded',
          reason: rateCheck.reason,
          retryAfter: rateCheck.retryAfter,
          currentCount: rateCheck.currentCount,
          limit: rateCheck.limit,
          message: getRateLimitMessage(rateCheck.reason, rateCheck.retryAfter)
        };
        
        console.log(`Rate limit exceeded: ${rateCheck.reason}`);
        return res.status(429).json(errorResponse);
      }
    } catch (error) {
      console.error('Rate limiting error:', error);
      next(); // Continue on error to avoid blocking requests
    }
  };
};

/**
 * Get user-friendly rate limit message
 */
const getRateLimitMessage = (reason, retryAfter) => {
  switch (reason) {
    case 'minute_limit':
      return 'Too many requests per minute. Please wait a moment and try again.';
    case 'hourly_limit':
      return 'Hourly request limit reached. Please try again in an hour.';
    case 'daily_limit':
      return 'Daily request limit reached. Please try again tomorrow.';
    default:
      return 'Rate limit exceeded. Please try again later.';
  }
};

/**
 * Get current rate limit status
 */
const getRateLimitStatus = (api = 'yelp') => {
  const { minute, hour, day } = getTimeWindows();
  const limits = RATE_LIMITS[api];
  
  const minuteKey = getRateLimitKey(api, 'minute', minute);
  const hourKey = getRateLimitKey(api, 'hour', hour);
  const dayKey = getRateLimitKey(api, 'day', day);
  
  return {
    minute: {
      current: rateLimitCache.get(minuteKey) || 0,
      limit: limits.minute,
      remaining: limits.minute - (rateLimitCache.get(minuteKey) || 0)
    },
    hour: {
      current: rateLimitCache.get(hourKey) || 0,
      limit: limits.hourly,
      remaining: limits.hourly - (rateLimitCache.get(hourKey) || 0)
    },
    day: {
      current: rateLimitCache.get(dayKey) || 0,
      limit: limits.daily,
      remaining: limits.daily - (rateLimitCache.get(dayKey) || 0)
    },
    queue: {
      length: requestQueue.length,
      processing: isProcessingQueue
    },
    stats: rateLimitStats
  };
};

/**
 * Reset rate limit counters (for testing)
 */
const resetRateLimits = () => {
  rateLimitCache.flushAll();
  requestQueue.length = 0;
  isProcessingQueue = false;
  
  // Reset stats
  Object.keys(rateLimitStats).forEach(key => {
    rateLimitStats[key] = 0;
  });
  
  console.log('Rate limits reset');
};

/**
 * Start queue processor
 */
const startQueueProcessor = (yelpService, cacheMiddleware) => {
  // Process queue every 30 seconds
  setInterval(() => {
    processQueue(yelpService, cacheMiddleware);
  }, 30000);
  
  console.log('Rate limiter queue processor started');
};

module.exports = {
  rateLimitMiddleware,
  checkRateLimit,
  incrementRateLimit,
  queueRequest,
  processQueue,
  getRateLimitStatus,
  resetRateLimits,
  startQueueProcessor,
  RATE_LIMITS
};
