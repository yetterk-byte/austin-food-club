/**
 * Enhanced Input Validation and Sanitization Utility
 * Provides comprehensive validation, sanitization, and security features
 */

const validator = require('validator');
const xss = require('xss');

class ValidationService {
  constructor() {
    this.rules = new Map();
    this.customValidators = new Map();
    this.setupDefaultRules();
  }

  /**
   * Setup default validation rules
   */
  setupDefaultRules() {
    // Phone number validation
    this.rules.set('phone', {
      pattern: /^\+1\d{10}$/,
      message: 'Phone number must be in format +1XXXXXXXXXX',
      sanitize: (value) => value.replace(/[^\d+]/g, '')
    });

    // Email validation
    this.rules.set('email', {
      pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: 'Please enter a valid email address',
      sanitize: (value) => validator.normalizeEmail(value) || value
    });

    // Name validation
    this.rules.set('name', {
      pattern: /^[a-zA-Z\s'-]{2,50}$/,
      message: 'Name must be 2-50 characters and contain only letters, spaces, hyphens, and apostrophes',
      sanitize: (value) => validator.escape(value.trim())
    });

    // Password validation
    this.rules.set('password', {
      pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
      message: 'Password must be at least 8 characters with uppercase, lowercase, number, and special character',
      sanitize: (value) => value // Don't sanitize passwords
    });

    // Restaurant name validation
    this.rules.set('restaurantName', {
      pattern: /^[a-zA-Z0-9\s&'.-]{2,100}$/,
      message: 'Restaurant name must be 2-100 characters',
      sanitize: (value) => validator.escape(value.trim())
    });

    // Address validation
    this.rules.set('address', {
      pattern: /^[a-zA-Z0-9\s,.-]{5,200}$/,
      message: 'Address must be 5-200 characters',
      sanitize: (value) => validator.escape(value.trim())
    });

    // Rating validation
    this.rules.set('rating', {
      pattern: /^[1-5](\.\d{1,2})?$/,
      message: 'Rating must be between 1.0 and 5.0',
      sanitize: (value) => parseFloat(value).toFixed(2)
    });

    // Price range validation
    this.rules.set('priceRange', {
      pattern: /^[1-4]$/,
      message: 'Price range must be 1, 2, 3, or 4',
      sanitize: (value) => value.toString()
    });

    // Cuisine validation
    this.rules.set('cuisine', {
      pattern: /^[a-zA-Z\s-]{2,50}$/,
      message: 'Cuisine must be 2-50 characters',
      sanitize: (value) => validator.escape(value.trim().toLowerCase())
    });

    // Day validation
    this.rules.set('day', {
      pattern: /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$/i,
      message: 'Day must be a valid day of the week',
      sanitize: (value) => value.toLowerCase()
    });

    // Status validation
    this.rules.set('status', {
      pattern: /^(confirmed|pending|cancelled)$/i,
      message: 'Status must be confirmed, pending, or cancelled',
      sanitize: (value) => value.toLowerCase()
    });
  }

  /**
   * Validate a single field
   */
  validateField(fieldName, value, customRules = {}) {
    const rule = this.rules.get(fieldName) || customRules[fieldName];
    
    if (!rule) {
      return {
        isValid: false,
        error: `No validation rule found for field: ${fieldName}`,
        sanitizedValue: value
      };
    }

    // Sanitize the value
    const sanitizedValue = rule.sanitize ? rule.sanitize(value) : value;

    // Check if value is required
    if (rule.required && (!sanitizedValue || sanitizedValue.toString().trim() === '')) {
      return {
        isValid: false,
        error: `${fieldName} is required`,
        sanitizedValue: sanitizedValue
      };
    }

    // Skip validation if value is empty and not required
    if (!rule.required && (!sanitizedValue || sanitizedValue.toString().trim() === '')) {
      return {
        isValid: true,
        error: null,
        sanitizedValue: sanitizedValue
      };
    }

    // Validate against pattern
    if (rule.pattern && !rule.pattern.test(sanitizedValue.toString())) {
      return {
        isValid: false,
        error: rule.message || `Invalid ${fieldName}`,
        sanitizedValue: sanitizedValue
      };
    }

    // Custom validation
    if (rule.custom && typeof rule.custom === 'function') {
      const customResult = rule.custom(sanitizedValue);
      if (customResult !== true) {
        return {
          isValid: false,
          error: customResult || `Invalid ${fieldName}`,
          sanitizedValue: sanitizedValue
        };
      }
    }

    return {
      isValid: true,
      error: null,
      sanitizedValue: sanitizedValue
    };
  }

  /**
   * Validate multiple fields
   */
  validateFields(fields, customRules = {}) {
    const results = {};
    const errors = {};
    let isValid = true;

    for (const [fieldName, value] of Object.entries(fields)) {
      const result = this.validateField(fieldName, value, customRules);
      results[fieldName] = result.sanitizedValue;
      
      if (!result.isValid) {
        errors[fieldName] = result.error;
        isValid = false;
      }
    }

    return {
      isValid,
      errors,
      sanitizedData: results
    };
  }

  /**
   * Sanitize HTML content
   */
  sanitizeHtml(html, options = {}) {
    const defaultOptions = {
      whiteList: {
        p: [],
        br: [],
        strong: [],
        em: [],
        u: [],
        h1: [],
        h2: [],
        h3: [],
        h4: [],
        h5: [],
        h6: [],
        ul: [],
        ol: [],
        li: [],
        a: ['href', 'title'],
        img: ['src', 'alt', 'title']
      },
      stripIgnoreTag: true,
      stripIgnoreTagBody: ['script']
    };

    const finalOptions = { ...defaultOptions, ...options };
    return xss(html, finalOptions);
  }

  /**
   * Sanitize SQL injection attempts
   */
  sanitizeSql(value) {
    if (typeof value !== 'string') return value;
    
    // Remove common SQL injection patterns
    return value
      .replace(/['"]/g, '') // Remove quotes
      .replace(/;/g, '') // Remove semicolons
      .replace(/--/g, '') // Remove SQL comments
      .replace(/\/\*/g, '') // Remove block comments
      .replace(/\*\//g, '') // Remove block comments
      .replace(/union/gi, '') // Remove UNION
      .replace(/select/gi, '') // Remove SELECT
      .replace(/insert/gi, '') // Remove INSERT
      .replace(/update/gi, '') // Remove UPDATE
      .replace(/delete/gi, '') // Remove DELETE
      .replace(/drop/gi, '') // Remove DROP
      .replace(/create/gi, '') // Remove CREATE
      .replace(/alter/gi, '') // Remove ALTER
      .trim();
  }

  /**
   * Validate and sanitize API input
   */
  validateApiInput(input, schema) {
    const validationResult = this.validateFields(input, schema);
    
    if (!validationResult.isValid) {
      return {
        success: false,
        errors: validationResult.errors,
        sanitizedData: validationResult.sanitizedData
      };
    }

    // Additional security checks
    const securityResult = this.performSecurityChecks(validationResult.sanitizedData);
    
    if (!securityResult.isValid) {
      return {
        success: false,
        errors: securityResult.errors,
        sanitizedData: validationResult.sanitizedData
      };
    }

    return {
      success: true,
      sanitizedData: validationResult.sanitizedData
    };
  }

  /**
   * Perform security checks
   */
  performSecurityChecks(data) {
    const errors = {};

    for (const [field, value] of Object.entries(data)) {
      if (typeof value === 'string') {
        // Check for XSS attempts
        if (value.includes('<script') || value.includes('javascript:') || value.includes('onload=')) {
          errors[field] = 'Invalid characters detected';
        }

        // Check for SQL injection attempts
        if (this.containsSqlInjection(value)) {
          errors[field] = 'Invalid characters detected';
        }

        // Check for excessive length
        if (value.length > 10000) {
          errors[field] = 'Input too long';
        }
      }
    }

    return {
      isValid: Object.keys(errors).length === 0,
      errors
    };
  }

  /**
   * Check for SQL injection patterns
   */
  containsSqlInjection(value) {
    const sqlPatterns = [
      /union\s+select/i,
      /select\s+.*\s+from/i,
      /insert\s+into/i,
      /update\s+.*\s+set/i,
      /delete\s+from/i,
      /drop\s+table/i,
      /create\s+table/i,
      /alter\s+table/i,
      /exec\s*\(/i,
      /execute\s*\(/i
    ];

    return sqlPatterns.some(pattern => pattern.test(value));
  }

  /**
   * Rate limiting validation
   */
  validateRateLimit(identifier, limit = 100, windowMs = 60000) {
    // This would integrate with your rate limiting system
    // For now, return a placeholder
    return {
      isValid: true,
      remaining: limit - 1,
      resetTime: Date.now() + windowMs
    };
  }

  /**
   * Validate file upload
   */
  validateFileUpload(file, options = {}) {
    const {
      maxSize = 5 * 1024 * 1024, // 5MB
      allowedTypes = ['image/jpeg', 'image/png', 'image/gif'],
      allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif']
    } = options;

    const errors = [];

    // Check file size
    if (file.size > maxSize) {
      errors.push(`File size must be less than ${maxSize / 1024 / 1024}MB`);
    }

    // Check file type
    if (!allowedTypes.includes(file.mimetype)) {
      errors.push(`File type must be one of: ${allowedTypes.join(', ')}`);
    }

    // Check file extension
    const extension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
    if (!allowedExtensions.includes(extension)) {
      errors.push(`File extension must be one of: ${allowedExtensions.join(', ')}`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Add custom validation rule
   */
  addCustomRule(fieldName, rule) {
    this.rules.set(fieldName, rule);
  }

  /**
   * Get validation rules for a field
   */
  getRule(fieldName) {
    return this.rules.get(fieldName);
  }

  /**
   * List all available validation rules
   */
  listRules() {
    return Array.from(this.rules.keys());
  }
}

// Create singleton instance
const validationService = new ValidationService();

module.exports = validationService;

