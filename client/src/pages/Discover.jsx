import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { apiService } from '../services/api';
import RestaurantCard from '../components/RestaurantCard';
import RestaurantFilters from '../components/RestaurantFilters';
import './Discover.css';

const Discover = () => {
  const { user } = useAuth(); // eslint-disable-line no-unused-vars
  const [restaurants, setRestaurants] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({});
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState('rating');
  const [currentPage, setCurrentPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [userLocation, setUserLocation] = useState(null);

  // Get user location
  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          });
        },
        (error) => {
          console.log('Geolocation error:', error);
          // Default to Austin downtown
          setUserLocation({
            latitude: 30.2672,
            longitude: -97.7431
          });
        }
      );
    } else {
      // Default to Austin downtown
      setUserLocation({
        latitude: 30.2672,
        longitude: -97.7431
      });
    }
  }, []);

  // Search restaurants based on filters
  const searchRestaurants = useCallback(async (page = 1, reset = false) => {
    try {
      setLoading(true);
      setError(null);

      let endpoint = '/restaurants/search';
      const params = new URLSearchParams();

      // Add search query
      if (searchQuery.trim()) {
        params.append('term', searchQuery.trim());
      }

      // Add filters
      if (filters.cuisine) {
        params.append('categories', filters.cuisine);
      }
      if (filters.priceRange) {
        params.append('price', filters.priceRange);
      }
      if (filters.neighborhood) {
        params.append('location', filters.neighborhood);
      }
      if (filters.rating) {
        params.append('min_rating', filters.rating);
      }
      if (filters.distance && userLocation) {
        params.append('latitude', userLocation.latitude);
        params.append('longitude', userLocation.longitude);
        params.append('radius', Math.round(filters.distance * 1609)); // Convert miles to meters
      }
      if (filters.openNow) {
        params.append('open_now', 'true');
      }

      // Handle Austin-specific categories
      if (filters.category) {
        switch (filters.category) {
          case 'food-trucks':
            endpoint = '/restaurants/austin/food-trucks';
            break;
          case 'live-music':
            params.append('categories', 'musicvenues,musicbars');
            break;
          case 'breweries':
            params.append('categories', 'breweries,beerbar');
            break;
          case 'brunch':
            params.append('categories', 'breakfast_brunch');
            params.append('term', 'brunch');
            break;
          case 'outdoor':
            params.append('attributes', 'outdoor_seating');
            break;
          case 'patio':
            params.append('attributes', 'outdoor_seating');
            break;
          case 'rooftop':
            params.append('term', 'rooftop');
            break;
          case 'waterfront':
            params.append('term', 'waterfront');
            break;
          default:
            break;
        }
      }

      // Add pagination
      params.append('limit', '20');
      params.append('offset', ((page - 1) * 20).toString());

      // Add sorting
      params.append('sort_by', sortBy);

      const queryString = params.toString();
      const fullEndpoint = queryString ? `${endpoint}?${queryString}` : endpoint;

      const data = await apiService.request(fullEndpoint);
      
      if (reset) {
        setRestaurants(data.restaurants || []);
        setCurrentPage(1);
      } else {
        setRestaurants(prev => [...prev, ...(data.restaurants || [])]);
      }
      
      setHasMore((data.restaurants || []).length === 20);
      setCurrentPage(page);
    } catch (err) {
      console.error('Error searching restaurants:', err);
      setError('Failed to search restaurants. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [searchQuery, filters, sortBy, userLocation]);

  // Load more restaurants
  const loadMore = () => {
    if (!loading && hasMore) {
      searchRestaurants(currentPage + 1, false);
    }
  };

  // Handle filter changes
  const handleFiltersChange = (newFilters) => {
    setFilters(newFilters);
    setCurrentPage(1);
    searchRestaurants(1, true);
  };

  // Handle search
  const handleSearch = (e) => {
    e.preventDefault();
    setCurrentPage(1);
    searchRestaurants(1, true);
  };

  // Handle sort change
  const handleSortChange = (newSortBy) => {
    setSortBy(newSortBy);
    setCurrentPage(1);
    searchRestaurants(1, true);
  };

  // Initial load
  useEffect(() => {
    searchRestaurants(1, true);
  }, [searchRestaurants]);

  const sortOptions = [
    { value: 'rating', label: 'Highest Rated' },
    { value: 'distance', label: 'Nearest' },
    { value: 'review_count', label: 'Most Reviewed' },
    { value: 'best_match', label: 'Best Match' }
  ];

  return (
    <div className="discover-page">
      <div className="discover-header">
        <h1>Discover Austin Restaurants</h1>
        <p>Find your next favorite spot in the Live Music Capital</p>
      </div>

      {/* Search Bar */}
      <div className="search-section">
        <form onSubmit={handleSearch} className="search-form">
          <div className="search-input-container">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search restaurants, cuisines, or dishes..."
              className="search-input"
            />
            <button type="submit" className="search-btn" disabled={loading}>
              {loading ? 'Searching...' : 'Search'}
            </button>
          </div>
        </form>
      </div>

      <div className="discover-content">
        {/* Filters Sidebar */}
        <div className="filters-sidebar">
          <RestaurantFilters
            onFiltersChange={handleFiltersChange}
            userLocation={userLocation}
          />
        </div>

        {/* Results Section */}
        <div className="results-section">
          {/* Results Header */}
          <div className="results-header">
            <div className="results-info">
              <h2>
                {restaurants.length > 0 
                  ? `${restaurants.length} Restaurants Found`
                  : 'No Restaurants Found'
                }
              </h2>
              {restaurants.length > 0 && (
                <p>Showing results for your search criteria</p>
              )}
            </div>
            
            <div className="sort-controls">
              <label htmlFor="sort-select">Sort by:</label>
              <select
                id="sort-select"
                value={sortBy}
                onChange={(e) => handleSortChange(e.target.value)}
                className="sort-select"
              >
                {sortOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Loading State */}
          {loading && restaurants.length === 0 && (
            <div className="loading-state">
              <div className="loading-spinner"></div>
              <p>Searching for restaurants...</p>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="error-state">
              <h3>Oops! Something went wrong</h3>
              <p>{error}</p>
              <button onClick={() => searchRestaurants(1, true)} className="retry-btn">
                Try Again
              </button>
            </div>
          )}

          {/* No Results */}
          {!loading && !error && restaurants.length === 0 && (
            <div className="no-results">
              <div className="no-results-icon">🔍</div>
              <h3>No restaurants found</h3>
              <p>Try adjusting your filters or search terms</p>
              <button onClick={() => {
                setSearchQuery('');
                setFilters({});
                searchRestaurants(1, true);
              }} className="clear-search-btn">
                Clear Search
              </button>
            </div>
          )}

          {/* Restaurant Grid */}
          {restaurants.length > 0 && (
            <div className="restaurants-grid">
              {restaurants.map((restaurant) => (
                <RestaurantCard
                  key={restaurant.id}
                  restaurant={restaurant}
                  showDistance={!!userLocation}
                  userLocation={userLocation}
                />
              ))}
            </div>
          )}

          {/* Load More Button */}
          {hasMore && restaurants.length > 0 && (
            <div className="load-more-section">
              <button
                onClick={loadMore}
                disabled={loading}
                className="load-more-btn"
              >
                {loading ? 'Loading...' : 'Load More Restaurants'}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Discover;
