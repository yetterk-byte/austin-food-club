import React from 'react';
import './SimpleMap.css';

const SimpleMap = ({ restaurant, className = '' }) => {
  if (!restaurant?.coordinates) {
    return (
      <div className={`simple-map-container ${className}`}>
        <div className="simple-map-placeholder">
          <div className="placeholder-icon">📍</div>
          <p>Location not available</p>
        </div>
      </div>
    );
  }

  const { latitude, longitude } = restaurant.coordinates;
  
  // For now, let's show the location information directly since the API key isn't working
  return (
    <div className={`simple-map-container ${className}`}>
      <div className="map-fallback">
        <div className="placeholder-icon">📍</div>
        <div className="location-details">
          <p><strong>{restaurant.name}</strong></p>
          <p>{restaurant.address}</p>
          <div className="map-actions">
            <a 
              href={`https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`}
              target="_blank"
              rel="noopener noreferrer"
              className="directions-link"
            >
              Open in Google Maps
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SimpleMap;
