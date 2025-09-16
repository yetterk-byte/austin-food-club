import React, { useState, useEffect } from 'react';
import { getOptimizedStaticMap, isStaticMapsConfigured } from '../utils/staticMapUtils';
import './StaticMap.css';

const StaticMap = ({ 
  restaurant, 
  className = '', 
  onClick, 
  showLoadButton = true,
  loadButtonText = 'Load Interactive Map',
  options = {}
}) => {
  const [mapConfig, setMapConfig] = useState(null);
  const [imageLoaded, setImageLoaded] = useState(false);
  const [imageError, setImageError] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  // Generate map configuration
  useEffect(() => {
    if (restaurant) {
      const config = getOptimizedStaticMap(restaurant, {
        containerClass: '.static-map-container',
        ...options
      });
      setMapConfig(config);
    }
  }, [restaurant?.id, restaurant?.coordinates?.latitude, restaurant?.coordinates?.longitude, options.width, options.height]);

  // Handle image load
  const handleImageLoad = () => {
    setImageLoaded(true);
    setImageError(false);
  };

  // Handle image error
  const handleImageError = () => {
    setImageError(true);
    if (retryCount < 2) {
      // Retry with different parameters
      setTimeout(() => {
        setRetryCount(prev => prev + 1);
        setMapConfig(prev => ({
          ...prev,
          url: prev.url + `&retry=${retryCount + 1}`
        }));
      }, 1000);
    }
  };

  // Handle click to load interactive map
  const handleClick = () => {
    if (onClick) {
      onClick();
    }
  };

  // Show loading state
  if (!mapConfig || !restaurant) {
    return (
      <div className={`static-map-container loading ${className}`}>
        <div className="static-map-loading">
          <div className="loading-spinner"></div>
          <p>Loading map...</p>
        </div>
      </div>
    );
  }

  // Show error state
  if (imageError && retryCount >= 2) {
    return (
      <div className={`static-map-container error ${className}`}>
        <div className="static-map-error">
          <div className="error-icon">🗺️</div>
          <p>Map unavailable</p>
          {showLoadButton && (
            <button 
              className="load-interactive-btn"
              onClick={handleClick}
            >
              {loadButtonText}
            </button>
          )}
        </div>
      </div>
    );
  }

  // Show not configured state
  if (!isStaticMapsConfigured()) {
    return (
      <div className={`static-map-container not-configured ${className}`}>
        <div className="static-map-placeholder">
          <div className="placeholder-icon">📍</div>
          <p>{restaurant?.name || 'Restaurant'}</p>
          <p className="address">{restaurant?.address}</p>
          <div className="location-info">
            <p>📍 {restaurant?.address}</p>
            <p>🗺️ Interactive map available</p>
          </div>
          {showLoadButton && (
            <button 
              className="load-interactive-btn"
              onClick={handleClick}
            >
              {loadButtonText}
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className={`static-map-container ${className}`}>
      <div className="static-map-wrapper">
        <img
          src={mapConfig.url}
          alt={mapConfig.alt}
          width={mapConfig.width}
          height={mapConfig.height}
          loading={mapConfig.loading}
          onLoad={handleImageLoad}
          onError={handleImageError}
          className={`static-map-image ${imageLoaded ? 'loaded' : 'loading'}`}
        />
        
        {/* Loading overlay */}
        {!imageLoaded && !imageError && (
          <div className="static-map-loading-overlay">
            <div className="loading-spinner"></div>
            <p>Loading map...</p>
          </div>
        )}

        {/* Click to load interactive map overlay */}
        {imageLoaded && showLoadButton && (
          <div className="static-map-overlay" onClick={handleClick}>
            <div className="overlay-content">
              <div className="overlay-icon">🗺️</div>
              <p>Click to load interactive map</p>
              <button className="load-interactive-btn">
                {loadButtonText}
              </button>
            </div>
          </div>
        )}

        {/* Map attribution */}
        <div className="static-map-attribution">
          <span>© Google Maps</span>
        </div>
      </div>
    </div>
  );
};

export default StaticMap;
