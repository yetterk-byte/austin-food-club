import React, { useState } from 'react';
import './RSVPBox.css';

const RSVPBox = ({ restaurant, userRSVP, onRSVP, onCancel }) => {
  const [isRSVPing, setIsRSVPing] = useState(false);
  const [formData, setFormData] = useState({
    status: userRSVP?.status || 'going',
    partySize: userRSVP?.partySize || 1,
    notes: userRSVP?.notes || '',
  });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsRSVPing(true);
    
    try {
      await onRSVP(formData);
    } catch (error) {
      console.error('RSVP error:', error);
    } finally {
      setIsRSVPing(false);
    }
  };

  const handleCancel = async () => {
    if (window.confirm('Are you sure you want to cancel your RSVP?')) {
      await onCancel();
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'partySize' ? parseInt(value) || 1 : value
    }));
  };

  return (
    <div className="rsvp-box">
      <h3>RSVP for {restaurant.name}</h3>
      
      {userRSVP ? (
        <div className="rsvp-status">
          <div className="current-rsvp">
            <p><strong>Status:</strong> 
              <span className={`status-badge ${userRSVP.status}`}>
                {userRSVP.status.charAt(0).toUpperCase() + userRSVP.status.slice(1)}
              </span>
            </p>
            <p><strong>Party Size:</strong> {userRSVP.partySize}</p>
            {userRSVP.notes && <p><strong>Notes:</strong> {userRSVP.notes}</p>}
          </div>
          
          <div className="rsvp-actions">
            <button 
              onClick={() => setFormData({
                status: userRSVP.status,
                partySize: userRSVP.partySize,
                notes: userRSVP.notes
              })}
              className="btn-secondary"
            >
              Update RSVP
            </button>
            <button 
              onClick={handleCancel}
              className="btn-danger"
            >
              Cancel RSVP
            </button>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="rsvp-form">
          <div className="form-group">
            <label htmlFor="status">Will you be attending?</label>
            <select
              id="status"
              name="status"
              value={formData.status}
              onChange={handleInputChange}
              required
            >
              <option value="going">Yes, I'm going!</option>
              <option value="maybe">Maybe</option>
              <option value="not-going">Not going</option>
            </select>
          </div>

          <div className="form-group">
            <label htmlFor="partySize">Party Size</label>
            <input
              type="number"
              id="partySize"
              name="partySize"
              value={formData.partySize}
              onChange={handleInputChange}
              min="1"
              max="20"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="notes">Notes (optional)</label>
            <textarea
              id="notes"
              name="notes"
              value={formData.notes}
              onChange={handleInputChange}
              placeholder="Any dietary restrictions, preferences, or other notes..."
              rows="3"
            />
          </div>

          <button 
            type="submit" 
            className="btn-primary"
            disabled={isRSVPing}
          >
            {isRSVPing ? 'RSVPing...' : 'Submit RSVP'}
          </button>
        </form>
      )}
    </div>
  );
};

export default RSVPBox;

