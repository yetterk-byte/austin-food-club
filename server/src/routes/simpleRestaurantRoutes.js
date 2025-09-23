const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Simple endpoint to get current featured restaurant
router.get('/current', async (req, res) => {
  try {
    console.log('🔍 Simple route: Getting featured restaurant...');
    
    const { cityId, citySlug } = req.query;
    
    let whereClause = { isFeatured: true };
    
    // If cityId is provided, filter by city ID
    if (cityId) {
      whereClause.cityId = cityId;
    }
    // If citySlug is provided, find city by slug first
    else if (citySlug) {
      const city = await prisma.city.findUnique({
        where: { slug: citySlug }
      });
      
      if (!city) {
        console.log('❌ City not found for slug:', citySlug);
        return res.status(404).json({ error: 'City not found' });
      }
      
      if (!city.isActive) {
        console.log('❌ City is inactive:', citySlug);
        return res.status(404).json({ error: 'City is not active' });
      }
      
      whereClause.cityId = city.id;
    }
    
    const restaurant = await prisma.restaurant.findFirst({
      where: whereClause,
      include: {
        rsvps: true,
        city: {
          select: {
            id: true,
            name: true,
            displayName: true,
            isActive: true
          }
        }
      }
    });

    if (!restaurant) {
      console.log('❌ No featured restaurant found for city:', citySlug || cityId || 'default');
      return res.status(404).json({ error: 'No featured restaurant this week' });
    }

    console.log('✅ Found restaurant:', restaurant.name);

    // Parse JSON fields safely
    let parsedRestaurant = { ...restaurant };
    
    if (restaurant.categories && typeof restaurant.categories === 'string') {
      try {
        parsedRestaurant.categories = JSON.parse(restaurant.categories);
      } catch (e) {
        console.log('⚠️ Categories parse error, keeping as string');
      }
    }
    
    if (restaurant.hours && typeof restaurant.hours === 'string') {
      try {
        parsedRestaurant.hours = JSON.parse(restaurant.hours);
      } catch (e) {
        console.log('⚠️ Hours parse error, keeping as string');
      }
    }

    console.log('✅ Sending restaurant data:', parsedRestaurant.name);
    res.json(parsedRestaurant);
    
  } catch (error) {
    console.error('❌ Error in /current endpoint:', error.message);
    console.error('   Stack:', error.stack);
    res.status(500).json({ error: 'Internal server error', details: error.message });
  }
});

module.exports = router;
