const express = require('express');
const router = express.Router();

// Mock verified visits data (in a real app, this would be stored in a database)
let verifiedVisits = [
  {
    id: 1,
    userId: 1,
    restaurantId: 'sundance-bbq-1',
    restaurantName: 'Sundance BBQ',
    restaurantAddress: '8116 Thomas Springs Rd and Cir Dr',
    rating: 5,
    imageUrl: 'https://example.com/photo1.jpg',
    verifiedAt: new Date('2024-01-15T18:30:00Z').toISOString(),
    citySlug: 'austin'
  },
  {
    id: 2,
    userId: 1,
    restaurantId: 'terry-blacks-1',
    restaurantName: 'Terry Black\'s Barbecue',
    restaurantAddress: '1003 Barton Springs Rd',
    rating: 4,
    imageUrl: 'https://example.com/photo2.jpg',
    verifiedAt: new Date('2024-01-10T19:45:00Z').toISOString(),
    citySlug: 'austin'
  },
  {
    id: 3,
    userId: 2,
    restaurantId: 'franklin-bbq-1',
    restaurantName: 'Franklin Barbecue',
    restaurantAddress: '900 E 11th St',
    rating: 5,
    imageUrl: 'https://example.com/photo3.jpg',
    verifiedAt: new Date('2024-01-08T12:15:00Z').toISOString(),
    citySlug: 'austin'
  }
];

// GET /api/visits/user/:userId - Get verified visits for a user
router.get('/user/:userId', (req, res) => {
  try {
    const { userId } = req.params;
    const userVisits = verifiedVisits.filter(visit => visit.userId === parseInt(userId));
    
    console.log(`🔍 Visits: Getting visits for user ${userId}`);
    console.log(`✅ Visits: Found ${userVisits.length} visits for user ${userId}`);
    
    res.json({
      success: true,
      visits: userVisits,
      total: userVisits.length
    });
  } catch (error) {
    console.error('❌ Visits: Error getting user visits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get user visits',
      message: error.message
    });
  }
});

// POST /api/visits - Create a new verified visit
router.post('/', (req, res) => {
  try {
    const { userId, restaurantId, restaurantName, restaurantAddress, rating, imageUrl, citySlug } = req.body;
    
    // Validate required fields
    if (!userId || !restaurantId || !restaurantName || !rating) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        message: 'userId, restaurantId, restaurantName, and rating are required'
      });
    }
    
    // Create new visit
    const newVisit = {
      id: verifiedVisits.length + 1,
      userId: parseInt(userId),
      restaurantId,
      restaurantName,
      restaurantAddress: restaurantAddress || '',
      rating: parseInt(rating),
      imageUrl: imageUrl || null,
      verifiedAt: new Date().toISOString(),
      citySlug: citySlug || 'austin'
    };
    
    verifiedVisits.push(newVisit);
    
    console.log(`🔍 Visits: Created new visit for user ${userId}`);
    console.log(`✅ Visits: Visit ID ${newVisit.id} - ${restaurantName} (${rating} stars)`);
    
    res.status(201).json({
      success: true,
      visit: newVisit,
      message: 'Visit verified successfully'
    });
  } catch (error) {
    console.error('❌ Visits: Error creating visit:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create visit',
      message: error.message
    });
  }
});

// GET /api/visits/recent - Get recent verified visits for social feed
router.get('/recent', (req, res) => {
  try {
    const { limit = 20, citySlug } = req.query;
    
    let recentVisits = [...verifiedVisits];
    
    // Filter by city if specified
    if (citySlug) {
      recentVisits = recentVisits.filter(visit => visit.citySlug === citySlug);
    }
    
    // Sort by most recent and limit
    recentVisits = recentVisits
      .sort((a, b) => new Date(b.verifiedAt) - new Date(a.verifiedAt))
      .slice(0, parseInt(limit));
    
    console.log(`🔍 Visits: Getting recent visits (limit: ${limit}, city: ${citySlug})`);
    console.log(`✅ Visits: Found ${recentVisits.length} recent visits`);
    
    res.json({
      success: true,
      visits: recentVisits,
      total: recentVisits.length
    });
  } catch (error) {
    console.error('❌ Visits: Error getting recent visits:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get recent visits',
      message: error.message
    });
  }
});

module.exports = router;
