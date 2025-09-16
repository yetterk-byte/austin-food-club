import React, { useState } from 'react';
import './RestaurantFilters.css';

const RestaurantFilters = ({ onFiltersChange, userLocation = null }) => {
  const [filters, setFilters] = useState({
    cuisine: '',
    priceRange: '',
    neighborhood: '',
    rating: '',
    distance: 10,
    openNow: false,
    category: ''
  });

  const cuisineTypes = [
    'BBQ', 'Tex-Mex', 'Mexican', 'Italian', 'Chinese', 'Japanese', 'Sushi',
    'Indian', 'Thai', 'Vietnamese', 'American', 'French', 'Mediterranean',
    'Seafood', 'Pizza', 'Vegan', 'Vegetarian', 'Korean', 'Ethiopian'
  ];

  const priceRanges = [
    { value: '1', label: '$', description: 'Budget' },
    { value: '2', label: '$$', description: 'Moderate' },
    { value: '3', label: '$$$', description: 'Expensive' },
    { value: '4', label: '$$$$', description: 'Very Expensive' }
  ];

  const neighborhoods = [
    'Downtown', 'East Austin', 'South Austin', 'North Austin', 'West Austin',
    'South Lamar', 'South First', 'Burnet Road', 'Domain', 'Cedar Park',
    'Round Rock', 'Pflugerville', 'Lake Travis', 'Barton Springs'
  ];

  const ratings = [
    { value: '4.5', label: '4.5+ Stars' },
    { value: '4.0', label: '4.0+ Stars' },
    { value: '3.5', label: '3.5+ Stars' },
    { value: '3.0', label: '3.0+ Stars' }
  ];

  const austinCategories = [
    { value: 'food-trucks', label: 'Food Trucks', icon: '🚚' },
    { value: 'live-music', label: 'Live Music', icon: '🎵' },
    { value: 'breweries', label: 'Breweries', icon: '🍺' },
    { value: 'brunch', label: 'Weekend Brunch', icon: '🥞' },
    { value: 'outdoor', label: 'Outdoor Seating', icon: '🌳' },
    { value: 'patio', label: 'Patio Dining', icon: '☀️' },
    { value: 'rooftop', label: 'Rooftop Bars', icon: '🏢' },
    { value: 'waterfront', label: 'Waterfront', icon: '🌊' }
  ];

  const handleFilterChange = (key, value) => {
    const newFilters = { ...filters, [key]: value };
    setFilters(newFilters);
    onFiltersChange(newFilters);
  };

  const clearFilters = () => {
    const clearedFilters = {
      cuisine: '',
      priceRange: '',
      neighborhood: '',
      rating: '',
      distance: 10,
      openNow: false,
      category: ''
    };
    setFilters(clearedFilters);
    onFiltersChange(clearedFilters);
  };

  const hasActiveFilters = Object.values(filters).some(value => 
    value !== '' && value !== 10 && value !== false
  );

  return (
    <div className="restaurant-filters">
      <div className="filters-header">
        <h3>Filter Restaurants</h3>
        {hasActiveFilters && (
          <button onClick={clearFilters} className="clear-filters-btn">
            Clear All
          </button>
        )}
      </div>

      <div className="filters-content">
        {/* Austin Categories */}
        <div className="filter-section">
          <label className="filter-label">Austin Specialties</label>
          <div className="category-grid">
            {austinCategories.map((category) => (
              <button
                key={category.value}
                className={`category-btn ${filters.category === category.value ? 'active' : ''}`}
                onClick={() => handleFilterChange('category', 
                  filters.category === category.value ? '' : category.value
                )}
              >
                <span className="category-icon">{category.icon}</span>
                <span className="category-label">{category.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Cuisine Type */}
        <div className="filter-section">
          <label className="filter-label">Cuisine Type</label>
          <select
            value={filters.cuisine}
            onChange={(e) => handleFilterChange('cuisine', e.target.value)}
            className="filter-select"
          >
            <option value="">All Cuisines</option>
            {cuisineTypes.map((cuisine) => (
              <option key={cuisine} value={cuisine}>
                {cuisine}
              </option>
            ))}
          </select>
        </div>

        {/* Price Range */}
        <div className="filter-section">
          <label className="filter-label">Price Range</label>
          <div className="price-buttons">
            {priceRanges.map((price) => (
              <button
                key={price.value}
                className={`price-btn ${filters.priceRange === price.value ? 'active' : ''}`}
                onClick={() => handleFilterChange('priceRange', 
                  filters.priceRange === price.value ? '' : price.value
                )}
              >
                <span className="price-symbol">{price.label}</span>
                <span className="price-desc">{price.description}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Neighborhood */}
        <div className="filter-section">
          <label className="filter-label">Neighborhood</label>
          <select
            value={filters.neighborhood}
            onChange={(e) => handleFilterChange('neighborhood', e.target.value)}
            className="filter-select"
          >
            <option value="">All Areas</option>
            {neighborhoods.map((neighborhood) => (
              <option key={neighborhood} value={neighborhood}>
                {neighborhood}
              </option>
            ))}
          </select>
        </div>

        {/* Rating */}
        <div className="filter-section">
          <label className="filter-label">Minimum Rating</label>
          <select
            value={filters.rating}
            onChange={(e) => handleFilterChange('rating', e.target.value)}
            className="filter-select"
          >
            <option value="">Any Rating</option>
            {ratings.map((rating) => (
              <option key={rating.value} value={rating.value}>
                {rating.label}
              </option>
            ))}
          </select>
        </div>

        {/* Distance */}
        {userLocation && (
          <div className="filter-section">
            <label className="filter-label">
              Distance: {filters.distance} miles
            </label>
            <input
              type="range"
              min="1"
              max="25"
              value={filters.distance}
              onChange={(e) => handleFilterChange('distance', parseInt(e.target.value))}
              className="distance-slider"
            />
            <div className="distance-labels">
              <span>1 mi</span>
              <span>25 mi</span>
            </div>
          </div>
        )}

        {/* Open Now */}
        <div className="filter-section">
          <label className="filter-label">Availability</label>
          <div className="toggle-container">
            <label className="toggle-switch">
              <input
                type="checkbox"
                checked={filters.openNow}
                onChange={(e) => handleFilterChange('openNow', e.target.checked)}
              />
              <span className="toggle-slider"></span>
            </label>
            <span className="toggle-label">Open Now</span>
          </div>
        </div>
      </div>

      {/* Active Filters Display */}
      {hasActiveFilters && (
        <div className="active-filters">
          <h4>Active Filters:</h4>
          <div className="active-filter-tags">
            {filters.cuisine && (
              <span className="active-filter-tag">
                Cuisine: {filters.cuisine}
                <button onClick={() => handleFilterChange('cuisine', '')}>×</button>
              </span>
            )}
            {filters.priceRange && (
              <span className="active-filter-tag">
                Price: {priceRanges.find(p => p.value === filters.priceRange)?.label}
                <button onClick={() => handleFilterChange('priceRange', '')}>×</button>
              </span>
            )}
            {filters.neighborhood && (
              <span className="active-filter-tag">
                Area: {filters.neighborhood}
                <button onClick={() => handleFilterChange('neighborhood', '')}>×</button>
              </span>
            )}
            {filters.rating && (
              <span className="active-filter-tag">
                Rating: {filters.rating}+ stars
                <button onClick={() => handleFilterChange('rating', '')}>×</button>
              </span>
            )}
            {filters.category && (
              <span className="active-filter-tag">
                {austinCategories.find(c => c.value === filters.category)?.label}
                <button onClick={() => handleFilterChange('category', '')}>×</button>
              </span>
            )}
            {filters.openNow && (
              <span className="active-filter-tag">
                Open Now
                <button onClick={() => handleFilterChange('openNow', false)}>×</button>
              </span>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default RestaurantFilters;
