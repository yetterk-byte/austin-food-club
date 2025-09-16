const express = require('express');
const router = express.Router();

// Import route modules
const restaurantRoutes = require('./restaurantRoutes');
const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const systemRoutes = require('./systemRoutes');

// API Response Helper
const apiResponse = {
  success: (data, message = 'Success', statusCode = 200) => ({
    success: true,
    status: statusCode,
    message,
    data,
    timestamp: new Date().toISOString()
  }),

  error: (message, statusCode = 500, details = null) => ({
    success: false,
    status: statusCode,
    message,
    details,
    timestamp: new Date().toISOString()
  }),

  validation: (errors, message = 'Validation failed') => ({
    success: false,
    status: 400,
    message,
    errors,
    timestamp: new Date().toISOString()
  })
};

// Middleware to add response helper to all routes
router.use((req, res, next) => {
  res.apiResponse = apiResponse;
  next();
});

// Health check endpoint
router.get('/health', (req, res) => {
  res.json(apiResponse.success({
    service: 'Austin Food Club API',
    version: '1.0.0',
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  }, 'API is healthy'));
});

// API Info endpoint
router.get('/info', (req, res) => {
  res.json(apiResponse.success({
    name: 'Austin Food Club API',
    version: '1.0.0',
    description: 'REST API for Austin Food Club restaurant discovery and RSVP system',
    endpoints: {
      restaurants: '/api/v1/restaurants',
      auth: '/api/v1/auth',
      users: '/api/v1/users',
      system: '/api/v1/system'
    },
    documentation: '/api/v1/docs'
  }, 'API information retrieved'));
});

// Mount route modules
router.use('/restaurants', restaurantRoutes);
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/system', systemRoutes);

// 404 handler for API routes
router.use('*', (req, res) => {
  res.status(404).json(apiResponse.error(
    `API endpoint not found: ${req.method} ${req.originalUrl}`,
    404,
    {
      availableEndpoints: [
        'GET /api/v1/health',
        'GET /api/v1/info',
        'GET /api/v1/restaurants',
        'GET /api/v1/auth',
        'GET /api/v1/users',
        'GET /api/v1/system'
      ]
    }
  ));
});

// Global error handler for API routes
router.use((err, req, res, next) => {
  console.error('API Error:', err);
  
  // Handle specific error types
  if (err.name === 'ValidationError') {
    return res.status(400).json(apiResponse.validation(
      err.errors || err.message,
      'Request validation failed'
    ));
  }
  
  if (err.name === 'UnauthorizedError') {
    return res.status(401).json(apiResponse.error(
      'Authentication required',
      401,
      { code: 'UNAUTHORIZED' }
    ));
  }
  
  if (err.name === 'ForbiddenError') {
    return res.status(403).json(apiResponse.error(
      'Access forbidden',
      403,
      { code: 'FORBIDDEN' }
    ));
  }
  
  // Default error response
  res.status(500).json(apiResponse.error(
    'Internal server error',
    500,
    process.env.NODE_ENV === 'development' ? err.message : null
  ));
});

module.exports = router;
