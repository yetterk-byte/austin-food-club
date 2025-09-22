const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { requireAdmin, logAdminActionMiddleware, logAdminAction } = require('../middleware/adminAuth');
const yelpService = require('../services/yelpService');

const router = express.Router();
const prisma = new PrismaClient();

// Apply admin authentication to all routes
router.use(requireAdmin);

/**
 * GET /api/admin/dashboard
 * Get dashboard statistics
 */
router.get('/dashboard', logAdminActionMiddleware('view_dashboard', 'dashboard'), async (req, res) => {
  try {
    // Get comprehensive dashboard stats
    const [
      totalUsers,
      totalRestaurants,
      totalRSVPs,
      totalVerifiedVisits,
      activeFriendships,
      queueLength,
      currentRestaurant,
      thisWeekRSVPs,
      recentAdminActions
    ] = await Promise.all([
      prisma.user.count(),
      prisma.restaurant.count(),
      prisma.rSVP.count(),
      prisma.verifiedVisit.count(),
      prisma.friendship.count({ where: { status: 'accepted' } }),
      prisma.restaurantQueue.count({ where: { status: 'PENDING' } }),
      prisma.restaurant.findFirst({ where: { isFeatured: true } }),
      prisma.rSVP.count({
        where: {
          createdAt: {
            gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000)
          }
        }
      }),
      prisma.adminLog.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: { admin: { select: { name: true } } }
      })
    ]);

    // Get RSVP breakdown by day for this week
    const rsvpsByDay = await prisma.rSVP.groupBy({
      by: ['day'],
      _count: { day: true },
      where: {
        createdAt: {
          gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000)
        }
      }
    });

    res.json({
      stats: {
        totalUsers,
        totalRestaurants,
        totalRSVPs,
        totalVerifiedVisits,
        activeFriendships,
        queueLength,
        thisWeekRSVPs
      },
      currentRestaurant,
      rsvpsByDay: rsvpsByDay.reduce((acc, item) => {
        acc[item.day] = item._count.day;
        return acc;
      }, {}),
      recentActions: recentAdminActions
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

/**
 * GET /api/admin/queue
 * Get restaurant queue
 */
router.get('/queue', logAdminActionMiddleware('view_queue', 'queue'), async (req, res) => {
  try {
    const queue = await prisma.restaurantQueue.findMany({
      orderBy: { position: 'asc' },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            address: true,
            imageUrl: true,
            rating: true,
            price: true,
            categories: true,
            yelpUrl: true
          }
        },
        admin: {
          select: { name: true, email: true }
        }
      }
    });

    res.json({ queue });
  } catch (error) {
    console.error('Queue fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch restaurant queue' });
  }
});

/**
 * POST /api/admin/queue
 * Add restaurant to queue
 */
router.post('/queue', logAdminActionMiddleware('add_to_queue', 'restaurant'), async (req, res) => {
  try {
    const { restaurantId, notes, scheduledWeek } = req.body;

    if (!restaurantId) {
      return res.status(400).json({ error: 'Restaurant ID required' });
    }

    // Check if restaurant exists
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId }
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // Check if restaurant is already in queue
    const existingQueueItem = await prisma.restaurantQueue.findFirst({
      where: { restaurantId, status: 'PENDING' }
    });

    if (existingQueueItem) {
      return res.status(400).json({ error: 'Restaurant already in queue' });
    }

    // Check if restaurant is currently featured
    const currentFeatured = await prisma.restaurant.findFirst({
      where: { isFeatured: true }
    });

    if (currentFeatured && currentFeatured.id === restaurantId) {
      return res.status(400).json({ error: 'Cannot add currently featured restaurant to queue' });
    }

    // Get next position in queue
    const lastPosition = await prisma.restaurantQueue.findFirst({
      orderBy: { position: 'desc' },
      select: { position: true }
    });

    const nextPosition = (lastPosition?.position || 0) + 1;

    // Handle demo admin - create a demo user if needed
    let adminId = req.admin.id;
    if (adminId === 'demo-admin') {
      // Create or find demo admin user
      let demoUser = await prisma.user.findUnique({
        where: { email: 'admin@austinfoodclub.com' }
      });
      
      if (!demoUser) {
        demoUser = await prisma.user.create({
          data: {
            supabaseId: 'demo-admin-supabase-id',
            email: 'admin@austinfoodclub.com',
            name: 'Austin Food Club Admin',
            isAdmin: true,
            emailVerified: true,
            provider: 'demo'
          }
        });
      }
      adminId = demoUser.id;
    }

    // Add to queue
    const queueItem = await prisma.restaurantQueue.create({
      data: {
        restaurantId,
        position: nextPosition,
        addedBy: adminId,
        notes,
        scheduledWeek: scheduledWeek ? new Date(scheduledWeek) : null
      },
      include: {
        restaurant: {
          select: {
            name: true,
            address: true,
            imageUrl: true,
            rating: true,
            price: true
          }
        }
      }
    });

    res.json({ queueItem });
  } catch (error) {
    console.error('Add to queue error:', error);
    res.status(500).json({ error: 'Failed to add restaurant to queue' });
  }
});

/**
 * PUT /api/admin/queue/:id
 * Update queue item position or details
 */
router.put('/queue/:id', logAdminActionMiddleware('update_queue_item', 'queue_item'), async (req, res) => {
  try {
    const { id } = req.params;
    const { position, notes, scheduledWeek, status } = req.body;

    const queueItem = await prisma.restaurantQueue.findUnique({
      where: { id }
    });

    if (!queueItem) {
      return res.status(404).json({ error: 'Queue item not found' });
    }

    // If position is being changed, handle reordering
    if (position !== undefined && position !== queueItem.position) {
      await reorderQueue(queueItem.position, position);
    }

    // Update the queue item
    const updatedItem = await prisma.restaurantQueue.update({
      where: { id },
      data: {
        position: position || queueItem.position,
        notes: notes !== undefined ? notes : queueItem.notes,
        scheduledWeek: scheduledWeek ? new Date(scheduledWeek) : queueItem.scheduledWeek,
        status: status || queueItem.status
      },
      include: {
        restaurant: {
          select: {
            name: true,
            address: true,
            imageUrl: true,
            rating: true,
            price: true
          }
        }
      }
    });

    res.json({ queueItem: updatedItem });
  } catch (error) {
    console.error('Update queue item error:', error);
    res.status(500).json({ error: 'Failed to update queue item' });
  }
});

/**
 * DELETE /api/admin/queue/:id
 * Remove restaurant from queue
 */
router.delete('/queue/:id', logAdminActionMiddleware('remove_from_queue', 'queue_item'), async (req, res) => {
  try {
    const { id } = req.params;

    const queueItem = await prisma.restaurantQueue.findUnique({
      where: { id },
      include: { restaurant: { select: { name: true } } }
    });

    if (!queueItem) {
      return res.status(404).json({ error: 'Queue item not found' });
    }

    // Remove from queue
    await prisma.restaurantQueue.delete({
      where: { id }
    });

    // Reorder remaining items to fill the gap
    await prisma.restaurantQueue.updateMany({
      where: { position: { gt: queueItem.position } },
      data: { position: { decrement: 1 } }
    });

    res.json({ message: 'Restaurant removed from queue', restaurantName: queueItem.restaurant.name });
  } catch (error) {
    console.error('Remove from queue error:', error);
    res.status(500).json({ error: 'Failed to remove restaurant from queue' });
  }
});

/**
 * POST /api/admin/queue/reorder
 * Bulk reorder queue
 */
router.post('/queue/reorder', logAdminActionMiddleware('reorder_queue', 'queue'), async (req, res) => {
  try {
    const { newOrder } = req.body; // Array of { id, position } objects

    if (!Array.isArray(newOrder)) {
      return res.status(400).json({ error: 'newOrder must be an array' });
    }

    // Update positions in a transaction
    await prisma.$transaction(async (tx) => {
      for (const item of newOrder) {
        await tx.restaurantQueue.update({
          where: { id: item.id },
          data: { position: item.position }
        });
      }
    });

    res.json({ message: 'Queue reordered successfully' });
  } catch (error) {
    console.error('Reorder queue error:', error);
    res.status(500).json({ error: 'Failed to reorder queue' });
  }
});

/**
 * PUT /api/admin/current-restaurant
 * Override current featured restaurant
 */
router.put('/current-restaurant', logAdminActionMiddleware('set_current_restaurant', 'restaurant'), async (req, res) => {
  try {
    const { restaurantId } = req.body;

    if (!restaurantId) {
      return res.status(400).json({ error: 'Restaurant ID required' });
    }

    // Unfeature current restaurant
    await prisma.restaurant.updateMany({
      where: { isFeatured: true },
      data: { isFeatured: false }
    });

    // Feature new restaurant
    const restaurant = await prisma.restaurant.update({
      where: { id: restaurantId },
      data: {
        isFeatured: true,
        featuredWeek: new Date(),
        featuredDate: new Date()
      }
    });

    res.json({ restaurant, message: 'Current restaurant updated successfully' });
  } catch (error) {
    console.error('Set current restaurant error:', error);
    res.status(500).json({ error: 'Failed to set current restaurant' });
  }
});

/**
 * GET /api/admin/users
 * List all users with stats
 */
router.get('/users', logAdminActionMiddleware('view_users', 'users'), async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = search ? {
      OR: [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ]
    } : {};

    const [users, totalCount] = await Promise.all([
      prisma.user.findMany({
        where: whereClause,
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          isAdmin: true,
          emailVerified: true,
          lastLogin: true,
          createdAt: true,
          _count: {
            select: {
              rsvps: true,
              verifiedVisits: true,
              friendships: true
            }
          }
        },
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: parseInt(limit)
      }),
      prisma.user.count({ where: whereClause })
    ]);

    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    });
  } catch (error) {
    console.error('Users fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

/**
 * PUT /api/admin/users/:id
 * Update user (make admin, etc.)
 */
router.put('/users/:id', logAdminActionMiddleware('update_user', 'user'), async (req, res) => {
  try {
    const { id } = req.params;
    const { isAdmin, emailVerified } = req.body;

    const user = await prisma.user.update({
      where: { id },
      data: {
        isAdmin: isAdmin !== undefined ? isAdmin : undefined,
        emailVerified: emailVerified !== undefined ? emailVerified : undefined
      },
      select: {
        id: true,
        name: true,
        email: true,
        isAdmin: true,
        emailVerified: true
      }
    });

    res.json({ user, message: 'User updated successfully' });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'Failed to update user' });
  }
});

/**
 * GET /api/admin/logs
 * Get admin action logs
 */
router.get('/logs', async (req, res) => {
  try {
    const { page = 1, limit = 50, action, adminId } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (action) whereClause.action = action;
    if (adminId) whereClause.adminId = adminId;

    const [logs, totalCount] = await Promise.all([
      prisma.adminLog.findMany({
        where: whereClause,
        include: {
          admin: { select: { name: true, email: true } }
        },
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: parseInt(limit)
      }),
      prisma.adminLog.count({ where: whereClause })
    ]);

    res.json({
      logs,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: totalCount,
        pages: Math.ceil(totalCount / limit)
      }
    });
  } catch (error) {
    console.error('Admin logs fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch admin logs' });
  }
});

/**
 * POST /api/admin/restaurants/search-yelp
 * Search Yelp for restaurants to add to queue
 */
router.post('/restaurants/search-yelp', logAdminActionMiddleware('search_yelp', 'yelp'), async (req, res) => {
  try {
    const { query, cuisine, location = 'Austin, TX' } = req.body;

    if (!query && !cuisine) {
      return res.status(400).json({ error: 'Query or cuisine required' });
    }

    let results;
    if (cuisine) {
      results = await yelpService.searchByCuisine(cuisine, location, 10);
    } else {
      results = await yelpService.searchRestaurants(location, null, null, 10);
    }

    // Format results for admin UI
    const formattedResults = results.businesses.map(business => ({
      yelpId: business.id,
      name: business.name,
      address: business.location?.address1,
      city: business.location?.city,
      rating: business.rating,
      reviewCount: business.review_count,
      price: business.price,
      imageUrl: business.image_url,
      categories: business.categories?.map(cat => cat.title).join(', '),
      yelpUrl: business.url
    }));

    res.json({ restaurants: formattedResults });
  } catch (error) {
    console.error('Yelp search error:', error);
    res.status(500).json({ error: 'Failed to search Yelp restaurants' });
  }
});

/**
 * POST /api/admin/restaurants/add-from-yelp
 * Add restaurant from Yelp to database and optionally to queue
 */
router.post('/restaurants/add-from-yelp', logAdminActionMiddleware('add_restaurant_from_yelp', 'restaurant'), async (req, res) => {
  try {
    const { yelpId, notes, addToQueue = true, queuePosition } = req.body;

    if (!yelpId) {
      return res.status(400).json({ error: 'Yelp ID required' });
    }

    // Check if restaurant already exists
    let restaurant = await prisma.restaurant.findUnique({
      where: { yelpId }
    });

    if (!restaurant) {
      // Get restaurant details from Yelp
      const yelpDetails = await yelpService.getRestaurantDetails(yelpId);
      
      // Create restaurant in database
      restaurant = await prisma.restaurant.create({
        data: {
          yelpId: yelpDetails.id,
          name: yelpDetails.name,
          slug: yelpDetails.alias || yelpDetails.name.toLowerCase().replace(/\s+/g, '-'),
          address: yelpDetails.location?.address1 || '',
          city: yelpDetails.location?.city || 'Austin',
          state: yelpDetails.location?.state || 'TX',
          zipCode: yelpDetails.location?.zip_code || '',
          latitude: yelpDetails.coordinates?.latitude || 30.2672,
          longitude: yelpDetails.coordinates?.longitude || -97.7431,
          phone: yelpDetails.phone,
          imageUrl: yelpDetails.image_url,
          yelpUrl: yelpDetails.url,
          price: yelpDetails.price,
          rating: yelpDetails.rating,
          reviewCount: yelpDetails.review_count,
          categories: JSON.stringify(yelpDetails.categories || []),
          hours: yelpDetails.hours ? JSON.stringify(yelpDetails.hours) : null,
          lastSyncedAt: new Date()
        }
      });
    }

    // Add to queue if requested
    let queueItem = null;
    if (addToQueue) {
      const nextPosition = queuePosition || await getNextQueuePosition();
      
      queueItem = await prisma.restaurantQueue.create({
        data: {
          restaurantId: restaurant.id,
          position: nextPosition,
          addedBy: req.admin.id,
          notes
        }
      });
    }

    res.json({ restaurant, queueItem, message: 'Restaurant added successfully' });
  } catch (error) {
    console.error('Add restaurant from Yelp error:', error);
    res.status(500).json({ error: 'Failed to add restaurant from Yelp' });
  }
});

/**
 * GET /api/admin/analytics
 * Get detailed analytics for admin dashboard
 */
router.get('/analytics', logAdminActionMiddleware('view_analytics', 'analytics'), async (req, res) => {
  try {
    const { timeframe = '30d' } = req.query;
    
    // Calculate date range
    const daysBack = timeframe === '7d' ? 7 : timeframe === '30d' ? 30 : 90;
    const startDate = new Date(new Date().getTime() - daysBack * 24 * 60 * 60 * 1000);

    const [
      userGrowth,
      rsvpTrends,
      popularRestaurants,
      verificationStats,
      friendshipStats
    ] = await Promise.all([
      // User growth over time
      prisma.user.groupBy({
        by: ['createdAt'],
        _count: { id: true },
        where: { createdAt: { gte: startDate } },
        orderBy: { createdAt: 'asc' }
      }),
      
      // RSVP trends by day
      prisma.rSVP.groupBy({
        by: ['day', 'createdAt'],
        _count: { id: true },
        where: { createdAt: { gte: startDate } }
      }),
      
      // Most popular restaurants by RSVPs
      prisma.restaurant.findMany({
        select: {
          id: true,
          name: true,
          rating: true,
          _count: { select: { rsvps: true } }
        },
        orderBy: { rsvps: { _count: 'desc' } },
        take: 10
      }),
      
      // Verification statistics
      prisma.verifiedVisit.groupBy({
        by: ['createdAt'],
        _count: { id: true },
        where: { createdAt: { gte: startDate } }
      }),
      
      // Friendship growth
      prisma.friendship.groupBy({
        by: ['createdAt'],
        _count: { id: true },
        where: { 
          createdAt: { gte: startDate },
          status: 'accepted'
        }
      })
    ]);

    res.json({
      timeframe,
      userGrowth,
      rsvpTrends,
      popularRestaurants,
      verificationStats,
      friendshipStats
    });
  } catch (error) {
    console.error('Analytics fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch analytics' });
  }
});

// Helper function to get next queue position
async function getNextQueuePosition() {
  const lastPosition = await prisma.restaurantQueue.findFirst({
    orderBy: { position: 'desc' },
    select: { position: true }
  });
  return (lastPosition?.position || 0) + 1;
}

// Helper function to reorder queue
async function reorderQueue(oldPosition, newPosition) {
  if (oldPosition === newPosition) return;

  await prisma.$transaction(async (tx) => {
    if (oldPosition < newPosition) {
      // Moving down: shift items up
      await tx.restaurantQueue.updateMany({
        where: {
          position: { gt: oldPosition, lte: newPosition }
        },
        data: { position: { decrement: 1 } }
      });
    } else {
      // Moving up: shift items down
      await tx.restaurantQueue.updateMany({
        where: {
          position: { gte: newPosition, lt: oldPosition }
        },
        data: { position: { increment: 1 } }
      });
    }
  });
}

/**
 * GET /api/admin/restaurants/search-yelp
 * Search Yelp for restaurants to add to queue
 */
router.get('/restaurants/search-yelp', async (req, res) => {
  try {
    const { term, location = 'Austin, TX', limit = 10 } = req.query;
    
    if (!term) {
      return res.status(400).json({ error: 'Search term is required' });
    }

    // Use the restaurant search endpoint that works
    const searchResults = await yelpService.searchRestaurants(location, term, null, parseInt(limit));
    
    if (!searchResults || !searchResults.businesses) {
      return res.json({ restaurants: [] });
    }

    // Format results for frontend
    const restaurants = searchResults.businesses.map(business => ({
      yelpId: business.id,
      name: business.name,
      address: business.location?.address1 || business.location?.display_address?.[0] || '',
      city: business.location?.city || 'Austin',
      rating: business.rating,
      reviewCount: business.review_count,
      price: business.price,
      categories: business.categories?.map(c => c.title).join(', ') || 'Restaurant',
      imageUrl: business.image_url,
      yelpUrl: business.url
    }));

    await logAdminAction(req.admin.id, 'search_yelp', null, 'yelp_api', { term, location, resultCount: restaurants.length }, req);
    
    res.json({ restaurants });
  } catch (error) {
    console.error('Yelp search error:', error);
    res.status(500).json({ error: 'Failed to search Yelp for restaurants' });
  }
});

/**
 * POST /api/admin/restaurants/add-from-yelp
 * Add a restaurant from Yelp to database and optionally to queue
 */
router.post('/restaurants/add-from-yelp', async (req, res) => {
  try {
    const { yelpId, notes, addToQueue = true, queuePosition, restaurantData } = req.body;
    
    if (!yelpId) {
      return res.status(400).json({ error: 'Yelp ID is required' });
    }

    // Check if restaurant already exists
    let restaurant = await prisma.restaurant.findUnique({
      where: { yelpId }
    });

    if (!restaurant) {
      // Create restaurant with basic data (will be synced later with full details)
      restaurant = await prisma.restaurant.create({
        data: {
          yelpId: yelpId,
          name: restaurantData?.name || `Restaurant ${yelpId}`,
          slug: restaurantData?.name?.toLowerCase().replace(/\s+/g, '-') || `restaurant-${yelpId}`,
          address: restaurantData?.address || 'Austin, TX',
          city: 'Austin',
          state: 'TX',
          zipCode: '78701',
          latitude: 30.2672, // Default Austin coordinates
          longitude: -97.7431,
          imageUrl: restaurantData?.imageUrl || null,
          price: restaurantData?.price || '$$',
          rating: restaurantData?.rating || 0,
          reviewCount: restaurantData?.reviewCount || 0,
          categories: restaurantData?.categories ? JSON.stringify([{alias: 'restaurant', title: restaurantData.categories}]) : null,
          lastSyncedAt: new Date()
        }
      });
    }

    // Add to queue if requested
    if (addToQueue) {
      // Check if restaurant is already in queue
      const existingQueueItem = await prisma.restaurantQueue.findFirst({
        where: { restaurantId: restaurant.id, status: 'PENDING' }
      });

      if (existingQueueItem) {
        return res.status(400).json({ error: 'Restaurant already in queue' });
      }

      // Check if restaurant is currently featured
      const currentFeatured = await prisma.restaurant.findFirst({
        where: { isFeatured: true }
      });

      if (currentFeatured && currentFeatured.id === restaurant.id) {
        return res.status(400).json({ error: 'Cannot add currently featured restaurant to queue' });
      }

      // Handle demo admin
      let adminId = req.admin.id;
      if (adminId === 'demo-admin') {
        let demoUser = await prisma.user.findUnique({
          where: { email: 'admin@austinfoodclub.com' }
        });
        
        if (!demoUser) {
          demoUser = await prisma.user.create({
            data: {
              supabaseId: 'demo-admin-supabase-id',
              email: 'admin@austinfoodclub.com',
              name: 'Austin Food Club Admin',
              isAdmin: true,
              emailVerified: true,
              provider: 'demo'
            }
          });
        }
        adminId = demoUser.id;
      }

      // Get next position
      const lastPosition = await prisma.restaurantQueue.findFirst({
        orderBy: { position: 'desc' },
        select: { position: true }
      });
      const nextPosition = queuePosition || (lastPosition?.position || 0) + 1;

      // Add to queue
      const queueItem = await prisma.restaurantQueue.create({
        data: {
          restaurantId: restaurant.id,
          position: nextPosition,
          addedBy: adminId,
          notes: notes || null
        },
        include: {
          restaurant: {
            select: {
              name: true,
              address: true,
              imageUrl: true,
              rating: true,
              price: true
            }
          }
        }
      });

      await logAdminAction(req.admin.id, 'add_restaurant_from_yelp', restaurant.id, 'restaurant', { yelpId, addedToQueue: true }, req);
      
      res.status(201).json({ 
        restaurant,
        queueItem,
        message: 'Restaurant added to database and queue successfully'
      });
    } else {
      await logAdminAction(req.admin.id, 'add_restaurant_from_yelp', restaurant.id, 'restaurant', { yelpId, addedToQueue: false }, req);
      
      res.status(201).json({ 
        restaurant,
        message: 'Restaurant added to database successfully'
      });
    }
  } catch (error) {
    console.error('Add restaurant from Yelp error:', error);
    res.status(500).json({ error: 'Failed to add restaurant from Yelp' });
  }
});

module.exports = router;
