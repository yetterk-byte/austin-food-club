const cron = require('node-cron');
const featuredRestaurant = require('./featuredRestaurant');
const restaurantSync = require('./restaurantSync');

class CronService {
  constructor() {
    this.jobs = new Map();
    this.isRunning = false;
  }

  // Start all cron jobs
  start() {
    if (this.isRunning) {
      console.log('Cron service is already running');
      return;
    }

    console.log('🕐 Starting cron service...');

    // Featured restaurant rotation - Every Tuesday at 9:00 AM
    this.scheduleFeaturedRotation();
    
    // Restaurant data sync - Every day at 2:00 AM
    this.scheduleRestaurantSync();
    
    // Cache cleanup - Every 6 hours
    this.scheduleCacheCleanup();

    this.isRunning = true;
    console.log('✅ Cron service started successfully');
  }

  // Stop all cron jobs
  stop() {
    console.log('🛑 Stopping cron service...');
    
    this.jobs.forEach((job, name) => {
      job.destroy();
      console.log(`Stopped job: ${name}`);
    });
    
    this.jobs.clear();
    this.isRunning = false;
    console.log('✅ Cron service stopped');
  }

  // Schedule featured restaurant rotation
  scheduleFeaturedRotation() {
    const job = cron.schedule('0 9 * * 2', async () => {
      console.log('🔄 Starting weekly featured restaurant rotation...');
      
      try {
        const weekStart = this.getWeekStart(new Date());
        const result = await featuredRestaurant.selectFeaturedRestaurant(weekStart);
        console.log('✅ Featured restaurant updated:', result);
        
        // Send notifications to users (if you implement this later)
        // await this.notifyUsersOfNewFeatured(result);
        
      } catch (error) {
        console.error('❌ Error rotating featured restaurant:', error);
      }
    }, {
      scheduled: false,
      timezone: 'America/Chicago' // Austin timezone
    });

    this.jobs.set('featured-rotation', job);
    job.start();
    console.log('📅 Featured restaurant rotation scheduled for Tuesdays at 9:00 AM CT');
  }

  // Schedule restaurant data sync
  scheduleRestaurantSync() {
    const job = cron.schedule('0 2 * * *', async () => {
      console.log('🔄 Starting daily restaurant data sync...');
      
      try {
        const result = await restaurantSync.syncAllRestaurants();
        console.log('✅ Restaurant data synced:', result);
      } catch (error) {
        console.error('❌ Error syncing restaurant data:', error);
      }
    }, {
      scheduled: false,
      timezone: 'America/Chicago'
    });

    this.jobs.set('restaurant-sync', job);
    job.start();
    console.log('📅 Restaurant sync scheduled for daily at 2:00 AM CT');
  }

  // Schedule cache cleanup
  scheduleCacheCleanup() {
    const job = cron.schedule('0 */6 * * *', async () => {
      console.log('🧹 Starting cache cleanup...');
      
      try {
        // Clear expired cache entries
        const { cache } = require('../middleware/cache');
        if (cache && typeof cache.clean === 'function') {
          cache.clean();
          console.log('✅ Cache cleaned');
        }
      } catch (error) {
        console.error('❌ Error cleaning cache:', error);
      }
    }, {
      scheduled: false,
      timezone: 'America/Chicago'
    });

    this.jobs.set('cache-cleanup', job);
    job.start();
    console.log('📅 Cache cleanup scheduled every 6 hours');
  }

  // Get status of all jobs
  getStatus() {
    const status = {
      isRunning: this.isRunning,
      jobs: {}
    };

    this.jobs.forEach((job, name) => {
      status.jobs[name] = {
        running: job.running,
        nextRun: job.nextDate ? job.nextDate().toISOString() : null
      };
    });

    return status;
  }

  // Manually trigger featured restaurant rotation
  async triggerFeaturedRotation() {
    console.log('🔄 Manually triggering featured restaurant rotation...');
    
    try {
      const weekStart = this.getWeekStart(new Date());
      const result = await featuredRestaurant.selectFeaturedRestaurant(weekStart);
      console.log('✅ Manual rotation completed:', result);
      return result;
    } catch (error) {
      console.error('❌ Error in manual rotation:', error);
      throw error;
    }
  }

  // Helper method to get week start date
  getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
    return new Date(d.setDate(diff));
  }

  // Manually trigger restaurant sync
  async triggerRestaurantSync() {
    console.log('🔄 Manually triggering restaurant sync...');
    
    try {
      const result = await restaurantSync.syncAllRestaurants();
      console.log('✅ Manual sync completed:', result);
      return result;
    } catch (error) {
      console.error('❌ Error in manual sync:', error);
      throw error;
    }
  }
}

module.exports = new CronService();
