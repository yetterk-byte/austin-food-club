import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { apiService } from '../../services/api';
import RestaurantCard from '../../components/RestaurantCard';
import SimpleMap from '../../components/SimpleMap';
import './CurrentPage.css';

const CurrentPage = ({ onDayChange, onStatusChange }) => {
  const { user } = useAuth();
  const [selectedDay, setSelectedDay] = useState(null);
  const [rsvpStatus, setRsvpStatus] = useState('pending');
  const [restaurant, setRestaurant] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rsvpLoading, setRsvpLoading] = useState(false);
  const [countdown, setCountdown] = useState('');
  const [message, setMessage] = useState('');
  const [rsvpCounts, setRsvpCounts] = useState({});

  // Calculate countdown to next Tuesday at 9:00 AM CT
  const calculateCountdown = () => {
    const now = new Date();
    const austinTime = new Date(now.toLocaleString("en-US", {timeZone: "America/Chicago"}));
    
    // Get next Tuesday at 9:00 AM CT
    const nextTuesday = new Date(austinTime);
    const daysUntilTuesday = (2 - austinTime.getDay() + 7) % 7; // Tuesday is day 2
    const daysToAdd = daysUntilTuesday === 0 ? 7 : daysUntilTuesday; // If it's Tuesday, get next Tuesday
    
    nextTuesday.setDate(austinTime.getDate() + daysToAdd);
    nextTuesday.setHours(9, 0, 0, 0); // 9:00 AM
    
    const timeDiff = nextTuesday.getTime() - austinTime.getTime();
    
    if (timeDiff <= 0) {
      return "Today at 9:00 AM CT";
    }
    
    // If it's Tuesday and before 9 AM, show special message
    if (austinTime.getDay() === 2 && austinTime.getHours() < 9) {
      const hoursUntil = 9 - austinTime.getHours();
      const minutesUntil = 60 - austinTime.getMinutes();
      if (hoursUntil > 1) {
        return `${hoursUntil - 1} hour${hoursUntil - 1 !== 1 ? 's' : ''}, ${minutesUntil} minute${minutesUntil !== 1 ? 's' : ''}`;
      } else {
        return `${minutesUntil} minute${minutesUntil !== 1 ? 's' : ''}`;
      }
    }
    
    const days = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((timeDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000);
    
    if (days > 0) {
      return `${days} day${days !== 1 ? 's' : ''}, ${hours} hour${hours !== 1 ? 's' : ''}`;
    } else if (hours > 0) {
      return `${hours} hour${hours !== 1 ? 's' : ''}, ${minutes} minute${minutes !== 1 ? 's' : ''}`;
    } else if (minutes > 0) {
      return `${minutes} minute${minutes !== 1 ? 's' : ''}, ${seconds} second${seconds !== 1 ? 's' : ''}`;
    } else {
      return `${seconds} second${seconds !== 1 ? 's' : ''}`;
    }
  };

  // Update countdown every second for better precision
  useEffect(() => {
    const updateCountdown = () => {
      setCountdown(calculateCountdown());
    };
    
    updateCountdown(); // Initial calculation
    const interval = setInterval(updateCountdown, 1000); // Update every second
    
    return () => clearInterval(interval);
  }, []);

  // Fetch featured restaurant data from API
  useEffect(() => {
    const fetchRestaurant = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await apiService.getFeaturedRestaurant();
        console.log('Featured restaurant response:', response);
        
        // Handle different response structures
        if (response.restaurant) {
          setRestaurant(response.restaurant);
        } else if (response.success && response.restaurant) {
          setRestaurant(response.restaurant);
        } else {
          setRestaurant(response);
        }
      } catch (err) {
        console.error('Error fetching featured restaurant:', err);
        setError('Failed to load featured restaurant data. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    fetchRestaurant();
  }, []);

  // Fetch RSVP counts and user's current RSVP when restaurant is loaded
  useEffect(() => {
    const fetchRSVPData = async () => {
      if (!restaurant?.id) return;
      
      try {
        // Fetch RSVP counts
        const countsResponse = await apiService.getRSVPCounts(restaurant.id);
        if (countsResponse.success) {
          setRsvpCounts(countsResponse.dayCounts || {});
        }

        // Fetch user's current RSVP if logged in
        if (user) {
          const rsvpResponse = await apiService.getRSVPs();
          if (rsvpResponse.rsvps) {
            const userRsvp = rsvpResponse.rsvps.find(rsvp => rsvp.restaurantId === restaurant.id);
            if (userRsvp) {
              setRsvpStatus(userRsvp.status);
              setSelectedDay(userRsvp.day);
            }
          }
        }
      } catch (err) {
        console.error('Error fetching RSVP data:', err);
        // Don't show error to user, just log it
      }
    };

    fetchRSVPData();
  }, [restaurant?.id, user]);

  // All possible days
  const allDays = [
    { id: 'thursday', label: 'Thu', full: 'Thursday' },
    { id: 'friday', label: 'Fri', full: 'Friday' },
    { id: 'saturday', label: 'Sat', full: 'Saturday' },
    { id: 'sunday', label: 'Sun', full: 'Sunday' }
  ];

  // Filter days based on restaurant hours - only show days when restaurant is open
  const getAvailableDays = () => {
    if (!restaurant?.hours) return allDays;
    
    return allDays.filter(day => {
      const dayHours = restaurant.hours[day.id];
      // Consider restaurant open if:
      // 1. Hours are defined and not "Closed"
      // 2. Hours are not empty/null
      // 3. Hours don't contain "Closed" text
      return dayHours && 
             dayHours !== 'Closed' && 
             dayHours.trim() !== '' && 
             !dayHours.toLowerCase().includes('closed');
    });
  };

  const availableDays = getAvailableDays();

  // Set default selected day when available days change
  useEffect(() => {
    if (availableDays.length > 0 && !selectedDay) {
      setSelectedDay(availableDays[0].id);
    } else if (availableDays.length === 0) {
      setSelectedDay(null);
    } else if (selectedDay && !availableDays.find(day => day.id === selectedDay)) {
      // If currently selected day is no longer available, select first available day
      setSelectedDay(availableDays[0].id);
    }
  }, [availableDays, selectedDay]);

  // Save RSVP to backend
  const saveRsvp = async (day, status) => {
    if (!user) {
      setError('You must be logged in to count yourself in');
      return;
    }

    if (!restaurant?.id) {
      setError('Restaurant information is not available. Please try again.');
      return;
    }

    try {
      setRsvpLoading(true);
      setError(null);
      
      console.log('Saving RSVP:', { day, status, restaurantId: restaurant.id });
      
      const data = await apiService.createRSVP({
        day,
        status,
        restaurantId: restaurant.id
      });
      
      console.log('RSVP saved successfully:', data);
      return data;
    } catch (err) {
      console.error('Error saving RSVP:', err);
      if (err.message.includes('401') || err.message.includes('Unauthorized')) {
        setError('Please log in to count yourself in');
      } else {
        setError(`Failed to save your response: ${err.message}`);
      }
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
    if (!selectedDay) {
      setError('Please select a day first');
      return;
    }
    
    try {
      await saveRsvp(selectedDay, 'going');
      setRsvpStatus('going');
      
      // Refresh RSVP counts
      if (restaurant?.id) {
        const response = await apiService.getRSVPCounts(restaurant.id);
        if (response.success) {
          setRsvpCounts(response.dayCounts || {});
        }
      }
      
      // Show success message with selected day
      const selectedDayName = availableDays.find(d => d.id === selectedDay)?.full || selectedDay;
      setError(''); // Clear any previous errors
      setMessage(`See you ${selectedDayName}!`);
      
      if (onStatusChange) {
        onStatusChange('going');
      }
    } catch (err) {
      // Error already handled in saveRsvp
    }
  };

  const handleNotGoing = async () => {
    if (!selectedDay) {
      setError('Please select a day first');
      return;
    }
    
    try {
      await saveRsvp(selectedDay, 'not_going');
      setRsvpStatus('not-going');
      
      // Refresh RSVP counts
      if (restaurant?.id) {
        const response = await apiService.getRSVPCounts(restaurant.id);
        if (response.success) {
          setRsvpCounts(response.dayCounts || {});
        }
      }
      
      // Show success message for not going
      setError(''); // Clear any previous errors
      setMessage('See you next time!');
      
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
    console.log('No restaurant data available');
    return <div className="current-page loading">No restaurant data available</div>;
  }

  console.log('Rendering restaurant:', restaurant);

  return (
    <div className="current-page">
      {/* Featured Restaurant Header */}
      <div className="featured-header">
        <div className="featured-badge">
          <span className="badge-text">Restaurant of the Week</span>
        </div>
        <div className="countdown-timer">
          <span className="countdown-label">Next restaurant in:</span>
          <span className="countdown-value">{countdown || 'Calculating...'}</span>
        </div>
      </div>

      {/* Featured Restaurant Card */}
      <div className="featured-restaurant">
        <RestaurantCard 
          restaurant={restaurant} 
        />
      </div>

      {/* Restaurant Details */}
      <div className="restaurant-details">
        <h2>About {restaurant?.name || 'Restaurant'}</h2>
        <p>{restaurant?.description || 'No description available.'}</p>
        
        {restaurant?.specialties && restaurant.specialties.length > 0 && (
          <div className="specialties">
            <h3>Specialties</h3>
            <div className="specialty-tags">
              {restaurant.specialties.map((specialty, index) => (
                <span key={index} className="specialty-tag">{specialty}</span>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Restaurant Map Section */}
      {restaurant?.coordinates && (
        <div className="restaurant-map-section">
          <h2>📍 Find Us This Week</h2>
          <div className="map-container">
            <SimpleMap 
              restaurant={restaurant}
              className="current-page-map"
            />
          </div>
        </div>
      )}

      {/* RSVP Section */}
      <div className="rsvp-section">
        <h2>See you there?</h2>
        
        {user ? (
          <>
            {/* Day Selection */}
            <div className="day-selection">
              <h3>Select Day</h3>
              <p className="rsvp-limit-notice">You can only RSVP for one day per restaurant</p>
              {availableDays.length > 0 ? (
                <div className="day-buttons">
                  {availableDays.map((day) => {
                    const count = rsvpCounts[day.id] || 0;
                    return (
                      <button
                        key={day.id}
                        className={`day-button ${selectedDay === day.id ? 'selected' : ''}`}
                        onClick={() => handleDaySelect(day.id)}
                      >
                        <span className="day-label">{day.label}</span>
                        {count > 0 && (
                          <span className="day-count">
                            {count} {count === 1 ? 'person' : 'people'}
                          </span>
                        )}
                      </button>
                    );
                  })}
                </div>
              ) : (
                <div className="no-available-days">
                  <p>This restaurant is currently closed on all available reservation days.</p>
                  <p>Please check back later or contact the restaurant directly.</p>
                </div>
              )}
            </div>

            {/* RSVP Actions */}
            {availableDays.length > 0 && selectedDay && (
              <div className="rsvp-actions">
                <button
                  className={`rsvp-button reserve ${rsvpStatus === 'going' ? 'active' : ''}`}
                  onClick={handleReserve}
                  disabled={rsvpLoading}
                >
                  {rsvpLoading ? 'Saving...' : 'Count Me In'}
                </button>
                <button
                  className={`rsvp-button not-going ${rsvpStatus === 'not-going' ? 'active' : ''}`}
                  onClick={handleNotGoing}
                  disabled={rsvpLoading}
                >
                  {rsvpLoading ? 'Saving...' : 'Count Me Out'}
                </button>
              </div>
            )}

            {/* Status Display - Hidden for cleaner UI */}
            {/* {rsvpStatus !== 'pending' && (
              <div className="status-display">
                <span className={`status-badge ${rsvpStatus}`}>
                  {rsvpStatus === 'going' ? 'Counted In' : 'Counted Out'}
                </span>
                <span className="status-day">
                  {availableDays.find(d => d.id === selectedDay)?.full}
                </span>
              </div>
            )} */}

            {/* Success Message */}
            {message && (
              <div className="success-message">
                <p>{message}</p>
              </div>
            )}
          </>
        ) : (
          <div className="auth-prompt">
            <h3>Login Required</h3>
            <p>Please log in to make RSVPs and reserve your spot.</p>
            <button 
              onClick={() => window.location.href = '/login'} 
              className="login-btn"
            >
              Log In
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default CurrentPage;