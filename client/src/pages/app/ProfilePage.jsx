import React, { useState } from 'react';
import FriendsModal from '../../components/FriendsModal';
import './ProfilePage.css';

const ProfilePage = ({ rsvpStatus, setCurrentPage }) => {
  const [showFriendsModal, setShowFriendsModal] = useState(false);
  const [verifiedVisits] = useState([ // eslint-disable-line no-unused-vars
    {
      id: 1,
      restaurant: 'Uchi',
      date: '2024-01-15',
      rating: 5,
      review: 'Amazing sushi and innovative dishes. The omakase was incredible!',
      image: null
    },
    {
      id: 2,
      restaurant: 'Suerte',
      date: '2024-01-20',
      rating: 4,
      review: 'Great modern Mexican cuisine. The masa dishes were outstanding.',
      image: null
    }
  ]);


  const handleFriendsClick = () => {
    setShowFriendsModal(true);
  };

  const handleCloseModal = () => {
    setShowFriendsModal(false);
  };

  const handleChangeRSVP = () => {
    setCurrentPage('current');
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  const renderStars = (rating) => {
    return '★'.repeat(rating) + '☆'.repeat(5 - rating);
  };

  return (
    <div className="profile-page">
      {/* Profile Header */}
      <div className="profile-header">
        <div className="avatar">JD</div>
        <h1 className="profile-name">John Davis</h1>
        <p className="profile-email">john.davis@email.com</p>
      </div>

      {/* Stats Section */}
      <div className="stats-section">
        <div className="stat-item">
          <div className="stat-number">12</div>
          <div className="stat-label">Verified</div>
        </div>
        <div className="stat-item">
          <div className="stat-number">3</div>
          <div className="stat-label">This Month</div>
        </div>
        <div className="stat-item clickable" onClick={handleFriendsClick}>
          <div className="stat-number">24</div>
          <div className="stat-label">Friends</div>
        </div>
      </div>

      {/* Conditional RSVP Section */}
      {rsvpStatus !== 'not-going' ? (
        <div className="upload-section">
          <h2>Been to Franklin?</h2>
          <div className="upload-box">
            <div className="upload-icon">📷</div>
            <p className="upload-text">Upload your visit photo</p>
            <p className="upload-subtext">Share your experience and get verified</p>
            <button className="upload-button">Choose Photo</button>
          </div>
        </div>
      ) : (
        <div className="not-going-section">
          <h2>Not Going This Week</h2>
          <div className="not-going-box">
            <div className="not-going-icon">😔</div>
            <p className="not-going-text">You're not going to Franklin this week</p>
            <button className="change-rsvp-button" onClick={handleChangeRSVP}>
              Change RSVP
            </button>
          </div>
        </div>
      )}

      {/* Verified Visits Section */}
      <div className="verified-visits-section">
        <h2>Verified Visits</h2>
        <div className="visits-grid">
          {verifiedVisits.map((visit) => (
            <div key={visit.id} className="visit-card">
              <div className="visit-header">
                <h3 className="visit-restaurant">{visit.restaurant}</h3>
                <div className="visit-rating">{renderStars(visit.rating)}</div>
              </div>
              <p className="visit-date">{formatDate(visit.date)}</p>
              <p className="visit-review">{visit.review}</p>
              <div className="visit-actions">
                <button className="visit-action-button">Edit</button>
                <button className="visit-action-button">Share</button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Friends Modal */}
      <FriendsModal 
        isOpen={showFriendsModal}
        onClose={handleCloseModal}
      />
    </div>
  );
};

export default ProfilePage;