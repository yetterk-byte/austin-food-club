import React, { useState, useEffect } from 'react';
import { DragDropContext, Droppable, Draggable } from 'react-beautiful-dnd';
import QueueItem from '../../components/Admin/QueueItem';
import './RestaurantQueue.css';

const RestaurantQueue = () => {
  const [queue, setQueue] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    fetchQueue();
  }, []);

  const fetchQueue = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('adminToken');
      
      const response = await fetch('/api/admin/queue', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Failed to fetch queue');
      }

      const data = await response.json();
      setQueue(data.queue);
    } catch (err) {
      console.error('Queue fetch error:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDragEnd = async (result) => {
    if (!result.destination) return;

    const items = Array.from(queue);
    const [reorderedItem] = items.splice(result.source.index, 1);
    items.splice(result.destination.index, 0, reorderedItem);

    // Update positions
    const newOrder = items.map((item, index) => ({
      id: item.id,
      position: index + 1
    }));

    // Optimistic update
    setQueue(items);

    try {
      const token = localStorage.getItem('adminToken');
      
      const response = await fetch('/api/admin/queue/reorder', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ newOrder })
      });

      if (!response.ok) {
        throw new Error('Failed to reorder queue');
      }

      // Refresh queue to get updated positions
      fetchQueue();
    } catch (err) {
      console.error('Reorder error:', err);
      // Revert optimistic update
      fetchQueue();
    }
  };

  const searchYelp = async (query, cuisine) => {
    try {
      setSearching(true);
      const token = localStorage.getItem('adminToken');
      
      const response = await fetch('/api/admin/restaurants/search-yelp', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ query, cuisine })
      });

      if (!response.ok) {
        throw new Error('Failed to search Yelp');
      }

      const data = await response.json();
      setSearchResults(data.restaurants);
    } catch (err) {
      console.error('Yelp search error:', err);
      setError(err.message);
    } finally {
      setSearching(false);
    }
  };

  const addRestaurantFromYelp = async (yelpId, notes = '') => {
    try {
      const token = localStorage.getItem('adminToken');
      
      const response = await fetch('/api/admin/restaurants/add-from-yelp', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ yelpId, notes, addToQueue: true })
      });

      if (!response.ok) {
        throw new Error('Failed to add restaurant');
      }

      // Refresh queue and close form
      fetchQueue();
      setShowAddForm(false);
      setSearchResults([]);
    } catch (err) {
      console.error('Add restaurant error:', err);
      setError(err.message);
    }
  };

  const removeFromQueue = async (queueItemId) => {
    if (!window.confirm('Are you sure you want to remove this restaurant from the queue?')) {
      return;
    }

    try {
      const token = localStorage.getItem('adminToken');
      
      const response = await fetch(`/api/admin/queue/${queueItemId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Failed to remove from queue');
      }

      fetchQueue();
    } catch (err) {
      console.error('Remove from queue error:', err);
      setError(err.message);
    }
  };

  if (loading) {
    return (
      <div className="admin-loading">
        <div className="admin-loading-spinner"></div>
        <span style={{ marginLeft: '1rem' }}>Loading restaurant queue...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="admin-error">
        <h3>Error Loading Queue</h3>
        <p>{error}</p>
        <button onClick={fetchQueue} className="retry-btn">
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="restaurant-queue">
      <div className="queue-header">
        <div>
          <h1>Restaurant Queue</h1>
          <p>Manage upcoming featured restaurants with drag-and-drop ordering</p>
        </div>
        <button 
          onClick={() => setShowAddForm(true)}
          className="btn-primary add-restaurant-btn"
        >
          + Add Restaurant
        </button>
      </div>

      {/* Add Restaurant Form */}
      {showAddForm && (
        <div className="add-restaurant-modal">
          <div className="modal-content">
            <div className="modal-header">
              <h2>Add Restaurant to Queue</h2>
              <button 
                onClick={() => {
                  setShowAddForm(false);
                  setSearchResults([]);
                }}
                className="modal-close"
              >
                ×
              </button>
            </div>
            
            <div className="search-section">
              <div className="search-form">
                <input
                  type="text"
                  placeholder="Search restaurant name..."
                  onKeyPress={(e) => {
                    if (e.key === 'Enter') {
                      searchYelp(e.target.value, '');
                    }
                  }}
                />
                <div className="cuisine-buttons">
                  {['BBQ', 'Mexican', 'Japanese', 'Italian', 'American'].map(cuisine => (
                    <button
                      key={cuisine}
                      onClick={() => searchYelp('', cuisine.toLowerCase())}
                      className="cuisine-btn"
                      disabled={searching}
                    >
                      {cuisine}
                    </button>
                  ))}
                </div>
              </div>

              {searching && (
                <div className="search-loading">
                  <div className="admin-loading-spinner"></div>
                  <span>Searching Yelp...</span>
                </div>
              )}

              {searchResults.length > 0 && (
                <div className="search-results">
                  <h3>Search Results</h3>
                  {searchResults.map(restaurant => (
                    <div key={restaurant.yelpId} className="search-result-item">
                      <div className="restaurant-basic-info">
                        <img 
                          src={restaurant.imageUrl || '/placeholder-restaurant.jpg'} 
                          alt={restaurant.name}
                          className="restaurant-thumbnail"
                        />
                        <div className="restaurant-details">
                          <h4>{restaurant.name}</h4>
                          <p>{restaurant.address}, {restaurant.city}</p>
                          <div className="restaurant-meta">
                            <span>⭐ {restaurant.rating}</span>
                            <span>{restaurant.price}</span>
                            <span>{restaurant.categories}</span>
                          </div>
                        </div>
                      </div>
                      <button
                        onClick={() => addRestaurantFromYelp(restaurant.yelpId)}
                        className="btn-primary add-btn"
                      >
                        Add to Queue
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Queue Display */}
      <div className="queue-container">
        {queue.length === 0 ? (
          <div className="empty-queue">
            <h3>Queue is Empty</h3>
            <p>Add restaurants to start building your weekly rotation</p>
            <button 
              onClick={() => setShowAddForm(true)}
              className="btn-primary"
            >
              Add First Restaurant
            </button>
          </div>
        ) : (
          <DragDropContext onDragEnd={handleDragEnd}>
            <Droppable droppableId="restaurant-queue">
              {(provided) => (
                <div
                  {...provided.droppableProps}
                  ref={provided.innerRef}
                  className="queue-list"
                >
                  {queue.map((item, index) => (
                    <Draggable 
                      key={item.id} 
                      draggableId={item.id} 
                      index={index}
                    >
                      {(provided, snapshot) => (
                        <div
                          ref={provided.innerRef}
                          {...provided.draggableProps}
                          {...provided.dragHandleProps}
                          className={`queue-item-wrapper ${snapshot.isDragging ? 'dragging' : ''}`}
                        >
                          <QueueItem
                            item={item}
                            position={index + 1}
                            onRemove={() => removeFromQueue(item.id)}
                            onEdit={(id) => {
                              // TODO: Implement edit functionality
                              console.log('Edit queue item:', id);
                            }}
                          />
                        </div>
                      )}
                    </Draggable>
                  ))}
                  {provided.placeholder}
                </div>
              )}
            </Droppable>
          </DragDropContext>
        )}
      </div>
    </div>
  );
};

export default RestaurantQueue;
