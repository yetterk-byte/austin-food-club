import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { apiService } from '../services/api';
import './RestaurantDetail.css';

const RestaurantDetail = () => {
  const { restaurantId } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [restaurant, setRestaurant] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rsvpLoading, setRsvpLoading] = useState(false);
  const [selectedDay, setSelectedDay] = useState('wednesday');
  const [rsvpStatus, setRsvpStatus] = useState('pending');

  const days = [
    { key: 'monday', label: 'Monday' },
    { key: 'tuesday', label: 'Tuesday' },
    { key: 'wednesday', label: 'Wednesday' },
    { key: 'thursday', label: 'Thursday' },
    { key: 'friday', label: 'Friday' },
    { key: 'saturday', label: 'Saturday' },
    { key: 'sunday', label: 'Sunday' }
  ];

  useEffect(() => {
    const fetchRestaurant = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await apiService.getRestaurant(restaurantId);
        setRestaurant(data);
      } catch (err) {
        console.error('Error fetching restaurant:', err);
        setError('Failed to load restaurant details. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    if (restaurantId) {
      fetchRestaurant();
    }
  }, [restaurantId]);

  const handleRSVP = async (status) => {
    if (!user) {
      setError('You must be logged in to make an RSVP');
      return;
    }

    try {
      setRsvpLoading(true);
      setError(null);
      
      const result = await apiService.createRSVP({
        day: selectedDay,
        status: status,
        restaurantId: restaurant.id
      });
      
      console.log('RSVP saved successfully:', result);
      setRsvpStatus(status);
    } catch (err) {
      console.error('Error saving RSVP:', err);
      setError(`Failed to save RSVP: ${err.message}`);
    } finally {
      setRsvpLoading(false);
    }
  };

  const handleAddToWishlist = async () => {
    if (!user) {
      setError('You must be logged in to add to wishlist');
      return;
    }

    try {
      setRsvpLoading(true);
      setError(null);
      
      const result = await apiService.addToWishlist(restaurant.id);
      console.log('Added to wishlist:', result);
    } catch (err) {
      console.error('Error adding to wishlist:', err);
      setError(`Failed to add to wishlist: ${err.message}`);
    } finally {
      setRsvpLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="restaurant-detail-container">
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading restaurant details...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="restaurant-detail-container">
        <div className="error-container">
          <h3>Error</h3>
          <p>{error}</p>
          <button onClick={() => navigate(-1)} className="back-btn">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  if (!restaurant) {
    return (
      <div className="restaurant-detail-container">
        <div className="error-container">
          <h3>Restaurant Not Found</h3>
          <p>The restaurant you're looking for doesn't exist.</p>
          <button onClick={() => navigate(-1)} className="back-btn">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="restaurant-detail-container">
      <div className="restaurant-header">
        <button onClick={() => navigate(-1)} className="back-btn">
          ← Back
        </button>
        <h1>{restaurant.name}</h1>
      </div>

      <div className="restaurant-content">
        <div className="restaurant-image">
          {restaurant.imageUrl ? (
            <img src={restaurant.imageUrl} alt={restaurant.name} />
          ) : (
            <div className="placeholder-image">
              <span>No Image</span>
            </div>
          )}
        </div>

        <div className="restaurant-info">
          <div className="restaurant-meta">
            <span className="cuisine">{restaurant.cuisine}</span>
            <span className="price-range">{restaurant.priceRange}</span>
            <span className="rating">⭐ {restaurant.rating}</span>
          </div>

          <div className="restaurant-details">
            <p><strong>Address:</strong> {restaurant.address}</p>
            <p><strong>Phone:</strong> {restaurant.phone}</p>
            {restaurant.website && (
              <p><strong>Website:</strong> <a href={restaurant.website} target="_blank" rel="noopener noreferrer">{restaurant.website}</a></p>
            )}
          </div>

          <div className="restaurant-description">
            <h3>About</h3>
            <p>{restaurant.description}</p>
          </div>

          {restaurant.specialties && (
            <div className="restaurant-specialties">
              <h3>Specialties</h3>
              <div className="specialties-list">
                {restaurant.specialties.map((specialty, index) => (
                  <span key={index} className="specialty-tag">
                    {specialty}
                  </span>
                ))}
              </div>
            </div>
          )}

          <div className="restaurant-hours">
            <h3>Hours</h3>
            <div className="hours-list">
              {Object.entries(restaurant.hours || {}).map(([day, hours]) => (
                <div key={day} className="hours-item">
                  <span className="day">{day.charAt(0).toUpperCase() + day.slice(1)}</span>
                  <span className="hours">{hours}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* RSVP Section */}
        {user && (
          <div className="rsvp-section">
            <h3>Make an RSVP</h3>
            
            <div className="day-selector">
              <label>Select Day:</label>
              <select 
                value={selectedDay} 
                onChange={(e) => setSelectedDay(e.target.value)}
                className="day-select"
              >
                {days.map(day => (
                  <option key={day.key} value={day.key}>
                    {day.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="rsvp-buttons">
              <button
                onClick={() => handleRSVP('going')}
                disabled={rsvpLoading}
                className={`rsvp-btn going ${rsvpStatus === 'going' ? 'active' : ''}`}
              >
                {rsvpLoading ? 'Saving...' : 'Going'}
              </button>
              <button
                onClick={() => handleRSVP('maybe')}
                disabled={rsvpLoading}
                className={`rsvp-btn maybe ${rsvpStatus === 'maybe' ? 'active' : ''}`}
              >
                {rsvpLoading ? 'Saving...' : 'Maybe'}
              </button>
              <button
                onClick={() => handleRSVP('not_going')}
                disabled={rsvpLoading}
                className={`rsvp-btn not-going ${rsvpStatus === 'not_going' ? 'active' : ''}`}
              >
                {rsvpLoading ? 'Saving...' : 'Not Going'}
              </button>
            </div>
          </div>
        )}

        {/* Wishlist Section */}
        {user && (
          <div className="wishlist-section">
            <button
              onClick={handleAddToWishlist}
              disabled={rsvpLoading}
              className="wishlist-btn"
            >
              {rsvpLoading ? 'Adding...' : 'Add to Wishlist'}
            </button>
          </div>
        )}

        {!user && (
          <div className="auth-prompt">
            <p>Please log in to make RSVPs and add to wishlist.</p>
            <button onClick={() => navigate('/login')} className="login-btn">
              Log In
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default RestaurantDetail;
