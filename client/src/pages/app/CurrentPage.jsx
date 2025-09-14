import React, { useState, useEffect } from 'react';
import './CurrentPage.css';

const CurrentPage = ({ onDayChange, onStatusChange }) => {
  const [selectedDay, setSelectedDay] = useState('wednesday');
  const [rsvpStatus, setRsvpStatus] = useState('pending');
  const [restaurant, setRestaurant] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rsvpLoading, setRsvpLoading] = useState(false);

  // Mock userId for now - in a real app this would come from auth context
  const userId = 'user123';

  // Fetch restaurant data from API
  useEffect(() => {
    const fetchRestaurant = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await fetch('http://localhost:3001/api/restaurants/current');
        
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        setRestaurant(data);
      } catch (err) {
        console.error('Error fetching restaurant:', err);
        setError('Failed to load restaurant data. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    fetchRestaurant();
  }, []);

  const days = [
    { id: 'tuesday', label: 'Tue', full: 'Tuesday' },
    { id: 'wednesday', label: 'Wed', full: 'Wednesday' },
    { id: 'thursday', label: 'Thu', full: 'Thursday' },
    { id: 'friday', label: 'Fri', full: 'Friday' },
    { id: 'saturday', label: 'Sat', full: 'Saturday' }
  ];

  // Save RSVP to backend
  const saveRsvp = async (day, status) => {
    try {
      setRsvpLoading(true);
      const response = await fetch('http://localhost:3001/api/rsvp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId,
          day,
          status
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      console.log('RSVP saved successfully:', data);
      return data;
    } catch (err) {
      console.error('Error saving RSVP:', err);
      setError(`Failed to save RSVP: ${err.message}`);
      throw err;
    } finally {
      setRsvpLoading(false);
    }
  };

  const handleDaySelect = (dayId) => {
    setSelectedDay(dayId);
    if (onDayChange) {
      onDayChange(dayId);
    }
  };

  const handleReserve = async () => {
    try {
      await saveRsvp(selectedDay, 'going');
      setRsvpStatus('going');
      if (onStatusChange) {
        onStatusChange('going');
      }
    } catch (err) {
      // Error already handled in saveRsvp
    }
  };

  const handleNotGoing = async () => {
    try {
      await saveRsvp(selectedDay, 'not_going');
      setRsvpStatus('not-going');
      if (onStatusChange) {
        onStatusChange('not-going');
      }
    } catch (err) {
      // Error already handled in saveRsvp
    }
  };

  if (loading) {
    return <div className="current-page loading">Loading restaurant data...</div>;
  }

  if (error) {
    return (
      <div className="current-page error">
        <div className="error-message">
          <h2>Oops! Something went wrong</h2>
          <p>{error}</p>
          <button 
            className="retry-button" 
            onClick={() => window.location.reload()}
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  if (!restaurant) {
    return <div className="current-page loading">No restaurant data available</div>;
  }

  return (
    <div className="current-page">
      {/* Hero Section */}
      <div className="hero-section">
        <div className="hero-image">
          <div className="image-placeholder">
            <span>Franklin Barbecue</span>
          </div>
        </div>
        <div className="hero-overlay">
          <h1 className="restaurant-name">{restaurant.name}</h1>
          <div className="restaurant-meta">
            <span className="cuisine">{restaurant.cuisine}</span>
            <span className="price">{restaurant.priceRange}</span>
            <span className="location">East Austin</span>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-value">{restaurant.waitTime}</div>
          <div className="stat-label">Wait Time</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">9:30 AM</div>
          <div className="stat-label">Arrival</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{restaurant.rating}</div>
          <div className="stat-label">Rating</div>
        </div>
      </div>

      {/* About Section */}
      <div className="about-section">
        <h2>About</h2>
        <p>{restaurant.description}</p>
        <div className="specialties">
          <h3>Specialties</h3>
          <div className="specialty-tags">
            {restaurant.specialties.map((specialty, index) => (
              <span key={index} className="specialty-tag">{specialty}</span>
            ))}
          </div>
        </div>
      </div>

      {/* RSVP Section */}
      <div className="rsvp-section">
        <h2>Reserve Your Spot</h2>
        
        {/* Day Selection */}
        <div className="day-selection">
          <h3>Select Day</h3>
          <div className="day-buttons">
            {days.map((day) => (
              <button
                key={day.id}
                className={`day-button ${selectedDay === day.id ? 'selected' : ''}`}
                onClick={() => handleDaySelect(day.id)}
              >
                <span className="day-label">{day.label}</span>
                <span className="day-hours">{restaurant.hours[day.id] || 'Closed'}</span>
              </button>
            ))}
          </div>
        </div>

        {/* RSVP Actions */}
        <div className="rsvp-actions">
          <button
            className={`rsvp-button reserve ${rsvpStatus === 'going' ? 'active' : ''}`}
            onClick={handleReserve}
            disabled={rsvpLoading}
          >
            {rsvpLoading ? 'Saving...' : 'Reserve Your Spot'}
          </button>
          <button
            className={`rsvp-button not-going ${rsvpStatus === 'not-going' ? 'active' : ''}`}
            onClick={handleNotGoing}
            disabled={rsvpLoading}
          >
            {rsvpLoading ? 'Saving...' : 'Not Going This Week'}
          </button>
        </div>

        {/* Status Display */}
        {rsvpStatus !== 'pending' && (
          <div className="status-display">
            <span className={`status-badge ${rsvpStatus}`}>
              {rsvpStatus === 'going' ? 'Going' : 'Not Going'}
            </span>
            <span className="status-day">
              {days.find(d => d.id === selectedDay)?.full}
            </span>
          </div>
        )}
      </div>
    </div>
  );
};

export default CurrentPage;