import React from 'react';

const QueueItem = ({ item, position, onRemove, onEdit }) => {
  const estimatedWeek = () => {
    const now = new Date();
    const estimatedDate = new Date(now.getTime() + (position * 7 * 24 * 60 * 60 * 1000));
    return estimatedDate.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  const daysSinceAdded = () => {
    const now = new Date();
    const addedDate = new Date(item.addedAt);
    const diffTime = Math.abs(now - addedDate);
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  return (
    <div className="queue-item">
      <div className="queue-position">
        <span className="position-number">{position}</span>
        <div className="drag-handle">
          <span>⋮⋮</span>
        </div>
      </div>

      <div className="restaurant-image">
        <img 
          src={item.restaurant.imageUrl || '/placeholder-restaurant.jpg'} 
          alt={item.restaurant.name}
          onError={(e) => e.target.src = '/placeholder-restaurant.jpg'}
        />
      </div>

      <div className="restaurant-details">
        <div className="restaurant-main-info">
          <h3 className="restaurant-name">{item.restaurant.name}</h3>
          <p className="restaurant-address">{item.restaurant.address}</p>
          
          <div className="restaurant-meta">
            {item.restaurant.rating && (
              <span className="rating">⭐ {item.restaurant.rating}</span>
            )}
            {item.restaurant.price && (
              <span className="price">{item.restaurant.price}</span>
            )}
            {item.restaurant.categories && (
              <span className="categories">{JSON.parse(item.restaurant.categories).map(cat => cat.title).join(', ')}</span>
            )}
          </div>
        </div>

        {item.notes && (
          <div className="queue-notes">
            <strong>Notes:</strong> {item.notes}
          </div>
        )}

        <div className="queue-meta">
          <span className="added-by">Added by {item.admin.name}</span>
          <span className="added-date">{daysSinceAdded()} days ago</span>
          <span className="estimated-week">Est. week of {estimatedWeek()}</span>
        </div>
      </div>

      <div className="queue-actions">
        <div className={`status-badge status-${item.status.toLowerCase()}`}>
          {item.status}
        </div>
        
        <div className="action-buttons">
          <button 
            onClick={() => onEdit(item.id)}
            className="btn-edit"
            title="Edit queue item"
          >
            ✏️
          </button>
          <button 
            onClick={() => onRemove(item.id)}
            className="btn-remove"
            title="Remove from queue"
          >
            🗑️
          </button>
          <a 
            href={item.restaurant.yelpUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-yelp"
            title="View on Yelp"
          >
            🔗
          </a>
        </div>
      </div>
    </div>
  );
};

export default QueueItem;
