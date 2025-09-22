const { PrismaClient } = require('@prisma/client');
const yelpService = require('../services/yelpService');

const prisma = new PrismaClient();

// Categories to search for variety
const SEARCH_CATEGORIES = [
  'bbq',
  'mexican', 
  'italian',
  'japanese',
  'thai',
  'indian',
  'chinese',
  'american',
  'steakhouses',
  'seafood',
  'pizza',
  'burgers',
  'breakfast_brunch',
  'cafes',
  'sandwiches',
  'vegetarian',
  'mediterranean',
  'french',
  'korean',
  'vietnamese'
];

async function populateQueue() {
  try {
    console.log('🍽️  Starting queue population with 20 Austin restaurants...');

    // Clear existing queue
    console.log('🗑️  Clearing existing queue...');
    await prisma.restaurantQueue.deleteMany({});

    // Get or create demo admin user
    let adminUser = await prisma.user.findFirst({
      where: { email: 'admin@austinfoodclub.com' }
    });

    if (!adminUser) {
      adminUser = await prisma.user.create({
        data: {
          supabaseId: 'demo-admin-populate-' + Date.now(),
          email: 'admin@austinfoodclub.com',
          name: 'Austin Food Club Admin',
          isAdmin: true,
          emailVerified: true,
          provider: 'demo'
        }
      });
      console.log('👤 Created demo admin user');
    }

    const restaurants = [];
    const addedYelpIds = new Set();

    // Search each category and get 1-2 restaurants from each
    for (let i = 0; i < SEARCH_CATEGORIES.length && restaurants.length < 20; i++) {
      const category = SEARCH_CATEGORIES[i];
      console.log(`🔍 Searching for ${category} restaurants...`);

      try {
        const searchResults = await yelpService.searchRestaurants(
          'Austin, TX',
          category,
          null,
          3 // Get 3 results per category
        );

        if (searchResults && searchResults.businesses) {
          // Add up to 2 restaurants from this category
          let addedFromCategory = 0;
          for (const business of searchResults.businesses) {
            if (restaurants.length >= 20 || addedFromCategory >= 2) break;
            if (addedYelpIds.has(business.id)) continue; // Skip duplicates

            // Check if restaurant already exists in database
            let restaurant = await prisma.restaurant.findUnique({
              where: { yelpId: business.id }
            });

            if (!restaurant) {
              // Create new restaurant with proper data format
              const categories = business.categories ? business.categories.map(cat => ({
                alias: cat.alias,
                title: cat.title
              })) : [];

              const hours = business.hours && business.hours.length > 0 ? business.hours[0].open.map(day => ({
                day: day.day,
                start: day.start,
                end: day.end,
                is_overnight: day.is_overnight
              })) : [];

              // Create a unique slug from name and ID
              const slug = `${business.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${business.id}`.substring(0, 50);

              const restaurantData = {
                yelpId: business.id,
                name: business.name,
                slug: slug,
                address: business.location.address1 || business.location.display_address?.[0] || '',
                city: business.location.city || 'Austin',
                state: business.location.state || 'TX',
                zipCode: business.location.zip_code || '78701',
                latitude: business.coordinates?.latitude || 30.2672,
                longitude: business.coordinates?.longitude || -97.7431,
                phone: business.display_phone || null,
                imageUrl: business.image_url || null,
                yelpUrl: business.url || null,
                price: business.price || null,
                rating: business.rating || null,
                reviewCount: business.review_count || null,
                categories: JSON.stringify(categories),
                hours: JSON.stringify(hours),
                lastSyncedAt: new Date()
              };

              restaurant = await prisma.restaurant.create({
                data: restaurantData
              });
              console.log(`✅ Created restaurant: ${restaurant.name}`);
            } else {
              console.log(`♻️  Found existing restaurant: ${restaurant.name}`);
            }

            restaurants.push(restaurant);
            addedYelpIds.add(business.id);
            addedFromCategory++;
          }
        }
      } catch (error) {
        console.error(`❌ Error searching ${category}:`, error.message);
        continue;
      }

      // Small delay to be respectful to Yelp API
      await new Promise(resolve => setTimeout(resolve, 200));
    }

    console.log(`📊 Found ${restaurants.length} restaurants, adding to queue...`);

    // Add restaurants to queue
    for (let i = 0; i < restaurants.length; i++) {
      const restaurant = restaurants[i];
      try {
        await prisma.restaurantQueue.create({
          data: {
            restaurantId: restaurant.id,
            position: i + 1,
            addedBy: adminUser.id,
            notes: `Auto-populated from ${SEARCH_CATEGORIES[i % SEARCH_CATEGORIES.length]} category`,
            status: 'PENDING'
          }
        });
        console.log(`📍 Position ${i + 1}: ${restaurant.name}`);
      } catch (error) {
        console.error(`❌ Error adding ${restaurant.name} to queue:`, error.message);
      }
    }

    console.log('🎉 Queue population completed!');
    console.log(`📋 Total restaurants in queue: ${restaurants.length}`);

    // Display final queue
    const finalQueue = await prisma.restaurantQueue.findMany({
      orderBy: { position: 'asc' },
      include: {
        restaurant: {
          select: { name: true, rating: true, price: true }
        }
      }
    });

    console.log('\n📋 Final Queue:');
    finalQueue.forEach((item, index) => {
      console.log(`${index + 1}. ${item.restaurant.name} (${item.restaurant.rating}⭐ ${item.restaurant.price || 'N/A'})`);
    });

  } catch (error) {
    console.error('❌ Queue population failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  populateQueue();
}

module.exports = { populateQueue };
