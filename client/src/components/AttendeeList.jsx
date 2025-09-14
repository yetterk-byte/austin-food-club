import React, { useState, useEffect } from 'react';
// import { rsvpAPI } from '../services/api';
import './AttendeeList.css';

const AttendeeList = ({ restaurantId }) => {
  const [attendees, setAttendees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchAttendees();
  }, [restaurantId]);

  const fetchAttendees = async () => {
    try {
      // For now, we'll simulate some data since we don't have a real API endpoint yet
      // const response = await rsvpAPI.getByUser(); // This would need to be updated to get all attendees
      setAttendees([
        { id: 1, user: { name: 'John Doe' }, status: 'going', partySize: 2 },
        { id: 2, user: { name: 'Jane Smith' }, status: 'going', partySize: 1 },
        { id: 3, user: { name: 'Mike Johnson' }, status: 'maybe', partySize: 3 },
        { id: 4, user: { name: 'Sarah Wilson' }, status: 'going', partySize: 1 },
      ]);
    } catch (err) {
      setError('Failed to load attendees');
      console.error('Error fetching attendees:', err);
    } finally {
      setLoading(false);
    }
  };

  const getStatusCounts = () => {
    const counts = { going: 0, maybe: 0, 'not-going': 0 };
    attendees.forEach(attendee => {
      counts[attendee.status] = (counts[attendee.status] || 0) + attendee.partySize;
    });
    return counts;
  };

  const statusCounts = getStatusCounts();

  if (loading) {
    return (
      <div className="attendee-list">
        <div className="loading">Loading attendees...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="attendee-list">
        <div className="error">{error}</div>
      </div>
    );
  }

  return (
    <div className="attendee-list">
      <h3>Who's Coming?</h3>
      
      <div className="attendee-stats">
        <div className="stat-item going">
          <span className="stat-number">{statusCounts.going}</span>
          <span className="stat-label">Going</span>
        </div>
        <div className="stat-item maybe">
          <span className="stat-number">{statusCounts.maybe}</span>
          <span className="stat-label">Maybe</span>
        </div>
        <div className="stat-item not-going">
          <span className="stat-number">{statusCounts['not-going']}</span>
          <span className="stat-label">Not Going</span>
        </div>
      </div>

      <div className="attendees-grid">
        {attendees.map(attendee => (
          <div key={attendee.id} className={`attendee-card ${attendee.status}`}>
            <div className="attendee-info">
              <h4>{attendee.user.name}</h4>
              <p className="party-size">
                {attendee.partySize} {attendee.partySize === 1 ? 'person' : 'people'}
              </p>
            </div>
            <div className="attendee-status">
              <span className={`status-badge ${attendee.status}`}>
                {attendee.status.charAt(0).toUpperCase() + attendee.status.slice(1)}
              </span>
            </div>
          </div>
        ))}
      </div>

      {attendees.length === 0 && (
        <div className="no-attendees">
          <p>No one has RSVP'd yet. Be the first!</p>
        </div>
      )}
    </div>
  );
};

export default AttendeeList;
