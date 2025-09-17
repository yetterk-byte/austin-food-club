import React, { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import FriendsModal from '../../components/FriendsModal';
import VerificationModal from '../../components/VerificationModal';
import StarRating from '../../components/StarRating';
import LazyImage from '../../components/LazyImage';
import { apiService as api } from '../../services/api';
import './ProfilePage.css';

const ProfilePage = ({ rsvpStatus, setCurrentPage }) => {
  const { user, signOut } = useAuth();
  const location = useLocation();
  const [showFriendsModal, setShowFriendsModal] = useState(false);
  const [showVerificationModal, setShowVerificationModal] = useState(false);
  const [selectedVisit, setSelectedVisit] = useState(null);
  const [verifiedVisits, setVerifiedVisits] = useState([]);
  const [rsvpHistory, setRsvpHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [successMessage, setSuccessMessage] = useState(null);
  const [stats, setStats] = useState({
    verifiedVisits: 0,
    thisMonth: 0,
    friends: 0
  });

  // Get RSVP data from navigation state
  const currentRsvp = location.state?.currentRsvp;
  const currentRestaurant = location.state?.restaurant;


  const handleFriendsClick = () => {
    setShowFriendsModal(true);
  };

  const handleCloseModal = () => {
    setShowFriendsModal(false);
  };

  const handleVerifyVisit = (visit) => {
    setSelectedVisit(visit);
    setShowVerificationModal(true);
  };

  const handleCloseVerificationModal = () => {
    setShowVerificationModal(false);
    setSelectedVisit(null);
  };

  const handleVerificationSubmit = async (verificationData) => {
    try {
      // Submit verification to backend
      const response = await api.submitVerification({
        userId: user.id,
        restaurantId: verificationData.restaurantId,
        photo: verificationData.photo,
        rating: verificationData.rating,
        review: verificationData.review,
        visitDate: verificationData.visitDate
      });

      // Add the verification to verified visits
      const newVisit = {
        id: response.id || Date.now(),
        restaurant: {
          name: verificationData.restaurantName,
          id: verificationData.restaurantId
        },
        visitDate: verificationData.visitDate,
        rating: verificationData.rating,
        review: verificationData.review,
        photo: verificationData.photo,
        verificationPhoto: verificationData.photo
      };
      
      setVerifiedVisits(prev => [newVisit, ...prev]);
      
      // Update basic stats
      setStats(prev => ({
        ...prev,
        verifiedVisits: prev.verifiedVisits + 1
      }));

      // Close verification modal
      setShowVerificationModal(false);
      
      // Show success message
      setSuccessMessage('Visit verified successfully!');
      setTimeout(() => setSuccessMessage(null), 3000);
      
    } catch (error) {
      console.error('Error submitting verification:', error);
      throw error;
    }
  };

  const handleChangeRSVP = () => {
    setCurrentPage('current');
  };

  const handleLogout = async () => {
    try {
      await signOut();
    } catch (err) {
      console.error('Error signing out:', err);
    }
  };

  // Fetch user data, RSVP history, and verified visits
  useEffect(() => {
    const fetchUserData = async () => {
      if (!user) {
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        setError(null);

        // Fetch RSVP history
        const rsvpResponse = await api.getRSVPs();
        let rsvpData = rsvpResponse?.rsvps || [];
        
        // Add current RSVP to history if it exists and is verifiable
        if (currentRsvp && currentRsvp.canVerify) {
          // Check if it's not already in the history
          const existingRsvp = rsvpData.find(rsvp => 
            rsvp.restaurantId === currentRsvp.restaurantId && 
            rsvp.day === currentRsvp.day
          );
          
          if (!existingRsvp) {
            rsvpData = [currentRsvp, ...rsvpData];
          }
        }
        
        setRsvpHistory(rsvpData);

        // Fetch verified visits
        const verifiedResponse = await api.getVerifiedVisits();
        setVerifiedVisits(verifiedResponse?.verifiedVisits || []);

        // Calculate stats
        const verifiedCount = verifiedResponse?.verifiedVisits?.length || 0;
        const thisMonthCount = verifiedResponse?.verifiedVisits?.filter(visit => {
          const visitDate = new Date(visit.visitDate);
          const now = new Date();
          return visitDate.getMonth() === now.getMonth() && 
                 visitDate.getFullYear() === now.getFullYear();
        }).length || 0;

        setStats({
          verifiedVisits: verifiedCount,
          thisMonth: thisMonthCount,
          friends: 24 // Mock data for now
        });
      } catch (err) {
        console.error('Error fetching user data:', err);
        setError('Failed to load profile data');
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, [user, currentRsvp]);

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

  const getInitials = (name) => {
    if (!name || typeof name !== 'string') {
      return 'U'; // Default fallback
    }
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  };

  const getProviderIcon = (provider) => {
    switch (provider) {
      case 'google':
        return '🔍';
      case 'apple':
        return '🍎';
      case 'email':
        return '📧';
      case 'phone':
        return '📱';
      default:
        return '👤';
    }
  };

  if (!user) {
    return (
      <div className="profile-page">
        <div className="auth-prompt">
          <h2>Please Log In</h2>
          <p>You need to be logged in to view your profile.</p>
          <button onClick={() => window.location.href = '/login'} className="login-btn">
            Log In
          </button>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="profile-page">
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading profile...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="profile-page">
        <div className="error-container">
          <h3>Error</h3>
          <p>{error}</p>
          <button onClick={() => window.location.reload()} className="retry-btn">
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="profile-page">
      {/* Profile Header */}
      <div className="profile-header">
        <div className="avatar">
          {user.avatar ? (
            <img src={user.avatar} alt={user.name} />
          ) : (
            getInitials(user.name)
          )}
        </div>
        <h1 className="profile-name">{user.name}</h1>
        <p className="profile-email">{user.email || 'No email provided'}</p>
        <div className="profile-meta">
          <span className="provider-info">
            {getProviderIcon(user.provider)} {user.provider || 'email'} authentication
          </span>
          {user.emailVerified && (
            <span className="verified-badge">✓ Verified</span>
          )}
        </div>
        <button onClick={handleLogout} className="logout-btn">
          Logout
        </button>
      </div>

      {/* Stats Section */}
      <div className="stats-section">
        <div className="stat-item">
          <div className="stat-number">{stats.verifiedVisits}</div>
          <div className="stat-label">Verified</div>
        </div>
        <div className="stat-item">
          <div className="stat-number">{stats.thisMonth}</div>
          <div className="stat-label">This Month</div>
        </div>
        <div className="stat-item clickable" onClick={handleFriendsClick}>
          <div className="stat-number">{stats.friends}</div>
          <div className="stat-label">Friends</div>
        </div>
      </div>


      {/* Conditional RSVP Section */}
      {rsvpStatus !== 'not-going' ? (
        <div className="upload-section">
          <h2>Did You Go?</h2>
          <div className="upload-box">
            <div className="upload-icon">📷</div>
            <p className="upload-text">Upload your visit photo</p>
            <p className="upload-subtext">Share your experience and get verified</p>
            <button className="upload-button" onClick={() => handleVerifyVisit({
              restaurantId: 'franklin-bbq',
              restaurantName: 'Franklin Barbecue',
              day: new Date().toISOString()
            })}>Verify Visit</button>
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
          {/* Show actual verified visits */}
          {verifiedVisits.map((visit) => (
            <div key={visit.id} className="visit-card">
              <LazyImage
                src={visit.verificationPhoto || visit.photo}
                alt={`Visit to ${typeof visit.restaurant === 'string' ? visit.restaurant : visit.restaurant.name}`}
                className="visit-background"
                placeholder={
                  <div className="visit-placeholder">
                    <div className="placeholder-icon">📸</div>
                    <div className="placeholder-text">Loading photo...</div>
                  </div>
                }
              />
              <div className="visit-content">
                <div className="visit-header">
                  <h3 className="visit-restaurant">
                    {typeof visit.restaurant === 'string' ? visit.restaurant : visit.restaurant.name}
                  </h3>
                  <StarRating
                    initialRating={visit.rating}
                    readonly={true}
                    size="small"
                    showLabel={false}
                  />
                </div>
                <p className="visit-date">{formatDate(visit.visitDate)}</p>
                <div className="visit-actions">
                  <button className="visit-action-button">Share</button>
                </div>
              </div>
            </div>
          ))}
          
          {/* Show RSVP restaurants as unverified visits */}
          {rsvpHistory.map((rsvp) => {
            const canVerify = rsvp.canVerify || false;
            const isPending = rsvp.status === 'going' && !canVerify;
            
            return (
              <div key={`rsvp-${rsvp.id}`} className="visit-card unverified">
                <div className="visit-background"></div>
                <div className="visit-content">
                  <div className="visit-header">
                    <h3 className="visit-restaurant">{rsvp.restaurant.name}</h3>
                    <div className={`status-badge ${canVerify ? 'ready-to-verify' : isPending ? 'pending-verification' : 'not-verified'}`}>
                      {canVerify ? 'Ready to Verify' : isPending ? 'Pending Verification' : 'Not Verified'}
                    </div>
                  </div>
                  <p className="visit-date">{formatDate(rsvp.createdAt)}</p>
                  <p className="visit-status">RSVP: {rsvp.status}</p>
                  {rsvp.day && (
                    <p className="visit-day">Scheduled: {rsvp.day}</p>
                  )}
                  <div className="visit-actions">
                    {canVerify ? (
                      <button 
                        className="verify-button"
                        onClick={() => handleVerifyVisit({
                          restaurantId: rsvp.restaurantId,
                          restaurantName: rsvp.restaurant.name,
                          day: rsvp.day
                        })}
                      >
                        Verify Visit
                      </button>
                    ) : isPending ? (
                      <div className="pending-message">
                        <span className="pending-icon">⏳</span>
                        <span>Visit scheduled - verify after your visit</span>
                      </div>
                    ) : (
                      <div className="no-verify-message">
                        <span className="no-verify-icon">❌</span>
                        <span>Not going - no verification needed</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Friends Modal */}
      <FriendsModal 
        isOpen={showFriendsModal}
        onClose={handleCloseModal}
      />

      {/* Verification Modal */}
      {selectedVisit && (
        <VerificationModal
          isOpen={showVerificationModal}
          onClose={handleCloseVerificationModal}
          restaurantId={selectedVisit.restaurantId}
          restaurantName={selectedVisit.restaurantName}
          visitDate={formatDate(selectedVisit.day)}
          onVerificationSubmit={handleVerificationSubmit}
        />
      )}


      {/* Success Message */}
      {successMessage && (
        <div className="success-toast">
          <span className="success-icon">✅</span>
          {successMessage}
        </div>
      )}
    </div>
  );
};

export default ProfilePage;