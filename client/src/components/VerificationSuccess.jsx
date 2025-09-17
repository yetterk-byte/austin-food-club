import React, { useState, useEffect } from 'react';
import StarRating from './StarRating';
import './VerificationSuccess.css';

const VerificationSuccess = ({ 
  isOpen, 
  onClose, 
  verificationData,
  userStats,
  onShare 
}) => {
  const [animationStep, setAnimationStep] = useState(0);
  const [pointsEarned, setPointsEarned] = useState(0);
  const [badgesEarned, setBadgesEarned] = useState([]);
  const [showShareOptions, setShowShareOptions] = useState(false);

  // Calculate points based on verification data
  const calculatePoints = (data) => {
    let points = 0;
    
    // Base points for verification
    points += 10;
    
    // Bonus points for rating
    if (data.rating >= 4) points += 5;
    if (data.rating === 5) points += 10; // Perfect rating bonus
    
    // Bonus points for review
    if (data.review && data.review.length > 50) points += 5;
    
    // Streak bonus
    if (userStats?.currentStreak >= 3) points += 5;
    if (userStats?.currentStreak >= 7) points += 10;
    
    return points;
  };

  // Check for new badges earned
  const checkBadges = (data, stats) => {
    const newBadges = [];
    
    // First verification badge
    if (stats?.totalVerifiedVisits === 1) {
      newBadges.push({
        id: 'first-verification',
        name: 'First Bite',
        description: 'Verified your first visit!',
        icon: '🍽️',
        color: '#4CAF50'
      });
    }
    
    // Rating badges
    if (data.rating === 5) {
      newBadges.push({
        id: 'perfect-rating',
        name: 'Perfectionist',
        description: 'Gave a perfect 5-star rating!',
        icon: '⭐',
        color: '#FFD700'
      });
    }
    
    // Streak badges
    if (stats?.currentStreak === 3) {
      newBadges.push({
        id: 'streak-3',
        name: 'Getting Started',
        description: '3-day verification streak!',
        icon: '🔥',
        color: '#FF6B35'
      });
    }
    
    if (stats?.currentStreak === 7) {
      newBadges.push({
        id: 'streak-7',
        name: 'Week Warrior',
        description: '7-day verification streak!',
        icon: '💪',
        color: '#9C27B0'
      });
    }
    
    // Review badges
    if (data.review && data.review.length > 100) {
      newBadges.push({
        id: 'detailed-review',
        name: 'Food Critic',
        description: 'Wrote a detailed review!',
        icon: '📝',
        color: '#2196F3'
      });
    }
    
    return newBadges;
  };

  // Animation sequence
  useEffect(() => {
    if (!isOpen) {
      setAnimationStep(0);
      setPointsEarned(0);
      setBadgesEarned([]);
      setShowShareOptions(false);
      return;
    }

    const timer = setTimeout(() => {
      setAnimationStep(1);
      
      // Calculate points and badges
      const points = calculatePoints(verificationData);
      const badges = checkBadges(verificationData, userStats);
      
      setPointsEarned(points);
      setBadgesEarned(badges);
      
      // Show share options after animation
      setTimeout(() => {
        setShowShareOptions(true);
      }, 2000);
    }, 500);

    return () => clearTimeout(timer);
  }, [isOpen, verificationData, userStats]);

  // Generate shareable content
  const generateShareContent = () => {
    const restaurantName = verificationData?.restaurantName || 'Restaurant';
    const rating = verificationData?.rating || 0;
    const review = verificationData?.review || '';
    
    return {
      text: `Just verified my visit to ${restaurantName}! ${rating}⭐ ${review ? `"${review.substring(0, 100)}${review.length > 100 ? '...' : ''}"` : ''} #AustinFoodClub`,
      url: window.location.origin,
      title: `My visit to ${restaurantName}`
    };
  };

  // Copy to clipboard
  const copyToClipboard = async (text) => {
    try {
      await navigator.clipboard.writeText(text);
      // Show success message
      alert('Copied to clipboard!');
    } catch (err) {
      console.error('Failed to copy: ', err);
    }
  };

  // Share via Web Share API
  const shareViaWebAPI = async () => {
    const shareContent = generateShareContent();
    
    if (navigator.share) {
      try {
        await navigator.share(shareContent);
      } catch (err) {
        console.log('Share cancelled or failed');
      }
    } else {
      // Fallback to copy
      copyToClipboard(shareContent.text);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="verification-success-overlay">
      <div className="verification-success-modal">
        <div className="success-content">
          {/* Success Animation */}
          <div className={`success-animation ${animationStep >= 1 ? 'animate' : ''}`}>
            <div className="success-icon">✅</div>
            <h2>Visit Verified!</h2>
            <p>Great job documenting your food adventure!</p>
          </div>

          {/* Points Display */}
          {animationStep >= 1 && (
            <div className="points-display">
              <div className="points-icon">🎯</div>
              <div className="points-text">
                <span className="points-number">+{pointsEarned}</span>
                <span className="points-label">Points Earned</span>
              </div>
            </div>
          )}

          {/* Badges Earned */}
          {badgesEarned.length > 0 && (
            <div className="badges-section">
              <h3>New Badges Earned!</h3>
              <div className="badges-grid">
                {badgesEarned.map((badge) => (
                  <div key={badge.id} className="badge-item">
                    <div 
                      className="badge-icon"
                      style={{ backgroundColor: badge.color }}
                    >
                      {badge.icon}
                    </div>
                    <div className="badge-info">
                      <div className="badge-name">{badge.name}</div>
                      <div className="badge-description">{badge.description}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Stats Display */}
          {userStats && (
            <div className="stats-section">
              <h3>Your Progress</h3>
              <div className="stats-grid">
                <div className="stat-item">
                  <div className="stat-icon">📊</div>
                  <div className="stat-info">
                    <div className="stat-value">{userStats.totalVerifiedVisits}</div>
                    <div className="stat-label">Verified Visits</div>
                  </div>
                </div>
                
                <div className="stat-item">
                  <div className="stat-icon">⭐</div>
                  <div className="stat-info">
                    <div className="stat-value">{userStats.averageRating?.toFixed(1) || '0.0'}</div>
                    <div className="stat-label">Avg Rating</div>
                  </div>
                </div>
                
                <div className="stat-item">
                  <div className="stat-icon">🔥</div>
                  <div className="stat-info">
                    <div className="stat-value">{userStats.currentStreak || 0}</div>
                    <div className="stat-label">Day Streak</div>
                  </div>
                </div>
                
                <div className="stat-item">
                  <div className="stat-icon">🏆</div>
                  <div className="stat-info">
                    <div className="stat-value">{userStats.rank || 'N/A'}</div>
                    <div className="stat-label">Rank</div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Progress Bar */}
          {userStats && (
            <div className="progress-section">
              <h4>Next Milestone</h4>
              <div className="progress-bar">
                <div 
                  className="progress-fill"
                  style={{ 
                    width: `${Math.min((userStats.totalVerifiedVisits / 10) * 100, 100)}%` 
                  }}
                ></div>
              </div>
              <p className="progress-text">
                {userStats.totalVerifiedVisits}/10 visits to next achievement
              </p>
            </div>
          )}

          {/* Social Sharing */}
          {showShareOptions && (
            <div className="sharing-section">
              <h3>Share Your Visit</h3>
              <div className="share-options">
                <button 
                  className="share-button primary"
                  onClick={shareViaWebAPI}
                >
                  <span className="share-icon">📱</span>
                  Share
                </button>
                
                <button 
                  className="share-button secondary"
                  onClick={() => copyToClipboard(generateShareContent().text)}
                >
                  <span className="share-icon">📋</span>
                  Copy Text
                </button>
                
                <button 
                  className="share-button secondary"
                  onClick={() => copyToClipboard(generateShareContent().url)}
                >
                  <span className="share-icon">🔗</span>
                  Copy Link
                </button>
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="action-buttons">
            <button 
              className="continue-button"
              onClick={onClose}
            >
              Continue
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VerificationSuccess;
