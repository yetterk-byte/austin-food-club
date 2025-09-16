const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const { verifySupabaseToken, requireAuth } = require('../middleware/auth');

const prisma = new PrismaClient();

// GET /api/v1/users/rsvps - Get user's RSVPs
router.get('/rsvps', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const rsvps = await prisma.rSVP.findMany({
      where: { userId: req.user.id },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            imageUrl: true,
            rating: true,
            address: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    
    res.json(res.apiResponse.success(rsvps, 'User RSVPs retrieved successfully'));
  } catch (error) {
    console.error('Error fetching user RSVPs:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch user RSVPs', 500));
  }
});

// POST /api/v1/users/rsvps - Create new RSVP
router.post('/rsvps', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { restaurantId, day, status } = req.body;
    
    if (!restaurantId || !day || !status) {
      return res.status(400).json(res.apiResponse.error(
        'Restaurant ID, day, and status are required',
        400,
        { code: 'MISSING_RSVP_DATA' }
      ));
    }
    
    // Check if restaurant exists
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId }
    });
    
    if (!restaurant) {
      return res.status(404).json(res.apiResponse.error(
        'Restaurant not found',
        404,
        { code: 'RESTAURANT_NOT_FOUND' }
      ));
    }
    
    // Check if RSVP already exists for this day
    const existingRSVP = await prisma.rSVP.findFirst({
      where: {
        userId: req.user.id,
        restaurantId: restaurantId,
        day: day
      }
    });
    
    let rsvp;
    if (existingRSVP) {
      // Update existing RSVP
      rsvp = await prisma.rSVP.update({
        where: { id: existingRSVP.id },
        data: { status: status },
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              imageUrl: true,
              rating: true,
              address: true
            }
          }
        }
      });
    } else {
      // Create new RSVP
      rsvp = await prisma.rSVP.create({
        data: {
          userId: req.user.id,
          restaurantId: restaurantId,
          day: day,
          status: status
        },
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              imageUrl: true,
              rating: true,
              address: true
            }
          }
        }
      });
    }
    
    res.json(res.apiResponse.success(rsvp, 'RSVP saved successfully'));
  } catch (error) {
    console.error('Error creating RSVP:', error);
    res.status(500).json(res.apiResponse.error('Failed to create RSVP', 500));
  }
});

// GET /api/v1/users/wishlist - Get user's wishlist
router.get('/wishlist', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const wishlist = await prisma.wishlist.findMany({
      where: { userId: req.user.id },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            imageUrl: true,
            rating: true,
            address: true,
            priceRange: true,
            categories: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    
    res.json(res.apiResponse.success(wishlist, 'User wishlist retrieved successfully'));
  } catch (error) {
    console.error('Error fetching user wishlist:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch user wishlist', 500));
  }
});

// POST /api/v1/users/wishlist - Add restaurant to wishlist
router.post('/wishlist', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { restaurantId } = req.body;
    
    if (!restaurantId) {
      return res.status(400).json(res.apiResponse.error(
        'Restaurant ID is required',
        400,
        { code: 'MISSING_RESTAURANT_ID' }
      ));
    }
    
    // Check if restaurant exists
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId }
    });
    
    if (!restaurant) {
      return res.status(404).json(res.apiResponse.error(
        'Restaurant not found',
        404,
        { code: 'RESTAURANT_NOT_FOUND' }
      ));
    }
    
    // Check if already in wishlist
    const existingWishlist = await prisma.wishlist.findFirst({
      where: {
        userId: req.user.id,
        restaurantId: restaurantId
      }
    });
    
    if (existingWishlist) {
      return res.status(409).json(res.apiResponse.error(
        'Restaurant already in wishlist',
        409,
        { code: 'ALREADY_IN_WISHLIST' }
      ));
    }
    
    const wishlistItem = await prisma.wishlist.create({
      data: {
        userId: req.user.id,
        restaurantId: restaurantId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            imageUrl: true,
            rating: true,
            address: true,
            priceRange: true,
            categories: true
          }
        }
      }
    });
    
    res.json(res.apiResponse.success(wishlistItem, 'Restaurant added to wishlist successfully'));
  } catch (error) {
    console.error('Error adding to wishlist:', error);
    res.status(500).json(res.apiResponse.error('Failed to add to wishlist', 500));
  }
});

// DELETE /api/v1/users/wishlist/:id - Remove restaurant from wishlist
router.delete('/wishlist/:id', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    
    const wishlistItem = await prisma.wishlist.findFirst({
      where: {
        id: id,
        userId: req.user.id
      }
    });
    
    if (!wishlistItem) {
      return res.status(404).json(res.apiResponse.error(
        'Wishlist item not found',
        404,
        { code: 'WISHLIST_ITEM_NOT_FOUND' }
      ));
    }
    
    await prisma.wishlist.delete({
      where: { id: id }
    });
    
    res.json(res.apiResponse.success(null, 'Restaurant removed from wishlist successfully'));
  } catch (error) {
    console.error('Error removing from wishlist:', error);
    res.status(500).json(res.apiResponse.error('Failed to remove from wishlist', 500));
  }
});

// GET /api/v1/users/profile - Get user profile
router.get('/profile', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        avatar: true,
        provider: true,
        createdAt: true,
        lastLoginAt: true
      }
    });
    
    if (!user) {
      return res.status(404).json(res.apiResponse.error(
        'User not found',
        404,
        { code: 'USER_NOT_FOUND' }
      ));
    }
    
    res.json(res.apiResponse.success(user, 'User profile retrieved successfully'));
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json(res.apiResponse.error('Failed to fetch user profile', 500));
  }
});

// PUT /api/v1/users/profile - Update user profile
router.put('/profile', verifySupabaseToken, requireAuth, async (req, res) => {
  try {
    const { name, avatar } = req.body;
    
    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        name: name || undefined,
        avatar: avatar || undefined
      },
      select: {
        id: true,
        email: true,
        name: true,
        avatar: true,
        provider: true,
        createdAt: true,
        lastLoginAt: true
      }
    });
    
    res.json(res.apiResponse.success(updatedUser, 'User profile updated successfully'));
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json(res.apiResponse.error('Failed to update user profile', 500));
  }
});

module.exports = router;
