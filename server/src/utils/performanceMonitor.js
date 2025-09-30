/**
 * Performance Monitoring Utility
 * Tracks API response times, database query performance, and system metrics
 */

class PerformanceMonitor {
  constructor() {
    this.metrics = new Map();
    this.thresholds = {
      api: 2000,      // 2 seconds
      database: 1000, // 1 second
      external: 5000  // 5 seconds
    };
  }

  /**
   * Start timing an operation
   * @param {string} operation - Name of the operation
   * @param {string} type - Type of operation (api, database, external)
   * @returns {string} - Timer ID
   */
  startTimer(operation, type = 'api') {
    const timerId = `${operation}_${Date.now()}_${Math.random()}`;
    this.metrics.set(timerId, {
      operation,
      type,
      startTime: process.hrtime.bigint(),
      startMemory: process.memoryUsage()
    });
    return timerId;
  }

  /**
   * End timing an operation
   * @param {string} timerId - Timer ID from startTimer
   * @param {Object} metadata - Additional metadata
   * @returns {Object} - Performance metrics
   */
  endTimer(timerId, metadata = {}) {
    const timer = this.metrics.get(timerId);
    if (!timer) {
      console.warn(`Timer ${timerId} not found`);
      return null;
    }

    const endTime = process.hrtime.bigint();
    const endMemory = process.memoryUsage();
    
    const duration = Number(endTime - timer.startTime) / 1000000; // Convert to milliseconds
    const memoryDelta = {
      heapUsed: endMemory.heapUsed - timer.startMemory.heapUsed,
      heapTotal: endMemory.heapTotal - timer.startMemory.heapTotal,
      external: endMemory.external - timer.startMemory.external
    };

    const metrics = {
      operation: timer.operation,
      type: timer.type,
      duration,
      memoryDelta,
      metadata,
      timestamp: new Date().toISOString()
    };

    // Check if operation exceeded threshold
    const threshold = this.thresholds[timer.type] || this.thresholds.api;
    if (duration > threshold) {
      console.warn(`⚠️ Slow ${timer.type} operation: ${timer.operation} took ${duration.toFixed(2)}ms (threshold: ${threshold}ms)`);
    }

    // Clean up timer
    this.metrics.delete(timerId);

    return metrics;
  }

  /**
   * Middleware for Express to track API performance
   */
  apiMiddleware() {
    return (req, res, next) => {
      const timerId = this.startTimer(`${req.method} ${req.route?.path || req.path}`, 'api');
      
      res.on('finish', () => {
        const metrics = this.endTimer(timerId, {
          statusCode: res.statusCode,
          contentLength: res.get('Content-Length'),
          userAgent: req.get('User-Agent'),
          ip: req.ip
        });
        
        if (metrics) {
          // Log slow API calls
          if (metrics.duration > this.thresholds.api) {
            console.warn(`🐌 Slow API call: ${metrics.operation} - ${metrics.duration.toFixed(2)}ms`);
          }
        }
      });
      
      next();
    };
  }

  /**
   * Wrap database operations for performance tracking
   */
  wrapDatabaseOperation(operation, query, params = {}) {
    const timerId = this.startTimer(`db_${operation}`, 'database');
    
    return async (...args) => {
      try {
        const result = await query(...args);
        const metrics = this.endTimer(timerId, {
          operation,
          params: Object.keys(params).length > 0 ? params : undefined,
          resultCount: Array.isArray(result) ? result.length : 1
        });
        
        if (metrics && metrics.duration > this.thresholds.database) {
          console.warn(`🐌 Slow database operation: ${operation} - ${metrics.duration.toFixed(2)}ms`);
        }
        
        return result;
      } catch (error) {
        this.endTimer(timerId, { error: error.message });
        throw error;
      }
    };
  }

  /**
   * Wrap external service calls
   */
  wrapExternalService(serviceName, operation) {
    const timerId = this.startTimer(`${serviceName}_${operation}`, 'external');
    
    return async (...args) => {
      try {
        const result = await operation(...args);
        const metrics = this.endTimer(timerId, {
          service: serviceName,
          operation
        });
        
        if (metrics && metrics.duration > this.thresholds.external) {
          console.warn(`🐌 Slow external service call: ${serviceName}.${operation} - ${metrics.duration.toFixed(2)}ms`);
        }
        
        return result;
      } catch (error) {
        this.endTimer(timerId, { error: error.message });
        throw error;
      }
    };
  }

  /**
   * Get system metrics
   */
  getSystemMetrics() {
    const memory = process.memoryUsage();
    const uptime = process.uptime();
    
    return {
      memory: {
        heapUsed: Math.round(memory.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memory.heapTotal / 1024 / 1024), // MB
        external: Math.round(memory.external / 1024 / 1024), // MB
        rss: Math.round(memory.rss / 1024 / 1024) // MB
      },
      uptime: Math.round(uptime), // seconds
      activeTimers: this.metrics.size,
      nodeVersion: process.version,
      platform: process.platform
    };
  }

  /**
   * Health check with performance metrics
   */
  getHealthMetrics() {
    const systemMetrics = this.getSystemMetrics();
    
    return {
      status: 'healthy',
      performance: {
        memoryUsage: `${systemMetrics.memory.heapUsed}MB / ${systemMetrics.memory.heapTotal}MB`,
        uptime: `${Math.floor(systemMetrics.uptime / 3600)}h ${Math.floor((systemMetrics.uptime % 3600) / 60)}m`,
        activeOperations: systemMetrics.activeTimers
      },
      thresholds: this.thresholds,
      timestamp: new Date().toISOString()
    };
  }
}

// Create singleton instance
const performanceMonitor = new PerformanceMonitor();

module.exports = performanceMonitor;

