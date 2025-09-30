/**
 * Global Error Handling Middleware
 * Provides centralized error handling across the application
 */

const { error } = require('./apiResponse');

/**
 * Custom Error Classes
 */
class AppError extends Error {
  constructor(message, statusCode = 500, errorCode = 'INTERNAL_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message, errors = []) {
    super(message, 422, 'VALIDATION_ERROR');
    this.errors = errors;
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Authentication required') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Access denied') {
    super(message, 403, 'FORBIDDEN');
  }
}

class ConflictError extends AppError {
  constructor(message = 'Resource conflict') {
    super(message, 409, 'CONFLICT');
  }
}

class RateLimitError extends AppError {
  constructor(message = 'Rate limit exceeded') {
    super(message, 429, 'RATE_LIMIT_EXCEEDED');
  }
}

class ServiceUnavailableError extends AppError {
  constructor(message = 'Service temporarily unavailable') {
    super(message, 503, 'SERVICE_UNAVAILABLE');
  }
}

/**
 * Error Handler Middleware
 */
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error details
  console.error('Error Handler:', {
    message: err.message,
    stack: err.stack,
    statusCode: err.statusCode,
    errorCode: err.errorCode,
    url: req.url,
    method: req.method,
    timestamp: new Date().toISOString()
  });

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Resource not found';
    error = new NotFoundError(message);
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const message = 'Duplicate field value entered';
    error = new ConflictError(message);
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = 'Validation Error';
    const errors = Object.values(err.errors).map(val => val.message);
    error = new ValidationError(message, errors);
  }

  // Prisma errors
  if (err.name === 'PrismaClientKnownRequestError') {
    switch (err.code) {
      case 'P2002':
        error = new ConflictError('Resource already exists');
        break;
      case 'P2025':
        error = new NotFoundError('Resource not found');
        break;
      case 'P2003':
        error = new ValidationError('Foreign key constraint failed');
        break;
      case 'P2014':
        error = new ValidationError('Invalid ID provided');
        break;
      default:
        error = new AppError('Database operation failed', 500, 'DATABASE_ERROR');
    }
  }

  // Prisma validation error
  if (err.name === 'PrismaClientValidationError') {
    error = new ValidationError('Invalid data provided');
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = new UnauthorizedError('Invalid token');
  }

  if (err.name === 'TokenExpiredError') {
    error = new UnauthorizedError('Token expired');
  }

  // Rate limiting errors
  if (err.name === 'TooManyRequestsError') {
    error = new RateLimitError();
  }

  // Yelp API errors
  if (err.name === 'YelpAPIError') {
    if (err.statusCode === 429) {
      error = new RateLimitError('Yelp API rate limit exceeded');
    } else if (err.statusCode >= 500) {
      error = new ServiceUnavailableError('Yelp API temporarily unavailable');
    } else {
      error = new AppError('Yelp API error', err.statusCode || 500, 'YELP_API_ERROR');
    }
  }

  // Send error response
  if (error.isOperational) {
    return res.status(error.statusCode).json({
      success: false,
      message: error.message,
      error: error.errorCode,
      timestamp: new Date().toISOString(),
      ...(error.errors && { errors: error.errors })
    });
  }

  // Send generic error for non-operational errors
  return res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: 'INTERNAL_ERROR',
    timestamp: new Date().toISOString()
  });
};

/**
 * Handle unhandled promise rejections
 */
const handleUnhandledRejection = () => {
  process.on('unhandledRejection', (err, promise) => {
    console.error('Unhandled Promise Rejection:', err.message);
    console.error('Promise:', promise);
    
    // Close server gracefully
    process.exit(1);
  });
};

/**
 * Handle uncaught exceptions
 */
const handleUncaughtException = () => {
  process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err.message);
    console.error('Stack:', err.stack);
    
    // Close server gracefully
    process.exit(1);
  });
};

/**
 * Async error wrapper
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * 404 handler for undefined routes
 */
const notFound = (req, res, next) => {
  const error = new NotFoundError(`Route ${req.originalUrl} not found`);
  next(error);
};

/**
 * Initialize error handling
 */
const initializeErrorHandling = () => {
  handleUnhandledRejection();
  handleUncaughtException();
};

module.exports = {
  AppError,
  ValidationError,
  NotFoundError,
  UnauthorizedError,
  ForbiddenError,
  ConflictError,
  RateLimitError,
  ServiceUnavailableError,
  errorHandler,
  asyncHandler,
  notFound,
  initializeErrorHandling
};

