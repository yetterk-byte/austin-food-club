/**
 * Standardized API Response Middleware
 * Provides consistent response formats across all endpoints
 */

/**
 * Standard API Response Format
 * @param {Object} res - Express response object
 * @param {number} statusCode - HTTP status code
 * @param {boolean} success - Whether the request was successful
 * @param {string} message - Human-readable message
 * @param {*} data - Response data (optional)
 * @param {Object} meta - Additional metadata (optional)
 * @param {string} error - Error code or type (optional)
 */
const sendResponse = (res, statusCode, success, message, data = null, meta = null, error = null) => {
  const response = {
    success,
    message,
    timestamp: new Date().toISOString(),
    ...(data !== null && { data }),
    ...(meta && { meta }),
    ...(error && { error })
  };

  return res.status(statusCode).json(response);
};

/**
 * Success Response Helpers
 */
const success = {
  // 200 OK
  ok: (res, message, data = null, meta = null) => {
    return sendResponse(res, 200, true, message, data, meta);
  },

  // 201 Created
  created: (res, message, data = null, meta = null) => {
    return sendResponse(res, 201, true, message, data, meta);
  },

  // 202 Accepted
  accepted: (res, message, data = null, meta = null) => {
    return sendResponse(res, 202, true, message, data, meta);
  },

  // 204 No Content
  noContent: (res, message = 'Operation completed successfully') => {
    return sendResponse(res, 204, true, message);
  }
};

/**
 * Error Response Helpers
 */
const error = {
  // 400 Bad Request
  badRequest: (res, message, errorCode = null) => {
    return sendResponse(res, 400, false, message, null, null, errorCode);
  },

  // 401 Unauthorized
  unauthorized: (res, message = 'Authentication required', errorCode = 'UNAUTHORIZED') => {
    return sendResponse(res, 401, false, message, null, null, errorCode);
  },

  // 403 Forbidden
  forbidden: (res, message = 'Access denied', errorCode = 'FORBIDDEN') => {
    return sendResponse(res, 403, false, message, null, null, errorCode);
  },

  // 404 Not Found
  notFound: (res, message = 'Resource not found', errorCode = 'NOT_FOUND') => {
    return sendResponse(res, 404, false, message, null, null, errorCode);
  },

  // 409 Conflict
  conflict: (res, message, errorCode = 'CONFLICT') => {
    return sendResponse(res, 409, false, message, null, null, errorCode);
  },

  // 422 Unprocessable Entity
  unprocessableEntity: (res, message, errorCode = 'VALIDATION_ERROR') => {
    return sendResponse(res, 422, false, message, null, null, errorCode);
  },

  // 429 Too Many Requests
  tooManyRequests: (res, message = 'Rate limit exceeded', errorCode = 'RATE_LIMIT_EXCEEDED') => {
    return sendResponse(res, 429, false, message, null, null, errorCode);
  },

  // 500 Internal Server Error
  internalServerError: (res, message = 'Internal server error', errorCode = 'INTERNAL_ERROR') => {
    return sendResponse(res, 500, false, message, null, null, errorCode);
  },

  // 503 Service Unavailable
  serviceUnavailable: (res, message = 'Service temporarily unavailable', errorCode = 'SERVICE_UNAVAILABLE') => {
    return sendResponse(res, 503, false, message, null, null, errorCode);
  }
};

/**
 * Validation Error Response Helper
 * @param {Object} res - Express response object
 * @param {Array|Object} validationErrors - Validation errors
 * @param {string} message - Custom message (optional)
 */
const validationError = (res, validationErrors, message = 'Validation failed') => {
  const errorData = Array.isArray(validationErrors) 
    ? { errors: validationErrors }
    : validationErrors;

  return sendResponse(res, 422, false, message, errorData, null, 'VALIDATION_ERROR');
};

/**
 * Pagination Helper
 * @param {Object} res - Express response object
 * @param {Array} data - Array of data items
 * @param {number} page - Current page number
 * @param {number} limit - Items per page
 * @param {number} total - Total number of items
 * @param {string} message - Success message
 */
const paginated = (res, data, page, limit, total, message = 'Data retrieved successfully') => {
  const totalPages = Math.ceil(total / limit);
  const hasNext = page < totalPages;
  const hasPrev = page > 1;

  const meta = {
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(total),
      totalPages,
      hasNext,
      hasPrev
    }
  };

  return sendResponse(res, 200, true, message, data, meta);
};

/**
 * Async Error Handler Middleware
 * Wraps async route handlers to catch errors and send standardized responses
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((err) => {
      console.error('Unhandled async error:', err);
      
      // Handle known error types
      if (err.name === 'ValidationError') {
        return validationError(res, err.errors, 'Validation failed');
      }
      
      if (err.name === 'PrismaClientKnownRequestError') {
        if (err.code === 'P2002') {
          return error.conflict(res, 'Resource already exists', 'DUPLICATE_RESOURCE');
        }
        if (err.code === 'P2025') {
          return error.notFound(res, 'Resource not found', 'RESOURCE_NOT_FOUND');
        }
      }
      
      // Default to internal server error
      return error.internalServerError(res, 'An unexpected error occurred', 'INTERNAL_ERROR');
    });
  };
};

/**
 * Response Middleware
 * Adds response helpers to the response object
 */
const responseMiddleware = (req, res, next) => {
  res.api = {
    success,
    error,
    validationError,
    paginated,
    sendResponse
  };
  next();
};

module.exports = {
  success,
  error,
  validationError,
  paginated,
  asyncHandler,
  responseMiddleware,
  sendResponse
};

