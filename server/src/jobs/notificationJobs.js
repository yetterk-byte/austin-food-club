const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');
const pushNotificationService = require('../services/pushNotificationService');

// Create a singleton Prisma client instance
let prisma;
const getPrismaClient = () => {
  if (!prisma) {
    prisma = new PrismaClient();
  }
  return prisma;
};

/**
 * Notification Cron Jobs for Austin Food Club
 */

class NotificationJobs {
  constructor() {
    this.jobs = new Map();
    this.isInitialized = false;
  }

  /**
   * Initialize all notification jobs
   */
  initialize() {
    if (this.isInitialized) {
      console.log('📱 Notification jobs already initialized');
      return;
    }

    try {
      // Weekly announcement job - Monday 9 AM CT
      this.jobs.set('weekly_announcement', cron.schedule('0 9 * * MON', async () => {
        await this.sendWeeklyAnnouncement();
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // RSVP reminders job - every 30 minutes
      this.jobs.set('rsvp_reminders', cron.schedule('*/30 * * * *', async () => {
        await this.sendRSVPReminders();
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // Visit reminders job - daily at 6 PM CT
      this.jobs.set('visit_reminders', cron.schedule('0 18 * * *', async () => {
        await this.sendVisitReminders();
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      // Cleanup job - weekly on Sunday at 2 AM CT
      this.jobs.set('cleanup', cron.schedule('0 2 * * SUN', async () => {
        await this.cleanupNotifications();
      }, {
        scheduled: true,
        timezone: 'America/Chicago'
      }));

      this.isInitialized = true;
      console.log('✅ Notification cron jobs initialized successfully');
      console.log('📋 Active notification jobs:', Array.from(this.jobs.keys()));
    } catch (error) {
      console.error('❌ Error initializing notification jobs:', error);
    }
  }

  /**
   * Send weekly restaurant announcement
   */
  async sendWeeklyAnnouncement() {
    try {
      console.log('📢 Running weekly announcement job...');
      
      // Get current featured restaurant
      const prismaClient = getPrismaClient();
      const currentRestaurant = await prismaClient.restaurant.findFirst({
        where: { isFeatured: true },
        include: { city: true }
      });

      if (!currentRestaurant) {
        console.log('⚠️ No featured restaurant found for weekly announcement');
        return;
      }

      const results = await pushNotificationService.sendWeeklyAnnouncement(currentRestaurant);
      
      console.log(`📊 Weekly announcement results: ${results.filter(r => r.sent).length}/${results.length} sent`);
    } catch (error) {
      console.error('❌ Error in weekly announcement job:', error);
    }
  }

  /**
   * Send RSVP reminders
   */
  async sendRSVPReminders() {
    try {
      console.log('⏰ Running RSVP reminder job...');
      
      // Get RSVPs that need reminders (based on user preferences)
      const upcomingRsvps = await this.getUpcomingRsvps();
      
      if (upcomingRsvps.length === 0) {
        console.log('📅 No upcoming RSVPs need reminders');
        return;
      }

      const results = [];
      for (const rsvp of upcomingRsvps) {
        const result = await pushNotificationService.sendRSVPReminder(rsvp);
        results.push(result);
      }

      console.log(`📊 RSVP reminder results: ${results.filter(r => r.sent).length}/${results.length} sent`);
    } catch (error) {
      console.error('❌ Error in RSVP reminder job:', error);
    }
  }

  /**
   * Send visit reminders for recent RSVPs
   */
  async sendVisitReminders() {
    try {
      console.log('📸 Running visit reminder job...');
      
      // Get users who had RSVPs yesterday but haven't verified visits
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      
      const unverifiedVisits = await this.getUnverifiedVisits(yesterday);
      
      if (unverifiedVisits.length === 0) {
        console.log('✅ No unverified visits need reminders');
        return;
      }

      const results = [];
      for (const visit of unverifiedVisits) {
        const result = await pushNotificationService.sendVisitReminder(visit.userId, {
          restaurantId: visit.restaurantId,
          restaurantName: visit.restaurant.name
        });
        results.push(result);
      }

      console.log(`📊 Visit reminder results: ${results.filter(r => r.sent).length}/${results.length} sent`);
    } catch (error) {
      console.error('❌ Error in visit reminder job:', error);
    }
  }

  /**
   * Cleanup old notifications and subscriptions
   */
  async cleanupNotifications() {
    try {
      console.log('🧹 Running notification cleanup job...');
      
      // Clean up old notification logs (older than 30 days)
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      
      const prismaClient = getPrismaClient();
      const deletedLogs = await prismaClient.notificationLog.deleteMany({
        where: {
          createdAt: { lt: thirtyDaysAgo }
        }
      });

      // Clean up inactive subscriptions
      const subscriptionManager = require('../services/subscriptionManager');
      const cleanupResult = await subscriptionManager.cleanupSubscriptions();

      console.log(`🧹 Cleanup complete: ${deletedLogs.count} logs, ${cleanupResult.count} subscriptions`);
    } catch (error) {
      console.error('❌ Error in cleanup job:', error);
    }
  }

  /**
   * Manual job triggers (for testing and admin use)
   */
  async triggerWeeklyAnnouncement() {
    console.log('🔧 Manually triggering weekly announcement...');
    await this.sendWeeklyAnnouncement();
  }

  async triggerRSVPReminders() {
    console.log('🔧 Manually triggering RSVP reminders...');
    await this.sendRSVPReminders();
  }

  async triggerVisitReminders() {
    console.log('🔧 Manually triggering visit reminders...');
    await this.sendVisitReminders();
  }

  /**
   * Helper methods
   */
  async getUpcomingRsvps() {
    try {
      // Ensure Prisma client is connected
      const prismaClient = getPrismaClient();
      if (!prismaClient) {
        console.error('❌ Prisma client not initialized');
        return [];
      }
      
      // Get RSVPs for today and tomorrow that need reminders
      const now = new Date();
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      // Get day names
      const todayName = now.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
      const tomorrowName = tomorrow.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
      
      return await prismaClient.rsvp.findMany({
      where: {
        day: { in: [todayName, tomorrowName] },
        status: 'confirmed',
        user: {
          notificationPreferences: {
            rsvpReminders: true,
            pushEnabled: true
          }
        }
      },
      include: {
        restaurant: true,
        user: {
          include: {
            notificationPreferences: true
          }
        }
      }
    });
    } catch (error) {
      console.error('❌ Error getting upcoming RSVPs:', error);
      return [];
    }
  }

  async getUnverifiedVisits(date) {
    const dayName = date.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    const prismaClient = getPrismaClient();
    
    return await prismaClient.rsvp.findMany({
      where: {
        day: dayName,
        status: 'confirmed',
        user: {
          notificationPreferences: {
            visitReminders: true,
            pushEnabled: true
          },
          verifiedVisits: {
            none: {
              visitDate: {
                gte: new Date(date.getFullYear(), date.getMonth(), date.getDate()),
                lt: new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1)
              }
            }
          }
        }
      },
      include: {
        restaurant: true,
        user: {
          include: {
            notificationPreferences: true
          }
        }
      }
    });
  }

  /**
   * Stop all jobs
   */
  stopAll() {
    this.jobs.forEach((job, name) => {
      job.stop();
      console.log(`🛑 Stopped notification job: ${name}`);
    });
    this.jobs.clear();
    this.isInitialized = false;
  }

  /**
   * Get job status
   */
  getStatus() {
    return {
      initialized: this.isInitialized,
      activeJobs: Array.from(this.jobs.keys()),
      jobCount: this.jobs.size
    };
  }
}

// Export singleton instance
module.exports = new NotificationJobs();
