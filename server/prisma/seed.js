const { PrismaClient } = require('@prisma/client');
const yelpService = require('../src/services/yelpService');

const prisma = new PrismaClient();

async function main() {
  console.log('🔍 Checking Yelp service configuration...');
  
  if (!yelpService.isConfigured()) {
    console.error('❌ Yelp service not configured. Please check YELP_API_KEY and YELP_API_URL in .env');
    process.exit(1);
  }

  try {
    console.log('🔍 Searching for Uchi Austin on Yelp...');
    
    // Search for sushi restaurants to find Uchi Austin (might be categorized as sushi)
    const searchResults = await yelpService.searchRestaurants('Austin, TX', 'sushi', null, 15);
    
    // Debug: Log all restaurant names to see if Uchi is in the results
    console.log('Found Japanese restaurants:', searchResults.businesses.map(b => b.name).join(', '));
    
    if (!searchResults || !searchResults.businesses || searchResults.businesses.length === 0) {
      throw new Error('No Japanese restaurants found on Yelp');
    }
    
    // Look for Uchi specifically, or take the first highly-rated Japanese restaurant
    let selectedRestaurant = searchResults.businesses.find(b => 
      b.name.toLowerCase().includes('uchi') && 
      b.location?.address1?.toLowerCase().includes('lamar')
    );
    
    if (!selectedRestaurant) {
      // If Uchi not found, look for any restaurant with "uchi" in the name
      selectedRestaurant = searchResults.businesses.find(b => 
        b.name.toLowerCase().includes('uchi')
      );
    }
    
    if (!selectedRestaurant) {
      // If still not found, take the highest-rated Japanese restaurant
      const topRestaurants = searchResults.businesses
        .filter(b => b.rating >= 4.0 && b.review_count >= 50)
        .sort((a, b) => {
          if (b.rating !== a.rating) {
            return b.rating - a.rating;
          }
          return b.review_count - a.review_count;
        });
      
      selectedRestaurant = topRestaurants.length > 0 ? topRestaurants[0] : searchResults.businesses[0];
      console.log('Uchi not found, using top Japanese restaurant:', selectedRestaurant.name);
    } else {
      console.log('✅ Found Uchi:', selectedRestaurant.name, `(${selectedRestaurant.rating}⭐, ${selectedRestaurant.review_count} reviews)`);
    }
    
    // Get detailed business information
    console.log('🔍 Getting detailed business information...');
    const detailedData = await yelpService.getRestaurantDetails(selectedRestaurant.id);
    
    // Format the data for our app
    const restaurantData = yelpService.formatRestaurantForApp(detailedData);
    
    // Unfeature all existing restaurants first
    await prisma.restaurant.updateMany({
      where: { isFeatured: true },
      data: { isFeatured: false }
    });
    
    // Create or update the restaurant with live Yelp data
    const restaurant = await prisma.restaurant.upsert({
      where: { yelpId: selectedRestaurant.id },
      update: {
        yelpId: selectedRestaurant.id,
        name: selectedRestaurant.name,
        slug: selectedRestaurant.alias || selectedRestaurant.name.toLowerCase().replace(/\s+/g, '-'),
        address: selectedRestaurant.location?.address1 || '',
        city: selectedRestaurant.location?.city || 'Austin',
        state: selectedRestaurant.location?.state || 'TX',
        zipCode: selectedRestaurant.location?.zip_code || '',
        latitude: selectedRestaurant.coordinates?.latitude || 30.2672,
        longitude: selectedRestaurant.coordinates?.longitude || -97.7431,
        phone: selectedRestaurant.phone || null,
        imageUrl: selectedRestaurant.image_url || null,
        yelpUrl: selectedRestaurant.url || null,
        price: selectedRestaurant.price || '$$',
        rating: selectedRestaurant.rating || 0,
        reviewCount: selectedRestaurant.review_count || 0,
        categories: JSON.stringify(selectedRestaurant.categories || []),
        hours: detailedData.hours ? JSON.stringify(detailedData.hours) : null,
        isFeatured: true,
        featuredWeek: new Date(),
        featuredDate: new Date(),
        specialNotes: "Upscale Japanese cuisine with innovative sushi and artistic presentation. A true Austin culinary landmark with exceptional quality.",
        expectedWait: "45-75 minutes",
        dressCode: "Smart Casual",
        parkingInfo: "Valet available, limited street parking",
        lastSyncedAt: new Date()
      },
      create: {
        yelpId: selectedRestaurant.id,
        name: selectedRestaurant.name,
        slug: selectedRestaurant.alias || selectedRestaurant.name.toLowerCase().replace(/\s+/g, '-'),
        address: selectedRestaurant.location?.address1 || '',
        city: selectedRestaurant.location?.city || 'Austin',
        state: selectedRestaurant.location?.state || 'TX',
        zipCode: selectedRestaurant.location?.zip_code || '',
        latitude: selectedRestaurant.coordinates?.latitude || 30.2672,
        longitude: selectedRestaurant.coordinates?.longitude || -97.7431,
        phone: selectedRestaurant.phone || null,
        imageUrl: selectedRestaurant.image_url || null,
        yelpUrl: selectedRestaurant.url || null,
        price: selectedRestaurant.price || '$$',
        rating: selectedRestaurant.rating || 0,
        reviewCount: selectedRestaurant.review_count || 0,
        categories: JSON.stringify(selectedRestaurant.categories || []),
        hours: detailedData.hours ? JSON.stringify(detailedData.hours) : null,
        isFeatured: true,
        featuredWeek: new Date(),
        featuredDate: new Date(),
        specialNotes: "Upscale Japanese cuisine with innovative sushi and artistic presentation. A true Austin culinary landmark with exceptional quality.",
        expectedWait: "45-75 minutes",
        dressCode: "Smart Casual",
        parkingInfo: "Valet available, limited street parking",
        lastSyncedAt: new Date()
      }
    });
    
    console.log('✅ Successfully featured restaurant:', restaurant.name);
    console.log('📍 Address:', restaurant.address);
    console.log('⭐ Rating:', restaurant.rating);
    console.log('💰 Price:', restaurant.price);
    console.log('📞 Phone:', restaurant.phone);
    
  } catch (error) {
    console.error('❌ Error setting up restaurant with live Yelp data:', error.message);
    console.log('🔄 Falling back to Uchi Austin as backup...');
    
    // Fallback to Uchi Austin if Franklin Barbecue fails
    try {
      const searchResults = await yelpService.searchRestaurants('Austin, TX', 'japanese', null, 10);
      
      if (searchResults && searchResults.businesses && searchResults.businesses.length > 0) {
        let uchiData = searchResults.businesses.find(b => 
          b.name.toLowerCase().includes('uchi')
        );
        
        if (!uchiData) {
          uchiData = searchResults.businesses[0]; // Take first Japanese restaurant
        }
        
        const detailedData = await yelpService.getRestaurantDetails(uchiData.id);
        
        await prisma.restaurant.updateMany({
          where: { isFeatured: true },
          data: { isFeatured: false }
        });
        
        const restaurant = await prisma.restaurant.upsert({
          where: { yelpId: restaurantData.yelpId },
          update: {
            ...restaurantData,
            isFeatured: true,
            featuredWeek: new Date(),
            featuredDate: new Date(),
            specialNotes: "Upscale Japanese cuisine with innovative sushi and artistic presentation. A true Austin culinary landmark.",
            expectedWait: "45-75 minutes",
            dressCode: "Smart Casual",
            parkingInfo: "Valet available, limited street parking",
          },
          create: {
            ...restaurantData,
            isFeatured: true,
            featuredWeek: new Date(),
            featuredDate: new Date(),
            specialNotes: "Upscale Japanese cuisine with innovative sushi and artistic presentation. A true Austin culinary landmark.",
            expectedWait: "45-75 minutes",
            dressCode: "Smart Casual",
            parkingInfo: "Valet available, limited street parking",
          }
        });
        
        console.log('✅ Successfully featured backup restaurant:', restaurant.name);
      } else {
        throw new Error('No suitable Austin restaurants found on Yelp');
      }
    } catch (backupError) {
      console.error('❌ Backup restaurant setup also failed:', backupError.message);
      process.exit(1);
    }
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
