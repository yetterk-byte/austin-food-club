const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const { requireAuth, optionalAuth } = require('../middleware/auth');

const prisma = new PrismaClient();

/**
 * RSVP Routes
 */

// Get RSVP counts for a restaurant by day
router.get('/rsvps/restaurant/:restaurantId/counts', async (req, res) => {
  try {
    const { restaurantId } = req.params;
    
    const counts = await prisma.rSVP.groupBy({
      by: ['day'],
      where: {
        restaurantId: restaurantId,
        status: 'confirmed'
      },
      _count: {
        day: true
      }
    });
    
    // Convert to the format expected by the Flutter app
    const formattedCounts = counts.map(item => ({
      day: item.day,
      count: item._count.day
    }));
    
    res.json(formattedCounts);
  } catch (error) {
    console.error('Error getting RSVP counts:', error);
    res.status(500).json({ error: 'Failed to get RSVP counts' });
  }
});

// Create RSVP
router.post('/rsvps', optionalAuth, async (req, res) => {
  try {
    const { restaurantId, day, userId } = req.body;
    
    // Use authenticated user ID or fallback to provided userId
    const actualUserId = req.user?.id || userId || 'demo-user-123';
    
    const rsvp = await prisma.rSVP.upsert({
      where: {
        userId_restaurantId_day: {
          userId: actualUserId,
          restaurantId: restaurantId,
          day: day
        }
      },
      update: {
        status: 'confirmed',
        createdAt: new Date()
      },
      create: {
        userId: actualUserId,
        restaurantId: restaurantId,
        day: day,
        status: 'confirmed'
      }
    });
    
    res.status(201).json(rsvp);
  } catch (error) {
    console.error('Error creating RSVP:', error);
    res.status(500).json({ error: 'Failed to create RSVP' });
  }
});

/**
 * Friends Routes
 */

// Get friends for a user
router.get('/friends/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const friendships = await prisma.friendship.findMany({
      where: {
        userId: userId,
        status: 'accepted'
      },
      include: {
        friend: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
            createdAt: true
          }
        }
      }
    });
    
    // Format for Flutter app
    const friends = friendships.map(friendship => ({
      id: friendship.id,
      userId: friendship.userId,
      friendId: friendship.friendId,
      createdAt: friendship.createdAt,
      friendUser: friendship.friend
    }));
    
    res.json(friends);
  } catch (error) {
    console.error('Error getting friends:', error);
    res.status(500).json({ error: 'Failed to get friends' });
  }
});

// Add friend
router.post('/friends', optionalAuth, async (req, res) => {
  try {
    const { friendId, userId } = req.body;
    const actualUserId = req.user?.id || userId || 'demo-user-123';
    
    const friendship = await prisma.friendship.create({
      data: {
        userId: actualUserId,
        friendId: friendId,
        status: 'pending'
      },
      include: {
        friend: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
            createdAt: true
          }
        }
      }
    });
    
    res.status(201).json({
      id: friendship.id,
      userId: friendship.userId,
      friendId: friendship.friendId,
      createdAt: friendship.createdAt,
      friendUser: friendship.friend
    });
  } catch (error) {
    console.error('Error adding friend:', error);
    res.status(500).json({ error: 'Failed to add friend' });
  }
});

/**
 * Verified Visits Routes
 */

// Get verified visits for a user
router.get('/verified-visits/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const visits = await prisma.verifiedVisit.findMany({
      where: {
        userId: userId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            address: true,
            city: true,
            state: true,
            zipCode: true,
            latitude: true,
            longitude: true,
            phone: true,
            imageUrl: true,
            price: true,
            rating: true,
            reviewCount: true,
            categories: true
          }
        }
      },
      orderBy: {
        visitDate: 'desc'
      }
    });
    
    // Format for Flutter app
    const formattedVisits = visits.map(visit => ({
      id: visit.id,
      restaurant: visit.restaurant,
      visitDate: visit.visitDate,
      rating: visit.rating,
      photoUrl: visit.photoUrl,
      review: visit.review
    }));
    
    res.json(formattedVisits);
  } catch (error) {
    console.error('Error getting verified visits:', error);
    res.status(500).json({ error: 'Failed to get verified visits' });
  }
});

/**
 * Social Feed Routes
 */

// Get social feed for a user
router.get('/social-feed/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get user's friends
    const friendships = await prisma.friendship.findMany({
      where: {
        userId: userId,
        status: 'accepted'
      },
      select: {
        friendId: true
      }
    });
    
    const friendIds = friendships.map(f => f.friendId);
    
    // Get verified visits from friends
    const friendVisits = await prisma.verifiedVisit.findMany({
      where: {
        userId: {
          in: friendIds
        }
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            avatar: true,
            createdAt: true
          }
        },
        restaurant: {
          select: {
            id: true,
            name: true,
            address: true,
            city: true,
            state: true,
            zipCode: true,
            latitude: true,
            longitude: true,
            phone: true,
            imageUrl: true,
            price: true,
            rating: true,
            reviewCount: true,
            categories: true
          }
        }
      },
      orderBy: {
        visitDate: 'desc'
      },
      take: 20 // Limit to 20 recent items
    });
    
    // Format for Flutter app
    const socialFeed = friendVisits.map(visit => ({
      id: visit.id,
      userId: visit.userId,
      type: 'verified_visit',
      createdAt: visit.visitDate,
      user: visit.user,
      restaurant: visit.restaurant,
      rating: visit.rating,
      photoUrl: visit.photoUrl,
      description: visit.review
    }));
    
    res.json(socialFeed);
  } catch (error) {
    console.error('Error getting social feed:', error);
    res.status(500).json({ error: 'Failed to get social feed' });
  }
});

module.exports = router;
