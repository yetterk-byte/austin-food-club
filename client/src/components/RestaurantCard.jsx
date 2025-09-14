import React from 'react';
import './RestaurantCard.css';

const RestaurantCard = ({ restaurant }) => {
  if (!restaurant) return null;

  const formatHours = (hours) => {
    if (!hours) return 'Hours not available';
    
    const dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return dayNames.map((day, index) => (
      <div key={day} className="hours-row">
        <span className="day">{dayLabels[index]}:</span>
        <span className="hours">{hours[day] || 'Closed'}</span>
      </div>
    ));
  };

  return (
    <div className="restaurant-card">
      <div className="restaurant-header">
        <h2 className="restaurant-name">{restaurant.name}</h2>
        <div className="restaurant-rating">
          <span className="rating">⭐ {restaurant.rating}</span>
          <span className="price-range">{restaurant.priceRange}</span>
        </div>
      </div>

      <div className="restaurant-info">
        <div className="info-section">
          <h3>Location</h3>
          <p>{restaurant.address}</p>
          {restaurant.phone && <p>{restaurant.phone}</p>}
        </div>

        <div className="info-section">
          <h3>Hours</h3>
          <div className="hours-container">
            {formatHours(restaurant.hours)}
          </div>
        </div>

        {restaurant.description && (
          <div className="info-section">
            <h3>About</h3>
            <p>{restaurant.description}</p>
          </div>
        )}

        {restaurant.specialties && restaurant.specialties.length > 0 && (
          <div className="info-section">
            <h3>Specialties</h3>
            <div className="specialties">
              {restaurant.specialties.map((specialty, index) => (
                <span key={index} className="specialty-tag">
                  {specialty}
                </span>
              ))}
            </div>
          </div>
        )}

        {restaurant.waitTime && (
          <div className="info-section wait-time">
            <h3>Wait Time</h3>
            <p className="wait-time-text">{restaurant.waitTime}</p>
          </div>
        )}

        {restaurant.website && (
          <div className="info-section">
            <a 
              href={restaurant.website} 
              target="_blank" 
              rel="noopener noreferrer"
              className="website-link"
            >
              Visit Website
            </a>
          </div>
        )}
      </div>
    </div>
  );
};

export default RestaurantCard;
