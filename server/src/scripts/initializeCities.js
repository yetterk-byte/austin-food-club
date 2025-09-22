const { PrismaClient } = require('@prisma/client');
const CityService = require('../services/cityService');

const prisma = new PrismaClient();

/**
 * Initialize Cities Migration Script
 * Sets up multi-city architecture and migrates existing Austin data
 */

async function initializeCities() {
  console.log('🏙️  Initializing multi-city architecture...');
  
  try {
    // Step 1: Initialize default cities
    console.log('📍 Creating city configurations...');
    const cityResults = await CityService.initializeDefaultCities();
    
    cityResults.forEach(({ city, created }) => {
      if (created) {
        console.log(`✅ Created city: ${city.displayName} (${city.slug})`);
      } else {
        console.log(`ℹ️  City already exists: ${city.displayName} (${city.slug})`);
      }
    });
    
    // Step 2: Get Austin city ID for data migration
    const austinCity = await prisma.city.findUnique({
      where: { slug: 'austin' }
    });
    
    if (!austinCity) {
      throw new Error('Austin city not found after initialization');
    }
    
    console.log(`🎯 Austin city ID: ${austinCity.id}`);
    
    // Step 3: Update existing restaurants to belong to Austin
    console.log('🍽️  Migrating existing restaurants to Austin...');
    
    const restaurantUpdateResult = await prisma.restaurant.updateMany({
      where: {
        cityId: null // Restaurants without city assignment
      },
      data: {
        cityId: austinCity.id
      }
    });
    
    console.log(`✅ Updated ${restaurantUpdateResult.count} restaurants to Austin`);
    
    // Step 4: Create rotation config for Austin if it doesn't exist
    console.log('⚙️  Setting up rotation configuration...');
    
    const existingRotationConfig = await prisma.rotationConfig.findUnique({
      where: { cityId: austinCity.id }
    });
    
    if (!existingRotationConfig) {
      await prisma.rotationConfig.create({
        data: {
          cityId: austinCity.id,
          rotationDay: 'tuesday',
          rotationTime: '09:00',
          isActive: true,
          minQueueSize: 3,
          notifyAdmins: true,
          notifyUsers: false
        }
      });
      console.log('✅ Created rotation configuration for Austin');
    } else {
      console.log('ℹ️  Rotation configuration already exists for Austin');
    }
    
    // Step 5: Display summary
    console.log('\n📊 Migration Summary:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    const cities = await prisma.city.findMany({
      include: {
        _count: {
          select: {
            restaurants: true,
            users: true,
            rotationConfigs: true
          }
        }
      },
      orderBy: { name: 'asc' }
    });
    
    cities.forEach(city => {
      const status = city.isActive ? '🟢 Active' : '🔴 Inactive';
      console.log(`${status} ${city.displayName} (${city.slug})`);
      console.log(`   📍 Location: ${city.yelpLocation}`);
      console.log(`   🍽️  Restaurants: ${city._count.restaurants}`);
      console.log(`   👥 Users: ${city._count.users}`);
      console.log(`   ⚙️  Rotation Configs: ${city._count.rotationConfigs}`);
      console.log('');
    });
    
    console.log('🎉 Multi-city initialization complete!');
    console.log('\nNext steps:');
    console.log('1. Update your application to use city context');
    console.log('2. Test the Austin Food Club with new architecture');
    console.log('3. When ready, activate other cities via admin panel');
    
  } catch (error) {
    console.error('❌ Error during city initialization:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  initializeCities()
    .then(() => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error);
      process.exit(1);
    });
}

module.exports = initializeCities;
