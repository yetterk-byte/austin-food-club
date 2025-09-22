const express = require('express');
const { requireAdmin, logAdminActionMiddleware } = require('../middleware/adminAuth');
const rotationService = require('../services/rotationService');
const queueService = require('../services/queueService');
const rotationJobManager = require('../jobs/rotationJob');

const router = express.Router();

// Apply admin authentication to all routes
router.use(requireAdmin);

/**
 * GET /api/rotation/config
 * Get current rotation configuration
 */
router.get('/config', logAdminActionMiddleware('view_rotation_config', 'rotation'), async (req, res) => {
  try {
    const config = await rotationService.getRotationConfig();
    const preview = await rotationService.getRotationPreview(8);
    
    res.json({
      config,
      preview: preview.preview,
      totalWeeksPlanned: preview.totalWeeksPlanned
    });
  } catch (error) {
    console.error('Get rotation config error:', error);
    res.status(500).json({ error: 'Failed to get rotation configuration' });
  }
});

/**
 * PUT /api/rotation/config
 * Update rotation configuration
 */
router.put('/config', logAdminActionMiddleware('update_rotation_config', 'rotation'), async (req, res) => {
  try {
    const updates = req.body;
    const updatedConfig = await rotationService.updateRotationConfig(updates, req.admin.id);
    
    res.json({
      config: updatedConfig,
      message: 'Rotation configuration updated successfully'
    });
  } catch (error) {
    console.error('Update rotation config error:', error);
    res.status(500).json({ error: 'Failed to update rotation configuration' });
  }
});

/**
 * GET /api/rotation/preview
 * Get rotation schedule preview
 */
router.get('/preview', logAdminActionMiddleware('view_rotation_preview', 'rotation'), async (req, res) => {
  try {
    const weeks = parseInt(req.query.weeks) || 8;
    const preview = await rotationService.getRotationPreview(weeks);
    
    res.json(preview);
  } catch (error) {
    console.error('Get rotation preview error:', error);
    res.status(500).json({ error: 'Failed to get rotation preview' });
  }
});

// Manual and emergency rotation removed - automatic rotation only

/**
 * GET /api/rotation/history
 * Get rotation history
 */
router.get('/history', logAdminActionMiddleware('view_rotation_history', 'rotation'), async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const history = await rotationService.getRotationHistory(limit);
    
    res.json(history);
  } catch (error) {
    console.error('Get rotation history error:', error);
    res.status(500).json({ error: 'Failed to get rotation history' });
  }
});

/**
 * GET /api/rotation/status
 * Get current rotation status
 */
router.get('/status', logAdminActionMiddleware('view_rotation_status', 'rotation'), async (req, res) => {
  try {
    const [config, queueStats, jobStatus] = await Promise.all([
      rotationService.getRotationConfig(),
      queueService.getQueueStats(),
      Promise.resolve(rotationJobManager.getJobStatus())
    ]);
    
    res.json({
      rotationConfig: config,
      queueStats,
      jobStatus,
      isRotationRunning: rotationService.isRotationRunning || false
    });
  } catch (error) {
    console.error('Get rotation status error:', error);
    res.status(500).json({ error: 'Failed to get rotation status' });
  }
});

/**
 * POST /api/rotation/test-schedule
 * Test rotation schedule (trigger check manually)
 */
router.post('/test-schedule', logAdminActionMiddleware('test_rotation_schedule', 'rotation'), async (req, res) => {
  try {
    const result = await rotationJobManager.triggerRotationCheck();
    res.json(result);
  } catch (error) {
    console.error('Test rotation schedule error:', error);
    res.status(500).json({ error: 'Failed to test rotation schedule' });
  }
});

/**
 * Queue Management Routes
 */

/**
 * GET /api/rotation/queue
 * Get queue with insights
 */
router.get('/queue', logAdminActionMiddleware('view_rotation_queue', 'queue'), async (req, res) => {
  try {
    const queue = await queueService.getQueueWithInsights();
    const stats = await queueService.getQueueStats();
    
    res.json({
      queue,
      stats
    });
  } catch (error) {
    console.error('Get rotation queue error:', error);
    res.status(500).json({ error: 'Failed to get rotation queue' });
  }
});

/**
 * POST /api/rotation/queue/add
 * Add restaurant to queue
 */
router.post('/queue/add', logAdminActionMiddleware('add_to_rotation_queue', 'queue'), async (req, res) => {
  try {
    const queueItem = await queueService.addToQueue(req.body, req.admin.id);
    res.json({
      queueItem,
      message: 'Restaurant added to queue successfully'
    });
  } catch (error) {
    console.error('Add to rotation queue error:', error);
    res.status(400).json({ error: error.message || 'Failed to add restaurant to queue' });
  }
});

/**
 * DELETE /api/rotation/queue/:id
 * Remove restaurant from queue
 */
router.delete('/queue/:id', logAdminActionMiddleware('remove_from_rotation_queue', 'queue'), async (req, res) => {
  try {
    const result = await queueService.removeFromQueue(req.params.id, req.admin.id);
    res.json(result);
  } catch (error) {
    console.error('Remove from rotation queue error:', error);
    res.status(400).json({ error: error.message || 'Failed to remove restaurant from queue' });
  }
});

/**
 * POST /api/rotation/queue/reorder
 * Reorder queue
 */
router.post('/queue/reorder', logAdminActionMiddleware('reorder_rotation_queue', 'queue'), async (req, res) => {
  try {
    const { newOrder } = req.body;
    const result = await queueService.reorderQueue(newOrder, req.admin.id);
    res.json(result);
  } catch (error) {
    console.error('Reorder rotation queue error:', error);
    res.status(400).json({ error: error.message || 'Failed to reorder queue' });
  }
});

/**
 * POST /api/rotation/queue/skip/:id
 * Skip restaurant in queue
 */
router.post('/queue/skip/:id', logAdminActionMiddleware('skip_restaurant_queue', 'queue'), async (req, res) => {
  try {
    const { reason, action = 'move_to_end' } = req.body;
    
    if (!reason) {
      return res.status(400).json({ error: 'Reason required for skipping restaurant' });
    }
    
    const result = await queueService.skipRestaurant(req.params.id, reason, req.admin.id, action);
    res.json(result);
  } catch (error) {
    console.error('Skip restaurant error:', error);
    res.status(400).json({ error: error.message || 'Failed to skip restaurant' });
  }
});

/**
 * POST /api/rotation/queue/urgent
 * Insert restaurant as urgent (next in line)
 */
router.post('/queue/urgent', logAdminActionMiddleware('insert_urgent_restaurant', 'queue'), async (req, res) => {
  try {
    const { restaurantId, notes } = req.body;
    
    if (!restaurantId) {
      return res.status(400).json({ error: 'Restaurant ID required' });
    }
    
    const queueItem = await queueService.insertUrgent(restaurantId, req.admin.id, notes);
    res.json({
      queueItem,
      message: 'Restaurant inserted as urgent successfully'
    });
  } catch (error) {
    console.error('Insert urgent restaurant error:', error);
    res.status(400).json({ error: error.message || 'Failed to insert urgent restaurant' });
  }
});

/**
 * POST /api/rotation/queue/validate
 * Validate queue integrity
 */
router.post('/queue/validate', logAdminActionMiddleware('validate_queue_integrity', 'queue'), async (req, res) => {
  try {
    const validation = await queueService.validateQueueIntegrity();
    res.json(validation);
  } catch (error) {
    console.error('Validate queue integrity error:', error);
    res.status(500).json({ error: 'Failed to validate queue integrity' });
  }
});

/**
 * POST /api/rotation/queue/fix
 * Fix queue integrity issues
 */
router.post('/queue/fix', logAdminActionMiddleware('fix_queue_integrity', 'queue'), async (req, res) => {
  try {
    const result = await queueService.fixQueueIntegrity(req.admin.id);
    res.json(result);
  } catch (error) {
    console.error('Fix queue integrity error:', error);
    res.status(500).json({ error: 'Failed to fix queue integrity' });
  }
});

/**
 * Job Management Routes
 */

/**
 * GET /api/rotation/jobs/status
 * Get job status
 */
router.get('/jobs/status', async (req, res) => {
  try {
    const status = rotationJobManager.getJobStatus();
    const nextRuns = rotationJobManager.getNextRunTimes();
    
    res.json({
      jobs: status,
      nextRuns,
      isInitialized: rotationJobManager.isInitialized
    });
  } catch (error) {
    console.error('Get job status error:', error);
    res.status(500).json({ error: 'Failed to get job status' });
  }
});

/**
 * POST /api/rotation/jobs/restart
 * Restart all rotation jobs
 */
router.post('/jobs/restart', logAdminActionMiddleware('restart_rotation_jobs', 'system'), async (req, res) => {
  try {
    await rotationJobManager.restart();
    res.json({ message: 'Rotation jobs restarted successfully' });
  } catch (error) {
    console.error('Restart rotation jobs error:', error);
    res.status(500).json({ error: 'Failed to restart rotation jobs' });
  }
});

/**
 * POST /api/rotation/jobs/test/queue-health
 * Test queue health check
 */
router.post('/jobs/test/queue-health', logAdminActionMiddleware('test_queue_health', 'system'), async (req, res) => {
  try {
    const result = await rotationJobManager.triggerQueueHealthCheck();
    res.json(result);
  } catch (error) {
    console.error('Test queue health error:', error);
    res.status(500).json({ error: 'Failed to test queue health check' });
  }
});

/**
 * GET /api/rotation/notifications
 * Get rotation notifications
 */
router.get('/notifications', logAdminActionMiddleware('view_rotation_notifications', 'notifications'), async (req, res) => {
  try {
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    
    const limit = parseInt(req.query.limit) || 50;
    const type = req.query.type;
    
    const whereClause = {};
    if (type) {
      whereClause.type = type;
    }
    
    const notifications = await prisma.rotationNotification.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      take: limit
    });
    
    res.json({ notifications });
  } catch (error) {
    console.error('Get rotation notifications error:', error);
    res.status(500).json({ error: 'Failed to get rotation notifications' });
  }
});

module.exports = router;
