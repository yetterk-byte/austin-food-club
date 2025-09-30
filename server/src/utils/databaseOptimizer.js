/**
 * Database Optimization Script
 * Analyzes and optimizes database queries, adds indexes, and improves performance
 */

const { PrismaClient } = require('@prisma/client');

class DatabaseOptimizer {
  constructor() {
    this.prisma = new PrismaClient();
    this.optimizations = [];
  }

  /**
   * Run all database optimizations
   */
  async optimize() {
    console.log('🔧 Starting Database Optimization...\n');

    const optimizations = [
      { name: 'Add Missing Indexes', fn: () => this.addMissingIndexes() },
      { name: 'Analyze Query Performance', fn: () => this.analyzeQueryPerformance() },
      { name: 'Optimize Restaurant Queries', fn: () => this.optimizeRestaurantQueries() },
      { name: 'Optimize User Queries', fn: () => this.optimizeUserQueries() },
      { name: 'Optimize Social Features', fn: () => this.optimizeSocialQueries() },
      { name: 'Clean Up Orphaned Records', fn: () => this.cleanupOrphanedRecords() }
    ];

    for (const optimization of optimizations) {
      try {
        console.log(`📋 ${optimization.name}...`);
        await optimization.fn();
        console.log(`✅ ${optimization.name} completed\n`);
      } catch (error) {
        console.log(`❌ ${optimization.name} failed: ${error.message}\n`);
      }
    }

    this.generateReport();
  }

  /**
   * Add missing database indexes
   */
  async addMissingIndexes() {
    const indexes = [
      // Restaurant indexes
      {
        name: 'restaurant_city_featured',
        query: 'CREATE INDEX IF NOT EXISTS idx_restaurant_city_featured ON "Restaurant" ("cityId", "isFeatured") WHERE "isFeatured" = true;',
        description: 'Index for finding featured restaurants by city'
      },
      {
        name: 'restaurant_cuisine_rating',
        query: 'CREATE INDEX IF NOT EXISTS idx_restaurant_cuisine_rating ON "Restaurant" ("cuisine", "rating" DESC);',
        description: 'Index for cuisine-based searches sorted by rating'
      },
      {
        name: 'restaurant_price_range',
        query: 'CREATE INDEX IF NOT EXISTS idx_restaurant_price_range ON "Restaurant" ("priceRange", "rating" DESC);',
        description: 'Index for price range searches'
      },
      {
        name: 'restaurant_featured_date',
        query: 'CREATE INDEX IF NOT EXISTS idx_restaurant_featured_date ON "Restaurant" ("featuredDate" DESC) WHERE "featuredDate" IS NOT NULL;',
        description: 'Index for featured restaurant history'
      },

      // User indexes
      {
        name: 'user_phone',
        query: 'CREATE UNIQUE INDEX IF NOT EXISTS idx_user_phone ON "User" ("phone");',
        description: 'Unique index for phone number lookups'
      },
      {
        name: 'user_supabase_id',
        query: 'CREATE UNIQUE INDEX IF NOT EXISTS idx_user_supabase_id ON "User" ("supabaseId") WHERE "supabaseId" IS NOT NULL;',
        description: 'Unique index for Supabase ID lookups'
      },
      {
        name: 'user_last_login',
        query: 'CREATE INDEX IF NOT EXISTS idx_user_last_login ON "User" ("lastLogin" DESC);',
        description: 'Index for active user queries'
      },

      // RSVP indexes
      {
        name: 'rsvp_user_restaurant',
        query: 'CREATE INDEX IF NOT EXISTS idx_rsvp_user_restaurant ON "RSVP" ("userId", "restaurantId");',
        description: 'Index for user-restaurant RSVP lookups'
      },
      {
        name: 'rsvp_day_status',
        query: 'CREATE INDEX IF NOT EXISTS idx_rsvp_day_status ON "RSVP" ("day", "status");',
        description: 'Index for day-based RSVP queries'
      },
      {
        name: 'rsvp_created_at',
        query: 'CREATE INDEX IF NOT EXISTS idx_rsvp_created_at ON "RSVP" ("createdAt" DESC);',
        description: 'Index for recent RSVP queries'
      },

      // Wishlist indexes
      {
        name: 'wishlist_user_restaurant',
        query: 'CREATE UNIQUE INDEX IF NOT EXISTS idx_wishlist_user_restaurant ON "Wishlist" ("userId", "restaurantId");',
        description: 'Unique index for user-restaurant wishlist entries'
      },
      {
        name: 'wishlist_created_at',
        query: 'CREATE INDEX IF NOT EXISTS idx_wishlist_created_at ON "Wishlist" ("createdAt" DESC);',
        description: 'Index for recent wishlist queries'
      },

      // Verified visits indexes
      {
        name: 'verified_visit_user_restaurant',
        query: 'CREATE INDEX IF NOT EXISTS idx_verified_visit_user_restaurant ON "VerifiedVisit" ("userId", "restaurantId");',
        description: 'Index for user-restaurant visit lookups'
      },
      {
        name: 'verified_visit_verification_date',
        query: 'CREATE INDEX IF NOT EXISTS idx_verified_visit_verification_date ON "VerifiedVisit" ("verificationDate" DESC);',
        description: 'Index for recent visit queries'
      },

      // Notification indexes
      {
        name: 'notification_log_created_at',
        query: 'CREATE INDEX IF NOT EXISTS idx_notification_log_created_at ON "NotificationLog" ("createdAt" DESC);',
        description: 'Index for notification log cleanup'
      },
      {
        name: 'notification_log_user_type',
        query: 'CREATE INDEX IF NOT EXISTS idx_notification_log_user_type ON "NotificationLog" ("userId", "type");',
        description: 'Index for user notification queries'
      }
    ];

    for (const index of indexes) {
      try {
        await this.prisma.$executeRawUnsafe(index.query);
        this.optimizations.push({
          type: 'index',
          name: index.name,
          description: index.description,
          status: 'created'
        });
        console.log(`  ✅ Created index: ${index.name}`);
      } catch (error) {
        console.log(`  ⚠️ Index ${index.name} may already exist: ${error.message}`);
      }
    }
  }

  /**
   * Analyze query performance
   */
  async analyzeQueryPerformance() {
    const queries = [
      {
        name: 'Featured Restaurant Query',
        query: () => this.prisma.restaurant.findFirst({
          where: { isFeatured: true },
          include: { city: true }
        })
      },
      {
        name: 'User RSVPs Query',
        query: () => this.prisma.rSVP.findMany({
          where: { status: 'confirmed' },
          include: { user: true, restaurant: true }
        })
      },
      {
        name: 'Restaurant Search Query',
        query: () => this.prisma.restaurant.findMany({
          where: { 
            city: { slug: 'austin' },
            rating: { gte: 4.0 }
          },
          orderBy: { rating: 'desc' },
          take: 10
        })
      }
    ];

    for (const queryTest of queries) {
      const startTime = Date.now();
      try {
        await queryTest.query();
        const duration = Date.now() - startTime;
        
        this.optimizations.push({
          type: 'query_analysis',
          name: queryTest.name,
          duration,
          status: duration < 100 ? 'fast' : duration < 500 ? 'moderate' : 'slow'
        });
        
        console.log(`  📊 ${queryTest.name}: ${duration}ms`);
      } catch (error) {
        console.log(`  ❌ ${queryTest.name} failed: ${error.message}`);
      }
    }
  }

  /**
   * Optimize restaurant-related queries
   */
  async optimizeRestaurantQueries() {
    // Add composite indexes for common restaurant queries
    const restaurantOptimizations = [
      {
        name: 'restaurant_city_cuisine_rating',
        query: 'CREATE INDEX IF NOT EXISTS idx_restaurant_city_cuisine_rating ON "Restaurant" ("cityId", "cuisine", "rating" DESC);',
        description: 'Composite index for city + cuisine + rating queries'
      },
      {
        name: 'restaurant_city_price_rating',
        query: 'CREATE INDEX IF NOT EXISTS idx_restaurant_city_price_rating ON "Restaurant" ("cityId", "priceRange", "rating" DESC);',
        description: 'Composite index for city + price + rating queries'
      }
    ];

    for (const opt of restaurantOptimizations) {
      try {
        await this.prisma.$executeRawUnsafe(opt.query);
        this.optimizations.push({
          type: 'restaurant_optimization',
          name: opt.name,
          description: opt.description,
          status: 'applied'
        });
        console.log(`  ✅ Applied: ${opt.name}`);
      } catch (error) {
        console.log(`  ⚠️ ${opt.name}: ${error.message}`);
      }
    }
  }

  /**
   * Optimize user-related queries
   */
  async optimizeUserQueries() {
    // Add indexes for user activity queries
    const userOptimizations = [
      {
        name: 'user_activity_composite',
        query: 'CREATE INDEX IF NOT EXISTS idx_user_activity ON "User" ("lastLogin" DESC, "createdAt" DESC);',
        description: 'Composite index for user activity queries'
      }
    ];

    for (const opt of userOptimizations) {
      try {
        await this.prisma.$executeRawUnsafe(opt.query);
        this.optimizations.push({
          type: 'user_optimization',
          name: opt.name,
          description: opt.description,
          status: 'applied'
        });
        console.log(`  ✅ Applied: ${opt.name}`);
      } catch (error) {
        console.log(`  ⚠️ ${opt.name}: ${error.message}`);
      }
    }
  }

  /**
   * Optimize social feature queries
   */
  async optimizeSocialQueries() {
    // Add indexes for social features
    const socialOptimizations = [
      {
        name: 'social_activity_composite',
        query: 'CREATE INDEX IF NOT EXISTS idx_social_activity ON "RSVP" ("createdAt" DESC, "status") WHERE "status" = \'confirmed\';',
        description: 'Index for social activity feeds'
      },
      {
        name: 'verified_visits_social',
        query: 'CREATE INDEX IF NOT EXISTS idx_verified_visits_social ON "VerifiedVisit" ("verificationDate" DESC, "userId");',
        description: 'Index for social visit feeds'
      }
    ];

    for (const opt of socialOptimizations) {
      try {
        await this.prisma.$executeRawUnsafe(opt.query);
        this.optimizations.push({
          type: 'social_optimization',
          name: opt.name,
          description: opt.description,
          status: 'applied'
        });
        console.log(`  ✅ Applied: ${opt.name}`);
      } catch (error) {
        console.log(`  ⚠️ ${opt.name}: ${error.message}`);
      }
    }
  }

  /**
   * Clean up orphaned records
   */
  async cleanupOrphanedRecords() {
    const cleanupQueries = [
      {
        name: 'Clean orphaned RSVPs',
        query: 'DELETE FROM "RSVP" WHERE "userId" NOT IN (SELECT "id" FROM "User");',
        description: 'Remove RSVPs for non-existent users'
      },
      {
        name: 'Clean orphaned wishlist entries',
        query: 'DELETE FROM "Wishlist" WHERE "userId" NOT IN (SELECT "id" FROM "User");',
        description: 'Remove wishlist entries for non-existent users'
      },
      {
        name: 'Clean orphaned verified visits',
        query: 'DELETE FROM "VerifiedVisit" WHERE "userId" NOT IN (SELECT "id" FROM "User");',
        description: 'Remove verified visits for non-existent users'
      }
    ];

    for (const cleanup of cleanupQueries) {
      try {
        const result = await this.prisma.$executeRawUnsafe(cleanup.query);
        this.optimizations.push({
          type: 'cleanup',
          name: cleanup.name,
          description: cleanup.description,
          recordsAffected: result,
          status: 'completed'
        });
        console.log(`  🧹 ${cleanup.name}: ${result} records cleaned`);
      } catch (error) {
        console.log(`  ⚠️ ${cleanup.name}: ${error.message}`);
      }
    }
  }

  /**
   * Generate optimization report
   */
  generateReport() {
    console.log('\n📊 Database Optimization Report');
    console.log('================================');

    const byType = this.optimizations.reduce((acc, opt) => {
      acc[opt.type] = (acc[opt.type] || 0) + 1;
      return acc;
    }, {});

    console.log('\n📈 Optimizations Applied:');
    Object.entries(byType).forEach(([type, count]) => {
      console.log(`  ${type}: ${count}`);
    });

    const indexes = this.optimizations.filter(opt => opt.type === 'index');
    if (indexes.length > 0) {
      console.log('\n🗂️ Indexes Created:');
      indexes.forEach(index => {
        console.log(`  ✅ ${index.name}: ${index.description}`);
      });
    }

    const slowQueries = this.optimizations.filter(opt => opt.status === 'slow');
    if (slowQueries.length > 0) {
      console.log('\n🐌 Slow Queries Detected:');
      slowQueries.forEach(query => {
        console.log(`  ⚠️ ${query.name}: ${query.duration}ms`);
      });
    }

    console.log('\n🎯 Database optimization complete!');
    console.log('💡 Consider running VACUUM ANALYZE for PostgreSQL to update statistics.');
  }

  /**
   * Close database connection
   */
  async close() {
    await this.prisma.$disconnect();
  }
}

module.exports = DatabaseOptimizer;

