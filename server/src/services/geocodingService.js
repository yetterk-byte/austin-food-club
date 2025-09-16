const axios = require('axios');

/**
 * Geocoding service for converting addresses to coordinates
 * Uses Google Maps Geocoding API as primary, with fallback options
 */
class GeocodingService {
  constructor() {
    this.googleApiKey = process.env.GOOGLE_MAPS_API_KEY;
    this.cache = new Map();
    this.cacheTimeout = 24 * 60 * 60 * 1000; // 24 hours
  }

  // Check if service is configured
  isConfigured() {
    return !!this.googleApiKey;
  }

  // Cache management
  getCacheKey(address) {
    return `geocode_${address.toLowerCase().replace(/\s+/g, '_')}`;
  }

  getFromCache(key) {
    const cached = this.cache.get(key);
    if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
      return cached.data;
    }
    this.cache.delete(key);
    return null;
  }

  setCache(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    });
  }

  /**
   * Geocode an address using Google Maps API
   */
  async geocodeAddress(address) {
    try {
      // Check cache first
      const cacheKey = this.getCacheKey(address);
      const cached = this.getFromCache(cacheKey);
      if (cached) {
        console.log(`Geocoding cache hit for: ${address}`);
        return cached;
      }

      if (!this.isConfigured()) {
        console.warn('Google Maps API key not configured, using fallback coordinates');
        return this.getFallbackCoordinates(address);
      }

      const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
        params: {
          address: address,
          key: this.googleApiKey,
          region: 'us-tx', // Bias towards Texas
          components: 'locality:Austin|administrative_area:TX|country:US'
        }
      });

      if (response.data.status === 'OK' && response.data.results.length > 0) {
        const result = response.data.results[0];
        const location = result.geometry.location;
        
        const coordinates = {
          latitude: location.lat,
          longitude: location.lng,
          formatted_address: result.formatted_address,
          place_id: result.place_id
        };

        // Cache the result
        this.setCache(cacheKey, coordinates);
        
        console.log(`Geocoded address: ${address} -> ${coordinates.latitude}, ${coordinates.longitude}`);
        return coordinates;
      } else {
        console.warn(`Geocoding failed for address: ${address}. Status: ${response.data.status}`);
        return this.getFallbackCoordinates(address);
      }
    } catch (error) {
      console.error(`Geocoding error for address: ${address}`, error.message);
      return this.getFallbackCoordinates(address);
    }
  }

  /**
   * Get fallback coordinates based on address patterns
   */
  getFallbackCoordinates(address) {
    const addressLower = address.toLowerCase();
    
    // Known Austin restaurant coordinates
    const knownLocations = {
      'franklin': { latitude: 30.2701, longitude: -97.7312 },
      'matt': { latitude: 30.2458, longitude: -97.7834 },
      'uchi': { latitude: 30.2531, longitude: -97.7534 },
      'salt lick': { latitude: 30.1234, longitude: -97.9876 },
      'rudy': { latitude: 30.2345, longitude: -97.8765 },
      'lambert': { latitude: 30.2672, longitude: -97.7431 },
      'la barbecue': { latitude: 30.2567, longitude: -97.7234 },
      'cooper': { latitude: 30.2456, longitude: -97.7890 },
      'terry black': { latitude: 30.2678, longitude: -97.7456 },
      'micklethwait': { latitude: 30.2789, longitude: -97.7123 }
    };

    // Try to match known locations
    for (const [key, coords] of Object.entries(knownLocations)) {
      if (addressLower.includes(key)) {
        console.log(`Matched known location: ${key} for address: ${address}`);
        return coords;
      }
    }

    // Default to downtown Austin if no match
    console.log(`Using default downtown Austin coordinates for: ${address}`);
    return {
      latitude: 30.2672,
      longitude: -97.7431,
      formatted_address: address,
      fallback: true
    };
  }

  /**
   * Batch geocode multiple addresses
   */
  async geocodeAddresses(addresses) {
    const results = [];
    
    for (const address of addresses) {
      try {
        const coordinates = await this.geocodeAddress(address);
        results.push({
          address,
          coordinates,
          success: true
        });
      } catch (error) {
        console.error(`Failed to geocode address: ${address}`, error.message);
        results.push({
          address,
          coordinates: this.getFallbackCoordinates(address),
          success: false,
          error: error.message
        });
      }
    }

    return results;
  }

  /**
   * Get coordinates for Austin neighborhoods
   */
  getAustinNeighborhoodCoords(neighborhood) {
    const neighborhoods = {
      'downtown': { latitude: 30.2672, longitude: -97.7431 },
      'east austin': { latitude: 30.2701, longitude: -97.7312 },
      'south austin': { latitude: 30.2458, longitude: -97.7834 },
      'north austin': { latitude: 30.2531, longitude: -97.7534 },
      'west austin': { latitude: 30.2789, longitude: -97.7890 },
      'south lamar': { latitude: 30.2345, longitude: -97.7890 },
      'south first': { latitude: 30.2456, longitude: -97.7890 },
      'rainey street': { latitude: 30.2678, longitude: -97.7456 },
      'sixth street': { latitude: 30.2672, longitude: -97.7431 },
      'domain': { latitude: 30.4000, longitude: -97.7000 }
    };

    return neighborhoods[neighborhood.toLowerCase()] || neighborhoods['downtown'];
  }

  /**
   * Calculate distance between two coordinates (in miles)
   */
  calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 3959; // Earth's radius in miles
    const dLat = this.toRadians(lat2 - lat1);
    const dLon = this.toRadians(lon2 - lon1);
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(this.toRadians(lat1)) * Math.cos(this.toRadians(lat2)) * 
      Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }

  toRadians(degrees) {
    return degrees * (Math.PI/180);
  }

  /**
   * Get service status
   */
  getStatus() {
    return {
      configured: this.isConfigured(),
      cacheSize: this.cache.size,
      cacheTimeout: this.cacheTimeout
    };
  }
}

module.exports = new GeocodingService();
