/**
 * Input Validation Middleware
 * Provides consistent validation across all endpoints
 */

const { validationError } = require('./apiResponse');

/**
 * Validation Rules
 */
const rules = {
  // User validation
  user: {
    email: {
      required: true,
      type: 'email',
      message: 'Valid email address is required'
    },
    phone: {
      required: false,
      type: 'phone',
      message: 'Valid phone number is required'
    },
    name: {
      required: true,
      type: 'string',
      minLength: 2,
      maxLength: 100,
      message: 'Name must be between 2 and 100 characters'
    }
  },

  // Restaurant validation
  restaurant: {
    name: {
      required: true,
      type: 'string',
      minLength: 2,
      maxLength: 200,
      message: 'Restaurant name must be between 2 and 200 characters'
    },
    address: {
      required: true,
      type: 'string',
      minLength: 10,
      maxLength: 500,
      message: 'Address must be between 10 and 500 characters'
    },
    cuisine: {
      required: false,
      type: 'string',
      maxLength: 100,
      message: 'Cuisine type must be less than 100 characters'
    },
    price: {
      required: false,
      type: 'string',
      enum: ['$', '$$', '$$$', '$$$$'],
      message: 'Price range must be one of: $, $$, $$$, $$$$'
    }
  },

  // RSVP validation
  rsvp: {
    day: {
      required: true,
      type: 'string',
      enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
      message: 'Day must be a valid day of the week'
    },
    status: {
      required: true,
      type: 'string',
      enum: ['going', 'maybe', 'not_going'],
      message: 'Status must be one of: going, maybe, not_going'
    },
    restaurantId: {
      required: false,
      type: 'string',
      minLength: 1,
      message: 'Restaurant ID is required'
    }
  },

  // Verified visit validation
  verifiedVisit: {
    restaurantId: {
      required: true,
      type: 'string',
      minLength: 1,
      message: 'Restaurant ID is required'
    },
    rating: {
      required: true,
      type: 'number',
      min: 1,
      max: 5,
      message: 'Rating must be a number between 1 and 5'
    },
    photoUrl: {
      required: true,
      type: 'string',
      minLength: 10,
      message: 'Photo URL is required'
    },
    review: {
      required: false,
      type: 'string',
      maxLength: 1000,
      message: 'Review must be less than 1000 characters'
    },
    visitDate: {
      required: false,
      type: 'date',
      message: 'Visit date must be a valid date'
    }
  },

  // City validation
  city: {
    name: {
      required: true,
      type: 'string',
      minLength: 2,
      maxLength: 100,
      message: 'City name must be between 2 and 100 characters'
    },
    slug: {
      required: true,
      type: 'string',
      pattern: /^[a-z0-9-]+$/,
      message: 'City slug must contain only lowercase letters, numbers, and hyphens'
    },
    displayName: {
      required: true,
      type: 'string',
      minLength: 2,
      maxLength: 100,
      message: 'Display name must be between 2 and 100 characters'
    }
  },

  // Pagination validation
  pagination: {
    page: {
      required: false,
      type: 'number',
      min: 1,
      message: 'Page must be a positive number'
    },
    limit: {
      required: false,
      type: 'number',
      min: 1,
      max: 100,
      message: 'Limit must be between 1 and 100'
    }
  }
};

/**
 * Validation Functions
 */
const validators = {
  email: (value) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(value);
  },

  phone: (value) => {
    const phoneRegex = /^\+?[\d\s\-\(\)]{10,}$/;
    return phoneRegex.test(value);
  },

  string: (value, minLength = 0, maxLength = Infinity) => {
    if (typeof value !== 'string') return false;
    return value.length >= minLength && value.length <= maxLength;
  },

  number: (value, min = -Infinity, max = Infinity) => {
    const num = Number(value);
    return !isNaN(num) && num >= min && num <= max;
  },

  date: (value) => {
    const date = new Date(value);
    return !isNaN(date.getTime());
  },

  enum: (value, allowedValues) => {
    return allowedValues.includes(value);
  },

  pattern: (value, regex) => {
    return regex.test(value);
  }
};

/**
 * Validate a single field
 */
const validateField = (value, rule, fieldName) => {
  const errors = [];

  // Check required
  if (rule.required && (value === undefined || value === null || value === '')) {
    errors.push(`${fieldName} is required`);
    return errors;
  }

  // Skip validation if not required and empty
  if (!rule.required && (value === undefined || value === null || value === '')) {
    return errors;
  }

  // Type validation
  if (rule.type) {
    switch (rule.type) {
      case 'email':
        if (!validators.email(value)) {
          errors.push(rule.message || `${fieldName} must be a valid email`);
        }
        break;
      case 'phone':
        if (!validators.phone(value)) {
          errors.push(rule.message || `${fieldName} must be a valid phone number`);
        }
        break;
      case 'string':
        if (!validators.string(value, rule.minLength, rule.maxLength)) {
          errors.push(rule.message || `${fieldName} validation failed`);
        }
        break;
      case 'number':
        if (!validators.number(value, rule.min, rule.max)) {
          errors.push(rule.message || `${fieldName} validation failed`);
        }
        break;
      case 'date':
        if (!validators.date(value)) {
          errors.push(rule.message || `${fieldName} must be a valid date`);
        }
        break;
    }
  }

  // Enum validation
  if (rule.enum) {
    if (!validators.enum(value, rule.enum)) {
      errors.push(rule.message || `${fieldName} must be one of: ${rule.enum.join(', ')}`);
    }
  }

  // Pattern validation
  if (rule.pattern) {
    if (!validators.pattern(value, rule.pattern)) {
      errors.push(rule.message || `${fieldName} format is invalid`);
    }
  }

  return errors;
};

/**
 * Validate request body against rules
 */
const validate = (validationRules) => {
  return (req, res, next) => {
    const errors = [];
    const data = req.body;

    // Validate each field
    for (const [fieldName, rule] of Object.entries(validationRules)) {
      const fieldErrors = validateField(data[fieldName], rule, fieldName);
      errors.push(...fieldErrors);
    }

    // Check for unexpected fields
    const allowedFields = Object.keys(validationRules);
    const providedFields = Object.keys(data);
    const unexpectedFields = providedFields.filter(field => !allowedFields.includes(field));
    
    if (unexpectedFields.length > 0) {
      errors.push(`Unexpected fields: ${unexpectedFields.join(', ')}`);
    }

    if (errors.length > 0) {
      return validationError(res, errors, 'Validation failed');
    }

    next();
  };
};

/**
 * Validate query parameters
 */
const validateQuery = (validationRules) => {
  return (req, res, next) => {
    const errors = [];
    const query = req.query;

    // Validate each field
    for (const [fieldName, rule] of Object.entries(validationRules)) {
      const fieldErrors = validateField(query[fieldName], rule, fieldName);
      errors.push(...fieldErrors);
    }

    if (errors.length > 0) {
      return validationError(res, errors, 'Query validation failed');
    }

    next();
  };
};

/**
 * Validate required fields exist
 */
const requireFields = (fields) => {
  return (req, res, next) => {
    const errors = [];
    const data = req.body;

    for (const field of fields) {
      if (data[field] === undefined || data[field] === null || data[field] === '') {
        errors.push(`${field} is required`);
      }
    }

    if (errors.length > 0) {
      return validationError(res, errors, 'Required fields missing');
    }

    next();
  };
};

/**
 * Validate ID parameter
 */
const validateId = (paramName = 'id') => {
  return (req, res, next) => {
    const id = req.params[paramName];
    
    if (!id || id.trim() === '') {
      return validationError(res, [`${paramName} parameter is required`], 'Invalid parameter');
    }

    // Check if it's a valid UUID or numeric ID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    const numericRegex = /^\d+$/;
    
    if (!uuidRegex.test(id) && !numericRegex.test(id)) {
      return validationError(res, [`${paramName} must be a valid ID`], 'Invalid ID format');
    }

    next();
  };
};

/**
 * Sanitize input data
 */
const sanitize = (req, res, next) => {
  const sanitizeValue = (value) => {
    if (typeof value === 'string') {
      return value.trim();
    }
    return value;
  };

  const sanitizeObject = (obj) => {
    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        sanitized[key] = sanitizeObject(value);
      } else if (Array.isArray(value)) {
        sanitized[key] = value.map(item => 
          typeof item === 'object' && item !== null ? sanitizeObject(item) : sanitizeValue(item)
        );
      } else {
        sanitized[key] = sanitizeValue(value);
      }
    }
    return sanitized;
  };

  if (req.body) {
    req.body = sanitizeObject(req.body);
  }

  if (req.query) {
    req.query = sanitizeObject(req.query);
  }

  next();
};

module.exports = {
  rules,
  validate,
  validateQuery,
  requireFields,
  validateId,
  sanitize,
  validators
};

