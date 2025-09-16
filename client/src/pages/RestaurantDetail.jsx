import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { apiService } from '../services/api';
import RestaurantMap from '../components/RestaurantMap';
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
  const [userRSVPs, setUserRSVPs] = useState([]);
  const [loadingRSVPs, setLoadingRSVPs] = useState(false);
  const [reviews, setReviews] = useState([]);
  const [loadingReviews, setLoadingReviews] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [addressCopied, setAddressCopied] = useState(false);
  const [currentWaitTime, setCurrentWaitTime] = useState(null);

  const days = [
    { key: 'monday', label: 'Monday' },
    { key: 'tuesday', label: 'Tuesday' },
    { key: 'wednesday', label: 'Wednesday' },
    { key: 'thursday', label: 'Thursday' },
    { key: 'friday', label: 'Friday' },
    { key: 'saturday', label: 'Saturday' },
    { key: 'sunday', label: 'Sunday' }
  ];

  // Helper functions for location features
  const copyAddress = async () => {
    if (restaurant?.address) {
      try {
        await navigator.clipboard.writeText(restaurant.address);
        setAddressCopied(true);
        setTimeout(() => setAddressCopied(false), 2000);
      } catch (err) {
        console.error('Failed to copy address:', err);
      }
    }
  };

  const getCurrentHours = () => {
    if (!restaurant?.hours) return null;
    const now = new Date();
    const austinTime = new Date(now.toLocaleString("en-US", {timeZone: "America/Chicago"}));
    const currentDay = austinTime.toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();
    return restaurant.hours[currentDay];
  };

  const getParkingInfo = () => {
    // Mock parking info - in real app, this would come from restaurant data
    const parkingOptions = [
      "Free street parking after 6 PM",
      "Valet parking available",
      "Garage parking nearby",
      "Free parking in adjacent lot"
    ];
    return parkingOptions[Math.floor(Math.random() * parkingOptions.length)];
  };

  const getTransitInfo = () => {
    // Mock transit info - in real app, this would come from restaurant data
    const transitOptions = [
      "Bus 3, 5, 7 - 2 min walk",
      "Metro Rail Red Line - 5 min walk",
      "Bus 1, 2, 4 - 3 min walk",
      "Metro Rail Blue Line - 7 min walk"
    ];
    return transitOptions[Math.floor(Math.random() * transitOptions.length)];
  };

  const getNeighborhoodInfo = () => {
    // Mock neighborhood info - in real app, this would come from restaurant data
    const neighborhoods = [
      "Downtown - 5 min from 6th Street",
      "East Austin - 3 min from Rainey Street",
      "South Austin - 2 min from South First",
      "North Austin - 4 min from Domain"
    ];
    return neighborhoods[Math.floor(Math.random() * neighborhoods.length)];
  };

  const getWaitTime = () => {
    // Mock wait time - in real app, this would come from restaurant data
    const waitTimes = ["~15 minutes", "~25 minutes", "~10 minutes", "~30 minutes", "No wait"];
    return waitTimes[Math.floor(Math.random() * waitTimes.length)];
  };

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

  // Fetch Yelp reviews if restaurant has yelpId
  useEffect(() => {
    const fetchReviews = async () => {
      if (!restaurant?.yelpId) return;

      try {
        setLoadingReviews(true);
        const data = await apiService.getYelpReviews(restaurant.yelpId);
        setReviews(data.reviews || []);
      } catch (err) {
        console.error('Error fetching reviews:', err);
      } finally {
        setLoadingReviews(false);
      }
    };

    fetchReviews();
  }, [restaurant?.yelpId]);

  // Fetch user's existing RSVPs when user is available
  useEffect(() => {
    const fetchUserRSVPs = async () => {
      if (!user || !restaurant) return;

      try {
        setLoadingRSVPs(true);
        const rsvps = await apiService.getRSVPs();
        const restaurantRSVPs = rsvps.filter(rsvp => rsvp.restaurantId === restaurant.id);
        setUserRSVPs(restaurantRSVPs);
        
        // Set current RSVP status for selected day
        const currentRSVP = restaurantRSVPs.find(rsvp => rsvp.day === selectedDay);
        if (currentRSVP) {
          setRsvpStatus(currentRSVP.status);
        } else {
          setRsvpStatus('pending');
        }
      } catch (err) {
        console.error('Error fetching user RSVPs:', err);
      } finally {
        setLoadingRSVPs(false);
      }
    };

    fetchUserRSVPs();
  }, [user, restaurant, selectedDay]);

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
      
      // Update local RSVP state
      const updatedRSVPs = userRSVPs.filter(rsvp => !(rsvp.day === selectedDay && rsvp.restaurantId === restaurant.id));
      updatedRSVPs.push({
        id: result.rsvp.id,
        day: selectedDay,
        status: status,
        restaurantId: restaurant.id,
        userId: user.id
      });
      setUserRSVPs(updatedRSVPs);
    } catch (err) {
      console.error('Error saving RSVP:', err);
      if (err.message.includes('401') || err.message.includes('Unauthorized')) {
        setError('Please log in to make an RSVP');
      } else {
        setError(`Failed to save RSVP: ${err.message}`);
      }
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
      if (err.message.includes('401') || err.message.includes('Unauthorized')) {
        setError('Please log in to add to wishlist');
      } else {
        setError(`Failed to add to wishlist: ${err.message}`);
      }
    } finally {
      setRsvpLoading(false);
    }
  };

  const renderStars = (rating) => {
    if (!rating) return null;
    
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 !== 0;
    const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return (
      <div className="rating-stars">
        {[...Array(fullStars)].map((_, i) => (
          <span key={i} className="star filled">★</span>
        ))}
        {hasHalfStar && <span className="star half">☆</span>}
        {[...Array(emptyStars)].map((_, i) => (
          <span key={i + fullStars + (hasHalfStar ? 1 : 0)} className="star empty">☆</span>
        ))}
        <span className="rating-number">{rating.toFixed(1)}</span>
      </div>
    );
  };

  const renderPriceRange = (priceRange) => {
    if (!priceRange) return null;
    
    const priceMap = {
      'Budget': '$',
      'Moderate': '$$',
      'Expensive': '$$$',
      'Very Expensive': '$$$$'
    };
    
    const priceSymbol = priceMap[priceRange] || priceRange;
    
    return (
      <div className="price-range">
        <span className="price-symbol">{priceSymbol}</span>
        <span className="price-label">{priceRange}</span>
      </div>
    );
  };

  const formatHours = (hours) => {
    if (!hours || typeof hours !== 'object') return null;
    
    return Object.entries(hours).map(([day, time]) => (
      <div key={day} className="hours-item">
        <span className="day">{day.charAt(0).toUpperCase() + day.slice(1)}</span>
        <span className="hours">{time}</span>
      </div>
    ));
  };

  const nextImage = () => {
    if (restaurant?.photos?.length > 1) {
      setCurrentImageIndex((prev) => 
        prev === restaurant.photos.length - 1 ? 0 : prev + 1
      );
    }
  };

  const prevImage = () => {
    if (restaurant?.photos?.length > 1) {
      setCurrentImageIndex((prev) => 
        prev === 0 ? restaurant.photos.length - 1 : prev - 1
      );
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
        {restaurant.yelpUrl && (
          <a 
            href={restaurant.yelpUrl} 
            target="_blank" 
            rel="noopener noreferrer"
            className="yelp-link"
          >
            View on Yelp ↗
          </a>
        )}
      </div>

      <div className="restaurant-content">
        {/* Image Gallery */}
        <div className="restaurant-gallery">
          {restaurant.photos && restaurant.photos.length > 0 ? (
            <div className="image-gallery">
              <img 
                src={restaurant.photos[currentImageIndex]} 
                alt={`${restaurant.name} - ${currentImageIndex + 1}`}
                className="main-image"
              />
              {restaurant.photos.length > 1 && (
                <>
                  <button className="gallery-nav prev" onClick={prevImage}>
                    ‹
                  </button>
                  <button className="gallery-nav next" onClick={nextImage}>
                    ›
                  </button>
                  <div className="gallery-indicators">
                    {restaurant.photos.map((_, index) => (
                      <button
                        key={index}
                        className={`indicator ${index === currentImageIndex ? 'active' : ''}`}
                        onClick={() => setCurrentImageIndex(index)}
                      />
                    ))}
                  </div>
                </>
              )}
            </div>
          ) : restaurant.imageUrl ? (
            <div className="single-image">
              <img src={restaurant.imageUrl} alt={restaurant.name} />
            </div>
          ) : (
            <div className="placeholder-image">
              <span>📷 No Images Available</span>
            </div>
          )}
        </div>

        <div className="restaurant-info">
          {/* Rating and Basic Info */}
          <div className="restaurant-meta">
            <div className="rating-section">
              {renderStars(restaurant.rating)}
              {restaurant.reviewCount && (
                <span className="review-count">
                  ({restaurant.reviewCount} reviews)
                </span>
              )}
            </div>
            
            <div className="cuisine-price">
              <span className="cuisine">{restaurant.cuisine}</span>
              {renderPriceRange(restaurant.priceRange)}
            </div>
          </div>

          {/* Location and Contact */}
          <div className="restaurant-details">
            <div className="detail-item">
              <strong>📍 Address:</strong> 
              <span>{restaurant.address}, {restaurant.city}, {restaurant.state} {restaurant.zipCode}</span>
            </div>
            
            {restaurant.phone && (
              <div className="detail-item">
                <strong>📞 Phone:</strong> 
                <a href={`tel:${restaurant.phone}`}>{restaurant.phone}</a>
              </div>
            )}
            
            {restaurant.website && (
              <div className="detail-item">
                <strong>🌐 Website:</strong> 
                <a href={restaurant.website} target="_blank" rel="noopener noreferrer">
                  {restaurant.website}
                </a>
              </div>
            )}

            {restaurant.distance && (
              <div className="detail-item">
                <strong>📍 Distance:</strong> 
                <span>{restaurant.distance} miles from downtown Austin</span>
              </div>
            )}
          </div>

          {/* Description */}
          {restaurant.description && (
            <div className="restaurant-description">
              <h3>About</h3>
              <p>{restaurant.description}</p>
            </div>
          )}

          {/* Specialties */}
          {restaurant.specialties && restaurant.specialties.length > 0 && (
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

          {/* Hours */}
          {restaurant.hours && (
            <div className="restaurant-hours">
              <h3>Hours of Operation</h3>
              <div className="hours-list">
                {formatHours(restaurant.hours)}
              </div>
            </div>
          )}

          {/* Yelp Reviews */}
          {reviews.length > 0 && (
            <div className="reviews-section">
              <h3>Recent Reviews</h3>
              {loadingReviews ? (
                <div className="loading-reviews">
                  <p>Loading reviews...</p>
                </div>
              ) : (
                <div className="reviews-list">
                  {reviews.slice(0, 3).map((review, index) => (
                    <div key={index} className="review-item">
                      <div className="review-header">
                        <div className="reviewer-info">
                          <img 
                            src={review.user?.image_url || '/default-avatar.png'} 
                            alt={review.user?.name || 'Anonymous'}
                            className="reviewer-avatar"
                          />
                          <div className="reviewer-details">
                            <span className="reviewer-name">
                              {review.user?.name || 'Anonymous'}
                            </span>
                            <div className="review-rating">
                              {renderStars(review.rating)}
                            </div>
                          </div>
                        </div>
                        <span className="review-date">
                          {new Date(review.time_created).toLocaleDateString()}
                        </span>
                      </div>
                      <p className="review-text">{review.text}</p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Location & Map Section */}
        {restaurant.coordinates && (
          <div className="location-section">
            <h2>📍 Find Us This Week</h2>
            
            {/* Quick Info Cards */}
            <div className="quick-info-cards">
              {getCurrentHours() && (
                <div className="info-card hours">
                  <span className="card-icon">⏰</span>
                  <span className="card-text">{getCurrentHours()}</span>
                </div>
              )}
              
              <div className="info-card parking">
                <span className="card-icon">🚗</span>
                <span className="card-text">{getParkingInfo()}</span>
              </div>
              
              <div className="info-card neighborhood">
                <span className="card-icon">📍</span>
                <span className="card-text">{getNeighborhoodInfo()}</span>
              </div>
              
              <div className="info-card wait-time">
                <span className="card-icon">👥</span>
                <span className="card-text">Current wait: {getWaitTime()}</span>
              </div>
            </div>

            {/* Address with Copy Button */}
            <div className="address-section">
              <div className="address-info">
                <h3>Address</h3>
                <p className="restaurant-address">{restaurant.address}</p>
                <button 
                  className={`copy-address-btn ${addressCopied ? 'copied' : ''}`}
                  onClick={copyAddress}
                >
                  {addressCopied ? '✓ Copied!' : '📋 Copy Address'}
                </button>
              </div>
              
              <div className="transit-info">
                <h4>🚌 Public Transit</h4>
                <p>{getTransitInfo()}</p>
              </div>
            </div>

            {/* Restaurant Map */}
            <RestaurantMap 
              restaurant={restaurant}
              className="restaurant-map-section"
              darkMode={true}
            />
          </div>
        )}

        {/* RSVP Section */}
        {user ? (
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

            {loadingRSVPs ? (
              <div className="rsvp-loading">
                <p>Loading your RSVPs...</p>
              </div>
            ) : (
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
            )}

            {/* Show existing RSVP status */}
            {rsvpStatus !== 'pending' && (
              <div className="current-rsvp-status">
                <p>Your current RSVP for {days.find(d => d.key === selectedDay)?.label}: 
                  <span className={`status-${rsvpStatus}`}>
                    {rsvpStatus === 'going' ? ' Going' : 
                     rsvpStatus === 'maybe' ? ' Maybe' : 
                     rsvpStatus === 'not_going' ? ' Not Going' : ''}
                  </span>
                </p>
              </div>
            )}
          </div>
        ) : (
          <div className="auth-prompt">
            <h3>RSVP Required</h3>
            <p>Please log in to make RSVPs and add to wishlist.</p>
            <button onClick={() => navigate('/login')} className="login-btn">
              Log In
            </button>
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
      </div>
    </div>
  );
};

export default RestaurantDetail;