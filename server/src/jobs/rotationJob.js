const cron = require('node-cron');
const rotationService = require('../services/rotationService');
const queueService = require('../services/queueService');

class RotationJobManager {
  constructor() {
    this.jobs = new Map();
    this.isInitialized = false;
  }

  /**
   * Initialize all rotation-related cron jobs
   */
  async initialize() {
    if (this.isInitialized) {
      console.log('⚠️ Rotation jobs already initialized');
      return;
    }

    try {
      // Job 1: Weekly rotation (Tuesdays at 10:00 AM)
      this.jobs.set('rotation_check', cron.schedule('0 10 * * 2', async () => {
        try {
          console.log('🔄 Tuesday 10:00 AM - Executing weekly rotation...');
          await rotationService.rotateToNextRestaurant('automatic', null, 'Weekly Tuesday rotation');
        } catch (error) {
          console.error('❌ Weekly rotation failed:', error);
        }
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // Job 2: Queue health check (every 2 hours for automatic maintenance)
      this.jobs.set('queue_health', cron.schedule('0 */2 * * *', async () => {
        try {
          console.log('🏥 Checking queue health and auto-maintaining...');
          await rotationService.checkQueueHealth();
          
          // Validate queue integrity
          const validation = await queueService.validateQueueIntegrity();
          if (!validation.isValid) {
            console.log('⚠️ Queue integrity issues detected:', validation.issues);
            // Auto-fix minor issues
            if (validation.issues.every(issue => issue.type === 'position_gap')) {
              await queueService.fixQueueIntegrity('system');
              console.log('✅ Queue integrity auto-fixed');
            }
          }
        } catch (error) {
          console.error('❌ Queue health check failed:', error);
        }
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // Job 3: Daily rotation analytics (every day at 2 AM)
      this.jobs.set('daily_analytics', cron.schedule('0 2 * * *', async () => {
        try {
          console.log('📊 Generating daily rotation analytics...');
          await this.generateDailyAnalytics();
        } catch (error) {
          console.error('❌ Daily analytics failed:', error);
        }
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // Job 4: Weekly queue planning reminder (Fridays at 10 AM)
      this.jobs.set('weekly_reminder', cron.schedule('0 10 * * 5', async () => {
        try {
          console.log('📅 Sending weekly queue planning reminder...');
          await this.sendWeeklyPlanningReminder();
        } catch (error) {
          console.error('❌ Weekly reminder failed:', error);
        }
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // Job 5: Cleanup old rotation history (monthly on 1st at midnight)
      this.jobs.set('cleanup_history', cron.schedule('0 0 1 * *', async () => {
        try {
          console.log('🧹 Cleaning up old rotation history...');
          await this.cleanupOldHistory();
        } catch (error) {
          console.error('❌ History cleanup failed:', error);
        }
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      this.isInitialized = true;
      console.log('✅ Rotation cron jobs initialized successfully');
      console.log(`📋 Active jobs: ${Array.from(this.jobs.keys()).join(', ')}`);

    } catch (error) {
      console.error('❌ Failed to initialize rotation jobs:', error);
    }
  }

  /**
   * Generate daily analytics and insights
   */
  async generateDailyAnalytics() {
    try {
      const { PrismaClient } = require('@prisma/client');
      const prisma = new PrismaClient();

      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Get yesterday's metrics
      const [rsvpCount, visitCount, currentRestaurant, queueStats] = await Promise.all([
        prisma.rSVP.count({
          where: {
            createdAt: {
              gte: yesterday,
              lt: today
            }
          }
        }),
        prisma.verifiedVisit.count({
          where: {
            createdAt: {
              gte: yesterday,
              lt: today
            }
          }
        }),
        prisma.restaurant.findFirst({
          where: { isFeatured: true },
          select: { id: true, name: true, featuredDate: true }
        }),
        queueService.getQueueStats()
      ]);

      // Store daily analytics
      await prisma.rotationNotification.create({
        data: {
          type: 'ROTATION_COMPLETE', // Using as analytics type
          recipientType: 'admin',
          title: 'Daily Rotation Analytics',
          message: `Yesterday: ${rsvpCount} RSVPs, ${visitCount} visits. Queue: ${queueStats.totalPending} pending, ${queueStats.queueHealth} health.`,
          status: 'sent'
        }
      });

      console.log(`📊 Daily analytics: ${rsvpCount} RSVPs, ${visitCount} visits, Queue health: ${queueStats.queueHealth}`);

    } catch (error) {
      console.error('❌ Error generating daily analytics:', error);
    }
  }

  /**
   * Send weekly queue planning reminder to admins
   */
  async sendWeeklyPlanningReminder() {
    try {
      const queueStats = await queueService.getQueueStats();
      const preview = await rotationService.getRotationPreview(4);

      let message = `Weekly Queue Planning Reminder:\n\n`;
      message += `• Queue Status: ${queueStats.totalPending} restaurants pending\n`;
      message += `• Queue Health: ${queueStats.queueHealth}\n`;
      message += `• Weeks Planned: ${preview.totalWeeksPlanned}\n\n`;

      if (queueStats.queueHealth === 'critical' || queueStats.queueHealth === 'low') {
        message += `⚠️ Action needed: Queue is running ${queueStats.queueHealth}. Please add more restaurants.\n`;
      }

      message += `Next 4 weeks:\n`;
      preview.preview.forEach(week => {
        message += `• Week ${week.week}: ${week.restaurant.name} (${week.estimatedDate.toLocaleDateString()})\n`;
      });

      await rotationService.sendNotification('QUEUE_LOW', {
        title: 'Weekly Queue Planning Reminder',
        message,
        recipientType: 'admin'
      });

      console.log('📅 Weekly planning reminder sent');

    } catch (error) {
      console.error('❌ Error sending weekly reminder:', error);
    }
  }

  /**
   * Clean up old rotation history (keep last 6 months)
   */
  async cleanupOldHistory() {
    try {
      const { PrismaClient } = require('@prisma/client');
      const prisma = new PrismaClient();

      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

      // Clean up old rotation history
      const deletedHistory = await prisma.rotationHistory.deleteMany({
        where: {
          endDate: {
            lt: sixMonthsAgo
          }
        }
      });

      // Clean up old notifications
      const deletedNotifications = await prisma.rotationNotification.deleteMany({
        where: {
          createdAt: {
            lt: sixMonthsAgo
          }
        }
      });

      console.log(`🧹 Cleanup complete: ${deletedHistory.count} history records, ${deletedNotifications.count} notifications deleted`);

    } catch (error) {
      console.error('❌ Error during cleanup:', error);
    }
  }

  /**
   * Stop a specific job
   */
  stopJob(jobName) {
    const job = this.jobs.get(jobName);
    if (job) {
      job.stop();
      console.log(`⏹️ Stopped job: ${jobName}`);
    } else {
      console.log(`⚠️ Job not found: ${jobName}`);
    }
  }

  /**
   * Start a specific job
   */
  startJob(jobName) {
    const job = this.jobs.get(jobName);
    if (job) {
      job.start();
      console.log(`▶️ Started job: ${jobName}`);
    } else {
      console.log(`⚠️ Job not found: ${jobName}`);
    }
  }

  /**
   * Get status of all jobs
   */
  getJobStatus() {
    const status = {};
    for (const [name, job] of this.jobs) {
      status[name] = {
        running: job.running || false,
        scheduled: job.scheduled || false
      };
    }
    return status;
  }

  /**
   * Manually trigger rotation check (for testing)
   */
  async triggerRotationCheck() {
    try {
      console.log('🔄 Manual rotation check triggered');
      await rotationService.checkRotationSchedule();
      return { success: true, message: 'Rotation check completed' };
    } catch (error) {
      console.error('❌ Manual rotation check failed:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Manually trigger queue health check (for testing)
   */
  async triggerQueueHealthCheck() {
    try {
      console.log('🏥 Manual queue health check triggered');
      await rotationService.checkQueueHealth();
      const validation = await queueService.validateQueueIntegrity();
      return { 
        success: true, 
        message: 'Queue health check completed',
        queueValid: validation.isValid,
        issues: validation.issues
      };
    } catch (error) {
      console.error('❌ Manual queue health check failed:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Stop all jobs and cleanup
   */
  destroy() {
    for (const [name, job] of this.jobs) {
      job.stop();
      job.destroy();
      console.log(`🛑 Destroyed job: ${name}`);
    }
    this.jobs.clear();
    this.isInitialized = false;
    console.log('🛑 All rotation jobs stopped');
  }

  /**
   * Restart all jobs
   */
  async restart() {
    this.destroy();
    await this.initialize();
    console.log('🔄 All rotation jobs restarted');
  }

  /**
   * Get next scheduled run times for all jobs
   */
  getNextRunTimes() {
    const nextRuns = {};
    for (const [name, job] of this.jobs) {
      try {
        // This is a simplified approach - actual implementation would depend on node-cron internals
        nextRuns[name] = 'Schedule information not available';
      } catch (error) {
        nextRuns[name] = 'Error getting schedule';
      }
    }
    return nextRuns;
  }
}

// Export singleton instance
module.exports = new RotationJobManager();
