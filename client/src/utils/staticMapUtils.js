/**
 * Static Map Utilities
 * Generates Google Static Maps API URLs for restaurant locations
 */

// Google Static Maps API configuration
const STATIC_MAPS_CONFIG = {
  baseUrl: 'https://maps.googleapis.com/maps/api/staticmap',
  apiKey: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
  defaultSize: '600x400',
  defaultZoom: 15,
  mapType: 'roadmap',
  format: 'png'
};

/**
 * Generate a static map URL for a restaurant
 * @param {Object} restaurant - Restaurant object with coordinates
 * @param {Object} options - Map options
 * @returns {string} Static map URL
 */
export const getStaticMapUrl = (restaurant, options = {}) => {
  if (!restaurant?.coordinates) {
    return getDefaultMapUrl(options);
  }

  const {
    latitude,
    longitude
  } = restaurant.coordinates;

  const {
    width = 600,
    height = 400,
    zoom = 15,
    mapType = 'roadmap',
    showMarker = true,
    markerColor = 'red',
    markerLabel = 'R',
    showScale = true,
    retina = true
  } = options;

  // Calculate size for retina displays
  const size = retina ? `${width * 2}x${height * 2}` : `${width}x${height}`;

  const params = new URLSearchParams({
    center: `${latitude},${longitude}`,
    zoom: zoom.toString(),
    size: size,
    maptype: mapType,
    format: 'png',
    key: STATIC_MAPS_CONFIG.apiKey
  });

  // Add marker if requested
  if (showMarker) {
    const marker = `color:${markerColor}|label:${markerLabel}|${latitude},${longitude}`;
    params.append('markers', marker);
  }

  // Add scale control
  if (showScale) {
    params.append('scale', '2'); // For retina displays
  }

  // Add map styling for better appearance
  params.append('style', 'feature:poi|visibility:off'); // Hide points of interest
  params.append('style', 'feature:transit|visibility:off'); // Hide transit

  return `${STATIC_MAPS_CONFIG.baseUrl}?${params.toString()}`;
};

/**
 * Generate a static map URL for multiple restaurants
 * @param {Array} restaurants - Array of restaurant objects
 * @param {Object} options - Map options
 * @returns {string} Static map URL
 */
export const getMultiRestaurantStaticMapUrl = (restaurants, options = {}) => {
  if (!restaurants || restaurants.length === 0) {
    return getDefaultMapUrl(options);
  }

  const {
    width = 600,
    height = 400,
    zoom = 13,
    mapType = 'roadmap',
    showMarkers = true,
    markerColors = ['red', 'blue', 'green', 'orange', 'purple'],
    showScale = true,
    retina = true
  } = options;

  const size = retina ? `${width * 2}x${height * 2}` : `${width}x${height}`;

  const params = new URLSearchParams({
    size: size,
    zoom: zoom.toString(),
    maptype: mapType,
    format: 'png',
    key: STATIC_MAPS_CONFIG.apiKey
  });

  // Add markers for each restaurant
  if (showMarkers && restaurants.length > 0) {
    restaurants.forEach((restaurant, index) => {
      if (restaurant.coordinates) {
        const color = markerColors[index % markerColors.length];
        const label = String.fromCharCode(65 + index); // A, B, C, etc.
        const marker = `color:${color}|label:${label}|${restaurant.coordinates.latitude},${restaurant.coordinates.longitude}`;
        params.append('markers', marker);
      }
    });

    // Center the map on the first restaurant
    const firstRestaurant = restaurants[0];
    if (firstRestaurant?.coordinates) {
      params.append('center', `${firstRestaurant.coordinates.latitude},${firstRestaurant.coordinates.longitude}`);
    }
  }

  if (showScale) {
    params.append('scale', '2');
  }

  return `${STATIC_MAPS_CONFIG.baseUrl}?${params.toString()}`;
};

/**
 * Generate a default map URL when no coordinates are available
 * @param {Object} options - Map options
 * @returns {string} Default map URL
 */
export const getDefaultMapUrl = (options = {}) => {
  const {
    width = 600,
    height = 400,
    zoom = 12,
    mapType = 'roadmap',
    retina = true
  } = options;

  const size = retina ? `${width * 2}x${height * 2}` : `${width}x${height}`;

  const params = new URLSearchParams({
    center: '30.2672,-97.7431', // Downtown Austin
    zoom: zoom.toString(),
    size: size,
    maptype: mapType,
    format: 'png',
    key: STATIC_MAPS_CONFIG.apiKey
  });

  return `${STATIC_MAPS_CONFIG.baseUrl}?${params.toString()}`;
};

/**
 * Generate a static map URL for a specific area/neighborhood
 * @param {string} area - Area name (e.g., 'downtown', 'east austin')
 * @param {Object} options - Map options
 * @returns {string} Static map URL
 */
export const getAreaStaticMapUrl = (area, options = {}) => {
  const areaCoordinates = {
    'downtown': { lat: 30.2672, lng: -97.7431 },
    'east austin': { lat: 30.2701, lng: -97.7312 },
    'south austin': { lat: 30.2458, lng: -97.7834 },
    'north austin': { lat: 30.2531, lng: -97.7534 },
    'west austin': { lat: 30.2789, lng: -97.7890 },
    'south lamar': { lat: 30.2345, lng: -97.7890 },
    'south first': { lat: 30.2456, lng: -97.7890 },
    'rainey street': { lat: 30.2678, lng: -97.7456 },
    'sixth street': { lat: 30.2672, lng: -97.7431 },
    'domain': { lat: 30.4000, lng: -97.7000 }
  };

  const coords = areaCoordinates[area.toLowerCase()] || areaCoordinates['downtown'];
  
  return getStaticMapUrl(
    { coordinates: { latitude: coords.lat, longitude: coords.lng } },
    { ...options, zoom: 14 }
  );
};

/**
 * Check if static maps are configured
 * @returns {boolean} True if API key is available
 */
export const isStaticMapsConfigured = () => {
  return !!STATIC_MAPS_CONFIG.apiKey;
};

/**
 * Get map dimensions based on container size
 * @param {string} containerClass - CSS class of the container
 * @param {Object} options - Additional options
 * @returns {Object} Width and height
 */
export const getMapDimensions = (containerClass = '.restaurant-map', options = {}) => {
  const {
    defaultWidth = 600,
    defaultHeight = 400,
    maxWidth = 800,
    maxHeight = 600,
    minWidth = 300,
    minHeight = 200
  } = options;

  // Try to get actual container dimensions
  if (typeof window !== 'undefined') {
    const container = document.querySelector(containerClass);
    if (container) {
      const rect = container.getBoundingClientRect();
      const width = Math.max(minWidth, Math.min(maxWidth, rect.width || defaultWidth));
      const height = Math.max(minHeight, Math.min(maxHeight, rect.height || defaultHeight));
      return { width: Math.round(width), height: Math.round(height) };
    }
  }

  return { width: defaultWidth, height: defaultHeight };
};

/**
 * Generate optimized static map URL with performance considerations
 * @param {Object} restaurant - Restaurant object
 * @param {Object} options - Map options
 * @returns {Object} Map configuration with URL and metadata
 */
export const getOptimizedStaticMap = (restaurant, options = {}) => {
  const dimensions = getMapDimensions(options.containerClass, options);
  const retina = window.devicePixelRatio > 1;
  
  const mapUrl = getStaticMapUrl(restaurant, {
    ...dimensions,
    retina,
    ...options
  });

  return {
    url: mapUrl,
    width: dimensions.width,
    height: dimensions.height,
    retina,
    loading: 'lazy',
    alt: `Map showing location of ${restaurant?.name || 'restaurant'}`,
    fallback: !restaurant?.coordinates
  };
};

const staticMapUtils = {
  getStaticMapUrl,
  getMultiRestaurantStaticMapUrl,
  getDefaultMapUrl,
  getAreaStaticMapUrl,
  isStaticMapsConfigured,
  getMapDimensions,
  getOptimizedStaticMap
};

export default staticMapUtils;
