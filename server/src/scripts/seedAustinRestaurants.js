const { PrismaClient } = require('@prisma/client');
const geocodingService = require('../services/geocodingService');

const prisma = new PrismaClient();

// Austin restaurants with known coordinates
const austinRestaurants = [
  {
    name: 'Franklin Barbecue',
    cuisine: 'Barbecue',
    price: '$$',
    area: 'East Austin',
    description: 'Legendary Austin barbecue joint known for its brisket and long lines. Often sells out by early afternoon.',
    address: '900 E 11th St, Austin, TX 78702',
    coordinates: { latitude: 30.2701, longitude: -97.7312 },
    rating: 4.5,
    reviewCount: 1250,
    categories: ['Barbecue', 'BBQ'],
    hours: {
      monday: 'Closed',
      tuesday: '11:00 AM - 3:00 PM',
      wednesday: '11:00 AM - 3:00 PM',
      thursday: '11:00 AM - 3:00 PM',
      friday: '11:00 AM - 3:00 PM',
      saturday: '11:00 AM - 3:00 PM',
      sunday: 'Closed'
    }
  },
  {
    name: 'Matt\'s El Rancho',
    cuisine: 'Mexican',
    price: '$$',
    area: 'South Austin',
    description: 'Austin institution serving Tex-Mex favorites since 1952. Known for their famous Bob Armstrong dip.',
    address: '2613 S Lamar Blvd, Austin, TX 78704',
    coordinates: { latitude: 30.2458, longitude: -97.7834 },
    rating: 4.2,
    reviewCount: 890,
    categories: ['Mexican', 'Tex-Mex'],
    hours: {
      monday: '11:00 AM - 10:00 PM',
      tuesday: '11:00 AM - 10:00 PM',
      wednesday: '11:00 AM - 10:00 PM',
      thursday: '11:00 AM - 10:00 PM',
      friday: '11:00 AM - 11:00 PM',
      saturday: '11:00 AM - 11:00 PM',
      sunday: '11:00 AM - 10:00 PM'
    }
  },
  {
    name: 'Uchi',
    cuisine: 'Japanese',
    price: '$$$',
    area: 'South Austin',
    description: 'Award-winning Japanese restaurant by Chef Tyson Cole, known for innovative sushi and modern Japanese cuisine.',
    address: '801 S Lamar Blvd, Austin, TX 78704',
    coordinates: { latitude: 30.2531, longitude: -97.7534 },
    rating: 4.6,
    reviewCount: 2100,
    categories: ['Japanese', 'Sushi', 'Fine Dining'],
    hours: {
      monday: '5:00 PM - 10:00 PM',
      tuesday: '5:00 PM - 10:00 PM',
      wednesday: '5:00 PM - 10:00 PM',
      thursday: '5:00 PM - 10:00 PM',
      friday: '5:00 PM - 11:00 PM',
      saturday: '5:00 PM - 11:00 PM',
      sunday: '5:00 PM - 10:00 PM'
    }
  },
  {
    name: 'Salt Traders Coastal Cooking',
    cuisine: 'Seafood',
    price: '$$',
    area: 'North Austin',
    description: 'Fresh seafood and coastal cuisine with a focus on sustainable ingredients and local sourcing.',
    address: '1101 S Lamar Blvd, Austin, TX 78704',
    coordinates: { latitude: 30.2567, longitude: -97.7234 },
    rating: 4.3,
    reviewCount: 650,
    categories: ['Seafood', 'American', 'Coastal'],
    hours: {
      monday: '11:00 AM - 9:00 PM',
      tuesday: '11:00 AM - 9:00 PM',
      wednesday: '11:00 AM - 9:00 PM',
      thursday: '11:00 AM - 9:00 PM',
      friday: '11:00 AM - 10:00 PM',
      saturday: '11:00 AM - 10:00 PM',
      sunday: '11:00 AM - 9:00 PM'
    }
  },
  {
    name: 'La Barbecue',
    cuisine: 'Barbecue',
    price: '$$',
    area: 'East Austin',
    description: 'East Austin barbecue joint known for their brisket, ribs, and creative sides. Often has shorter lines than Franklin.',
    address: '2401 E Cesar Chavez St, Austin, TX 78702',
    coordinates: { latitude: 30.2567, longitude: -97.7234 },
    rating: 4.4,
    reviewCount: 980,
    categories: ['Barbecue', 'BBQ'],
    hours: {
      monday: 'Closed',
      tuesday: '11:00 AM - 6:00 PM',
      wednesday: '11:00 AM - 6:00 PM',
      thursday: '11:00 AM - 6:00 PM',
      friday: '11:00 AM - 6:00 PM',
      saturday: '11:00 AM - 6:00 PM',
      sunday: 'Closed'
    }
  },
  {
    name: 'Rudy\'s Country Store and Bar-B-Q',
    cuisine: 'Barbecue',
    price: '$',
    area: 'North Austin',
    description: 'Casual barbecue chain with a country store atmosphere. Known for their "sause" and no-frills approach.',
    address: '11570 Research Blvd, Austin, TX 78759',
    coordinates: { latitude: 30.4000, longitude: -97.7000 },
    rating: 4.1,
    reviewCount: 750,
    categories: ['Barbecue', 'BBQ', 'Casual'],
    hours: {
      monday: '6:00 AM - 9:00 PM',
      tuesday: '6:00 AM - 9:00 PM',
      wednesday: '6:00 AM - 9:00 PM',
      thursday: '6:00 AM - 9:00 PM',
      friday: '6:00 AM - 9:00 PM',
      saturday: '6:00 AM - 9:00 PM',
      sunday: '6:00 AM - 9:00 PM'
    }
  },
  {
    name: 'Lambert\'s Downtown Barbecue',
    cuisine: 'Barbecue',
    price: '$$$',
    area: 'Downtown',
    description: 'Upscale barbecue restaurant in downtown Austin with craft cocktails and refined atmosphere.',
    address: '401 W 2nd St, Austin, TX 78701',
    coordinates: { latitude: 30.2672, longitude: -97.7431 },
    rating: 4.2,
    reviewCount: 1100,
    categories: ['Barbecue', 'BBQ', 'Fine Dining'],
    hours: {
      monday: '5:00 PM - 10:00 PM',
      tuesday: '5:00 PM - 10:00 PM',
      wednesday: '5:00 PM - 10:00 PM',
      thursday: '5:00 PM - 10:00 PM',
      friday: '5:00 PM - 11:00 PM',
      saturday: '5:00 PM - 11:00 PM',
      sunday: '5:00 PM - 10:00 PM'
    }
  },
  {
    name: 'Cooper\'s Old Time Pit Bar-B-Que',
    cuisine: 'Barbecue',
    price: '$$',
    area: 'Downtown',
    description: 'Traditional Texas barbecue with a downtown location. Known for their pit-style cooking and classic sides.',
    address: '217 Congress Ave, Austin, TX 78701',
    coordinates: { latitude: 30.2672, longitude: -97.7431 },
    rating: 4.0,
    reviewCount: 850,
    categories: ['Barbecue', 'BBQ', 'Traditional'],
    hours: {
      monday: '11:00 AM - 9:00 PM',
      tuesday: '11:00 AM - 9:00 PM',
      wednesday: '11:00 AM - 9:00 PM',
      thursday: '11:00 AM - 9:00 PM',
      friday: '11:00 AM - 10:00 PM',
      saturday: '11:00 AM - 10:00 PM',
      sunday: '11:00 AM - 9:00 PM'
    }
  }
];

async function seedRestaurants() {
  try {
    console.log('🌱 Starting Austin restaurants seed...');
    
    let created = 0;
    let updated = 0;
    let errors = 0;

    for (const restaurantData of austinRestaurants) {
      try {
        // Check if restaurant already exists
        const existing = await prisma.restaurant.findFirst({
          where: {
            OR: [
              { name: restaurantData.name },
              { address: restaurantData.address }
            ]
          }
        });

        if (existing) {
          // Update existing restaurant
          await prisma.restaurant.update({
            where: { id: existing.id },
            data: {
              ...restaurantData,
              lastSynced: new Date()
            }
          });
          console.log(`✅ Updated: ${restaurantData.name}`);
          updated++;
        } else {
          // Create new restaurant
          await prisma.restaurant.create({
            data: {
              ...restaurantData,
              weekOf: new Date(),
              lastSynced: new Date()
            }
          });
          console.log(`🆕 Created: ${restaurantData.name}`);
          created++;
        }
      } catch (error) {
        console.error(`❌ Error with ${restaurantData.name}:`, error.message);
        errors++;
      }
    }

    console.log(`\n📊 Seed Results:`);
    console.log(`   Created: ${created}`);
    console.log(`   Updated: ${updated}`);
    console.log(`   Errors: ${errors}`);
    console.log(`   Total processed: ${austinRestaurants.length}`);

    // Show geocoding service status
    const geocodingStatus = geocodingService.getStatus();
    console.log(`\n🗺️  Geocoding Service Status:`);
    console.log(`   Configured: ${geocodingStatus.configured}`);
    console.log(`   Cache Size: ${geocodingStatus.cacheSize}`);

  } catch (error) {
    console.error('❌ Seed failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the seed if this file is executed directly
if (require.main === module) {
  seedRestaurants();
}

module.exports = { seedRestaurants, austinRestaurants };
