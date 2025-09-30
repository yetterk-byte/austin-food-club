/**
 * Monitoring Dashboard Routes
 * Provides endpoints for monitoring and health checks
 */

const express = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const monitoringService = require('../utils/monitoringService');

const router = express.Router();

/**
 * @route GET /api/monitoring/health
 * @desc Get current health status
 * @access Public
 */
router.get('/health', asyncHandler(async (req, res) => {
  const healthStatus = monitoringService.getHealthStatus();
  
  res.status(200).json({
    success: true,
    data: healthStatus,
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route GET /api/monitoring/dashboard
 * @desc Get monitoring dashboard data
 * @access Public
 */
router.get('/dashboard', asyncHandler(async (req, res) => {
  const dashboardData = monitoringService.getDashboardData();
  
  res.status(200).json({
    success: true,
    data: dashboardData,
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route GET /api/monitoring/metrics
 * @desc Get system metrics
 * @access Public
 */
router.get('/metrics', asyncHandler(async (req, res) => {
  const metrics = await monitoringService.collectMetrics();
  
  res.status(200).json({
    success: true,
    data: metrics,
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route POST /api/monitoring/start
 * @desc Start monitoring service
 * @access Public
 */
router.post('/start', asyncHandler(async (req, res) => {
  const { interval = 30000 } = req.body;
  
  monitoringService.startMonitoring(interval);
  
  res.status(200).json({
    success: true,
    message: 'Monitoring service started',
    interval: interval,
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route POST /api/monitoring/stop
 * @desc Stop monitoring service
 * @access Public
 */
router.post('/stop', asyncHandler(async (req, res) => {
  monitoringService.stopMonitoring();
  
  res.status(200).json({
    success: true,
    message: 'Monitoring service stopped',
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route PUT /api/monitoring/thresholds
 * @desc Update monitoring thresholds
 * @access Public
 */
router.put('/thresholds', asyncHandler(async (req, res) => {
  const { thresholds } = req.body;
  
  if (!thresholds || typeof thresholds !== 'object') {
    return res.status(400).json({
      success: false,
      message: 'Invalid thresholds provided',
      timestamp: new Date().toISOString()
    });
  }
  
  monitoringService.updateThresholds(thresholds);
  
  res.status(200).json({
    success: true,
    message: 'Thresholds updated successfully',
    thresholds: thresholds,
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route DELETE /api/monitoring/alerts
 * @desc Clear all alerts
 * @access Public
 */
router.delete('/alerts', asyncHandler(async (req, res) => {
  monitoringService.clearAlerts();
  
  res.status(200).json({
    success: true,
    message: 'All alerts cleared',
    timestamp: new Date().toISOString()
  });
}));

/**
 * @route GET /api/monitoring/status
 * @desc Get monitoring service status
 * @access Public
 */
router.get('/status', asyncHandler(async (req, res) => {
  const status = monitoringService.getHealthStatus();
  
  res.status(200).json({
    success: true,
    data: {
      isMonitoring: monitoringService.isMonitoring,
      status: status.status,
      uptime: status.uptime,
      timestamp: new Date().toISOString()
    }
  });
}));

module.exports = router;

