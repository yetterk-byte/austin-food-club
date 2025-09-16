import React from 'react';
import { useNavigate } from 'react-router-dom';
import './RestaurantCard.css';

const RestaurantCard = ({ restaurant }) => {
  const navigate = useNavigate();

  const handleCardClick = () => {
    navigate(`/restaurant/${restaurant.id}`);
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


  const getCuisineColor = (cuisine) => {
    const colors = {
      'BBQ': '#8B4513',
      'Barbeque': '#8B4513',
      'Mexican': '#FF6B35',
      'Tex-Mex': '#FF6B35',
      'Italian': '#228B22',
      'Chinese': '#DC143C',
      'Japanese': '#FF1493',
      'Sushi': '#FF1493',
      'Indian': '#FF8C00',
      'Thai': '#32CD32',
      'Vietnamese': '#00CED1',
      'American': '#4169E1',
      'French': '#9370DB',
      'Mediterranean': '#20B2AA',
      'Seafood': '#1E90FF',
      'Pizza': '#FF6347',
      'Food Trucks': '#FFD700',
      'Vegan': '#90EE90',
      'Vegetarian': '#90EE90'
    };
    
    return colors[cuisine] || '#666';
  };


  // Select the best atmospheric photo from available photos
  const getAtmosphericPhoto = () => {
    if (restaurant.photos && restaurant.photos.length > 0) {
      // Prioritize photos that might show atmosphere (interior/exterior)
      // For now, we'll use the first photo, but this could be enhanced with image analysis
      return restaurant.photos[0];
    }
    return restaurant.imageUrl;
  };

  const heroImage = getAtmosphericPhoto();

  return (
    <div className="restaurant-card" onClick={handleCardClick}>
      <div className="restaurant-image">
        {heroImage ? (
          <img 
            src={heroImage} 
            alt={`${restaurant.name} atmosphere`}
            loading="lazy"
          />
        ) : (
          <div className="placeholder-image">
            <span>📷</span>
          </div>
        )}
        
      </div>

      <div className="restaurant-info">
        <div className="restaurant-header">
          <h3 className="restaurant-name">{restaurant.name}</h3>
          <div className="restaurant-badges">
            {restaurant.cuisine && (
              <span 
                className="cuisine-badge"
                style={{ backgroundColor: getCuisineColor(restaurant.cuisine) }}
              >
                {restaurant.cuisine}
              </span>
            )}
            {restaurant.categories && restaurant.categories.length > 0 && (
              <span className="category-badge">
                {restaurant.categories[0]}
              </span>
            )}
          </div>
        </div>

        <div className="restaurant-details">
          <div className="info-row">
            <div className="rating-section">
              {renderStars(restaurant.rating)}
            </div>

            <div className="price-section">
              {renderPriceRange(restaurant.priceRange)}
            </div>

            <div className="wait-time-section">
              <span className="wait-time">~15 min</span>
            </div>
          </div>



        </div>

        <div className="restaurant-footer">
          {restaurant.yelpUrl && (
            <a 
              href={restaurant.yelpUrl} 
              target="_blank" 
              rel="noopener noreferrer"
              className="yelp-link"
              onClick={(e) => e.stopPropagation()}
            >
              View on Yelp
            </a>
          )}
          
          {restaurant.isClaimed && (
            <span className="claimed-badge">✓ Claimed</span>
          )}
        </div>
      </div>
    </div>
  );
};

export default RestaurantCard;