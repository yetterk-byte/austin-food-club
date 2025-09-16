/**
 * Custom Google Maps styling for Austin Food Club
 * Dark theme optimized for restaurant discovery and navigation
 */

// Dark charcoal theme matching the app's design
export const darkMapStyles = [
  // Base map styling
  {
    elementType: "geometry",
    stylers: [{ color: "#1a1a1a" }] // Dark charcoal background
  },
  {
    elementType: "labels.text.stroke",
    stylers: [{ color: "#1a1a1a" }]
  },
  {
    elementType: "labels.text.fill",
    stylers: [{ color: "#e0e0e0" }] // Light text for readability
  },

  // Water features - highlight Lady Bird Lake and other water bodies
  {
    featureType: "water",
    elementType: "geometry",
    stylers: [
      { color: "#2c5aa0" }, // Deep blue for water
      { visibility: "on" }
    ]
  },
  {
    featureType: "water",
    elementType: "labels.text.fill",
    stylers: [{ color: "#4a90e2" }] // Light blue text for water labels
  },
  {
    featureType: "water",
    elementType: "labels.text.stroke",
    stylers: [{ color: "#1a1a1a" }]
  },

  // Roads - make them clearly visible for navigation
  {
    featureType: "road",
    elementType: "geometry",
    stylers: [{ color: "#2d2d2d" }] // Dark gray for road surfaces
  },
  {
    featureType: "road",
    elementType: "geometry.stroke",
    stylers: [
      { color: "#404040" }, // Lighter gray for road edges
      { weight: 1 }
    ]
  },
  {
    featureType: "road",
    elementType: "labels.text.fill",
    stylers: [{ color: "#f0f0f0" }] // Bright white for road labels
  },
  {
    featureType: "road",
    elementType: "labels.text.stroke",
    stylers: [{ color: "#1a1a1a" }]
  },

  // Highways - make them more prominent
  {
    featureType: "road.highway",
    elementType: "geometry",
    stylers: [
      { color: "#3a3a3a" }, // Slightly lighter for highways
      { weight: 2 }
    ]
  },
  {
    featureType: "road.highway",
    elementType: "geometry.stroke",
    stylers: [
      { color: "#5a5a5a" }, // Brighter edges for highways
      { weight: 1.5 }
    ]
  },
  {
    featureType: "road.highway",
    elementType: "labels.text.fill",
    stylers: [{ color: "#ffffff" }] // Pure white for highway labels
  },

  // Arterial roads - medium prominence
  {
    featureType: "road.arterial",
    elementType: "geometry",
    stylers: [{ color: "#2a2a2a" }]
  },
  {
    featureType: "road.arterial",
    elementType: "geometry.stroke",
    stylers: [{ color: "#404040" }]
  },

  // Local roads - subtle
  {
    featureType: "road.local",
    elementType: "geometry",
    stylers: [{ color: "#252525" }]
  },
  {
    featureType: "road.local",
    elementType: "geometry.stroke",
    stylers: [{ color: "#353535" }]
  },

  // Parks and green spaces - subtle green tint
  {
    featureType: "poi.park",
    elementType: "geometry",
    stylers: [{ color: "#1e2a1e" }] // Dark green for parks
  },
  {
    featureType: "poi.park",
    elementType: "labels.text.fill",
    stylers: [{ color: "#4a7c59" }] // Green text for park labels
  },

  // Points of interest - dim most, highlight important ones
  {
    featureType: "poi",
    elementType: "geometry",
    stylers: [
      { color: "#2a2a2a" },
      { visibility: "simplified" } // Reduce clutter
    ]
  },
  {
    featureType: "poi",
    elementType: "labels.text.fill",
    stylers: [{ color: "#888888" }] // Dimmed text for most POIs
  },
  {
    featureType: "poi",
    elementType: "labels.icon",
    stylers: [{ visibility: "off" }] // Hide most POI icons
  },

  // Business districts - slightly highlighted
  {
    featureType: "poi.business",
    elementType: "geometry",
    stylers: [{ color: "#2d2d2d" }]
  },
  {
    featureType: "poi.business",
    elementType: "labels.text.fill",
    stylers: [{ color: "#cccccc" }] // Brighter text for businesses
  },

  // Transit - make visible but not overwhelming
  {
    featureType: "transit",
    elementType: "geometry",
    stylers: [{ color: "#2a2a2a" }]
  },
  {
    featureType: "transit",
    elementType: "labels.text.fill",
    stylers: [{ color: "#aaaaaa" }]
  },
  {
    featureType: "transit.station",
    elementType: "geometry",
    stylers: [{ color: "#3a3a3a" }] // Slightly brighter for stations
  },

  // Administrative areas - very subtle
  {
    featureType: "administrative",
    elementType: "geometry",
    stylers: [{ color: "#1a1a1a" }]
  },
  {
    featureType: "administrative.locality",
    elementType: "labels.text.fill",
    stylers: [{ color: "#999999" }] // Dimmed city labels
  },
  {
    featureType: "administrative.neighborhood",
    elementType: "labels.text.fill",
    stylers: [{ color: "#666666" }] // Very dimmed neighborhood labels
  },

  // Land features - subtle
  {
    featureType: "landscape",
    elementType: "geometry",
    stylers: [{ color: "#1e1e1e" }] // Slightly lighter than base
  },

  // Remove unnecessary elements
  {
    featureType: "poi.attraction",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  },
  {
    featureType: "poi.government",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  },
  {
    featureType: "poi.medical",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  },
  {
    featureType: "poi.place_of_worship",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  },
  {
    featureType: "poi.school",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  }
];

// Light theme for contrast (optional)
export const lightMapStyles = [
  {
    elementType: "geometry",
    stylers: [{ color: "#f5f5f5" }]
  },
  {
    elementType: "labels.text.stroke",
    stylers: [{ color: "#ffffff" }]
  },
  {
    elementType: "labels.text.fill",
    stylers: [{ color: "#333333" }]
  },
  {
    featureType: "water",
    elementType: "geometry",
    stylers: [{ color: "#4a90e2" }]
  },
  {
    featureType: "road",
    elementType: "geometry",
    stylers: [{ color: "#ffffff" }]
  },
  {
    featureType: "road",
    elementType: "geometry.stroke",
    stylers: [{ color: "#cccccc" }]
  }
];

// Austin-specific styling enhancements
export const austinMapStyles = [
  // Highlight Lady Bird Lake specifically
  {
    featureType: "water",
    elementType: "geometry",
    stylers: [
      { color: "#2c5aa0" },
      { visibility: "on" }
    ]
  },
  // Make downtown area more prominent
  {
    featureType: "poi.business",
    elementType: "geometry",
    stylers: [
      { color: "#3a3a3a" },
      { visibility: "on" }
    ]
  },
  // Highlight major Austin landmarks
  {
    featureType: "poi",
    elementType: "labels.text.fill",
    stylers: [
      { color: "#ffffff" },
      { visibility: "on" }
    ]
  }
];

// Combined dark theme with Austin enhancements
export const austinDarkMapStyles = [
  ...darkMapStyles,
  ...austinMapStyles
];

// Default export - use the Austin dark theme
export default austinDarkMapStyles;
