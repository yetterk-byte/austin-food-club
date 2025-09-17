import React, { useState } from 'react';
import StarRating from './StarRating';
import './StarRating.css';

const StarRatingExample = () => {
  const [rating, setRating] = useState(0);
  const [readonlyRating] = useState(4.5);

  const handleRatingChange = (newRating) => {
    setRating(newRating);
    console.log('New rating:', newRating);
  };

  return (
    <div style={{ 
      padding: '20px', 
      background: '#1a1a1a', 
      color: '#ffffff',
      minHeight: '100vh',
      fontFamily: 'Arial, sans-serif'
    }}>
      <h1>StarRating Component Examples</h1>
      
      <div style={{ marginBottom: '40px' }}>
        <h2>Interactive Rating (Medium Size)</h2>
        <StarRating
          initialRating={rating}
          onRatingChange={handleRatingChange}
          size="medium"
          showLabel={true}
        />
        <p>Current rating: {rating}</p>
      </div>

      <div style={{ marginBottom: '40px' }}>
        <h2>Readonly Rating (Large Size)</h2>
        <StarRating
          initialRating={readonlyRating}
          readonly={true}
          size="large"
          showLabel={true}
        />
      </div>

      <div style={{ marginBottom: '40px' }}>
        <h2>Small Rating with Half Stars</h2>
        <StarRating
          initialRating={3.5}
          onRatingChange={handleRatingChange}
          size="small"
          allowHalfStars={true}
          showLabel={true}
        />
      </div>

      <div style={{ marginBottom: '40px' }}>
        <h2>Compact Inline Rating</h2>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          <span>Restaurant Quality:</span>
          <StarRating
            initialRating={4}
            readonly={true}
            size="small"
            showLabel={false}
          />
        </div>
      </div>

      <div style={{ marginBottom: '40px' }}>
        <h2>Different Sizes</h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div>
            <p>Small:</p>
            <StarRating size="small" showLabel={false} />
          </div>
          <div>
            <p>Medium:</p>
            <StarRating size="medium" showLabel={false} />
          </div>
          <div>
            <p>Large:</p>
            <StarRating size="large" showLabel={false} />
          </div>
        </div>
      </div>
    </div>
  );
};

export default StarRatingExample;
