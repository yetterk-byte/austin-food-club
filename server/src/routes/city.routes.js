const express = require('express');
const router = express.Router();
const CityService = require('../services/cityService');
const { cityContext, requireActiveCity, clearCityCache } = require('../middleware/cityContext');
const { requireAdmin } = require('../middleware/adminAuth');

/**
 * City Management Routes for Multi-City Food Club
 */

// Apply city context to all routes
router.use(cityContext);

/**
 * Public Routes
 */

// Get all active cities
router.get('/', async (req, res) => {
  try {
    const cities = await CityService.getAllCities();
    res.json({
      success: true,
      cities: cities.map(city => ({
        id: city.id,
        name: city.name,
        slug: city.slug,
        displayName: city.displayName,
        state: city.state,
        brandColor: city.brandColor,
        logoUrl: city.logoUrl,
        isActive: city.isActive,
        launchDate: city.launchDate
      }))
    });
  } catch (error) {
    console.error('Error fetching cities:', error);
    res.status(500).json({
      error: 'Failed to fetch cities',
      code: 'CITIES_FETCH_ERROR'
    });
  }
});

// Get current city configuration
router.get('/current', requireActiveCity, async (req, res) => {
  try {
    res.json({
      success: true,
      city: req.city
    });
  } catch (error) {
    console.error('Error fetching current city:', error);
    res.status(500).json({
      error: 'Failed to fetch city configuration',
      code: 'CITY_CONFIG_ERROR'
    });
  }
});

// Get city by slug
router.get('/:slug', async (req, res) => {
  try {
    const { slug } = req.params;
    const city = await CityService.getCityBySlug(slug);
    
    if (!city) {
      return res.status(404).json({
        error: 'City not found',
        code: 'CITY_NOT_FOUND'
      });
    }
    
    const cityConfig = await CityService.getCityConfig(city.id);
    
    res.json({
      success: true,
      city: cityConfig
    });
  } catch (error) {
    console.error('Error fetching city:', error);
    res.status(500).json({
      error: 'Failed to fetch city',
      code: 'CITY_FETCH_ERROR'
    });
  }
});

/**
 * Admin Routes (require authentication)
 */

// Create new city
router.post('/', requireAdmin, async (req, res) => {
  try {
    const cityData = req.body;
    const city = await CityService.createCity(cityData);
    
    // Clear cache
    clearCityCache();
    
    res.status(201).json({
      success: true,
      city,
      message: 'City created successfully'
    });
  } catch (error) {
    console.error('Error creating city:', error);
    res.status(500).json({
      error: 'Failed to create city',
      code: 'CITY_CREATE_ERROR',
      details: error.message
    });
  }
});

// Update city configuration
router.put('/:slug', requireAdmin, async (req, res) => {
  try {
    const { slug } = req.params;
    const updateData = req.body;
    
    const city = await CityService.getCityBySlug(slug);
    if (!city) {
      return res.status(404).json({
        error: 'City not found',
        code: 'CITY_NOT_FOUND'
      });
    }
    
    const updatedCity = await CityService.updateCity(city.id, updateData);
    
    // Clear cache for this city
    clearCityCache(slug);
    
    res.json({
      success: true,
      city: updatedCity,
      message: 'City updated successfully'
    });
  } catch (error) {
    console.error('Error updating city:', error);
    res.status(500).json({
      error: 'Failed to update city',
      code: 'CITY_UPDATE_ERROR',
      details: error.message
    });
  }
});

// Initialize default cities (development/setup endpoint)
router.post('/initialize', requireAdmin, async (req, res) => {
  try {
    const results = await CityService.initializeDefaultCities();
    
    // Clear cache
    clearCityCache();
    
    res.json({
      success: true,
      results,
      message: 'Cities initialized successfully'
    });
  } catch (error) {
    console.error('Error initializing cities:', error);
    res.status(500).json({
      error: 'Failed to initialize cities',
      code: 'CITIES_INIT_ERROR',
      details: error.message
    });
  }
});

// Get city-specific statistics
router.get('/:slug/stats', requireAdmin, async (req, res) => {
  try {
    const { slug } = req.params;
    const city = await CityService.getCityBySlug(slug);
    
    if (!city) {
      return res.status(404).json({
        error: 'City not found',
        code: 'CITY_NOT_FOUND'
      });
    }
    
    // Get city-specific stats
    const featuredRestaurant = await CityService.getFeaturedRestaurant(city.id);
    const queue = await CityService.getCityQueue(city.id, 10);
    
    res.json({
      success: true,
      stats: {
        city: {
          name: city.name,
          displayName: city.displayName,
          isActive: city.isActive
        },
        restaurants: city._count.restaurants,
        users: city._count.users,
        featuredRestaurant: featuredRestaurant ? {
          name: featuredRestaurant.name,
          rating: featuredRestaurant.rating,
          categories: featuredRestaurant.categories
        } : null,
        queueSize: queue.length
      }
    });
  } catch (error) {
    console.error('Error fetching city stats:', error);
    res.status(500).json({
      error: 'Failed to fetch city statistics',
      code: 'CITY_STATS_ERROR'
    });
  }
});

// Clear city cache (admin utility)
router.post('/cache/clear', requireAdmin, async (req, res) => {
  try {
    const { citySlug } = req.body;
    clearCityCache(citySlug);
    
    res.json({
      success: true,
      message: citySlug ? `Cache cleared for ${citySlug}` : 'All city cache cleared'
    });
  } catch (error) {
    console.error('Error clearing cache:', error);
    res.status(500).json({
      error: 'Failed to clear cache',
      code: 'CACHE_CLEAR_ERROR'
    });
  }
});

module.exports = router;
