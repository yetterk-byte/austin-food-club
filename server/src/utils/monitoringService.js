/**
 * Enhanced Monitoring and Alerting System
 * Provides comprehensive monitoring, alerting, and health checks
 */

const os = require('os');
const fs = require('fs').promises;
const path = require('path');

class MonitoringService {
  constructor() {
    this.metrics = new Map();
    this.alerts = new Map();
    this.healthChecks = new Map();
    this.thresholds = {
      cpu: 80,           // CPU usage percentage
      memory: 85,        // Memory usage percentage
      disk: 90,          // Disk usage percentage
      responseTime: 2000, // API response time in ms
      errorRate: 5,      // Error rate percentage
      uptime: 3600      // Minimum uptime in seconds
    };
    this.alertHistory = [];
    this.isMonitoring = false;
    this.monitoringInterval = null;
  }

  /**
   * Start monitoring
   */
  startMonitoring(intervalMs = 30000) {
    if (this.isMonitoring) {
      console.log('⚠️ Monitoring is already running');
      return;
    }

    this.isMonitoring = true;
    console.log('📊 Starting monitoring service...');

    // Initial health check
    this.performHealthCheck();

    // Start periodic monitoring
    this.monitoringInterval = setInterval(() => {
      this.collectMetrics();
      this.performHealthCheck();
      this.checkAlerts();
    }, intervalMs);

    console.log(`✅ Monitoring started (interval: ${intervalMs}ms)`);
  }

  /**
   * Stop monitoring
   */
  stopMonitoring() {
    if (!this.isMonitoring) {
      console.log('⚠️ Monitoring is not running');
      return;
    }

    this.isMonitoring = false;
    if (this.monitoringInterval) {
      clearInterval(this.monitoringInterval);
      this.monitoringInterval = null;
    }

    console.log('🛑 Monitoring stopped');
  }

  /**
   * Collect system metrics
   */
  async collectMetrics() {
    try {
      const metrics = {
        timestamp: new Date().toISOString(),
        system: await this.getSystemMetrics(),
        process: this.getProcessMetrics(),
        application: this.getApplicationMetrics()
      };

      this.metrics.set(metrics.timestamp, metrics);
      
      // Keep only last 100 metrics to prevent memory leaks
      if (this.metrics.size > 100) {
        const oldestKey = this.metrics.keys().next().value;
        this.metrics.delete(oldestKey);
      }

      return metrics;
    } catch (error) {
      console.error('❌ Failed to collect metrics:', error);
      return null;
    }
  }

  /**
   * Get system metrics
   */
  async getSystemMetrics() {
    const cpus = os.cpus();
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;

    return {
      platform: os.platform(),
      arch: os.arch(),
      uptime: os.uptime(),
      loadAverage: os.loadavg(),
      cpu: {
        count: cpus.length,
        model: cpus[0].model,
        speed: cpus[0].speed
      },
      memory: {
        total: totalMem,
        used: usedMem,
        free: freeMem,
        usagePercent: Math.round((usedMem / totalMem) * 100)
      },
      network: os.networkInterfaces()
    };
  }

  /**
   * Get process metrics
   */
  getProcessMetrics() {
    const usage = process.memoryUsage();
    const uptime = process.uptime();

    return {
      pid: process.pid,
      uptime: uptime,
      memory: {
        rss: usage.rss,
        heapTotal: usage.heapTotal,
        heapUsed: usage.heapUsed,
        external: usage.external,
        arrayBuffers: usage.arrayBuffers
      },
      cpu: process.cpuUsage(),
      version: process.version,
      platform: process.platform
    };
  }

  /**
   * Get application metrics
   */
  getApplicationMetrics() {
    return {
      nodeEnv: process.env.NODE_ENV,
      port: process.env.PORT || 3001,
      timestamp: new Date().toISOString(),
      activeConnections: this.getActiveConnections(),
      errorCount: this.getErrorCount(),
      requestCount: this.getRequestCount()
    };
  }

  /**
   * Perform health check
   */
  async performHealthCheck() {
    const healthChecks = {
      timestamp: new Date().toISOString(),
      status: 'healthy',
      checks: {}
    };

    // System health checks
    healthChecks.checks.system = await this.checkSystemHealth();
    healthChecks.checks.database = await this.checkDatabaseHealth();
    healthChecks.checks.externalServices = await this.checkExternalServicesHealth();
    healthChecks.checks.application = this.checkApplicationHealth();

    // Determine overall status
    const allHealthy = Object.values(healthChecks.checks).every(check => check.status === 'healthy');
    healthChecks.status = allHealthy ? 'healthy' : 'unhealthy';

    this.healthChecks.set(healthChecks.timestamp, healthChecks);
    
    // Keep only last 50 health checks
    if (this.healthChecks.size > 50) {
      const oldestKey = this.healthChecks.keys().next().value;
      this.healthChecks.delete(oldestKey);
    }

    return healthChecks;
  }

  /**
   * Check system health
   */
  async checkSystemHealth() {
    const metrics = await this.getSystemMetrics();
    const issues = [];

    // Check memory usage
    if (metrics.memory.usagePercent > this.thresholds.memory) {
      issues.push(`High memory usage: ${metrics.memory.usagePercent}%`);
    }

    // Check disk usage (if available)
    try {
      const diskUsage = await this.getDiskUsage();
      if (diskUsage.usagePercent > this.thresholds.disk) {
        issues.push(`High disk usage: ${diskUsage.usagePercent}%`);
      }
    } catch (error) {
      // Disk usage check not available on all systems
    }

    return {
      status: issues.length === 0 ? 'healthy' : 'unhealthy',
      issues,
      metrics: {
        memoryUsage: metrics.memory.usagePercent,
        uptime: metrics.uptime
      }
    };
  }

  /**
   * Check database health
   */
  async checkDatabaseHealth() {
    try {
      // This would integrate with your database connection
      // For now, return a placeholder
      return {
        status: 'healthy',
        issues: [],
        metrics: {
          connectionCount: 0,
          queryTime: 0
        }
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        issues: [`Database connection failed: ${error.message}`],
        metrics: {}
      };
    }
  }

  /**
   * Check external services health
   */
  async checkExternalServicesHealth() {
    const services = {
      yelp: { status: 'unknown', issues: [] },
      twilio: { status: 'unknown', issues: [] },
      supabase: { status: 'unknown', issues: [] }
    };

    // Check Yelp API
    if (!process.env.YELP_API_KEY || process.env.YELP_API_KEY.includes('your_')) {
      services.yelp.status = 'unhealthy';
      services.yelp.issues.push('Yelp API key not configured');
    } else {
      services.yelp.status = 'healthy';
    }

    // Check Twilio
    if (!process.env.TWILIO_ACCOUNT_SID || process.env.TWILIO_ACCOUNT_SID.includes('your_')) {
      services.twilio.status = 'unhealthy';
      services.twilio.issues.push('Twilio credentials not configured');
    } else {
      services.twilio.status = 'healthy';
    }

    // Check Supabase
    if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
      services.supabase.status = 'unhealthy';
      services.supabase.issues.push('Supabase credentials not configured');
    } else {
      services.supabase.status = 'healthy';
    }

    const allHealthy = Object.values(services).every(service => service.status === 'healthy');
    
    return {
      status: allHealthy ? 'healthy' : 'unhealthy',
      services,
      issues: Object.values(services).flatMap(service => service.issues)
    };
  }

  /**
   * Check application health
   */
  checkApplicationHealth() {
    const issues = [];
    
    // Check if monitoring is running
    if (!this.isMonitoring) {
      issues.push('Monitoring service not running');
    }

    // Check error rate
    const errorRate = this.getErrorRate();
    if (errorRate > this.thresholds.errorRate) {
      issues.push(`High error rate: ${errorRate}%`);
    }

    return {
      status: issues.length === 0 ? 'healthy' : 'unhealthy',
      issues,
      metrics: {
        errorRate,
        uptime: process.uptime(),
        memoryUsage: process.memoryUsage()
      }
    };
  }

  /**
   * Check alerts
   */
  checkAlerts() {
    const currentMetrics = Array.from(this.metrics.values()).pop();
    if (!currentMetrics) return;

    const alerts = [];

    // Check memory usage
    if (currentMetrics.system.memory.usagePercent > this.thresholds.memory) {
      alerts.push({
        type: 'memory',
        severity: 'warning',
        message: `High memory usage: ${currentMetrics.system.memory.usagePercent}%`,
        threshold: this.thresholds.memory,
        value: currentMetrics.system.memory.usagePercent,
        timestamp: new Date().toISOString()
      });
    }

    // Check error rate
    const errorRate = this.getErrorRate();
    if (errorRate > this.thresholds.errorRate) {
      alerts.push({
        type: 'error_rate',
        severity: 'critical',
        message: `High error rate: ${errorRate}%`,
        threshold: this.thresholds.errorRate,
        value: errorRate,
        timestamp: new Date().toISOString()
      });
    }

    // Process alerts
    alerts.forEach(alert => this.processAlert(alert));
  }

  /**
   * Process alert
   */
  processAlert(alert) {
    const alertKey = `${alert.type}_${alert.severity}`;
    const lastAlert = this.alerts.get(alertKey);
    
    // Prevent spam - only alert if it's been more than 5 minutes since last alert
    if (lastAlert && (Date.now() - new Date(lastAlert.timestamp).getTime()) < 300000) {
      return;
    }

    this.alerts.set(alertKey, alert);
    this.alertHistory.push(alert);
    
    // Keep only last 100 alerts
    if (this.alertHistory.length > 100) {
      this.alertHistory.shift();
    }

    // Log alert
    console.log(`🚨 ${alert.severity.toUpperCase()} ALERT: ${alert.message}`);
    
    // Here you would integrate with your alerting system (email, Slack, etc.)
    this.sendAlert(alert);
  }

  /**
   * Send alert (integrate with your alerting system)
   */
  sendAlert(alert) {
    // This would integrate with your alerting system
    // Examples: email, Slack, PagerDuty, etc.
    console.log(`📧 Alert sent: ${alert.message}`);
  }

  /**
   * Get current health status
   */
  getHealthStatus() {
    const latestHealthCheck = Array.from(this.healthChecks.values()).pop();
    const latestMetrics = Array.from(this.metrics.values()).pop();
    
    return {
      status: latestHealthCheck?.status || 'unknown',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      healthChecks: latestHealthCheck,
      metrics: latestMetrics,
      alerts: Array.from(this.alerts.values()),
      thresholds: this.thresholds
    };
  }

  /**
   * Get monitoring dashboard data
   */
  getDashboardData() {
    const metrics = Array.from(this.metrics.values());
    const healthChecks = Array.from(this.healthChecks.values());
    
    return {
      metrics: metrics.slice(-10), // Last 10 metrics
      healthChecks: healthChecks.slice(-10), // Last 10 health checks
      alerts: this.alertHistory.slice(-20), // Last 20 alerts
      summary: {
        totalMetrics: metrics.length,
        totalHealthChecks: healthChecks.length,
        totalAlerts: this.alertHistory.length,
        isMonitoring: this.isMonitoring
      }
    };
  }

  /**
   * Helper methods (placeholders for now)
   */
  getActiveConnections() {
    // This would track active connections
    return 0;
  }

  getErrorCount() {
    // This would track error count
    return 0;
  }

  getRequestCount() {
    // This would track request count
    return 0;
  }

  getErrorRate() {
    // This would calculate error rate
    return 0;
  }

  async getDiskUsage() {
    // This would get disk usage
    return { usagePercent: 0 };
  }

  /**
   * Update thresholds
   */
  updateThresholds(newThresholds) {
    this.thresholds = { ...this.thresholds, ...newThresholds };
    console.log('📊 Monitoring thresholds updated');
  }

  /**
   * Clear alerts
   */
  clearAlerts() {
    this.alerts.clear();
    this.alertHistory.length = 0;
    console.log('🧹 Alerts cleared');
  }
}

// Create singleton instance
const monitoringService = new MonitoringService();

module.exports = monitoringService;

