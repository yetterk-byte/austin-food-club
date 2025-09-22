require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const { verifySupabaseToken, requireAuth, optionalAuth } = require('./middleware/auth');
const twilioService = require('./services/twilioService');
const yelpService = require('./services/yelpService');
const restaurantSync = require('./services/restaurantSync');
const featuredRestaurant = require('./services/featuredRestaurant');
const fallbackService = require('./services/fallbackService');
const { 
  cacheRestaurantDetails, 
  cacheSearchResults, 
  cacheReviews,
  clearCacheByPattern,
  clearAllCaches,
  getCacheStats,
  warmUpCache
} = require('./middleware/cache');
const { 
  rateLimitMiddleware, 
  getRateLimitStatus, 
  resetRateLimits,
  startQueueProcessor
} = require('./utils/rateLimiter');
const cronService = require('./services/cronService');
const rotationJobManager = require('./jobs/rotationJob');
const notificationJobs = require('./jobs/notificationJobs');

// Import API router
const apiRouter = require('./routes/apiRouter');
const simpleRestaurantRoutes = require('./routes/simpleRestaurantRoutes');
const adminRoutes = require('./routes/admin.routes'); // Admin routes
const rotationRoutes = require('./routes/rotation.routes'); // Rotation routes
const cityRoutes = require('./routes/city.routes'); // City routes for multi-city support
const notificationRoutes = require('./routes/notification.routes'); // Push notification routes

const app = express();
const PORT = 3001;
const prisma = new PrismaClient();

// Database storage via Prisma (in-memory storage removed)

// Middleware
// CORS configuration for Flutter web (dynamic ports)
app.use(cors({
  origin: [
    'http://localhost:51070',  // Current Flutter port
    'http://localhost:8080',   // Standard Flutter web port
    'http://localhost:8081',   // Alternative Flutter ports
    'http://localhost:8082',
    'http://localhost:3000',   // React dev server
    /^http:\/\/localhost:\d+$/ // Allow any localhost port
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  optionsSuccessStatus: 200
}));
app.use(express.json());

// API versioning - Mount v1 API routes
app.use('/api/v1', apiRouter);

// Simple restaurant routes (working version)
app.use('/api/restaurants', simpleRestaurantRoutes);

// Admin routes (protected)
app.use('/api/admin', adminRoutes);

// Rotation routes (protected)
app.use('/api/rotation', rotationRoutes);

// City routes (multi-city support)
app.use('/api/cities', cityRoutes);

// Notification routes (push notifications)
app.use('/api/notifications', notificationRoutes);

// Test endpoint
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Server is running!', 
    timestamp: new Date().toISOString() 
  });
});

// Admin login endpoint (demo - replace with proper auth)
app.post('/api/auth/admin-login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Demo credentials - replace with proper auth
    if (email === 'admin@austinfoodclub.com' && password === 'admin123') {
      // Generate a demo token (in production, use proper JWT)
      const token = 'demo-admin-token-' + Date.now();
      
      res.json({
        token,
        user: {
          id: 'admin-user',
          email: 'admin@austinfoodclub.com',
          name: 'Austin Food Club Admin',
          isAdmin: true
        }
      });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Test user endpoint (requires auth)
app.get('/api/test/user', verifySupabaseToken, requireAuth, (req, res) => {
  res.json({ 
    message: 'User data retrieved successfully',
    user: {
      id: req.user.id,
      supabaseId: req.user.supabaseId,
      email: req.user.email,
      phone: req.user.phone,
      name: req.user.name,
      avatar: req.user.avatar,
      provider: req.user.provider,
      emailVerified: req.user.emailVerified,
      lastLogin: req.user.lastLogin,
      createdAt: req.user.createdAt
    }
  });
});

// Test SMS endpoint
app.post('/api/test/sms', async (req, res) => {
  try {
    const { phone, message } = req.body;
    
    // Validate required fields
    if (!phone || !message) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: phone and message are required'
      });
    }
    
    // Send SMS
    const result = await twilioService.sendSMS(phone, message);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'SMS sent successfully',
        sid: result.sid,
        phone: phone
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('Error in test SMS endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Test OTP endpoint
app.post('/api/test/otp', async (req, res) => {
  try {
    const { phone } = req.body;
    
    if (!phone) {
      return res.status(400).json({
        success: false,
        error: 'Missing required field: phone'
      });
    }
    
    const result = await twilioService.sendOTP(phone);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'OTP sent successfully',
        phone: phone,
        // Note: In production, don't return the actual OTP code
        otpCode: result.otpCode // Only for testing
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('Error in test OTP endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Current restaurant endpoint - fetch from database
app.get('/api/restaurants/current', async (req, res) => {
  try {
    // Get the current week's featured restaurant
    const currentWeek = new Date();
    currentWeek.setDate(currentWeek.getDate() - currentWeek.getDay()); // Start of week
    
    let restaurant = await prisma.restaurant.findFirst({
      where: {
        weekOf: {
          gte: currentWeek
        }
      },
      orderBy: {
        weekOf: 'desc'
      }
    });

    // If no restaurant found for current week, create Franklin Barbecue as default
    if (!restaurant) {
      restaurant = await prisma.restaurant.create({
        data: {
          name: 'Franklin Barbecue',
          cuisine: 'Barbecue',
          price: '$$',
          area: 'East Austin',
          description: 'Legendary Austin barbecue joint known for its brisket and long lines. Often sells out by early afternoon.',
          address: '900 E 11th St, Austin, TX 78702',
          imageUrl: null,
          coordinates: { latitude: 30.2701, longitude: -97.7312 },
          weekOf: currentWeek
        }
      });
    }

    // Format response to match frontend expectations
    const response = {
      id: restaurant.id,
      name: restaurant.name,
      address: restaurant.address,
      phone: '(512) 653-1187', // Static for now
      cuisine: restaurant.cuisine,
      rating: 4.5, // Static for now
      priceRange: restaurant.price,
      hours: {
        monday: 'Closed',
        tuesday: '11:00 AM - 3:00 PM',
        wednesday: '11:00 AM - 3:00 PM',
        thursday: '11:00 AM - 3:00 PM',
        friday: '11:00 AM - 3:00 PM',
        saturday: '11:00 AM - 3:00 PM',
        sunday: 'Closed'
      },
      description: restaurant.description,
      specialties: ['Brisket', 'Pork Ribs', 'Turkey', 'Sausage'], // Static for now
      waitTime: '2-4 hours (arrive early)', // Static for now
      coordinates: {
        latitude: 30.2672,
        longitude: -97.7431
      },
      website: 'https://franklinbarbecue.com',
      isFeatured: true,
      lastUpdated: restaurant.createdAt.toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching current restaurant:', error);
    res.status(500).json({ error: 'Failed to fetch restaurant data' });
  }
});

// All restaurants endpoint
app.get('/api/restaurants', async (req, res) => {
  try {
    const restaurants = await prisma.restaurant.findMany({
      orderBy: {
        weekOf: 'desc'
      }
    });

    // Format response to match frontend expectations
    const formattedRestaurants = restaurants.map(restaurant => ({
      id: restaurant.id,
      name: restaurant.name,
      address: restaurant.address,
      phone: '(512) 653-1187', // Static for now
      cuisine: restaurant.cuisine,
      rating: 4.5, // Static for now
      priceRange: restaurant.price,
      area: restaurant.area,
      description: restaurant.description,
      imageUrl: restaurant.imageUrl,
      specialties: ['Brisket', 'Pork Ribs', 'Turkey', 'Sausage'], // Static for now
      waitTime: '2-4 hours (arrive early)', // Static for now
      coordinates: {
        latitude: 30.2672,
        longitude: -97.7431
      },
      website: 'https://franklinbarbecue.com',
      isFeatured: false,
      lastUpdated: restaurant.createdAt.toISOString()
    }));

    res.json(formattedRestaurants);
  } catch (error) {
    console.error('Error fetching restaurants:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Yelp-powered restaurant endpoints
// GET /api/restaurants/featured - Get this week's featured restaurant (with Yelp fallback)
app.get('/api/restaurants/featured', async (req, res) => {
  try {
    // First try to get from our database
    const dbRestaurant = await prisma.restaurant.findFirst({
      where: { isFeatured: true },
      orderBy: { createdAt: 'desc' }
    });

    console.log('Database restaurant found:', dbRestaurant ? dbRestaurant.name : 'None');
    console.log('Database restaurant isFeatured:', dbRestaurant ? dbRestaurant.isFeatured : 'N/A');

    if (dbRestaurant) {
      return res.json({
        success: true,
        source: 'database',
        restaurant: {
          id: dbRestaurant.id,
          name: dbRestaurant.name,
          address: dbRestaurant.address,
          phone: dbRestaurant.phone,
          cuisine: dbRestaurant.cuisine,
          rating: dbRestaurant.rating || 4.5,
          priceRange: dbRestaurant.price || '$$',
          hours: dbRestaurant.hours || {},
          description: dbRestaurant.description,
          specialties: dbRestaurant.specialties || ['Brisket', 'Pork Ribs', 'Turkey', 'Sausage'],
          waitTime: dbRestaurant.waitTime || '2-4 hours (arrive early)',
          coordinates: dbRestaurant.coordinates || { latitude: 30.2701, longitude: -97.7312 },
          website: dbRestaurant.website || 'https://franklinbarbecue.com',
          imageUrl: dbRestaurant.imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
          photos: dbRestaurant.photos || [
            'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Food photo
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Restaurant interior
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Dining room atmosphere
            'https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80'  // Restaurant exterior
          ],
          categories: dbRestaurant.categories || [dbRestaurant.cuisine],
          reviewCount: dbRestaurant.reviewCount || 0,
          isFeatured: true,
          lastUpdated: dbRestaurant.createdAt.toISOString()
        }
      });
    }

    // Fallback to Yelp if no database restaurant
    if (yelpService.isConfigured()) {
      const featured = await yelpService.getFeaturedRestaurants(1);
      if (featured.businesses.length > 0) {
        const yelpRestaurant = featured.businesses[0];
        const formattedRestaurant = yelpService.formatRestaurantForApp(yelpRestaurant);
        
        return res.json({
          success: true,
          source: 'yelp',
          restaurant: {
            ...formattedRestaurant,
            isFeatured: true,
            lastUpdated: new Date().toISOString()
          }
        });
      }
    }

    // Final fallback - return a real restaurant from database
    const fallbackRestaurant = await prisma.restaurant.findFirst({
      orderBy: { createdAt: 'desc' }
    });

    if (fallbackRestaurant) {
      return res.json({
        success: true,
        source: 'fallback',
        restaurant: {
          id: fallbackRestaurant.id,
          name: fallbackRestaurant.name,
          address: fallbackRestaurant.address,
          phone: fallbackRestaurant.phone,
          cuisine: fallbackRestaurant.cuisine,
          rating: fallbackRestaurant.rating || 4.5,
          priceRange: fallbackRestaurant.price || '$$',
          hours: fallbackRestaurant.hours || {
            monday: 'Closed',
            tuesday: '11:00 AM - 3:00 PM',
            wednesday: '11:00 AM - 3:00 PM',
            thursday: '11:00 AM - 3:00 PM',
            friday: '11:00 AM - 3:00 PM',
            saturday: '11:00 AM - 3:00 PM',
            sunday: 'Closed'
          },
          description: fallbackRestaurant.description || 'A great restaurant in Austin',
          specialties: fallbackRestaurant.specialties || ['Great Food'],
          waitTime: fallbackRestaurant.waitTime || '1-2 hours',
          coordinates: fallbackRestaurant.coordinates || { latitude: 30.2701, longitude: -97.7312 },
          website: fallbackRestaurant.website || 'https://example.com',
          imageUrl: fallbackRestaurant.imageUrl || 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
          photos: fallbackRestaurant.photos || ['https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop'],
          categories: fallbackRestaurant.categories || [fallbackRestaurant.cuisine],
          reviewCount: fallbackRestaurant.reviewCount || 0,
          isFeatured: true,
          lastUpdated: new Date().toISOString()
        }
      });
    }

    // Ultimate fallback if no restaurants in database
    console.log('Using ultimate fallback - Franklin Barbecue');
    res.json({
      success: true,
      source: 'fallback',
      restaurant: {
        id: 'franklin-barbecue',
        name: 'Franklin Barbecue',
        address: '900 E 11th St, Austin, TX 78702',
        phone: '(512) 653-1187',
        cuisine: 'Barbecue',
        rating: 4.5,
        priceRange: '$$',
        hours: {
          monday: 'Closed',
          tuesday: '11:00 AM - 3:00 PM',
          wednesday: '11:00 AM - 3:00 PM',
          thursday: '11:00 AM - 3:00 PM',
          friday: '11:00 AM - 3:00 PM',
          saturday: '11:00 AM - 3:00 PM',
          sunday: 'Closed'
        },
        description: 'Legendary Austin barbecue joint known for its brisket and long lines. Often sells out by early afternoon.',
        specialties: ['Brisket', 'Pork Ribs', 'Turkey', 'Sausage'],
        waitTime: '2-4 hours (arrive early)',
        coordinates: { latitude: 30.2701, longitude: -97.7312 },
        website: 'https://franklinbarbecue.com',
        imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
        photos: [
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Food photo
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Restaurant interior
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Dining room atmosphere
          'https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80'  // Restaurant exterior
        ],
        categories: ['Barbecue', 'BBQ'],
        reviewCount: 1250,
        isFeatured: true,
        lastUpdated: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Error getting featured restaurant:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get featured restaurant',
      message: error.message
    });
  }
});

// GET /api/restaurants/search - Search Austin restaurants via Yelp
app.get('/api/restaurants/search', 
  rateLimitMiddleware('yelp'),
  cacheSearchResults,
  async (req, res) => {
  try {
    const { 
      location = 'Austin, TX', 
      cuisine, 
      price, 
      limit = 20,
      sortBy = 'rating'
    } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching restaurants:', { location, cuisine, price, limit });

    const results = await yelpService.searchRestaurants(location, cuisine, price, parseInt(limit));
    
    // Format results for our app
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      region: results.region,
      searchParams: {
        location,
        cuisine,
        price,
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error searching restaurants:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search restaurants',
      message: error.message
    });
  }
});

// GET /api/restaurants/yelp/:id - Get restaurant details from Yelp
app.get('/api/restaurants/yelp/:id', 
  rateLimitMiddleware('yelp'),
  cacheRestaurantDetails,
  async (req, res) => {
  try {
    const { id } = req.params;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Getting restaurant details for:', id);

    const details = await yelpService.getRestaurantDetails(id);
    const formattedRestaurant = yelpService.formatRestaurantForApp(details);

    res.json({
      success: true,
      restaurant: formattedRestaurant
    });
  } catch (error) {
    console.error('Error getting restaurant details:', error);
    
    if (error.message.includes('not found') || error.message.includes('404')) {
      return res.status(404).json({
        success: false,
        error: 'Restaurant not found',
        message: 'The requested restaurant could not be found'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to get restaurant details',
      message: error.message
    });
  }
});

// GET /api/restaurants/yelp/:id/reviews - Get restaurant reviews from Yelp
app.get('/api/restaurants/yelp/:id/reviews', 
  rateLimitMiddleware('yelp'),
  cacheReviews,
  async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 3 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Getting reviews for restaurant:', id);

    const reviews = await yelpService.getRestaurantReviews(id, parseInt(limit));

    res.json({
      success: true,
      reviews: reviews.reviews,
      total: reviews.total,
      restaurantId: id
    });
  } catch (error) {
    console.error('Error getting restaurant reviews:', error);
    
    if (error.message.includes('not found') || error.message.includes('404')) {
      return res.status(404).json({
        success: false,
        error: 'Restaurant not found',
        message: 'The requested restaurant could not be found'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to get restaurant reviews',
      message: error.message
    });
  }
});

// GET /api/restaurants/cuisine/:cuisine - Search by cuisine type
app.get('/api/restaurants/cuisine/:cuisine', async (req, res) => {
  try {
    const { cuisine } = req.params;
    const { location = 'Austin, TX', limit = 20 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching by cuisine:', cuisine);

    const results = await yelpService.searchByCuisine(cuisine, location, parseInt(limit));
    
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      cuisine,
      location
    });
  } catch (error) {
    console.error('Error searching by cuisine:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search by cuisine',
      message: error.message
    });
  }
});

// GET /api/restaurants/price/:priceRange - Search by price range
app.get('/api/restaurants/price/:priceRange', async (req, res) => {
  try {
    const { priceRange } = req.params;
    const { location = 'Austin, TX', limit = 20 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching by price range:', priceRange);

    const results = await yelpService.searchByPrice(priceRange, location, parseInt(limit));
    
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      priceRange,
      location
    });
  } catch (error) {
    console.error('Error searching by price range:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search by price range',
      message: error.message
    });
  }
});

// GET /api/restaurants/cache/stats - Get cache statistics (admin endpoint)
app.get('/api/restaurants/cache/stats', (req, res) => {
  try {
    const stats = yelpService.getCacheStats();
    res.json({
      success: true,
      cache: stats
    });
  } catch (error) {
    console.error('Error getting cache stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get cache statistics',
      message: error.message
    });
  }
});

// DELETE /api/restaurants/cache - Clear cache (admin endpoint)
app.delete('/api/restaurants/cache', (req, res) => {
  try {
    yelpService.clearCache();
    res.json({
      success: true,
      message: 'Cache cleared successfully'
    });
  } catch (error) {
    console.error('Error clearing cache:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear cache',
      message: error.message
    });
  }
});

// Austin-specific restaurant endpoints

// GET /api/restaurants/austin/bbq - Search BBQ restaurants (Austin specialty)
app.get('/api/restaurants/austin/bbq', async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching Austin BBQ restaurants');

    const results = await yelpService.searchBBQ(parseInt(limit));
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      category: 'BBQ',
      location: 'Austin, TX',
      specialty: 'Austin BBQ Scene'
    });
  } catch (error) {
    console.error('Error searching Austin BBQ:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search BBQ restaurants',
      message: error.message
    });
  }
});

// GET /api/restaurants/austin/tex-mex - Search Tex-Mex restaurants
app.get('/api/restaurants/austin/tex-mex', async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching Austin Tex-Mex restaurants');

    const results = await yelpService.searchTexMex(parseInt(limit));
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      category: 'Tex-Mex',
      location: 'Austin, TX',
      specialty: 'Austin Tex-Mex Scene'
    });
  } catch (error) {
    console.error('Error searching Austin Tex-Mex:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search Tex-Mex restaurants',
      message: error.message
    });
  }
});

// GET /api/restaurants/austin/food-trucks - Search food trucks
app.get('/api/restaurants/austin/food-trucks', async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching Austin food trucks');

    const results = await yelpService.searchFoodTrucks(parseInt(limit));
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      category: 'Food Trucks',
      location: 'Austin, TX',
      specialty: 'Austin Food Truck Scene'
    });
  } catch (error) {
    console.error('Error searching Austin food trucks:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search food trucks',
      message: error.message
    });
  }
});

// GET /api/restaurants/austin/downtown - Search downtown restaurants
app.get('/api/restaurants/austin/downtown', async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching downtown Austin restaurants');

    const results = await yelpService.searchDowntown(parseInt(limit));
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      area: 'Downtown',
      location: 'Downtown Austin, TX'
    });
  } catch (error) {
    console.error('Error searching downtown Austin:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search downtown restaurants',
      message: error.message
    });
  }
});

// GET /api/restaurants/austin/highly-rated - Search highly-rated restaurants
app.get('/api/restaurants/austin/highly-rated', async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Searching highly-rated Austin restaurants');

    const results = await yelpService.searchHighlyRated(parseInt(limit));
    const formattedRestaurants = results.businesses.map(restaurant => 
      yelpService.formatRestaurantForApp(restaurant)
    );

    res.json({
      success: true,
      restaurants: formattedRestaurants,
      total: results.total,
      criteria: 'Highly-rated (4.5+ stars)',
      location: 'Austin, TX'
    });
  } catch (error) {
    console.error('Error searching highly-rated restaurants:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search highly-rated restaurants',
      message: error.message
    });
  }
});

// GET /api/restaurants/austin/stats - Get Austin food scene statistics
app.get('/api/restaurants/austin/stats', async (req, res) => {
  try {
    if (!yelpService.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Yelp API not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Getting Austin food scene statistics');

    const stats = await yelpService.getAustinFoodStats();

    res.json({
      success: true,
      stats: stats
    });
  } catch (error) {
    console.error('Error getting Austin food stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get Austin food statistics',
      message: error.message
    });
  }
});

// Restaurant sync endpoints

// POST /api/restaurants/sync - Sync a restaurant by Yelp ID
app.post('/api/restaurants/sync', async (req, res) => {
  try {
    const { yelpId } = req.body;

    if (!yelpId) {
      return res.status(400).json({
        success: false,
        error: 'Yelp ID is required'
      });
    }

    if (!restaurantSync.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Restaurant sync not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log(`Syncing restaurant with Yelp ID: ${yelpId}`);

    const restaurant = await restaurantSync.syncRestaurant(yelpId);

    res.json({
      success: true,
      restaurant: restaurant,
      message: 'Restaurant synced successfully'
    });
  } catch (error) {
    console.error('Error syncing restaurant:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync restaurant',
      message: error.message
    });
  }
});

// POST /api/restaurants/sync/featured - Sync featured restaurants
app.post('/api/restaurants/sync/featured', async (req, res) => {
  try {
    const { limit = 5 } = req.body;

    if (!restaurantSync.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Restaurant sync not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Syncing featured restaurants...');

    const results = await restaurantSync.syncFeaturedRestaurants(limit);

    res.json({
      success: true,
      results: results,
      message: `Synced ${results.successful.length} featured restaurants`
    });
  } catch (error) {
    console.error('Error syncing featured restaurants:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync featured restaurants',
      message: error.message
    });
  }
});

// POST /api/restaurants/sync/category - Sync restaurants by category
app.post('/api/restaurants/sync/category', async (req, res) => {
  try {
    const { category, limit = 10 } = req.body;

    if (!category) {
      return res.status(400).json({
        success: false,
        error: 'Category is required'
      });
    }

    if (!restaurantSync.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Restaurant sync not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log(`Syncing ${category} restaurants...`);

    const results = await restaurantSync.syncRestaurantsByCategory(category, limit);

    res.json({
      success: true,
      results: results,
      message: `Synced ${results.successful.length} ${category} restaurants`
    });
  } catch (error) {
    console.error(`Error syncing ${req.body.category} restaurants:`, error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync restaurants by category',
      message: error.message
    });
  }
});

// POST /api/restaurants/sync/stale - Sync stale restaurants
app.post('/api/restaurants/sync/stale', async (req, res) => {
  try {
    if (!restaurantSync.isConfigured()) {
      return res.status(503).json({
        success: false,
        error: 'Restaurant sync not configured',
        message: 'Please set YELP_API_KEY in environment variables'
      });
    }

    console.log('Syncing stale restaurants...');

    const results = await restaurantSync.syncStaleRestaurants();

    res.json({
      success: true,
      results: results,
      message: results.message
    });
  } catch (error) {
    console.error('Error syncing stale restaurants:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync stale restaurants',
      message: error.message
    });
  }
});

// GET /api/restaurants/sync/stats - Get restaurant sync statistics
app.get('/api/restaurants/sync/stats', async (req, res) => {
  try {
    const stats = await restaurantSync.getRestaurantStats();

    res.json({
      success: true,
      stats: stats
    });
  } catch (error) {
    console.error('Error getting restaurant sync stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get restaurant sync statistics',
      message: error.message
    });
  }
});

// GET /api/restaurants/sync/cache - Get sync cache statistics
app.get('/api/restaurants/sync/cache', (req, res) => {
  try {
    const stats = restaurantSync.getCacheStats();

    res.json({
      success: true,
      cache: stats
    });
  } catch (error) {
    console.error('Error getting sync cache stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get sync cache statistics',
      message: error.message
    });
  }
});

// DELETE /api/restaurants/sync/cache - Clear sync cache
app.delete('/api/restaurants/sync/cache', (req, res) => {
  try {
    restaurantSync.clearCache();

    res.json({
      success: true,
      message: 'Restaurant sync cache cleared successfully'
    });
  } catch (error) {
    console.error('Error clearing sync cache:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear sync cache',
      message: error.message
    });
  }
});

// Featured restaurant endpoints

// GET /api/restaurants/featured/current - Get current week's featured restaurant
app.get('/api/restaurants/featured/current', async (req, res) => {
  try {
    const featured = await featuredRestaurant.getCurrentFeatured();

    if (!featured) {
      return res.status(404).json({
        success: false,
        message: 'No featured restaurant for current week'
      });
    }

    res.json({
      success: true,
      featured: featured,
      message: 'Current featured restaurant retrieved successfully'
    });
  } catch (error) {
    console.error('Error getting current featured restaurant:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get current featured restaurant',
      message: error.message
    });
  }
});

// GET /api/restaurants/featured/history - Get featured restaurant history
app.get('/api/restaurants/featured/history', async (req, res) => {
  try {
    const { limit = 12 } = req.query;
    const history = await featuredRestaurant.getFeaturedHistory(parseInt(limit));

    res.json({
      success: true,
      history: history,
      count: history.length,
      message: 'Featured restaurant history retrieved successfully'
    });
  } catch (error) {
    console.error('Error getting featured restaurant history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get featured restaurant history',
      message: error.message
    });
  }
});

// GET /api/restaurants/featured/stats - Get featured restaurant statistics
app.get('/api/restaurants/featured/stats', async (req, res) => {
  try {
    const stats = await featuredRestaurant.getFeaturedStats();

    res.json({
      success: true,
      stats: stats,
      message: 'Featured restaurant statistics retrieved successfully'
    });
  } catch (error) {
    console.error('Error getting featured restaurant stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get featured restaurant statistics',
      message: error.message
    });
  }
});

// POST /api/restaurants/featured/select - Manually select featured restaurant
app.post('/api/restaurants/featured/select', async (req, res) => {
  try {
    const { 
      weekStartDate, 
      customRestaurantId, 
      customDescription,
      forceNew = false 
    } = req.body;

    if (!weekStartDate) {
      return res.status(400).json({
        success: false,
        error: 'Week start date is required'
      });
    }

    const weekStart = new Date(weekStartDate);
    const featured = await featuredRestaurant.selectFeaturedRestaurant(weekStart, {
      customRestaurantId,
      customDescription,
      forceNew
    });

    res.json({
      success: true,
      featured: featured,
      message: 'Featured restaurant selected successfully'
    });
  } catch (error) {
    console.error('Error selecting featured restaurant:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to select featured restaurant',
      message: error.message
    });
  }
});

// POST /api/restaurants/featured/set-custom - Set custom featured restaurant
app.post('/api/restaurants/featured/set-custom', async (req, res) => {
  try {
    const { 
      restaurantId, 
      weekStartDate, 
      customDescription 
    } = req.body;

    if (!restaurantId || !weekStartDate) {
      return res.status(400).json({
        success: false,
        error: 'Restaurant ID and week start date are required'
      });
    }

    const weekStart = new Date(weekStartDate);
    const featured = await featuredRestaurant.setCustomFeatured(
      restaurantId, 
      weekStart, 
      customDescription
    );

    res.json({
      success: true,
      featured: featured,
      message: 'Custom featured restaurant set successfully'
    });
  } catch (error) {
    console.error('Error setting custom featured restaurant:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to set custom featured restaurant',
      message: error.message
    });
  }
});

// POST /api/restaurants/featured/archive - Archive old featured restaurants
app.post('/api/restaurants/featured/archive', async (req, res) => {
  try {
    const { monthsToKeep = 6 } = req.body;
    const archivedCount = await featuredRestaurant.archiveOldFeatured(monthsToKeep);

    res.json({
      success: true,
      archivedCount: archivedCount,
      message: `Archived ${archivedCount} old featured restaurants`
    });
  } catch (error) {
    console.error('Error archiving featured restaurants:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to archive featured restaurants',
      message: error.message
    });
  }
});

// POST /api/restaurants/featured/rotate - Trigger weekly rotation manually
app.post('/api/restaurants/featured/rotate', async (req, res) => {
  try {
    console.log('🔄 Manual weekly rotation triggered');
    
    // Import and run the rotation script
    const WeeklyRotationScript = require('./scripts/weeklyRotation');
    const script = new WeeklyRotationScript();
    const result = await script.run();

    res.json({
      success: result.success,
      result: result,
      message: result.success ? 'Weekly rotation completed' : 'Weekly rotation failed'
    });
  } catch (error) {
    console.error('Error running weekly rotation:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to run weekly rotation',
      message: error.message
    });
  }
});

// POST /api/restaurants/test-photos - Add test photos to a restaurant for demo
app.post('/api/restaurants/test-photos', async (req, res) => {
  try {
    const { restaurantId } = req.body;
    
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        error: 'Restaurant ID is required'
      });
    }

        const testPhotos = [
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Taqueria interior atmosphere
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Mexican restaurant dining room
          'https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80', // Restaurant exterior facade
          'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80'  // Food photo (lowest priority)
        ];

    const updatedRestaurant = await prisma.restaurant.update({
      where: { id: restaurantId },
      data: { 
        photos: testPhotos,
        imageUrl: testPhotos[1] // Use the interior photo as the main image
      }
    });

    res.json({
      success: true,
      restaurant: updatedRestaurant,
      message: 'Test photos added successfully'
    });
  } catch (error) {
    console.error('Error adding test photos:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add test photos',
      message: error.message
    });
  }
});

// RSVP endpoints
app.post('/api/rsvp', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { day, status, restaurantId } = req.body;
    const userId = req.user.id; // Get userId from authenticated user
    
    // Validate required fields
    if (!day || !status) {
      return res.status(400).json({ 
        error: 'Missing required fields: day and status are required' 
      });
    }
    
    // Validate status values
    const validStatuses = ['going', 'maybe', 'not_going'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        error: 'Invalid status. Must be one of: going, maybe, not_going' 
      });
    }

    // Get current restaurant ID if not provided
    let currentRestaurantId = restaurantId;
    if (!currentRestaurantId) {
      // Get the most recent restaurant (current week's featured restaurant)
      const currentRestaurant = await prisma.restaurant.findFirst({
        orderBy: {
          weekOf: 'desc'
        }
      });
      
      if (!currentRestaurant) {
        return res.status(404).json({ error: 'No current restaurant found' });
      }
      
      currentRestaurantId = currentRestaurant.id;
    }
    
    // Use a transaction to ensure only one RSVP per user per restaurant
    const rsvp = await prisma.$transaction(async (tx) => {
      // Delete any existing RSVPs for this user-restaurant pair
      await tx.rSVP.deleteMany({
      where: {
          userId,
          restaurantId: currentRestaurantId
        }
      });

      // Create new RSVP
      return await tx.rSVP.create({
        data: {
        userId,
        restaurantId: currentRestaurantId,
        day,
        status
      }
      });
    });
    
    res.status(201).json({ 
      message: 'RSVP saved successfully',
      rsvp: { 
        id: rsvp.id,
        userId: rsvp.userId, 
        restaurantId: rsvp.restaurantId,
        day: rsvp.day, 
        status: rsvp.status,
        createdAt: rsvp.createdAt
      }
    });
  } catch (error) {
    console.error('Error saving RSVP:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/rsvp', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const userId = req.user.id; // Get userId from authenticated user
    
    // Get all RSVPs for this user with restaurant details
    const userRsvps = await prisma.rSVP.findMany({
      where: {
        userId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });
    
    res.json({ 
      userId,
      rsvps: userRsvps.map(rsvp => ({
        id: rsvp.id,
        userId: rsvp.userId,
        restaurantId: rsvp.restaurantId,
        day: rsvp.day,
        status: rsvp.status,
        createdAt: rsvp.createdAt,
        restaurant: rsvp.restaurant
      }))
    });
  } catch (error) {
    console.error('Error fetching RSVPs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/rsvp/counts - Get RSVP counts for each day for current restaurant
app.get('/api/rsvp/counts', async (req, res) => {
  try {
    const { restaurantId } = req.query;
    
    if (!restaurantId) {
      return res.status(400).json({ 
        success: false,
        error: 'Restaurant ID is required' 
      });
    }

    // Get RSVP counts for each day for this restaurant
    const rsvpCounts = await prisma.rSVP.groupBy({
      by: ['day'],
      where: {
        restaurantId: restaurantId,
        status: 'going' // Only count people who are going
      },
      _count: {
        id: true
      }
    });

    // Format the data for easier consumption
    const dayCounts = {};
    rsvpCounts.forEach(count => {
      dayCounts[count.day] = count._count.id;
    });

    res.json({
      success: true,
      restaurantId: restaurantId,
      dayCounts: dayCounts,
      totalGoing: Object.values(dayCounts).reduce((sum, count) => sum + count, 0)
    });
  } catch (error) {
    console.error('Error fetching RSVP counts:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// GET /api/verified-visits - Get user's verified visits
app.get('/api/verified-visits', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const verifiedVisits = await prisma.verifiedVisit.findMany({
      where: {
        userId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true
          }
        }
      },
      orderBy: {
        visitDate: 'desc'
      }
    });
    
    res.json({
      success: true,
      verifiedVisits: verifiedVisits.map(visit => ({
        id: visit.id,
        userId: visit.userId,
        restaurantId: visit.restaurantId,
        photoUrl: visit.photoUrl,
        rating: visit.rating,
        review: visit.review,
        visitDate: visit.visitDate,
        createdAt: visit.createdAt,
        restaurant: visit.restaurant
      }))
    });
  } catch (error) {
    console.error('Error fetching verified visits:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// POST /api/verified-visits - Submit a new verified visit
app.post('/api/verified-visits', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { restaurantId, photoUrl, rating, review, visitDate } = req.body;
    
    // Validation
    if (!restaurantId) {
      return res.status(400).json({
        success: false,
        error: 'Restaurant ID is required'
      });
    }
    
    if (!rating) {
      return res.status(400).json({
        success: false,
        error: 'Rating is required'
      });
    }
    
    const ratingNum = parseInt(rating);
    if (isNaN(ratingNum) || ratingNum < 1 || ratingNum > 5) {
      return res.status(400).json({
        success: false,
        error: 'Rating must be a number between 1 and 5'
      });
    }
    
    if (!photoUrl) {
      return res.status(400).json({
        success: false,
        error: 'Photo URL is required'
      });
    }
    
    // Validate visit date
    let parsedVisitDate;
    if (visitDate) {
      parsedVisitDate = new Date(visitDate);
      if (isNaN(parsedVisitDate.getTime())) {
        return res.status(400).json({
          success: false,
          error: 'Invalid visit date format'
        });
      }
    } else {
      parsedVisitDate = new Date();
    }
    
    // Check if restaurant exists
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId }
    });
    
    if (!restaurant) {
      return res.status(404).json({
        success: false,
        error: 'Restaurant not found'
      });
    }
    
    // Create the verified visit
    const verifiedVisit = await prisma.verifiedVisit.create({
      data: {
        userId,
        restaurantId,
        photoUrl,
        rating: ratingNum,
        review: review?.trim() || null,
        visitDate: parsedVisitDate
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true
          }
        }
      }
    });
    
    res.status(201).json({
      success: true,
      message: 'Verified visit created successfully',
      verifiedVisit: {
        id: verifiedVisit.id,
        userId: verifiedVisit.userId,
        restaurantId: verifiedVisit.restaurantId,
        photoUrl: verifiedVisit.photoUrl,
        rating: verifiedVisit.rating,
        review: verifiedVisit.review,
        visitDate: verifiedVisit.visitDate,
        createdAt: verifiedVisit.createdAt,
        restaurant: verifiedVisit.restaurant
      }
    });
  } catch (error) {
    console.error('Error creating verified visit:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// GET /api/verified-visits/:userId - Get verified visits for a specific user
app.get('/api/verified-visits/:userId', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const requestingUserId = req.user.id;
    
    // Users can only view their own verified visits
    if (userId !== requestingUserId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. You can only view your own verified visits.'
      });
    }
    
    const verifiedVisits = await prisma.verifiedVisit.findMany({
      where: {
        userId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true
          }
        }
      },
      orderBy: {
        visitDate: 'desc'
      }
    });
    
    res.json({
      success: true,
      userId,
      verifiedVisits: verifiedVisits.map(visit => ({
        id: visit.id,
        userId: visit.userId,
        restaurantId: visit.restaurantId,
        photoUrl: visit.photoUrl,
        rating: visit.rating,
        review: visit.review,
        visitDate: visit.visitDate,
        createdAt: visit.createdAt,
        restaurant: visit.restaurant
      }))
    });
  } catch (error) {
    console.error('Error fetching verified visits for user:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// DELETE /api/verified-visits/:visitId - Delete a verified visit
app.delete('/api/verified-visits/:visitId', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { visitId } = req.params;
    const userId = req.user.id;
    
    // First, check if the verified visit exists and belongs to the user
    const verifiedVisit = await prisma.verifiedVisit.findUnique({
      where: { id: visitId },
      select: { id: true, userId: true }
    });
    
    if (!verifiedVisit) {
      return res.status(404).json({
        success: false,
        error: 'Verified visit not found'
      });
    }
    
    if (verifiedVisit.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. You can only delete your own verified visits.'
      });
    }
    
    // Delete the verified visit
    await prisma.verifiedVisit.delete({
      where: { id: visitId }
    });
    
    res.json({
      success: true,
      message: 'Verified visit deleted successfully',
      deletedVisitId: visitId
    });
  } catch (error) {
    console.error('Error deleting verified visit:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error' 
    });
  }
});

// Wishlist endpoints
app.get('/api/wishlist', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const userId = req.user.id; // Get userId from authenticated user
    
    // Get user's wishlist from database
    const wishlist = await prisma.wishlist.findMany({
      where: {
        userId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true,
            price: true,
            specialNotes: true,
            address: true,
            imageUrl: true
          }
        }
      },
      orderBy: {
        addedAt: 'desc'
      }
    });
    
    res.json({ 
      userId,
      wishlist: wishlist.map(item => ({
        id: item.id,
        restaurant: item.restaurant,
        addedAt: item.addedAt
      }))
    });
  } catch (error) {
    console.error('Error fetching wishlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/wishlist', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { restaurantId } = req.body;
    const userId = req.user.id; // Get userId from authenticated user
    
    // Validate required fields
    if (!restaurantId) {
      return res.status(400).json({ 
        error: 'Missing required field: restaurantId is required' 
      });
    }
    
    // Check if restaurant exists
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId }
    });
    
    if (!restaurant) {
      return res.status(404).json({ 
        error: 'Restaurant not found' 
      });
    }
    
    // Check if restaurant already exists in user's wishlist
    const existingWishlistItem = await prisma.wishlist.findUnique({
      where: {
        userId_restaurantId: {
          userId,
          restaurantId
        }
      }
    });
    
    if (existingWishlistItem) {
      return res.status(409).json({ 
        error: 'Restaurant already exists in wishlist' 
      });
    }
    
    // Add restaurant to wishlist
    const wishlistItem = await prisma.wishlist.create({
      data: {
        userId,
        restaurantId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true,
            price: true,
            specialNotes: true,
            address: true,
            imageUrl: true
          }
        }
      }
    });
    
    res.status(201).json({ 
      message: 'Restaurant added to wishlist successfully',
      wishlistItem: {
        id: wishlistItem.id,
        restaurant: wishlistItem.restaurant,
        addedAt: wishlistItem.addedAt
      }
    });
  } catch (error) {
    console.error('Error adding to wishlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/wishlist/:restaurantId', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { restaurantId } = req.params;
    const userId = req.user.id; // Get userId from authenticated user
    
    if (!restaurantId) {
      return res.status(400).json({ 
        error: 'restaurantId is required' 
      });
    }
    
    // Find and delete wishlist item
    const wishlistItem = await prisma.wishlist.findUnique({
      where: {
        userId_restaurantId: {
          userId,
          restaurantId
        }
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            categories: true,
            city: true
          }
        }
      }
    });
    
    if (!wishlistItem) {
      return res.status(404).json({ 
        error: 'Restaurant not found in wishlist' 
      });
    }
    
    // Remove restaurant from wishlist
    await prisma.wishlist.delete({
      where: {
        userId_restaurantId: {
          userId,
          restaurantId
        }
      }
    });
    
    res.json({ 
      message: 'Restaurant removed from wishlist successfully',
      removedRestaurant: {
        id: wishlistItem.id,
        restaurant: wishlistItem.restaurant,
        addedAt: wishlistItem.addedAt
      }
    });
  } catch (error) {
    console.error('Error removing from wishlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(PORT, async () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Test endpoint: http://localhost:${PORT}/api/test`);
  
  // Initialize rotation system
  try {
    await rotationJobManager.initialize();
    console.log('🔄 Rotation system initialized');
  } catch (error) {
    console.error('❌ Failed to initialize rotation system:', error);
  }

  // Initialize notification jobs
  try {
    notificationJobs.initialize();
    console.log('📱 Notification system initialized');
  } catch (error) {
    console.error('❌ Failed to initialize notification system:', error);
  }
  console.log(`\nRestaurant endpoints:`);
  console.log(`  - Current: http://localhost:${PORT}/api/restaurants/current`);
  console.log(`  - Featured: http://localhost:${PORT}/api/restaurants/featured`);
  console.log(`  - Search: http://localhost:${PORT}/api/restaurants/search`);
  console.log(`  - Yelp Details: http://localhost:${PORT}/api/restaurants/yelp/:id`);
  console.log(`  - Yelp Reviews: http://localhost:${PORT}/api/restaurants/yelp/:id/reviews`);
  console.log(`  - By Cuisine: http://localhost:${PORT}/api/restaurants/cuisine/:cuisine`);
  console.log(`  - By Price: http://localhost:${PORT}/api/restaurants/price/:priceRange`);
  console.log(`\nAustin-specific endpoints:`);
  console.log(`  - BBQ: http://localhost:${PORT}/api/restaurants/austin/bbq`);
  console.log(`  - Tex-Mex: http://localhost:${PORT}/api/restaurants/austin/tex-mex`);
  console.log(`  - Food Trucks: http://localhost:${PORT}/api/restaurants/austin/food-trucks`);
  console.log(`  - Downtown: http://localhost:${PORT}/api/restaurants/austin/downtown`);
  console.log(`  - Highly-Rated: http://localhost:${PORT}/api/restaurants/austin/highly-rated`);
  console.log(`  - Stats: http://localhost:${PORT}/api/restaurants/austin/stats`);
  console.log(`\nRestaurant sync endpoints:`);
  console.log(`  - Sync Restaurant: POST http://localhost:${PORT}/api/restaurants/sync`);
  console.log(`  - Sync Featured: POST http://localhost:${PORT}/api/restaurants/sync/featured`);
  console.log(`  - Sync Category: POST http://localhost:${PORT}/api/restaurants/sync/category`);
  console.log(`  - Sync Stale: POST http://localhost:${PORT}/api/restaurants/sync/stale`);
  console.log(`  - Sync Stats: GET http://localhost:${PORT}/api/restaurants/sync/stats`);
  console.log(`  - Sync Cache: GET/DELETE http://localhost:${PORT}/api/restaurants/sync/cache`);
  console.log(`\nFeatured restaurant endpoints:`);
  console.log(`  - Current Featured: GET http://localhost:${PORT}/api/restaurants/featured/current`);
  console.log(`  - Featured History: GET http://localhost:${PORT}/api/restaurants/featured/history`);
  console.log(`  - Featured Stats: GET http://localhost:${PORT}/api/restaurants/featured/stats`);
  console.log(`  - Select Featured: POST http://localhost:${PORT}/api/restaurants/featured/select`);
  console.log(`  - Set Custom: POST http://localhost:${PORT}/api/restaurants/featured/set-custom`);
  console.log(`  - Archive Old: POST http://localhost:${PORT}/api/restaurants/featured/archive`);
  console.log(`  - Manual Rotation: POST http://localhost:${PORT}/api/restaurants/featured/rotate`);
  console.log(`\nProtected endpoints (AUTH REQUIRED):`);
  console.log(`  - RSVP: POST/GET http://localhost:${PORT}/api/rsvp`);
  console.log(`  - Wishlist: GET/POST/DELETE http://localhost:${PORT}/api/wishlist`);
  console.log(`\nInclude Authorization header: Bearer <supabase-jwt-token>`);
  console.log(`\nYelp API Status: ${yelpService.isConfigured() ? '✅ Configured' : '❌ Not configured (set YELP_API_KEY)'}`);
  console.log(`Restaurant Sync Status: ${restaurantSync.isConfigured() ? '✅ Configured' : '❌ Not configured'}`);
  console.log(`\nCache Management endpoints:`);
  console.log(`  - Cache Stats: GET http://localhost:${PORT}/api/cache/stats`);
  console.log(`  - Clear Cache: DELETE http://localhost:${PORT}/api/cache`);
  console.log(`  - Clear Pattern: DELETE http://localhost:${PORT}/api/cache/pattern/:pattern`);
  console.log(`\nRate Limiting endpoints:`);
  console.log(`  - Rate Limit Status: GET http://localhost:${PORT}/api/rate-limit/status`);
  console.log(`  - Reset Rate Limits: POST http://localhost:${PORT}/api/rate-limit/reset`);
  console.log(`\nFallback Service endpoints:`);
  console.log(`  - Fallback Status: GET http://localhost:${PORT}/api/fallback/status`);
  console.log(`  - Health Check: GET http://localhost:${PORT}/api/health`);
  console.log(`\nCron Service endpoints:`);
  console.log(`  - Cron Status: GET http://localhost:${PORT}/api/cron/status`);
  console.log(`  - Manual Rotation: POST http://localhost:${PORT}/api/cron/rotate`);
  console.log(`  - Manual Sync: POST http://localhost:${PORT}/api/cron/sync`);
  
  // Start queue processor for rate limiting
  startQueueProcessor(yelpService, { cacheRestaurantDetails, cacheSearchResults, cacheReviews });
  
  // Warm up cache with popular searches
  if (yelpService.isConfigured()) {
    warmUpCache(yelpService);
  }
  
  // Start cron service for automated tasks
  cronService.start();
});

// Cache Management endpoints
// GET /api/cache/stats - Get cache statistics
app.get('/api/cache/stats', (req, res) => {
  try {
    const stats = getCacheStats();
    res.json({
      success: true,
      stats: stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting cache stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get cache statistics',
      message: error.message
    });
  }
});

// DELETE /api/cache - Clear all caches
app.delete('/api/cache', (req, res) => {
  try {
    const cleared = clearAllCaches();
    res.json({
      success: cleared,
      message: cleared ? 'All caches cleared successfully' : 'Failed to clear caches',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error clearing caches:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear caches',
      message: error.message
    });
  }
});

// DELETE /api/cache/pattern/:pattern - Clear cache by pattern
app.delete('/api/cache/pattern/:pattern', (req, res) => {
  try {
    const { pattern } = req.params;
    const cleared = clearCacheByPattern(pattern);
    res.json({
      success: cleared,
      message: cleared ? `Cache cleared for pattern: ${pattern}` : 'Failed to clear cache pattern',
      pattern: pattern,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error clearing cache pattern:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear cache pattern',
      message: error.message
    });
  }
});

// Rate Limiting endpoints
// GET /api/rate-limit/status - Get rate limiting status
app.get('/api/rate-limit/status', (req, res) => {
  try {
    const status = getRateLimitStatus('yelp');
    res.json({
      success: true,
      status: status,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting rate limit status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get rate limit status',
      message: error.message
    });
  }
});

// POST /api/rate-limit/reset - Reset rate limits (for testing)
app.post('/api/rate-limit/reset', (req, res) => {
  try {
    resetRateLimits();
    res.json({
      success: true,
      message: 'Rate limits reset successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error resetting rate limits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to reset rate limits',
      message: error.message
    });
  }
});

// Fallback Service endpoints
// GET /api/fallback/status - Get fallback service status
app.get('/api/fallback/status', (req, res) => {
  try {
    const status = fallbackService.getFallbackStatus();
    const notice = fallbackService.getFallbackNotice();
    
    res.json({
      success: true,
      status: status,
      notice: notice,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting fallback status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get fallback status',
      message: error.message
    });
  }
});

// GET /api/health - Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const yelpHealth = await yelpService.checkHealth();
    const fallbackStatus = fallbackService.getFallbackStatus();
    
    res.json({
      success: true,
      status: 'healthy',
      services: {
        yelp: yelpHealth ? 'up' : 'down',
        fallback: fallbackStatus.isYelpDown ? 'active' : 'standby',
        database: 'up' // Assuming database is up if we can respond
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      success: false,
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Cron Service endpoints
// GET /api/cron/status - Get cron service status
app.get('/api/cron/status', (req, res) => {
  try {
    const status = cronService.getStatus();
    res.json({
      success: true,
      status
    });
  } catch (error) {
    console.error('Error getting cron status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get cron status',
      message: error.message
    });
  }
});

// POST /api/cron/rotate - Manually trigger featured restaurant rotation
app.post('/api/cron/rotate', async (req, res) => {
  try {
    const result = await cronService.triggerFeaturedRotation();
    res.json({
      success: true,
      message: 'Featured restaurant rotation triggered successfully',
      result
    });
  } catch (error) {
    console.error('Error triggering rotation:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to trigger rotation',
      message: error.message
    });
  }
});

// POST /api/cron/sync - Manually trigger restaurant sync
app.post('/api/cron/sync', async (req, res) => {
  try {
    const result = await cronService.triggerRestaurantSync();
    res.json({
      success: true,
      message: 'Restaurant sync triggered successfully',
      result
    });
  } catch (error) {
    console.error('Error triggering sync:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to trigger sync',
      message: error.message
    });
  }
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  cronService.stop();
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  cronService.stop();
  await prisma.$disconnect();
  process.exit(0);
});

module.exports = app;
