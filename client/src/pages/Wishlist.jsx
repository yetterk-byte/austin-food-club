import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { apiService } from '../services/api';
import './Wishlist.css';

const Wishlist = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [wishlist, setWishlist] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [availableRestaurants, setAvailableRestaurants] = useState([]);
  const [loadingRestaurants, setLoadingRestaurants] = useState(false);

  useEffect(() => {
    const fetchWishlist = async () => {
      if (!user) {
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        setError(null);
        const data = await apiService.getWishlist();
        setWishlist(data.wishlist || []);
      } catch (err) {
        console.error('Error fetching wishlist:', err);
        setError('Failed to load wishlist. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    fetchWishlist();
  }, [user]);

  const handleRemoveFromWishlist = async (restaurantId) => {
    try {
      setError(null);
      await apiService.removeFromWishlist(restaurantId);
      
      // Update local state
      setWishlist(prev => prev.filter(item => item.restaurant.id !== restaurantId));
    } catch (err) {
      console.error('Error removing from wishlist:', err);
      setError(`Failed to remove from wishlist: ${err.message}`);
    }
  };

  const handleRestaurantClick = (restaurantId) => {
    navigate(`/restaurant/${restaurantId}`);
  };

  const handleAddToWishlist = async (restaurantId) => {
    try {
      setError(null);
      await apiService.addToWishlist(restaurantId);
      
      // Refresh wishlist
      const data = await apiService.getWishlist();
      setWishlist(data.wishlist || []);
      
      // Close modal
      setShowAddModal(false);
    } catch (err) {
      console.error('Error adding to wishlist:', err);
      setError(`Failed to add to wishlist: ${err.message}`);
    }
  };

  const handleShowAddModal = async () => {
    setShowAddModal(true);
    if (availableRestaurants.length === 0) {
      try {
        setLoadingRestaurants(true);
        const restaurants = await apiService.getRestaurants();
        setAvailableRestaurants(restaurants);
      } catch (err) {
        console.error('Error fetching restaurants:', err);
        setError('Failed to load restaurants');
      } finally {
        setLoadingRestaurants(false);
      }
    }
  };

  const handleCloseAddModal = () => {
    setShowAddModal(false);
  };

  // Check if restaurant is already in wishlist
  const isInWishlist = (restaurantId) => {
    return wishlist.some(item => item.restaurant.id === restaurantId);
  };

  if (!user) {
    return (
      <div className="wishlist-container">
        <div className="auth-prompt">
          <h2>Please Log In</h2>
          <p>You need to be logged in to view your wishlist.</p>
          <button onClick={() => navigate('/login')} className="login-btn">
            Log In
          </button>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="wishlist-container">
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading your wishlist...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="wishlist-container">
        <div className="error-container">
          <h3>Error</h3>
          <p>{error}</p>
          <button onClick={() => window.location.reload()} className="retry-btn">
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="wishlist-container">
      <div className="wishlist-header">
        <div className="header-info">
          <h1>Your Wishlist</h1>
          <p>{wishlist.length} restaurant{wishlist.length !== 1 ? 's' : ''} saved</p>
        </div>
        <button onClick={handleShowAddModal} className="add-restaurant-btn">
          + Add Restaurant
        </button>
      </div>

      {wishlist.length === 0 ? (
        <div className="empty-wishlist">
          <div className="empty-icon">📝</div>
          <h3>Your wishlist is empty</h3>
          <p>Start exploring restaurants and add them to your wishlist!</p>
          <button onClick={() => navigate('/current')} className="explore-btn">
            Explore Restaurants
          </button>
        </div>
      ) : (
        <div className="wishlist-grid">
          {wishlist.map((item) => (
            <div key={item.id} className="wishlist-item">
              <div 
                className="restaurant-card"
                onClick={() => handleRestaurantClick(item.restaurant.id)}
              >
                <div className="restaurant-image">
                  {item.restaurant.imageUrl ? (
                    <img src={item.restaurant.imageUrl} alt={item.restaurant.name} />
                  ) : (
                    <div className="placeholder-image">
                      <span>No Image</span>
                    </div>
                  )}
                </div>
                
                <div className="restaurant-info">
                  <h3>{item.restaurant.name}</h3>
                  <p className="cuisine">{item.restaurant.cuisine}</p>
                  <p className="area">{item.restaurant.area}</p>
                  <p className="price">{item.restaurant.price}</p>
                  
                  {item.restaurant.description && (
                    <p className="description">
                      {item.restaurant.description.length > 100 
                        ? `${item.restaurant.description.substring(0, 100)}...`
                        : item.restaurant.description
                      }
                    </p>
                  )}
                </div>
              </div>
              
              <div className="wishlist-actions">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleRemoveFromWishlist(item.restaurant.id);
                  }}
                  className="remove-btn"
                  title="Remove from wishlist"
                >
                  ❌
                </button>
                <div className="added-date">
                  Added {new Date(item.addedAt).toLocaleDateString()}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Restaurant Modal */}
      {showAddModal && (
        <div className="modal-overlay" onClick={handleCloseAddModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Add Restaurant to Wishlist</h2>
              <button onClick={handleCloseAddModal} className="close-btn">×</button>
            </div>
            
            <div className="modal-body">
              {loadingRestaurants ? (
                <div className="loading-container">
                  <div className="loading-spinner"></div>
                  <p>Loading restaurants...</p>
                </div>
              ) : (
                <div className="restaurants-list">
                  {availableRestaurants.map((restaurant) => (
                    <div key={restaurant.id} className="restaurant-item">
                      <div className="restaurant-info">
                        <h3>{restaurant.name}</h3>
                        <p className="cuisine">{restaurant.cuisine}</p>
                        <p className="area">{restaurant.area}</p>
                        <p className="price">{restaurant.priceRange}</p>
                      </div>
                      <div className="restaurant-actions">
                        {isInWishlist(restaurant.id) ? (
                          <span className="already-added">✓ Added</span>
                        ) : (
                          <button
                            onClick={() => handleAddToWishlist(restaurant.id)}
                            className="add-btn"
                          >
                            Add
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Wishlist;
