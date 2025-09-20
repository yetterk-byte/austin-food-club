const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Simple endpoint to get current featured restaurant
router.get('/current', async (req, res) => {
  try {
    console.log('🔍 Simple route: Getting featured restaurant...');
    
    const restaurant = await prisma.restaurant.findFirst({
      where: { isFeatured: true },
      include: {
        rsvps: true
      }
    });

    if (!restaurant) {
      console.log('❌ No featured restaurant found');
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
