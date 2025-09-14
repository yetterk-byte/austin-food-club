const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');

const app = express();
const PORT = 3001;
const prisma = new PrismaClient();

// Database storage via Prisma (in-memory storage removed)

// Middleware
app.use(cors());
app.use(express.json());

// Test endpoint
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Server is running!', 
    timestamp: new Date().toISOString() 
  });
});

// Current restaurant endpoint - fetch from database
app.get('/api/restaurants/current', async (req, res) => {
  try {
    // Get the current week's featured restaurant
    const currentWeek = new Date();
    currentWeek.setDate(currentWeek.getDate() - currentWeek.getDay()); // Start of week
    
    let restaurant = await prisma.restaurant.findFirst({
      where: {
        weekOf: {
          gte: currentWeek
        }
      },
      orderBy: {
        weekOf: 'desc'
      }
    });

    // If no restaurant found for current week, create Franklin Barbecue as default
    if (!restaurant) {
      restaurant = await prisma.restaurant.create({
        data: {
          name: 'Franklin Barbecue',
          cuisine: 'Barbecue',
          price: '$$',
          area: 'East Austin',
          description: 'Legendary Austin barbecue joint known for its brisket and long lines. Often sells out by early afternoon.',
          address: '900 E 11th St, Austin, TX 78702',
          imageUrl: null,
          weekOf: currentWeek
        }
      });
    }

    // Format response to match frontend expectations
    const response = {
      id: restaurant.id,
      name: restaurant.name,
      address: restaurant.address,
      phone: '(512) 653-1187', // Static for now
      cuisine: restaurant.cuisine,
      rating: 4.5, // Static for now
      priceRange: restaurant.price,
      hours: {
        monday: 'Closed',
        tuesday: '11:00 AM - 3:00 PM',
        wednesday: '11:00 AM - 3:00 PM',
        thursday: '11:00 AM - 3:00 PM',
        friday: '11:00 AM - 3:00 PM',
        saturday: '11:00 AM - 3:00 PM',
        sunday: 'Closed'
      },
      description: restaurant.description,
      specialties: ['Brisket', 'Pork Ribs', 'Turkey', 'Sausage'], // Static for now
      waitTime: '2-4 hours (arrive early)', // Static for now
      coordinates: {
        latitude: 30.2672,
        longitude: -97.7431
      },
      website: 'https://franklinbarbecue.com',
      isCurrentPick: true,
      lastUpdated: restaurant.createdAt.toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching current restaurant:', error);
    res.status(500).json({ error: 'Failed to fetch restaurant data' });
  }
});

// RSVP endpoints
app.post('/api/rsvp', async (req, res) => {
  try {
    const { userId, day, status, restaurantId } = req.body;
    
    // Validate required fields
    if (!userId || !day || !status) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId, day, and status are required' 
      });
    }
    
    // Validate status values
    const validStatuses = ['going', 'maybe', 'not_going'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        error: 'Invalid status. Must be one of: going, maybe, not_going' 
      });
    }

    // Get current restaurant ID if not provided
    let currentRestaurantId = restaurantId;
    if (!currentRestaurantId) {
      // Get the most recent restaurant (current week's featured restaurant)
      const currentRestaurant = await prisma.restaurant.findFirst({
        orderBy: {
          weekOf: 'desc'
        }
      });
      
      if (!currentRestaurant) {
        return res.status(404).json({ error: 'No current restaurant found' });
      }
      
      currentRestaurantId = currentRestaurant.id;
    }
    
    // Upsert RSVP (create or update)
    const rsvp = await prisma.rSVP.upsert({
      where: {
        userId_restaurantId_day: {
          userId,
          restaurantId: currentRestaurantId,
          day
        }
      },
      update: {
        status
      },
      create: {
        userId,
        restaurantId: currentRestaurantId,
        day,
        status
      }
    });
    
    res.status(201).json({ 
      message: 'RSVP saved successfully',
      rsvp: { 
        id: rsvp.id,
        userId: rsvp.userId, 
        restaurantId: rsvp.restaurantId,
        day: rsvp.day, 
        status: rsvp.status,
        createdAt: rsvp.createdAt
      }
    });
  } catch (error) {
    console.error('Error saving RSVP:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/rsvp/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    
    // Get all RSVPs for this user with restaurant details
    const userRsvps = await prisma.rSVP.findMany({
      where: {
        userId
      },
      include: {
        restaurant: {
          select: {
            id: true,
            name: true,
            cuisine: true,
            area: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });
    
    res.json({ 
      userId,
      rsvps: userRsvps.map(rsvp => ({
        id: rsvp.id,
        userId: rsvp.userId,
        restaurantId: rsvp.restaurantId,
        day: rsvp.day,
        status: rsvp.status,
        createdAt: rsvp.createdAt,
        restaurant: rsvp.restaurant
      }))
    });
  } catch (error) {
    console.error('Error fetching RSVPs:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Wishlist endpoints
app.get('/api/wishlist/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }
    
    // Get user's wishlist or return empty array
    const wishlist = wishlists.get(userId) || [];
    
    res.json({ 
      userId,
      wishlist 
    });
  } catch (error) {
    console.error('Error fetching wishlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/wishlist', (req, res) => {
  try {
    const { userId, restaurant } = req.body;
    
    // Validate required fields
    if (!userId || !restaurant) {
      return res.status(400).json({ 
        error: 'Missing required fields: userId and restaurant are required' 
      });
    }
    
    // Validate restaurant object has required fields
    if (!restaurant.id || !restaurant.name) {
      return res.status(400).json({ 
        error: 'Restaurant must have id and name fields' 
      });
    }
    
    // Get existing wishlist or create new one
    const wishlist = wishlists.get(userId) || [];
    
    // Check if restaurant already exists in wishlist
    const existingRestaurant = wishlist.find(r => r.id === restaurant.id);
    if (existingRestaurant) {
      return res.status(409).json({ 
        error: 'Restaurant already exists in wishlist' 
      });
    }
    
    // Add restaurant to wishlist
    const restaurantWithTimestamp = {
      ...restaurant,
      addedAt: new Date().toISOString()
    };
    wishlist.push(restaurantWithTimestamp);
    wishlists.set(userId, wishlist);
    
    res.status(201).json({ 
      message: 'Restaurant added to wishlist successfully',
      restaurant: restaurantWithTimestamp
    });
  } catch (error) {
    console.error('Error adding to wishlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/wishlist/:userId/:restaurantId', (req, res) => {
  try {
    const { userId, restaurantId } = req.params;
    
    if (!userId || !restaurantId) {
      return res.status(400).json({ 
        error: 'userId and restaurantId are required' 
      });
    }
    
    // Get user's wishlist
    const wishlist = wishlists.get(userId) || [];
    
    // Find restaurant index
    const restaurantIndex = wishlist.findIndex(r => r.id === restaurantId);
    
    if (restaurantIndex === -1) {
      return res.status(404).json({ 
        error: 'Restaurant not found in wishlist' 
      });
    }
    
    // Remove restaurant from wishlist
    const removedRestaurant = wishlist.splice(restaurantIndex, 1)[0];
    wishlists.set(userId, wishlist);
    
    res.json({ 
      message: 'Restaurant removed from wishlist successfully',
      removedRestaurant 
    });
  } catch (error) {
    console.error('Error removing from wishlist:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Test endpoint: http://localhost:${PORT}/api/test`);
  console.log(`Restaurants endpoint: http://localhost:${PORT}/api/restaurants/current`);
  console.log(`RSVP endpoints: POST/GET http://localhost:${PORT}/api/rsvp`);
  console.log(`Wishlist endpoints: GET/POST/DELETE http://localhost:${PORT}/api/wishlist`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

module.exports = app;
