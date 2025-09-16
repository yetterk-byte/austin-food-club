const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const yelpService = require('../services/yelpService');
const restaurantSync = require('../services/restaurantSync');
const featuredRestaurant = require('../services/featuredRestaurant');
const { verifySupabaseToken, requireAuth } = require('../middleware/auth');

const prisma = new PrismaClient();

// GET /api/v1/restaurants - Get all restaurants with pagination
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 20, search, cuisine, price, rating } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const where = {};
    if (search) where.name = { contains: search, mode: 'insensitive' };
    if (cuisine) where.categories = { has: cuisine };
    if (price) where.priceRange = price;
    if (rating) where.rating = { gte: parseFloat(rating) };
    
    const [restaurants, total] = await Promise.all([
      prisma.restaurant.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { rating: 'desc' }
      }),
      prisma.restaurant.count({ where })
    ]);
    
    res.json(res.apiResponse.success({
      restaurants,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    }, 'Restaurants retrieved successfully'));
  } catch (error) {
    console.error('Error fetching restaurants:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch restaurants', 500));
  }
});

// GET /api/v1/restaurants/featured - Get current featured restaurant
router.get('/featured', async (req, res) => {
  try {
    const featured = await featuredRestaurant.getCurrentFeatured();
    
    if (!featured) {
      return res.status(404).json(res.apiResponse.error(
        'No featured restaurant found',
        404,
        { code: 'NO_FEATURED_RESTAURANT' }
      ));
    }
    
    res.json(res.apiResponse.success(featured, 'Featured restaurant retrieved successfully'));
  } catch (error) {
    console.error('Error fetching featured restaurant:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch featured restaurant', 500));
  }
});

// GET /api/v1/restaurants/search - Search restaurants
router.get('/search', async (req, res) => {
  try {
    const { location, cuisine, price, limit = 20, sort_by = 'rating' } = req.query;
    
    if (!location) {
      return res.status(400).json(res.apiResponse.error(
        'Location parameter is required',
        400,
        { code: 'MISSING_LOCATION' }
      ));
    }
    
    const results = await yelpService.searchRestaurants(location, cuisine, price, parseInt(limit), sort_by);
    
    res.json(res.apiResponse.success(results, 'Restaurant search completed successfully'));
  } catch (error) {
    console.error('Error searching restaurants:', error);
    res.status(500).json(res.apiResponse.error('Failed to search restaurants', 500));
  }
});

// GET /api/v1/restaurants/:id - Get restaurant by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const restaurant = await prisma.restaurant.findUnique({
      where: { id }
    });
    
    if (!restaurant) {
      return res.status(404).json(res.apiResponse.error(
        'Restaurant not found',
        404,
        { code: 'RESTAURANT_NOT_FOUND' }
      ));
    }
    
    res.json(res.apiResponse.success(restaurant, 'Restaurant retrieved successfully'));
  } catch (error) {
    console.error('Error fetching restaurant:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch restaurant', 500));
  }
});

// GET /api/v1/restaurants/yelp/:id - Get Yelp restaurant details
router.get('/yelp/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const details = await yelpService.getRestaurantDetails(id);
    
    res.json(res.apiResponse.success(details, 'Yelp restaurant details retrieved successfully'));
  } catch (error) {
    console.error('Error fetching Yelp restaurant details:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch Yelp restaurant details', 500));
  }
});

// GET /api/v1/restaurants/yelp/:id/reviews - Get Yelp restaurant reviews
router.get('/yelp/:id/reviews', async (req, res) => {
  try {
    const { id } = req.params;
    
    const reviews = await yelpService.getRestaurantReviews(id);
    
    res.json(res.apiResponse.success(reviews, 'Yelp restaurant reviews retrieved successfully'));
  } catch (error) {
    console.error('Error fetching Yelp restaurant reviews:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch Yelp restaurant reviews', 500));
  }
});

// POST /api/v1/restaurants/sync - Sync restaurant with Yelp
router.post('/sync', async (req, res) => {
  try {
    const { yelpId } = req.body;
    
    if (!yelpId) {
      return res.status(400).json(res.apiResponse.error(
        'Yelp ID is required',
        400,
        { code: 'MISSING_YELP_ID' }
      ));
    }
    
    const result = await restaurantSync.syncRestaurant(yelpId);
    
    res.json(res.apiResponse.success(result, 'Restaurant synced successfully'));
  } catch (error) {
    console.error('Error syncing restaurant:', error);
    res.status(500).json(res.apiResponse.error('Failed to sync restaurant', 500));
  }
});

// Austin-specific endpoints
router.get('/austin/bbq', async (req, res) => {
  try {
    const results = await yelpService.searchRestaurants('Austin, TX', 'bbq', null, 20);
    res.json(res.apiResponse.success(results, 'Austin BBQ restaurants retrieved successfully'));
  } catch (error) {
    console.error('Error fetching Austin BBQ restaurants:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch Austin BBQ restaurants', 500));
  }
});

router.get('/austin/tex-mex', async (req, res) => {
  try {
    const results = await yelpService.searchRestaurants('Austin, TX', 'mexican', null, 20);
    res.json(res.apiResponse.success(results, 'Austin Tex-Mex restaurants retrieved successfully'));
  } catch (error) {
    console.error('Error fetching Austin Tex-Mex restaurants:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch Austin Tex-Mex restaurants', 500));
  }
});

router.get('/austin/food-trucks', async (req, res) => {
  try {
    const results = await yelpService.searchRestaurants('Austin, TX', 'foodtrucks', null, 20);
    res.json(res.apiResponse.success(results, 'Austin food trucks retrieved successfully'));
  } catch (error) {
    console.error('Error fetching Austin food trucks:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch Austin food trucks', 500));
  }
});

module.exports = router;
