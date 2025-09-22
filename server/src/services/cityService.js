const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * City Service for Multi-City Food Club Architecture
 * Manages city configurations, branding, and settings
 */
class CityService {
  
  /**
   * Get all active cities
   */
  static async getAllCities() {
    return await prisma.city.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' }
    });
  }
  
  /**
   * Get city by slug (e.g., 'austin', 'nola', 'boston')
   */
  static async getCityBySlug(slug) {
    return await prisma.city.findUnique({
      where: { slug },
      include: {
        rotationConfigs: true,
        _count: {
          select: {
            restaurants: true,
            users: true
          }
        }
      }
    });
  }
  
  /**
   * Get city configuration for API requests
   * Includes all settings needed for city-specific operations
   */
  static async getCityConfig(cityId) {
    const city = await prisma.city.findUnique({
      where: { id: cityId },
      include: {
        rotationConfigs: true
      }
    });
    
    if (!city) {
      throw new Error(`City not found: ${cityId}`);
    }
    
    return {
      id: city.id,
      name: city.name,
      slug: city.slug,
      displayName: city.displayName,
      state: city.state,
      timezone: city.timezone,
      yelpLocation: city.yelpLocation,
      yelpRadius: city.yelpRadius,
      brandColor: city.brandColor,
      logoUrl: city.logoUrl,
      heroImageUrl: city.heroImageUrl,
      rotationConfig: city.rotationConfigs[0] || null
    };
  }
  
  /**
   * Create a new city
   */
  static async createCity(cityData) {
    const { rotationConfig, ...cityInfo } = cityData;
    
    // Create city and rotation config in transaction
    return await prisma.$transaction(async (tx) => {
      const city = await tx.city.create({
        data: cityInfo
      });
      
      // Create default rotation config
      await tx.rotationConfig.create({
        data: {
          cityId: city.id,
          rotationDay: rotationConfig?.rotationDay || city.rotationDay,
          rotationTime: rotationConfig?.rotationTime || city.rotationTime,
          minQueueSize: rotationConfig?.minQueueSize || city.minQueueSize
        }
      });
      
      return city;
    });
  }
  
  /**
   * Update city configuration
   */
  static async updateCity(cityId, updateData) {
    const { rotationConfig, ...cityData } = updateData;
    
    return await prisma.$transaction(async (tx) => {
      // Update city
      const city = await tx.city.update({
        where: { id: cityId },
        data: cityData
      });
      
      // Update rotation config if provided
      if (rotationConfig) {
        await tx.rotationConfig.upsert({
          where: { cityId },
          create: {
            cityId,
            ...rotationConfig
          },
          update: rotationConfig
        });
      }
      
      return city;
    });
  }
  
  /**
   * Get city-specific Yelp search parameters
   */
  static async getYelpSearchParams(cityId) {
    const city = await prisma.city.findUnique({
      where: { id: cityId },
      select: {
        yelpLocation: true,
        yelpRadius: true,
        name: true
      }
    });
    
    if (!city) {
      throw new Error(`City not found: ${cityId}`);
    }
    
    return {
      location: city.yelpLocation,
      radius: city.yelpRadius,
      cityName: city.name
    };
  }
  
  /**
   * Get featured restaurant for a specific city
   */
  static async getFeaturedRestaurant(cityId) {
    return await prisma.restaurant.findFirst({
      where: {
        cityId,
        isFeatured: true
      },
      include: {
        city: true
      }
    });
  }
  
  /**
   * Get city-specific restaurant queue
   */
  static async getCityQueue(cityId, limit = 50) {
    return await prisma.restaurantQueue.findMany({
      where: {
        restaurant: {
          cityId
        },
        status: 'PENDING'
      },
      include: {
        restaurant: {
          include: {
            city: true
          }
        },
        admin: true
      },
      orderBy: { position: 'asc' },
      take: limit
    });
  }
  
  /**
   * Initialize default cities (for seeding)
   */
  static async initializeDefaultCities() {
    const cities = [
      {
        name: 'Austin',
        slug: 'austin',
        state: 'TX',
        displayName: 'Austin Food Club',
        timezone: 'America/Chicago',
        yelpLocation: 'Austin, TX',
        yelpRadius: 24140,
        brandColor: '#20b2aa',
        isActive: true,
        launchDate: new Date()
      },
      {
        name: 'New Orleans',
        slug: 'nola',
        state: 'LA',
        displayName: 'NOLA Food Club',
        timezone: 'America/Chicago',
        yelpLocation: 'New Orleans, LA',
        yelpRadius: 24140,
        brandColor: '#8b4513',
        isActive: false // Not launched yet
      },
      {
        name: 'Boston',
        slug: 'boston',
        state: 'MA',
        displayName: 'Boston Food Club',
        timezone: 'America/New_York',
        yelpLocation: 'Boston, MA',
        yelpRadius: 24140,
        brandColor: '#0f4c75',
        isActive: false // Not launched yet
      },
      {
        name: 'New York',
        slug: 'nyc',
        state: 'NY',
        displayName: 'NYC Food Club',
        timezone: 'America/New_York',
        yelpLocation: 'New York, NY',
        yelpRadius: 24140,
        brandColor: '#ff6b35',
        isActive: false // Not launched yet
      }
    ];
    
    const results = [];
    for (const cityData of cities) {
      try {
        const existingCity = await prisma.city.findUnique({
          where: { slug: cityData.slug }
        });
        
        if (!existingCity) {
          const city = await this.createCity(cityData);
          results.push({ city, created: true });
        } else {
          results.push({ city: existingCity, created: false });
        }
      } catch (error) {
        console.error(`Error initializing city ${cityData.name}:`, error);
      }
    }
    
    return results;
  }
  
  /**
   * Get city context middleware helper
   * Determines current city from request (domain, header, or default)
   */
  static getCityContext(req) {
    // Priority order:
    // 1. X-City-Slug header
    // 2. city query parameter  
    // 3. Subdomain (e.g., austin.foodclub.com)
    // 4. Default to Austin
    
    const citySlug = 
      req.headers['x-city-slug'] ||
      req.query.city ||
      req.subdomains[0] ||
      'austin';
    
    return citySlug.toLowerCase();
  }
}

module.exports = CityService;
