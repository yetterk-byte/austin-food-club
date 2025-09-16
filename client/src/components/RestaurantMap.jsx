import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { GoogleMap, useJsApiLoader, Marker, InfoWindow, DirectionsRenderer } from '@react-google-maps/api';
import { austinDarkMapStyles } from '../utils/mapStyles';
import StaticMap from './StaticMap';
import './RestaurantMap.css';

const mapContainerStyle = {
  width: '100%',
  height: '400px',
  borderRadius: '12px',
  boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
};

const mobileMapContainerStyle = {
  width: '100%',
  height: '300px',
  borderRadius: '12px',
  boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
};

const fullScreenMapStyle = {
  width: '100vw',
  height: '100vh',
  position: 'fixed',
  top: 0,
  left: 0,
  zIndex: 9999,
  borderRadius: '0px',
  boxShadow: 'none'
};

const defaultCenter = {
  lat: 30.2672, // Austin, TX coordinates
  lng: -97.7431
};

// Austin landmarks for reference
const austinLandmarks = [
  { name: 'Capitol Building', lat: 30.2747, lng: -97.7404, icon: '🏛️', type: 'landmark' },
  { name: 'University of Texas', lat: 30.2849, lng: -97.7341, icon: '🎓', type: 'landmark' },
  { name: 'South by Southwest', lat: 30.2672, lng: -97.7431, icon: '🎵', type: 'landmark' },
  { name: 'Zilker Park', lat: 30.2681, lng: -97.7713, icon: '🌳', type: 'landmark' },
  { name: 'Barton Springs', lat: 30.2642, lng: -97.7713, icon: '🏊', type: 'landmark' },
  { name: 'Austin Airport', lat: 30.1945, lng: -97.6699, icon: '✈️', type: 'landmark' }
];

// Popular Austin music venues
const musicVenues = [
  { name: 'Antone\'s', lat: 30.2672, lng: -97.7431, icon: '🎵', type: 'music' },
  { name: 'Continental Club', lat: 30.2672, lng: -97.7431, icon: '🎵', type: 'music' },
  { name: 'Cactus Cafe', lat: 30.2849, lng: -97.7341, icon: '🎵', type: 'music' },
  { name: 'Mohawk', lat: 30.2672, lng: -97.7431, icon: '🎵', type: 'music' },
  { name: 'Emo\'s', lat: 30.2672, lng: -97.7431, icon: '🎵', type: 'music' }
];

// Popular Austin breweries
const breweries = [
  { name: 'Jester King', lat: 30.2672, lng: -97.7431, icon: '🍺', type: 'brewery' },
  { name: 'Austin Beerworks', lat: 30.2672, lng: -97.7431, icon: '🍺', type: 'brewery' },
  { name: 'Live Oak Brewing', lat: 30.2672, lng: -97.7431, icon: '🍺', type: 'brewery' },
  { name: 'Zilker Brewing', lat: 30.2672, lng: -97.7431, icon: '🍺', type: 'brewery' }
];

const RestaurantMap = ({ restaurant, className = '', darkMode = false }) => {
  const [map, setMap] = useState(null);
  const [selectedMarker, setSelectedMarker] = useState(null);
  const [userLocation, setUserLocation] = useState(null);
  const [directions, setDirections] = useState(null);
  const [directionsService, setDirectionsService] = useState(null);
  const [directionsRenderer, setDirectionsRenderer] = useState(null);
  const [isLoadingLocation, setIsLoadingLocation] = useState(false);
  const [locationError, setLocationError] = useState(null);
  const [distance, setDistance] = useState(null);
  const [travelTime, setTravelTime] = useState(null);
  const [nearbyParking, setNearbyParking] = useState([]);
  const [nearbyRestaurants, setNearbyRestaurants] = useState([]);
  const [isMobile, setIsMobile] = useState(false);
  const [showLandmarks, setShowLandmarks] = useState(false);
  const [showMusicVenues, setShowMusicVenues] = useState(false);
  const [showBreweries, setShowBreweries] = useState(false);
  const [showOtherRestaurants, setShowOtherRestaurants] = useState(false);
  const [showDistanceRings, setShowDistanceRings] = useState(false);
  const [legendOpen, setLegendOpen] = useState(false);
  const [selectedTransportMode, setSelectedTransportMode] = useState('DRIVING');
  const [clickedPoint, setClickedPoint] = useState(null);
  const [clickedDistance, setClickedDistance] = useState(null);
  const [clickedTravelTime, setClickedTravelTime] = useState(null);
  const [isOpenNow, setIsOpenNow] = useState(null);
  const [hoursStatus, setHoursStatus] = useState('');
  const [isFullScreen, setIsFullScreen] = useState(false);
  const [bottomSheetOpen, setBottomSheetOpen] = useState(false);
  const [isVisible, setIsVisible] = useState(false);
  const [touchStartY, setTouchStartY] = useState(0);
  const [touchCurrentY, setTouchCurrentY] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const [showInteractiveMap, setShowInteractiveMap] = useState(false);

  const { isLoaded, loadError } = useJsApiLoader({
    id: 'google-map-script',
    googleMapsApiKey: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
    libraries: ['places']
  });

  // Get restaurant coordinates with useMemo to prevent unnecessary re-renders
  const restaurantCoords = useMemo(() => {
    if (!restaurant?.coordinates) return null;
    return {
      lat: restaurant.coordinates.lat || restaurant.coordinates.latitude,
      lng: restaurant.coordinates.lng || restaurant.coordinates.longitude
    };
  }, [restaurant?.coordinates]);

  // Check if mobile
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth <= 768);
    };
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Calculate distance and travel time
  const calculateDistanceAndTime = useCallback((userPos, restaurantPos, travelMode = selectedTransportMode) => {
    if (!userPos || !restaurantPos) return;

    const service = new window.google.maps.DistanceMatrixService();
    service.getDistanceMatrix({
      origins: [userPos],
      destinations: [restaurantPos],
      travelMode: window.google.maps.TravelMode[travelMode],
      unitSystem: window.google.maps.UnitSystem.IMPERIAL,
      avoidHighways: false,
      avoidTolls: false
    }, (response, status) => {
      if (status === window.google.maps.DistanceMatrixStatus.OK) {
        const result = response.rows[0].elements[0];
        if (result.status === 'OK') {
          setDistance(result.distance.text);
          setTravelTime(result.duration.text);
        }
      }
    });
  }, [selectedTransportMode]);

  // Calculate distance from clicked point
  const calculateClickedDistance = useCallback((clickedPos, restaurantPos, travelMode = selectedTransportMode) => {
    if (!clickedPos || !restaurantPos) return;

    const service = new window.google.maps.DistanceMatrixService();
    service.getDistanceMatrix({
      origins: [clickedPos],
      destinations: [restaurantPos],
      travelMode: window.google.maps.TravelMode[travelMode],
      unitSystem: window.google.maps.UnitSystem.IMPERIAL,
      avoidHighways: false,
      avoidTolls: false
    }, (response, status) => {
      if (status === window.google.maps.DistanceMatrixStatus.OK) {
        const result = response.rows[0].elements[0];
        if (result.status === 'OK') {
          setClickedDistance(result.distance.text);
          setClickedTravelTime(result.duration.text);
        }
      }
    });
  }, [selectedTransportMode]);

  // Check if restaurant is currently open
  const checkRestaurantHours = useCallback(() => {
    if (!restaurant?.hours) {
      setIsOpenNow(null);
      setHoursStatus('Hours not available');
      return;
    }

    const now = new Date();
    const austinTime = new Date(now.toLocaleString("en-US", {timeZone: "America/Chicago"}));
    const currentDay = austinTime.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    const currentTime = austinTime.getHours() * 100 + austinTime.getMinutes();
    
    const todayHours = restaurant.hours[currentDay];
    
    if (!todayHours || todayHours === 'Closed' || todayHours.toLowerCase().includes('closed')) {
      setIsOpenNow(false);
      setHoursStatus('Closed today');
      return;
    }

    // Parse hours (assuming format like "11:00 AM - 10:00 PM")
    const hoursMatch = todayHours.match(/(\d{1,2}):(\d{2})\s*(AM|PM)\s*-\s*(\d{1,2}):(\d{2})\s*(AM|PM)/);
    
    if (!hoursMatch) {
      setIsOpenNow(null);
      setHoursStatus(todayHours);
      return;
    }

    const [, openHour, openMin, openPeriod, closeHour, closeMin, closePeriod] = hoursMatch;
    
    const parseTime = (hour, min, period) => {
      let h = parseInt(hour);
      if (period === 'PM' && h !== 12) h += 12;
      if (period === 'AM' && h === 12) h = 0;
      return h * 100 + parseInt(min);
    };

    const openTime = parseTime(openHour, openMin, openPeriod);
    const closeTime = parseTime(closeHour, closeMin, closePeriod);

    if (currentTime >= openTime && currentTime < closeTime) {
      const timeUntilClose = closeTime - currentTime;
      if (timeUntilClose <= 100) { // Within 1 hour (100 minutes)
        setIsOpenNow('closing_soon');
        setHoursStatus(`Closes at ${closeHour}:${closeMin} ${closePeriod}`);
      } else {
        setIsOpenNow(true);
        setHoursStatus(`Open until ${closeHour}:${closeMin} ${closePeriod}`);
      }
    } else {
      setIsOpenNow(false);
      if (currentTime < openTime) {
        setHoursStatus(`Opens at ${openHour}:${openMin} ${openPeriod}`);
      } else {
        setHoursStatus(`Closed - Opens tomorrow at ${openHour}:${openMin} ${openPeriod}`);
      }
    }
  }, [restaurant?.hours]);

  // Find nearby parking
  const findNearbyParking = useCallback(() => {
    if (!map || !restaurantCoords) return;

    const service = new window.google.maps.places.PlacesService(map);
    const request = {
      location: restaurantCoords,
      radius: 500, // 500 meters
      type: 'parking'
    };

    service.nearbySearch(request, (results, status) => {
      if (status === window.google.maps.places.PlacesServiceStatus.OK) {
        setNearbyParking(results.slice(0, 3)); // Get top 3 parking options
      }
    });
  }, [map, restaurantCoords]);

  // Find nearby restaurants
  const findNearbyRestaurants = useCallback(() => {
    if (!map || !restaurantCoords) return;

    const service = new window.google.maps.places.PlacesService(map);
    const request = {
      location: restaurantCoords,
      radius: 1000, // 1 km
      type: 'restaurant',
      keyword: 'restaurant'
    };

    service.nearbySearch(request, (results, status) => {
      if (status === window.google.maps.places.PlacesServiceStatus.OK) {
        // Filter out the current restaurant and get top 5 nearby restaurants
        const filtered = results
          .filter(place => place.place_id !== restaurant?.yelpId)
          .slice(0, 5);
        setNearbyRestaurants(filtered);
      }
    });
  }, [map, restaurantCoords, restaurant?.yelpId]);

  // Calculate distance rings
  const drawDistanceRings = useCallback(() => {
    if (!map || !restaurantCoords) return;

    const circles = [];
    
    // 0.5 mile ring
    circles.push(new window.google.maps.Circle({
      strokeColor: '#4CAF50',
      strokeOpacity: 0.3,
      strokeWeight: 2,
      fillColor: '#4CAF50',
      fillOpacity: 0.05,
      center: restaurantCoords,
      radius: 804.672 // 0.5 mile in meters
    }));

    // 1 mile ring
    circles.push(new window.google.maps.Circle({
      strokeColor: '#FF9800',
      strokeOpacity: 0.3,
      strokeWeight: 2,
      fillColor: '#FF9800',
      fillOpacity: 0.05,
      center: restaurantCoords,
      radius: 1609.344 // 1 mile in meters
    }));

    circles.forEach(circle => {
      circle.setMap(showDistanceRings ? map : null);
    });

    return circles;
  }, [map, restaurantCoords, showDistanceRings]);

  // Get user's current location
  const getUserLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setLocationError('Geolocation is not supported by this browser');
      return;
    }

    setIsLoadingLocation(true);
    setLocationError(null);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const userPos = {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        };
        setUserLocation(userPos);
        setIsLoadingLocation(false);
        
        // Calculate distance and time when user location is found
        if (restaurantCoords) {
          calculateDistanceAndTime(userPos, restaurantCoords);
        }
      },
      (error) => {
        console.error('Error getting location:', error);
        setLocationError('Unable to get your location. Please enable location services.');
        setIsLoadingLocation(false);
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000 // 5 minutes
      }
    );
  }, [restaurantCoords, calculateDistanceAndTime]);

  // Calculate directions from user to restaurant
  const calculateDirections = useCallback(() => {
    if (!directionsService || !userLocation || !restaurantCoords) return;

    const request = {
      origin: userLocation,
      destination: restaurantCoords,
      travelMode: window.google.maps.TravelMode.DRIVING
    };

    directionsService.route(request, (result, status) => {
      if (status === window.google.maps.DirectionsStatus.OK) {
        setDirections(result);
        if (directionsRenderer) {
          directionsRenderer.setDirections(result);
        }
      } else {
        console.error('Directions request failed:', status);
      }
    });
  }, [directionsService, userLocation, restaurantCoords, directionsRenderer]);

      // Initialize directions service and renderer
      useEffect(() => {
        if (isLoaded && map) {
          const service = new window.google.maps.DirectionsService();
          const renderer = new window.google.maps.DirectionsRenderer({
            suppressMarkers: true // We'll use our own markers
          });
          setDirectionsService(service);
          setDirectionsRenderer(renderer);
          
          // Find nearby points of interest when map is ready
          findNearbyParking();
          findNearbyRestaurants();
        }
      }, [isLoaded, map, findNearbyParking, findNearbyRestaurants]);

  // Calculate directions when user location or restaurant changes
  useEffect(() => {
    if (userLocation && restaurantCoords) {
      calculateDirections();
    }
  }, [userLocation, restaurantCoords, calculateDirections]);

  // Center map on restaurant when it loads
  useEffect(() => {
    if (map && restaurantCoords) {
      map.panTo(restaurantCoords);
      map.setZoom(15);
    }
  }, [map, restaurantCoords]);

  // Draw distance rings when showDistanceRings changes
  useEffect(() => {
    if (map && restaurantCoords) {
      drawDistanceRings();
    }
  }, [map, restaurantCoords, showDistanceRings, drawDistanceRings]);

  // Check restaurant hours when restaurant changes
  useEffect(() => {
    checkRestaurantHours();
  }, [checkRestaurantHours]);

  // Update distances when transport mode changes
  useEffect(() => {
    if (userLocation && restaurantCoords) {
      calculateDistanceAndTime(userLocation, restaurantCoords);
    }
    if (clickedPoint && restaurantCoords) {
      calculateClickedDistance(clickedPoint, restaurantCoords);
    }
  }, [selectedTransportMode, userLocation, restaurantCoords, clickedPoint, calculateDistanceAndTime, calculateClickedDistance]);

  const onMapLoad = useCallback((map) => {
    setMap(map);
  }, []);

  const onMapUnmount = useCallback(() => {
    setMap(null);
  }, []);

  const handleGetDirections = () => {
    if (restaurantCoords) {
      const url = `https://www.google.com/maps/dir/?api=1&destination=${restaurantCoords.lat},${restaurantCoords.lng}`;
      window.open(url, '_blank');
    }
  };

  const handleMarkerClick = () => {
    setSelectedMarker(restaurant);
  };

  const handleInfoWindowClose = () => {
    setSelectedMarker(null);
  };

  const handleCenterOnUser = () => {
    if (userLocation && map) {
      map.panTo(userLocation);
      map.setZoom(15);
    } else {
      getUserLocation();
    }
  };

  // Handle map clicks for distance measurement
  const handleMapClick = useCallback((event) => {
    if (!restaurantCoords) return;
    
    const clickedLat = event.latLng.lat();
    const clickedLng = event.latLng.lng();
    const clickedPos = { lat: clickedLat, lng: clickedLng };
    
    setClickedPoint(clickedPos);
    calculateClickedDistance(clickedPos, restaurantCoords);
  }, [restaurantCoords, calculateClickedDistance]);

  // Handle transportation mode change
  const handleTransportModeChange = useCallback((mode) => {
    setSelectedTransportMode(mode);
    
    // Recalculate distances with new mode
    if (userLocation && restaurantCoords) {
      calculateDistanceAndTime(userLocation, restaurantCoords, mode);
    }
    if (clickedPoint && restaurantCoords) {
      calculateClickedDistance(clickedPoint, restaurantCoords, mode);
    }
  }, [userLocation, restaurantCoords, clickedPoint, calculateDistanceAndTime, calculateClickedDistance]);

  // Open Street View
  const handleStreetView = useCallback(() => {
    if (!restaurantCoords) return;
    
    const streetViewUrl = `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${restaurantCoords.lat},${restaurantCoords.lng}`;
    window.open(streetViewUrl, '_blank');
  }, [restaurantCoords]);

  // Clear clicked point
  const clearClickedPoint = useCallback(() => {
    setClickedPoint(null);
    setClickedDistance(null);
    setClickedTravelTime(null);
  }, []);

  // Mobile-specific functions
  const toggleFullScreen = useCallback(() => {
    setIsFullScreen(!isFullScreen);
    if (!isFullScreen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
  }, [isFullScreen]);

  // Handle transition from static to interactive map
  const handleLoadInteractiveMap = useCallback(() => {
    setShowInteractiveMap(true);
    // Trigger the map to load when it becomes visible
    if (!isVisible) {
      setIsVisible(true);
    }
  }, [isVisible]);

  // Touch handlers for bottom sheet
  const handleTouchStart = useCallback((e) => {
    setTouchStartY(e.touches[0].clientY);
    setTouchCurrentY(e.touches[0].clientY);
    setIsDragging(true);
  }, []);

  const handleTouchMove = useCallback((e) => {
    if (!isDragging) return;
    setTouchCurrentY(e.touches[0].clientY);
  }, [isDragging]);

  const handleTouchEnd = useCallback(() => {
    if (!isDragging) return;
    
    const deltaY = touchCurrentY - touchStartY;
    const threshold = 50;
    
    if (deltaY > threshold) {
      // Swipe down - close bottom sheet
      setBottomSheetOpen(false);
    } else if (deltaY < -threshold) {
      // Swipe up - open bottom sheet
      setBottomSheetOpen(true);
    }
    
    setIsDragging(false);
  }, [isDragging, touchCurrentY, touchStartY]);

  // Intersection Observer for lazy loading
  const mapRef = useCallback((node) => {
    if (node && !isVisible) {
      const observer = new IntersectionObserver(
        ([entry]) => {
          if (entry.isIntersecting) {
            setIsVisible(true);
            observer.disconnect();
          }
        },
        { threshold: 0.1 }
      );
      observer.observe(node);
    }
  }, [isVisible]);

  if (loadError) {
    return (
      <div className={`restaurant-map-error ${className}`}>
        <div className="error-message">
          <h3>🗺️ Map Unavailable</h3>
          <p>Unable to load Google Maps. Please check your internet connection.</p>
        </div>
      </div>
    );
  }

  // Show static map first for better performance
  if (!showInteractiveMap) {
    return (
      <div 
        ref={mapRef}
        className={`restaurant-map-static ${className} ${isMobile ? 'mobile' : ''}`}
      >
        <StaticMap
          restaurant={restaurant}
          onClick={handleLoadInteractiveMap}
          showLoadButton={true}
          loadButtonText="Load Interactive Map"
          options={{
            containerClass: '.restaurant-map-static',
            width: isMobile ? 300 : 600,
            height: isMobile ? 300 : 400
          }}
        />
      </div>
    );
  }

  if (!isLoaded) {
    return (
      <div className={`restaurant-map-loading ${className} ${isMobile ? 'mobile' : ''}`}>
        <div className="loading-spinner"></div>
        <p>Loading map...</p>
      </div>
    );
  }

  if (!restaurantCoords) {
    return (
      <div className={`restaurant-map-error ${className}`}>
        <div className="error-message">
          <h3>📍 Location Not Available</h3>
          <p>Restaurant location information is not available.</p>
        </div>
      </div>
    );
  }

  // Get today's hours
  const getTodaysHours = () => {
    if (!restaurant?.hours) return 'Hours not available';
    const today = new Date().toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    return restaurant.hours[today] || 'Closed today';
  };

  return (
    <div className={`restaurant-map-container ${className} ${darkMode ? 'dark-mode' : ''} ${isMobile ? 'mobile' : ''} ${isFullScreen ? 'fullscreen' : ''}`}>
      {/* Mobile Full-Screen Overlay */}
      {isFullScreen && (
        <div className="fullscreen-overlay">
          <button 
            className="close-fullscreen-btn"
            onClick={toggleFullScreen}
          >
            ✕
          </button>
        </div>
      )}

      {/* Mobile Bottom Sheet */}
      {isMobile && (
        <div 
          className={`bottom-sheet ${bottomSheetOpen ? 'open' : ''} ${isDragging ? 'dragging' : ''}`}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
        >
          <div className="bottom-sheet-handle">
            <div className="handle-bar"></div>
          </div>
          <div className="bottom-sheet-content">
            <h3>{restaurant?.name}</h3>
            <p className="restaurant-address">{restaurant?.address}</p>
            {restaurant?.rating && (
              <div className="restaurant-rating">
                <span className="rating-stars">⭐ {restaurant.rating}</span>
                <span className="rating-count">({restaurant.reviewCount} reviews)</span>
              </div>
            )}
            {hoursStatus && (
              <div className={`hours-status-mobile ${isOpenNow === true ? 'open' : isOpenNow === 'closing_soon' ? 'closing-soon' : 'closed'}`}>
                <span className="status-icon">
                  {isOpenNow === true ? '🟢' : isOpenNow === 'closing_soon' ? '🟡' : '🔴'}
                </span>
                <span className="status-text">{hoursStatus}</span>
              </div>
            )}
            <div className="mobile-actions">
              <button 
                className="mobile-action-btn primary"
                onClick={handleGetDirections}
              >
                🧭 Get Directions
              </button>
              <button 
                className="mobile-action-btn secondary"
                onClick={handleStreetView}
              >
                🏙️ Street View
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="map-header">
        <h3>📍 Find Us This Week</h3>
        <div className="map-controls">
          <button 
            className="location-btn"
            onClick={handleCenterOnUser}
            disabled={isLoadingLocation}
          >
            {isLoadingLocation ? '⏳' : '📍'} My Location
          </button>
          <button 
            className="directions-btn"
            onClick={handleGetDirections}
          >
            🧭 Get Directions
          </button>
          {!isMobile && (
            <>
              <button 
                className="legend-btn"
                onClick={() => setLegendOpen(!legendOpen)}
              >
                {legendOpen ? '📋 Hide' : '📋'} Legend
              </button>
              <button 
                className="streetview-btn"
                onClick={handleStreetView}
              >
                🏙️ Street View
              </button>
            </>
          )}
          {isMobile && (
            <button 
              className="fullscreen-btn"
              onClick={toggleFullScreen}
            >
              {isFullScreen ? '📱 Exit' : '🔍 Full Screen'}
            </button>
          )}
        </div>
      </div>

          {/* Legend/Key */}
          {legendOpen && (
            <div className="map-legend">
              <h4>Map Legend</h4>
              <div className="legend-items">
                <div className="legend-item">
                  <span className="legend-icon">🍽️</span>
                  <span>This Week's Restaurant</span>
                </div>
                <div className="legend-item">
                  <span className="legend-icon">🅿️</span>
                  <span>Parking</span>
                </div>
                <div className="legend-item">
                  <span className="legend-icon">🎵</span>
                  <span>Live Music Venues</span>
                </div>
                <div className="legend-item">
                  <span className="legend-icon">🍺</span>
                  <span>Breweries</span>
                </div>
                <div className="legend-item">
                  <span className="legend-icon">🏛️</span>
                  <span>Austin Landmarks</span>
                </div>
                <div className="legend-item">
                  <span className="legend-icon">🍴</span>
                  <span>Other Restaurants</span>
                </div>
                <div className="legend-item">
                  <span className="legend-icon">⭕</span>
                  <span>Distance Rings (0.5mi, 1mi)</span>
                </div>
              </div>
              
              <div className="legend-toggles">
                <label className="toggle-item">
                  <input 
                    type="checkbox" 
                    checked={showLandmarks}
                    onChange={(e) => setShowLandmarks(e.target.checked)}
                  />
                  <span>🏛️ Landmarks</span>
                </label>
                <label className="toggle-item">
                  <input 
                    type="checkbox" 
                    checked={showMusicVenues}
                    onChange={(e) => setShowMusicVenues(e.target.checked)}
                  />
                  <span>🎵 Music Venues</span>
                </label>
                <label className="toggle-item">
                  <input 
                    type="checkbox" 
                    checked={showBreweries}
                    onChange={(e) => setShowBreweries(e.target.checked)}
                  />
                  <span>🍺 Breweries</span>
                </label>
                <label className="toggle-item">
                  <input 
                    type="checkbox" 
                    checked={showOtherRestaurants}
                    onChange={(e) => setShowOtherRestaurants(e.target.checked)}
                  />
                  <span>🍴 Other Restaurants</span>
                </label>
                <label className="toggle-item">
                  <input 
                    type="checkbox" 
                    checked={showDistanceRings}
                    onChange={(e) => setShowDistanceRings(e.target.checked)}
                  />
                  <span>⭕ Distance Rings</span>
                </label>
              </div>
            </div>
          )}

          {/* Transportation Mode Selector */}
          <div className="transportation-modes">
            <h4>Transportation</h4>
            <div className="transport-buttons">
              <button 
                className={`transport-btn ${selectedTransportMode === 'DRIVING' ? 'active' : ''}`}
                onClick={() => handleTransportModeChange('DRIVING')}
              >
                🚗 Drive
              </button>
              <button 
                className={`transport-btn ${selectedTransportMode === 'WALKING' ? 'active' : ''}`}
                onClick={() => handleTransportModeChange('WALKING')}
              >
                🚶 Walk
              </button>
              <button 
                className={`transport-btn ${selectedTransportMode === 'BICYCLING' ? 'active' : ''}`}
                onClick={() => handleTransportModeChange('BICYCLING')}
              >
                🚴 Bike
              </button>
              <button 
                className={`transport-btn ${selectedTransportMode === 'TRANSIT' ? 'active' : ''}`}
                onClick={() => handleTransportModeChange('TRANSIT')}
              >
                🚌 Transit
              </button>
            </div>
          </div>

          {/* Hours Status Indicator */}
          {isOpenNow !== null && (
            <div className={`hours-indicator ${isOpenNow === true ? 'open' : isOpenNow === 'closing_soon' ? 'closing-soon' : 'closed'}`}>
              <div className="hours-status">
                <span className="hours-icon">
                  {isOpenNow === true ? '🟢' : isOpenNow === 'closing_soon' ? '🟡' : '🔴'}
                </span>
                <span className="hours-text">{hoursStatus}</span>
              </div>
            </div>
          )}

          {/* Clicked Point Distance Info */}
          {clickedPoint && clickedDistance && (
            <div className="clicked-distance-info">
              <div className="distance-details">
                <span className="distance-label">Distance from clicked point:</span>
                <span className="distance-value">{clickedDistance}</span>
                <span className="travel-time-value">{clickedTravelTime}</span>
              </div>
              <button 
                className="clear-distance-btn"
                onClick={clearClickedPoint}
              >
                ✕ Clear
              </button>
            </div>
          )}

      {locationError && (
        <div className="location-error">
          <p>{locationError}</p>
        </div>
      )}

      {/* Distance and time info */}
      {userLocation && distance && travelTime && (
        <div className="distance-info">
          <span className="distance">📍 {distance} away</span>
          <span className="travel-time">🚗 {travelTime} drive</span>
        </div>
      )}

      <div className="map-wrapper">
            <GoogleMap
              mapContainerStyle={
                isFullScreen ? fullScreenMapStyle : 
                isMobile ? mobileMapContainerStyle : 
                mapContainerStyle
              }
              center={restaurantCoords || defaultCenter}
              zoom={15}
              onLoad={onMapLoad}
              onUnmount={onMapUnmount}
              onClick={handleMapClick}
              options={{
                zoomControl: !isMobile,
                streetViewControl: false,
                mapTypeControl: !isMobile,
                fullscreenControl: false,
                gestureHandling: 'greedy',
                styles: darkMode ? austinDarkMapStyles : [],
                clickableIcons: true,
                disableDefaultUI: isMobile
              }}
            >
          {/* Restaurant marker with custom icon */}
          {restaurantCoords && (
            <Marker
              position={restaurantCoords}
              onClick={handleMarkerClick}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="20" cy="20" r="18" fill="${
                      isOpenNow === true ? '#10b981' : 
                      isOpenNow === 'closing_soon' ? '#f59e0b' : 
                      isOpenNow === false ? '#ef4444' : '#6b7280'
                    }" stroke="#fff" stroke-width="2"/>
                    <text x="20" y="26" text-anchor="middle" font-size="20" fill="white">🍽️</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(40, 40),
                anchor: new window.google.maps.Point(20, 20)
              }}
            />
          )}

          {/* Clicked point marker */}
          {clickedPoint && (
            <Marker
              position={clickedPoint}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="20" height="20" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="10" cy="10" r="8" fill="#3b82f6" stroke="#fff" stroke-width="2"/>
                    <text x="10" y="14" text-anchor="middle" font-size="10" fill="white">📍</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(20, 20),
                anchor: new window.google.maps.Point(10, 10)
              }}
            />
          )}

          {/* User location marker */}
          {userLocation && (
            <Marker
              position={userLocation}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="30" height="30" viewBox="0 0 30 30" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="15" cy="15" r="12" fill="#3b82f6" stroke="#fff" stroke-width="2"/>
                    <circle cx="15" cy="15" r="6" fill="white"/>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(30, 30),
                anchor: new window.google.maps.Point(15, 15)
              }}
            />
          )}

          {/* Austin landmarks */}
          {showLandmarks && austinLandmarks.map((landmark, index) => (
            <Marker
              key={index}
              position={{ lat: landmark.lat, lng: landmark.lng }}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="25" height="25" viewBox="0 0 25 25" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="12.5" cy="12.5" r="10" fill="#10b981" stroke="#fff" stroke-width="1"/>
                    <text x="12.5" y="16" text-anchor="middle" font-size="12" fill="white">${landmark.icon}</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(25, 25),
                anchor: new window.google.maps.Point(12.5, 12.5)
              }}
            />
          ))}

          {/* Music venues */}
          {showMusicVenues && musicVenues.map((venue, index) => (
            <Marker
              key={`music-${index}`}
              position={{ lat: venue.lat, lng: venue.lng }}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="22" height="22" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="12" cy="12" r="10" fill="#E91E63" stroke="#C2185B" stroke-width="2"/>
                    <text x="12" y="16" text-anchor="middle" font-size="12" fill="white">${venue.icon}</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(22, 22),
                anchor: new window.google.maps.Point(11, 11)
              }}
              title={venue.name}
            />
          ))}

          {/* Breweries */}
          {showBreweries && breweries.map((brewery, index) => (
            <Marker
              key={`brewery-${index}`}
              position={{ lat: brewery.lat, lng: brewery.lng }}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="22" height="22" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="12" cy="12" r="10" fill="#FF9800" stroke="#F57C00" stroke-width="2"/>
                    <text x="12" y="16" text-anchor="middle" font-size="12" fill="white">${brewery.icon}</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(22, 22),
                anchor: new window.google.maps.Point(11, 11)
              }}
              title={brewery.name}
            />
          ))}

          {/* Other restaurants */}
          {showOtherRestaurants && nearbyRestaurants.map((restaurant, index) => (
            <Marker
              key={`other-restaurant-${index}`}
              position={{
                lat: restaurant.geometry.location.lat(),
                lng: restaurant.geometry.location.lng()
              }}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="18" height="18" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="12" cy="12" r="8" fill="#9E9E9E" stroke="#757575" stroke-width="1"/>
                    <text x="12" y="15" text-anchor="middle" font-size="10" fill="white">🍴</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(18, 18),
                anchor: new window.google.maps.Point(9, 9)
              }}
              title={restaurant.name || 'Restaurant'}
            />
          ))}

          {/* Parking markers */}
          {nearbyParking.map((parking, index) => (
            <Marker
              key={`parking-${index}`}
              position={{ lat: parking.geometry.location.lat(), lng: parking.geometry.location.lng() }}
              icon={{
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
                  <svg width="20" height="20" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                    <rect x="2" y="2" width="16" height="16" fill="#f59e0b" stroke="#fff" stroke-width="1" rx="2"/>
                    <text x="10" y="14" text-anchor="middle" font-size="10" fill="white">P</text>
                  </svg>
                `),
                scaledSize: new window.google.maps.Size(20, 20),
                anchor: new window.google.maps.Point(10, 10)
              }}
              title={parking.name || 'Parking'}
            />
          ))}

          {/* Restaurant info window */}
          {selectedMarker && (
            <InfoWindow
              position={restaurantCoords}
              onCloseClick={handleInfoWindowClose}
            >
              <div className="info-window">
                <h4>{restaurant.name}</h4>
                <p>{restaurant.address}</p>
                <p>🕒 {getTodaysHours()}</p>
                {restaurant.phone && (
                  <p>📞 {restaurant.phone}</p>
                )}
                <button 
                  className="info-directions-btn"
                  onClick={handleGetDirections}
                >
                  Get Directions
                </button>
              </div>
            </InfoWindow>
          )}

          {/* Directions route */}
          {directions && (
            <DirectionsRenderer
              directions={directions}
              options={{
                suppressMarkers: true,
                polylineOptions: {
                  strokeColor: '#3B82F6',
                  strokeWeight: 4,
                  strokeOpacity: 0.8
                }
              }}
            />
          )}
        </GoogleMap>
      </div>

      <div className="map-footer">
        <div className="restaurant-info">
          <h4>{restaurant.name}</h4>
          <p>{restaurant.address}</p>
          <p>🕒 {getTodaysHours()}</p>
          {restaurant.phone && (
            <p>📞 {restaurant.phone}</p>
          )}
        </div>

        {/* Distance and time info */}
        {userLocation && distance && travelTime && (
          <div className="travel-info">
            <div className="travel-item">
              <span className="icon">📍</span>
              <span className="text">{distance} away</span>
            </div>
            <div className="travel-item">
              <span className="icon">🚗</span>
              <span className="text">{travelTime} drive</span>
            </div>
          </div>
        )}

        {/* Nearby parking */}
        {nearbyParking.length > 0 && (
          <div className="parking-info">
            <h5>🅿️ Nearby Parking</h5>
            <div className="parking-list">
              {nearbyParking.map((parking, index) => (
                <div key={index} className="parking-item">
                  <span className="parking-name">{parking.name}</span>
                  <span className="parking-rating">
                    {parking.rating ? `⭐ ${parking.rating.toFixed(1)}` : 'No rating'}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="map-actions">
          <button 
            className="action-btn primary"
            onClick={handleGetDirections}
          >
            🧭 Get Directions
          </button>
          {!userLocation && (
            <button 
              className="action-btn secondary"
              onClick={getUserLocation}
              disabled={isLoadingLocation}
            >
              {isLoadingLocation ? '⏳' : '📍'} Find My Location
            </button>
          )}
          <button 
            className="action-btn secondary"
            onClick={() => setShowLandmarks(!showLandmarks)}
          >
            {showLandmarks ? '🏛️ Hide' : '🏛️'} Landmarks
          </button>
        </div>
      </div>
    </div>
  );
};

export default RestaurantMap;
