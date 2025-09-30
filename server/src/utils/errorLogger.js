/**
 * Enhanced Error Logging Utility
 * Provides structured error logging with context and severity levels
 */

const fs = require('fs').promises;
const path = require('path');

class ErrorLogger {
  constructor() {
    this.logLevels = {
      ERROR: 0,
      WARN: 1,
      INFO: 2,
      DEBUG: 3
    };
    this.currentLevel = this.logLevels.INFO;
    this.logDir = path.join(__dirname, '../../logs');
    this.ensureLogDirectory();
  }

  async ensureLogDirectory() {
    try {
      await fs.mkdir(this.logDir, { recursive: true });
    } catch (error) {
      console.error('Failed to create log directory:', error);
    }
  }

  /**
   * Log an error with context
   * @param {Error|string} error - The error to log
   * @param {Object} context - Additional context information
   * @param {string} level - Log level (ERROR, WARN, INFO, DEBUG)
   */
  async log(error, context = {}, level = 'ERROR') {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level,
      error: error instanceof Error ? {
        message: error.message,
        stack: error.stack,
        name: error.name
      } : error,
      context,
      pid: process.pid,
      memory: process.memoryUsage()
    };

    // Console output with colors
    this.logToConsole(logEntry);

    // File output
    await this.logToFile(logEntry);
  }

  logToConsole(logEntry) {
    const colors = {
      ERROR: '\x1b[31m', // Red
      WARN: '\x1b[33m',  // Yellow
      INFO: '\x1b[36m',  // Cyan
      DEBUG: '\x1b[37m', // White
      RESET: '\x1b[0m'
    };

    const color = colors[logEntry.level] || colors.RESET;
    const reset = colors.RESET;

    console.log(`${color}[${logEntry.level}]${reset} ${logEntry.timestamp}`);
    console.log(`${color}Error:${reset}`, logEntry.error);
    
    if (Object.keys(logEntry.context).length > 0) {
      console.log(`${color}Context:${reset}`, logEntry.context);
    }
    
    if (logEntry.error.stack) {
      console.log(`${color}Stack:${reset}`, logEntry.error.stack);
    }
    
    console.log(`${color}Memory:${reset}`, `${Math.round(logEntry.memory.heapUsed / 1024 / 1024)}MB`);
    console.log('---');
  }

  async logToFile(logEntry) {
    try {
      const filename = `error-${new Date().toISOString().split('T')[0]}.log`;
      const filepath = path.join(this.logDir, filename);
      const logLine = JSON.stringify(logEntry) + '\n';
      
      await fs.appendFile(filepath, logLine);
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  /**
   * Log API errors with request context
   */
  async logApiError(error, req, res, additionalContext = {}) {
    const context = {
      method: req.method,
      url: req.url,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.id,
      ...additionalContext
    };

    await this.log(error, context, 'ERROR');
  }

  /**
   * Log database errors with query context
   */
  async logDatabaseError(error, query, params = {}) {
    const context = {
      query: query.substring(0, 200) + (query.length > 200 ? '...' : ''),
      params: Object.keys(params).length > 0 ? params : undefined,
      type: 'database'
    };

    await this.log(error, context, 'ERROR');
  }

  /**
   * Log external service errors (Yelp, Twilio, etc.)
   */
  async logServiceError(error, service, request = {}) {
    const context = {
      service,
      request: Object.keys(request).length > 0 ? request : undefined,
      type: 'external_service'
    };

    await this.log(error, context, 'ERROR');
  }

  /**
   * Log performance issues
   */
  async logPerformanceIssue(operation, duration, threshold = 1000) {
    if (duration > threshold) {
      const context = {
        operation,
        duration,
        threshold,
        type: 'performance'
      };

      await this.log(`Slow operation: ${operation} took ${duration}ms`, context, 'WARN');
    }
  }

  /**
   * Log security events
   */
  async logSecurityEvent(event, details = {}) {
    const context = {
      event,
      details,
      type: 'security'
    };

    await this.log(`Security event: ${event}`, context, 'WARN');
  }
}

// Create singleton instance
const errorLogger = new ErrorLogger();

module.exports = errorLogger;

