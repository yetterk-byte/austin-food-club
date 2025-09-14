import React, { useState, useEffect } from 'react';
import './WishlistPage.css';

const WishlistPage = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [wishlistItems, setWishlistItems] = useState([]);
  const [filteredItems, setFilteredItems] = useState([]);

  // Initialize with example restaurants
  useEffect(() => {
    const initialItems = [
      {
        id: 1,
        name: 'Uchi',
        cuisine: 'Japanese',
        priceRange: '$$$',
        location: 'South Austin',
        rating: 4.8,
        description: 'Contemporary Japanese restaurant with innovative sushi and small plates.',
        addedDate: '2024-01-15'
      },
      {
        id: 2,
        name: 'Suerte',
        cuisine: 'Mexican',
        priceRange: '$$$',
        location: 'East Austin',
        rating: 4.7,
        description: 'Modern Mexican cuisine with a focus on masa and traditional techniques.',
        addedDate: '2024-01-20'
      },
      {
        id: 3,
        name: 'Franklin Barbecue',
        cuisine: 'BBQ',
        priceRange: '$$',
        location: 'East Austin',
        rating: 4.9,
        description: 'Legendary Austin barbecue joint known for its brisket and long lines.',
        addedDate: '2024-01-25'
      },
      {
        id: 4,
        name: 'Emmer & Rye',
        cuisine: 'American',
        priceRange: '$$$',
        location: 'Rainey Street',
        rating: 4.6,
        description: 'Farm-to-table restaurant with seasonal menu and craft cocktails.',
        addedDate: '2024-01-30'
      }
    ];
    
    setWishlistItems(initialItems);
    setFilteredItems(initialItems);
  }, []);

  // Filter items based on search term
  useEffect(() => {
    if (!searchTerm.trim()) {
      setFilteredItems(wishlistItems);
    } else {
      const filtered = wishlistItems.filter(item =>
        item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.cuisine.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.location.toLowerCase().includes(searchTerm.toLowerCase())
      );
      setFilteredItems(filtered);
    }
  }, [searchTerm, wishlistItems]);

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
  };

  const handleRemoveItem = (itemId) => {
    const updatedItems = wishlistItems.filter(item => item.id !== itemId);
    setWishlistItems(updatedItems);
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  return (
    <div className="wishlist-page">
      {/* Search Header */}
      <div className="search-header">
        <div className="search-container">
          <input
            type="text"
            placeholder="Search wishlist..."
            value={searchTerm}
            onChange={handleSearchChange}
            className="search-input"
          />
          <div className="search-icon">🔍</div>
        </div>
        <div className="wishlist-count">
          {filteredItems.length} {filteredItems.length === 1 ? 'item' : 'items'}
        </div>
      </div>

      {/* Wishlist Items */}
      <div className="wishlist-content">
        {filteredItems.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📋</div>
            <h3>No items found</h3>
            <p>
              {searchTerm 
                ? `No restaurants match "${searchTerm}"`
                : 'Your wishlist is empty'
              }
            </p>
          </div>
        ) : (
          <div className="wishlist-grid">
            {filteredItems.map((item) => (
              <div key={item.id} className="wishlist-item">
                <div className="item-header">
                  <h3 className="item-name">{item.name}</h3>
                  <button
                    className="remove-button"
                    onClick={() => handleRemoveItem(item.id)}
                    title="Remove from wishlist"
                  >
                    ×
                  </button>
                </div>
                
                <div className="item-meta">
                  <span className="cuisine">{item.cuisine}</span>
                  <span className="price">{item.priceRange}</span>
                  <span className="location">{item.location}</span>
                </div>
                
                <div className="item-rating">
                  <span className="rating-value">{item.rating}</span>
                  <span className="rating-label">rating</span>
                </div>
                
                <p className="item-description">{item.description}</p>
                
                <div className="item-footer">
                  <span className="added-date">Added {formatDate(item.addedDate)}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default WishlistPage;