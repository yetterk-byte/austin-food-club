const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const yelpService = require('../services/yelpService');

const prisma = new PrismaClient();

// Search restaurants on Yelp (admin functionality)
router.get('/search', async (req, res) => {
  try {
    const { name } = req.query;
    if (!name) {
      return res.status(400).json({ error: 'Restaurant name required' });
    }
    
    const results = await yelpService.searchRestaurant(name);
    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add a restaurant from Yelp and set as featured
router.post('/feature', async (req, res) => {
  try {
    const { yelpId, specialNotes, expectedWait, dressCode, parkingInfo } = req.body;
    
    let restaurant = await prisma.restaurant.findUnique({
      where: { yelpId }
    });

    const yelpData = await yelpService.syncRestaurantData(yelpId);
    
    if (restaurant) {
      restaurant = await prisma.restaurant.update({
        where: { yelpId },
        data: {
          ...yelpData,
          isFeatured: true,
          featuredWeek: new Date(),
          featuredDate: new Date(),
          specialNotes,
          expectedWait,
          dressCode,
          parkingInfo
        }
      });
    } else {
      restaurant = await prisma.restaurant.create({
        data: {
          ...yelpData,
          isFeatured: true,
          featuredWeek: new Date(),
          featuredDate: new Date(),
          specialNotes,
          expectedWait,
          dressCode,
          parkingInfo
        }
      });
    }

    // Unfeature previous restaurants
    await prisma.restaurant.updateMany({
      where: {
        id: { not: restaurant.id },
        isFeatured: true
      },
      data: { isFeatured: false }
    });

    res.json(restaurant);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get current featured restaurant
router.get('/current', async (req, res) => {
  try {
    const restaurant = await prisma.restaurant.findFirst({
      where: { isFeatured: true },
      include: {
        rsvps: {
          where: {
            createdAt: {
              gte: new Date(new Date().setDate(new Date().getDate() - 7))
            }
          }
        }
      }
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'No featured restaurant this week' });
    }

    // Sync with Yelp if data is older than 24 hours
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    if (!restaurant.lastSyncedAt || restaurant.lastSyncedAt < oneDayAgo) {
      try {
        const freshData = await yelpService.syncRestaurantData(restaurant.yelpId);
        await prisma.restaurant.update({
          where: { id: restaurant.id },
          data: freshData
        });
        Object.assign(restaurant, freshData);
      } catch (error) {
        console.error('Failed to sync with Yelp:', error);
      }
    }

    // Parse JSON fields for response
    if (restaurant.categories) {
      restaurant.categories = JSON.parse(restaurant.categories);
    }
    if (restaurant.hours) {
      restaurant.hours = JSON.parse(restaurant.hours);
    }

    res.json(restaurant);
  } catch (error) {
    console.error('Error in /current endpoint:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;