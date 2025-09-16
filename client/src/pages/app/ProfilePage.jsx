import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import FriendsModal from '../../components/FriendsModal';
import './ProfilePage.css';

const ProfilePage = ({ rsvpStatus, setCurrentPage }) => {
  const { user, signOut } = useAuth();
  const [showFriendsModal, setShowFriendsModal] = useState(false);
  const [verifiedVisits, setVerifiedVisits] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [stats, setStats] = useState({
    verifiedVisits: 0,
    thisMonth: 0,
    friends: 0
  });


  const handleFriendsClick = () => {
    setShowFriendsModal(true);
  };

  const handleCloseModal = () => {
    setShowFriendsModal(false);
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

  // Fetch user data and verified visits
  useEffect(() => {
    const fetchUserData = async () => {
      if (!user) {
        setLoading(false);
        return;
      }

      try {
        setLoading(true);
        setError(null);

        // For now, use mock data since we don't have verified visits API yet
        // In a real app, you would fetch from API endpoints
        const mockVisits = [
          {
            id: 1,
            restaurant: 'Uchi',
            date: '2024-01-15',
            rating: 5,
            image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjRkY2QjZCIi8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIyNCIgZmlsbD0iI0ZGRiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPlN1c2hpPC90ZXh0Pgo8L3N2Zz4K',
            verificationPhoto: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjRkY2QjZCIi8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIyNCIgZmlsbD0iI0ZGRiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPlN1c2hpPC90ZXh0Pgo8L3N2Zz4K'
          },
          {
            id: 2,
            restaurant: 'Suerte',
            date: '2024-01-20',
            rating: 4,
            image: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjNEVDREM0Ii8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIyNCIgZmlsbD0iI0ZGRiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPk1leGljYW4gRm9vZDwvdGV4dD4KPC9zdmc+Cg==',
            verificationPhoto: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjNEVDREM0Ii8+CiAgPHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIyNCIgZmlsbD0iI0ZGRiIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPk1leGljYW4gRm9vZDwvdGV4dD4KPC9zdmc+Cg=='
          }
        ];

        console.log('Mock visits with images:', mockVisits);
        setVerifiedVisits(mockVisits);
        setStats({
          verifiedVisits: mockVisits.length,
          thisMonth: mockVisits.filter(visit => {
            const visitDate = new Date(visit.date);
            const now = new Date();
            return visitDate.getMonth() === now.getMonth() && 
                   visitDate.getFullYear() === now.getFullYear();
          }).length,
          friends: 24 // Mock data
        });
      } catch (err) {
        console.error('Error fetching user data:', err);
        setError('Failed to load profile data');
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, [user]);

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
              <div 
                className="visit-background"
                style={{
                  backgroundImage: `url(${visit.verificationPhoto || visit.image})`
                }}
                title={`Background: ${visit.verificationPhoto || visit.image}`}
              ></div>
              <div className="visit-content">
                <div className="visit-header">
                  <h3 className="visit-restaurant">{visit.restaurant}</h3>
                  <div className="visit-rating">{renderStars(visit.rating)}</div>
                </div>
                <p className="visit-date">{formatDate(visit.date)}</p>
                <div className="visit-actions">
                  <button className="visit-action-button">Share</button>
                </div>
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