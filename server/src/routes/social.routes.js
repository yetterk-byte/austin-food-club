const express = require('express');
const { PrismaClient } = require('@prisma/client');

const router = express.Router();
const prisma = new PrismaClient();

// Mock data for friends
const mockFriends = [
  {
    id: 'friend_1',
    userId: '1', // Current user
    friendId: '3',
    createdAt: new Date('2024-01-15').toISOString(),
    friendUser: {
      id: '3',
      email: 'sarah.johnson@email.com',
      name: 'Sarah Johnson',
      isVerified: true,
      createdAt: new Date('2024-01-10').toISOString(),
    }
  },
  {
    id: 'friend_2',
    userId: '1',
    friendId: '4',
    createdAt: new Date('2024-02-20').toISOString(),
    friendUser: {
      id: '4',
      email: 'mike.chen@email.com',
      name: 'Mike Chen',
      isVerified: true,
      createdAt: new Date('2024-02-15').toISOString(),
    }
  },
  {
    id: 'friend_3',
    userId: '1',
    friendId: '5',
    createdAt: new Date('2024-03-05').toISOString(),
    friendUser: {
      id: '5',
      email: 'alex.rivera@email.com',
      name: 'Alex Rivera',
      isVerified: false,
      createdAt: new Date('2024-03-01').toISOString(),
    }
  },
  {
    id: 'friend_4',
    userId: '1',
    friendId: '6',
    createdAt: new Date('2024-03-10').toISOString(),
    friendUser: {
      id: '6',
      email: 'emma.wilson@email.com',
      name: 'Emma Wilson',
      isVerified: true,
      createdAt: new Date('2024-03-08').toISOString(),
    }
  },
  {
    id: 'friend_5',
    userId: '1',
    friendId: '7',
    createdAt: new Date('2024-03-15').toISOString(),
    friendUser: {
      id: '7',
      email: 'david.martinez@email.com',
      name: 'David Martinez',
      isVerified: true,
      createdAt: new Date('2024-03-12').toISOString(),
    }
  }
];

// Mock data for social feed
const mockSocialFeed = [
  // Recent verified visits
  {
    id: 'feed_1',
    userId: '3',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // 2 days ago
    user: {
      id: '3',
      email: 'sarah.johnson@email.com',
      name: 'Sarah Johnson',
      isVerified: true,
      createdAt: new Date('2024-01-10').toISOString(),
    },
    restaurant: {
      id: 'rest_1',
      name: 'Sundance BBQ',
      address: '8116 Thomas Springs Rd and Cir Dr',
      city: 'Austin',
      state: 'TX',
      zipCode: '78717',
      phone: '(512) 555-0123',
      rating: 4.5,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' },
        { alias: 'tacos', title: 'Tacos' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'sundance-bbq-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.5,
    photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
    description: 'Amazing BBQ and great atmosphere!'
  },
  {
    id: 'feed_2',
    userId: '4',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(), // 5 days ago
    user: {
      id: '4',
      email: 'mike.chen@email.com',
      name: 'Mike Chen',
      isVerified: true,
      createdAt: new Date('2024-02-15').toISOString(),
    },
    restaurant: {
      id: 'rest_2',
      name: 'Tsuke Edomae',
      address: '1234 Main St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
      phone: '(512) 555-0456',
      rating: 4.9,
      priceRange: '$$$',
      categories: [
        { alias: 'japanese', title: 'Japanese' },
        { alias: 'sushi', title: 'Sushi' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
      yelpId: 'tsuke-edomae-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.9,
    photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
    description: 'Incredible omakase experience!'
  },
  {
    id: 'feed_3',
    userId: '6',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(), // 1 week ago
    user: {
      id: '6',
      email: 'emma.wilson@email.com',
      name: 'Emma Wilson',
      isVerified: true,
      createdAt: new Date('2024-03-08').toISOString(),
    },
    restaurant: {
      id: 'rest_3',
      name: 'Loro Asian Smokehouse and Bar',
      address: '2115 S Lamar Blvd',
      city: 'Austin',
      state: 'TX',
      zipCode: '78704',
      phone: '(512) 555-0789',
      rating: 4.3,
      priceRange: '$$',
      categories: [
        { alias: 'asian', title: 'Asian Fusion' },
        { alias: 'bbq', title: 'Barbeque' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
      yelpId: 'loro-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.3,
    photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
    description: 'Perfect fusion of Asian and BBQ flavors!'
  },
  // Recent RSVPs
  {
    id: 'feed_4',
    userId: '5',
    type: 'rsvp',
    createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(), // 1 hour ago
    user: {
      id: '5',
      email: 'alex.rivera@email.com',
      name: 'Alex Rivera',
      isVerified: false,
      createdAt: new Date('2024-03-01').toISOString(),
    },
    restaurant: {
      id: 'rest_1',
      name: 'Sundance BBQ',
      address: '8116 Thomas Springs Rd and Cir Dr',
      city: 'Austin',
      state: 'TX',
      zipCode: '78717',
      phone: '(512) 555-0123',
      rating: 4.5,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' },
        { alias: 'tacos', title: 'Tacos' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'sundance-bbq-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rsvpDay: 'Friday',
    description: 'RSVPed to this week\'s event'
  },
  {
    id: 'feed_5',
    userId: '7',
    type: 'rsvp',
    createdAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(), // 3 hours ago
    user: {
      id: '7',
      email: 'david.martinez@email.com',
      name: 'David Martinez',
      isVerified: true,
      createdAt: new Date('2024-03-12').toISOString(),
    },
    restaurant: {
      id: 'rest_1',
      name: 'Sundance BBQ',
      address: '8116 Thomas Springs Rd and Cir Dr',
      city: 'Austin',
      state: 'TX',
      zipCode: '78717',
      phone: '(512) 555-0123',
      rating: 4.5,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' },
        { alias: 'tacos', title: 'Tacos' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'sundance-bbq-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rsvpDay: 'Saturday',
    description: 'RSVPed to this week\'s event'
  },
  // Older verified visits
  {
    id: 'feed_6',
    userId: '3',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString(), // 2 weeks ago
    user: {
      id: '3',
      email: 'sarah.johnson@email.com',
      name: 'Sarah Johnson',
      isVerified: true,
      createdAt: new Date('2024-01-10').toISOString(),
    },
    restaurant: {
      id: 'rest_4',
      name: 'Franklin Barbecue',
      address: '900 E 11th St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78702',
      phone: '(512) 555-0321',
      rating: 4.8,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
      yelpId: 'franklin-barbecue-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.8,
    photoUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
    description: 'Worth the wait! Best brisket in Austin.'
  },
  {
    id: 'feed_7',
    userId: '4',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 21 * 24 * 60 * 60 * 1000).toISOString(), // 3 weeks ago
    user: {
      id: '4',
      email: 'mike.chen@email.com',
      name: 'Mike Chen',
      isVerified: true,
      createdAt: new Date('2024-02-15').toISOString(),
    },
    restaurant: {
      id: 'rest_5',
      name: 'Uchi',
      address: '801 S Lamar Blvd',
      city: 'Austin',
      state: 'TX',
      zipCode: '78704',
      phone: '(512) 555-0654',
      rating: 4.6,
      priceRange: '$$$',
      categories: [
        { alias: 'japanese', title: 'Japanese' },
        { alias: 'sushi', title: 'Sushi' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
      yelpId: 'uchi-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.6,
    photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
    description: 'Creative sushi and amazing service!'
  },
  // Friend joined notifications
  {
    id: 'feed_8',
    userId: '6',
    type: 'new_friend',
    createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(), // 10 days ago
    user: {
      id: '6',
      email: 'emma.wilson@email.com',
      name: 'Emma Wilson',
      isVerified: true,
      createdAt: new Date('2024-03-08').toISOString(),
    },
    description: 'Joined Austin Food Club! 🎉'
  },
  {
    id: 'feed_9',
    userId: '7',
    type: 'new_friend',
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(), // 5 days ago
    user: {
      id: '7',
      email: 'david.martinez@email.com',
      name: 'David Martinez',
      isVerified: true,
      createdAt: new Date('2024-03-12').toISOString(),
    },
    description: 'Joined Austin Food Club! 🎉'
  }
];

/**
 * GET /api/friends/user/:userId
 * Get friends list for a user
 */
router.get('/friends/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`🔍 Social: Getting friends for user ${userId}`);
    
    // Filter friends for the current user
    const userFriends = mockFriends.filter(friend => friend.userId === userId);
    
    console.log(`✅ Social: Found ${userFriends.length} friends for user ${userId}`);
    
    res.json(userFriends);
  } catch (error) {
    console.error('❌ Social: Error getting friends:', error);
    res.status(500).json({ error: 'Failed to get friends: ' + error.message });
  }
});

/**
 * GET /api/social-feed/user/:userId
 * Get social feed for a user (friends' activities)
 */
router.get('/social-feed/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`🔍 Social: Getting social feed for user ${userId}`);
    
    // Get user's friends
    const userFriends = mockFriends.filter(friend => friend.userId === userId);
    const friendIds = userFriends.map(friend => friend.friendId);
    
    // Filter social feed to only show activities from friends
    const userSocialFeed = mockSocialFeed.filter(item => friendIds.includes(item.userId));
    
    // Sort by most recent first
    userSocialFeed.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    console.log(`✅ Social: Found ${userSocialFeed.length} social feed items for user ${userId}`);
    
    res.json(userSocialFeed);
  } catch (error) {
    console.error('❌ Social: Error getting social feed:', error);
    res.status(500).json({ error: 'Failed to get social feed: ' + error.message });
  }
});

/**
 * POST /api/friends/add
 * Add a friend
 */
router.post('/friends/add', async (req, res) => {
  try {
    const { userId, friendId } = req.body;
    
    console.log(`🔍 Social: Adding friend ${friendId} for user ${userId}`);
    
    // Check if friendship already exists
    const existingFriendship = mockFriends.find(
      friend => friend.userId === userId && friend.friendId === friendId
    );
    
    if (existingFriendship) {
      return res.status(400).json({ error: 'Friendship already exists' });
    }
    
    // Create new friendship (in a real app, this would be saved to database)
    const newFriendship = {
      id: `friend_${Date.now()}`,
      userId,
      friendId,
      createdAt: new Date().toISOString(),
      friendUser: {
        id: friendId,
        email: `user${friendId}@email.com`,
        name: `User ${friendId}`,
        isVerified: true,
        createdAt: new Date().toISOString(),
      }
    };
    
    console.log(`✅ Social: Added friend ${friendId} for user ${userId}`);
    
    res.json(newFriendship);
  } catch (error) {
    console.error('❌ Social: Error adding friend:', error);
    res.status(500).json({ error: 'Failed to add friend: ' + error.message });
  }
});

/**
 * DELETE /api/friends/remove
 * Remove a friend
 */
router.delete('/friends/remove', async (req, res) => {
  try {
    const { userId, friendId } = req.body;
    
    console.log(`🔍 Social: Removing friend ${friendId} for user ${userId}`);
    
    // In a real app, this would remove from database
    // For mock data, we'll just return success
    
    console.log(`✅ Social: Removed friend ${friendId} for user ${userId}`);
    
    res.json({ success: true, message: 'Friend removed successfully' });
  } catch (error) {
    console.error('❌ Social: Error removing friend:', error);
    res.status(500).json({ error: 'Failed to remove friend: ' + error.message });
  }
});

// Mock data for city activity (public activity from all Austin Food Club members)
const mockCityActivity = [
  // Recent verified visits from various users
  {
    id: 'city_1',
    userId: '8',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(), // 1 day ago
    user: {
      id: '8',
      email: 'jessica.taylor@email.com',
      name: 'Jessica Taylor',
      isVerified: true,
      createdAt: new Date('2024-01-05').toISOString(),
    },
    restaurant: {
      id: 'rest_6',
      name: 'Salt Traders Coastal Cooking',
      address: '1101 S Lamar Blvd',
      city: 'Austin',
      state: 'TX',
      zipCode: '78704',
      phone: '(512) 555-0987',
      rating: 4.4,
      priceRange: '$$',
      categories: [
        { alias: 'seafood', title: 'Seafood' },
        { alias: 'american', title: 'American' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
      yelpId: 'salt-traders-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.4,
    photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
    description: 'Fresh seafood and great cocktails!'
  },
  {
    id: 'city_2',
    userId: '9',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(), // 3 days ago
    user: {
      id: '9',
      email: 'ryan.kim@email.com',
      name: 'Ryan Kim',
      isVerified: true,
      createdAt: new Date('2024-02-01').toISOString(),
    },
    restaurant: {
      id: 'rest_7',
      name: 'Kemuri Tatsu-ya',
      address: '2713 E 2nd St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78702',
      phone: '(512) 555-1234',
      rating: 4.7,
      priceRange: '$$',
      categories: [
        { alias: 'japanese', title: 'Japanese' },
        { alias: 'bbq', title: 'Barbeque' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
      yelpId: 'kemuri-tatsuya-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.7,
    photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
    description: 'Amazing Japanese BBQ fusion!'
  },
  {
    id: 'city_3',
    userId: '10',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(), // 4 days ago
    user: {
      id: '10',
      email: 'maya.patel@email.com',
      name: 'Maya Patel',
      isVerified: true,
      createdAt: new Date('2024-01-20').toISOString(),
    },
    restaurant: {
      id: 'rest_8',
      name: 'Odd Duck',
      address: '1201 S Lamar Blvd',
      city: 'Austin',
      state: 'TX',
      zipCode: '78704',
      phone: '(512) 555-5678',
      rating: 4.5,
      priceRange: '$$$',
      categories: [
        { alias: 'american', title: 'American' },
        { alias: 'farmersmarket', title: 'Farmers Market' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'odd-duck-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.5,
    photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
    description: 'Creative farm-to-table dishes!'
  },
  {
    id: 'city_4',
    userId: '11',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString(), // 6 days ago
    user: {
      id: '11',
      email: 'carlos.rodriguez@email.com',
      name: 'Carlos Rodriguez',
      isVerified: false,
      createdAt: new Date('2024-02-10').toISOString(),
    },
    restaurant: {
      id: 'rest_9',
      name: 'La Barbecue',
      address: '2401 E Cesar Chavez St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78702',
      phone: '(512) 555-9012',
      rating: 4.6,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
      yelpId: 'la-barbecue-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.6,
    photoUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&h=600&fit=crop',
    description: 'Best brisket in South Austin!'
  },
  {
    id: 'city_5',
    userId: '12',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(), // 8 days ago
    user: {
      id: '12',
      email: 'sophie.anderson@email.com',
      name: 'Sophie Anderson',
      isVerified: true,
      createdAt: new Date('2024-01-15').toISOString(),
    },
    restaurant: {
      id: 'rest_10',
      name: 'Barley Swine',
      address: '6555 Burnet Rd',
      city: 'Austin',
      state: 'TX',
      zipCode: '78757',
      phone: '(512) 555-3456',
      rating: 4.8,
      priceRange: '$$$',
      categories: [
        { alias: 'american', title: 'American' },
        { alias: 'fine_dining', title: 'Fine Dining' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
      yelpId: 'barley-swine-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.8,
    photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
    description: 'Incredible tasting menu experience!'
  },
  // Recent RSVPs from city members
  {
    id: 'city_6',
    userId: '13',
    type: 'rsvp',
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), // 2 hours ago
    user: {
      id: '13',
      email: 'tyler.brown@email.com',
      name: 'Tyler Brown',
      isVerified: true,
      createdAt: new Date('2024-02-05').toISOString(),
    },
    restaurant: {
      id: 'rest_1',
      name: 'Sundance BBQ',
      address: '8116 Thomas Springs Rd and Cir Dr',
      city: 'Austin',
      state: 'TX',
      zipCode: '78717',
      phone: '(512) 555-0123',
      rating: 4.5,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' },
        { alias: 'tacos', title: 'Tacos' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'sundance-bbq-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rsvpDay: 'Friday',
    description: 'RSVPed to this week\'s event'
  },
  {
    id: 'city_7',
    userId: '14',
    type: 'rsvp',
    createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(), // 4 hours ago
    user: {
      id: '14',
      email: 'lisa.garcia@email.com',
      name: 'Lisa Garcia',
      isVerified: true,
      createdAt: new Date('2024-01-25').toISOString(),
    },
    restaurant: {
      id: 'rest_1',
      name: 'Sundance BBQ',
      address: '8116 Thomas Springs Rd and Cir Dr',
      city: 'Austin',
      state: 'TX',
      zipCode: '78717',
      phone: '(512) 555-0123',
      rating: 4.5,
      priceRange: '$$',
      categories: [
        { alias: 'bbq', title: 'Barbeque' },
        { alias: 'tacos', title: 'Tacos' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'sundance-bbq-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rsvpDay: 'Saturday',
    description: 'RSVPed to this week\'s event'
  },
  // New member joins
  {
    id: 'city_8',
    userId: '15',
    type: 'new_friend',
    createdAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(), // 12 hours ago
    user: {
      id: '15',
      email: 'jordan.white@email.com',
      name: 'Jordan White',
      isVerified: false,
      createdAt: new Date('2024-03-20').toISOString(),
    },
    description: 'Joined Austin Food Club! 🎉'
  },
  {
    id: 'city_9',
    userId: '16',
    type: 'new_friend',
    createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(), // 1 day ago
    user: {
      id: '16',
      email: 'ashley.thompson@email.com',
      name: 'Ashley Thompson',
      isVerified: true,
      createdAt: new Date('2024-03-19').toISOString(),
    },
    description: 'Joined Austin Food Club! 🎉'
  },
  // More verified visits
  {
    id: 'city_10',
    userId: '17',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(), // 10 days ago
    user: {
      id: '17',
      email: 'marcus.johnson@email.com',
      name: 'Marcus Johnson',
      isVerified: true,
      createdAt: new Date('2024-01-30').toISOString(),
    },
    restaurant: {
      id: 'rest_11',
      name: 'Jeffrey\'s',
      address: '1204 W Lynn St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78703',
      phone: '(512) 555-7890',
      rating: 4.7,
      priceRange: '$$$',
      categories: [
        { alias: 'american', title: 'American' },
        { alias: 'fine_dining', title: 'Fine Dining' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
      yelpId: 'jeffreys-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.7,
    photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop',
    description: 'Elegant dining with perfect service!'
  },
  {
    id: 'city_11',
    userId: '18',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 12 * 24 * 60 * 60 * 1000).toISOString(), // 12 days ago
    user: {
      id: '18',
      email: 'natalie.clark@email.com',
      name: 'Natalie Clark',
      isVerified: true,
      createdAt: new Date('2024-02-20').toISOString(),
    },
    restaurant: {
      id: 'rest_12',
      name: 'Comedor',
      address: '501 Colorado St',
      city: 'Austin',
      state: 'TX',
      zipCode: '78701',
      phone: '(512) 555-2468',
      rating: 4.4,
      priceRange: '$$',
      categories: [
        { alias: 'mexican', title: 'Mexican' },
        { alias: 'latin', title: 'Latin American' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
      yelpId: 'comedor-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.4,
    photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=600&fit=crop',
    description: 'Modern Mexican cuisine done right!'
  },
  {
    id: 'city_12',
    userId: '19',
    type: 'verified_visit',
    createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(), // 15 days ago
    user: {
      id: '19',
      email: 'kevin.lee@email.com',
      name: 'Kevin Lee',
      isVerified: false,
      createdAt: new Date('2024-02-25').toISOString(),
    },
    restaurant: {
      id: 'rest_13',
      name: 'Ramen Tatsu-ya',
      address: '8557 Research Blvd',
      city: 'Austin',
      state: 'TX',
      zipCode: '78758',
      phone: '(512) 555-1357',
      rating: 4.3,
      priceRange: '$',
      categories: [
        { alias: 'japanese', title: 'Japanese' },
        { alias: 'ramen', title: 'Ramen' }
      ],
      imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
      yelpId: 'ramen-tatsuya-austin',
      isActive: true,
      createdAt: new Date('2024-01-01').toISOString(),
      updatedAt: new Date('2024-01-01').toISOString(),
    },
    rating: 4.3,
    photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
    description: 'Best ramen in Austin!'
  }
];

/**
 * GET /api/city-activity/user/:userId
 * Get city-wide public activity feed
 */
router.get('/city-activity/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`🔍 Social: Getting city activity for user ${userId}`);
    
    // Return only verified visits from city activity (filter out RSVPs and new member joins)
    // Sort by most recent first
    const verifiedVisitsOnly = mockCityActivity.filter(activity => activity.type === 'verified_visit');
    const sortedCityActivity = [...verifiedVisitsOnly].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    console.log(`✅ Social: Found ${sortedCityActivity.length} city activity items for user ${userId}`);
    
    res.json(sortedCityActivity);
  } catch (error) {
    console.error('❌ Social: Error getting city activity:', error);
    res.status(500).json({ error: 'Failed to get city activity: ' + error.message });
  }
});

module.exports = router;