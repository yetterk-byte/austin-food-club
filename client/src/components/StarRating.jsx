import React, { useState, useEffect } from 'react';
import './StarRating.css';

const StarRating = ({ 
  initialRating = 0, 
  onRatingChange, 
  readonly = false,
  allowHalfStars = false,
  size = 'medium',
  showLabel = true
}) => {
  const [rating, setRating] = useState(initialRating);
  const [hoverRating, setHoverRating] = useState(0);
  const [isHovering, setIsHovering] = useState(false);

  // Update internal rating when initialRating prop changes
  useEffect(() => {
    setRating(initialRating);
  }, [initialRating]);

  const handleMouseEnter = (starValue) => {
    if (!readonly) {
      setHoverRating(starValue);
      setIsHovering(true);
    }
  };

  const handleMouseLeave = () => {
    if (!readonly) {
      setHoverRating(0);
      setIsHovering(false);
    }
  };

  const handleClick = (starValue) => {
    if (!readonly) {
      setRating(starValue);
      if (onRatingChange) {
        onRatingChange(starValue);
      }
    }
  };

  const handleTouchStart = (starValue) => {
    if (!readonly) {
      setHoverRating(starValue);
      setIsHovering(true);
    }
  };

  const handleTouchEnd = (starValue) => {
    if (!readonly) {
      setRating(starValue);
      setHoverRating(0);
      setIsHovering(false);
      if (onRatingChange) {
        onRatingChange(starValue);
      }
    }
  };

  const renderStar = (starValue) => {
    const currentRating = isHovering ? hoverRating : rating;
    const isFilled = starValue <= currentRating;
    const isHalfFilled = allowHalfStars && 
      starValue === Math.ceil(currentRating) && 
      currentRating % 1 !== 0;

    return (
      <span
        key={starValue}
        className={`star ${isFilled ? 'filled' : ''} ${isHalfFilled ? 'half-filled' : ''} ${readonly ? 'readonly' : ''} ${size}`}
        onMouseEnter={() => handleMouseEnter(starValue)}
        onMouseLeave={handleMouseLeave}
        onClick={() => handleClick(starValue)}
        onTouchStart={() => handleTouchStart(starValue)}
        onTouchEnd={() => handleTouchEnd(starValue)}
        role={readonly ? 'img' : 'button'}
        aria-label={readonly ? `${rating} out of 5 stars` : `Rate ${starValue} out of 5 stars`}
        tabIndex={readonly ? -1 : 0}
        onKeyDown={(e) => {
          if (!readonly && (e.key === 'Enter' || e.key === ' ')) {
            e.preventDefault();
            handleClick(starValue);
          }
        }}
      >
        {isHalfFilled ? (
          <svg
            viewBox="0 0 24 24"
            className="star-svg"
            fill="none"
            stroke="currentColor"
            strokeWidth="1"
          >
            <defs>
              <linearGradient id={`halfGradient${starValue}`}>
                <stop offset="50%" stopColor="#FFD700" />
                <stop offset="50%" stopColor="transparent" />
              </linearGradient>
            </defs>
            <path
              d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
              fill={`url(#halfGradient${starValue})`}
              stroke="#FFD700"
            />
          </svg>
        ) : (
          <svg
            viewBox="0 0 24 24"
            className="star-svg"
            fill={isFilled ? '#FFD700' : 'none'}
            stroke={isFilled ? '#FFD700' : '#666'}
            strokeWidth="1"
          >
            <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
          </svg>
        )}
      </span>
    );
  };

  const getRatingText = () => {
    if (isHovering && hoverRating > 0) {
      return `${hoverRating} out of 5 stars`;
    }
    if (rating > 0) {
      return `${rating} out of 5 stars`;
    }
    return 'No rating';
  };

  return (
    <div className={`star-rating ${size} ${readonly ? 'readonly' : ''}`}>
      <div 
        className="stars-container"
        onMouseLeave={handleMouseLeave}
      >
        {[1, 2, 3, 4, 5].map(renderStar)}
      </div>
      {showLabel && (
        <div className="rating-label">
          {getRatingText()}
        </div>
      )}
    </div>
  );
};

export default StarRating;
