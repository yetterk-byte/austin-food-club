const CityService = require('../services/cityService');

/**
 * City Context Middleware
 * Adds city information to request context for multi-city support
 */

// Cache for city configurations (refresh every 5 minutes)
const cityCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

/**
 * Get city configuration with caching
 */
async function getCachedCityConfig(citySlug) {
  const cacheKey = `city:${citySlug}`;
  const cached = cityCache.get(cacheKey);
  
  if (cached && (Date.now() - cached.timestamp) < CACHE_TTL) {
    return cached.data;
  }
  
  try {
    const city = await CityService.getCityBySlug(citySlug);
    if (city) {
      const cityConfig = await CityService.getCityConfig(city.id);
      cityCache.set(cacheKey, {
        data: cityConfig,
        timestamp: Date.now()
      });
      return cityConfig;
    }
  } catch (error) {
    console.error(`Error fetching city config for ${citySlug}:`, error);
  }
  
  return null;
}

/**
 * Main city context middleware
 */
const cityContext = async (req, res, next) => {
  try {
    // Determine city slug from request
    const citySlug = CityService.getCityContext(req);
    
    // Get city configuration
    const cityConfig = await getCachedCityConfig(citySlug);
    
    if (!cityConfig) {
      // Default to Austin if city not found
      const austinConfig = await getCachedCityConfig('austin');
      if (austinConfig) {
        req.city = austinConfig;
        req.citySlug = 'austin';
      } else {
        return res.status(500).json({
          error: 'City configuration not available',
          code: 'CITY_CONFIG_ERROR'
        });
      }
    } else {
      req.city = cityConfig;
      req.citySlug = citySlug;
    }
    
    // Add city context to response headers for debugging
    res.set('X-City-Context', req.citySlug);
    res.set('X-City-Name', req.city.displayName);
    
    next();
  } catch (error) {
    console.error('City context middleware error:', error);
    res.status(500).json({
      error: 'Failed to determine city context',
      code: 'CITY_CONTEXT_ERROR'
    });
  }
};

/**
 * Middleware to require active city
 */
const requireActiveCity = (req, res, next) => {
  if (!req.city) {
    return res.status(400).json({
      error: 'City context required',
      code: 'MISSING_CITY_CONTEXT'
    });
  }
  
  // Check if city is active (for non-admin routes)
  if (!req.city.isActive && !req.admin) {
    return res.status(403).json({
      error: `${req.city.displayName} is not yet available`,
      code: 'CITY_INACTIVE',
      city: req.city.displayName
    });
  }
  
  next();
};

/**
 * Clear city cache (useful for admin updates)
 */
const clearCityCache = (citySlug) => {
  if (citySlug) {
    cityCache.delete(`city:${citySlug}`);
  } else {
    cityCache.clear();
  }
};

module.exports = {
  cityContext,
  requireActiveCity,
  clearCityCache,
  getCachedCityConfig
};
