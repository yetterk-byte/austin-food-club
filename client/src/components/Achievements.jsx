import React, { useState, useEffect } from 'react';
import './Achievements.css';

const Achievements = ({ userStats, verifiedVisits }) => {
  const [achievements, setAchievements] = useState([]);
  const [nextMilestone, setNextMilestone] = useState(null);

  // Define all possible achievements
  const allAchievements = [
    {
      id: 'first-verification',
      name: 'First Bite',
      description: 'Verify your first visit',
      icon: '🍽️',
      color: '#4CAF50',
      requirement: 1,
      type: 'visits'
    },
    {
      id: 'explorer',
      name: 'Explorer',
      description: 'Verify 5 visits',
      icon: '🗺️',
      color: '#2196F3',
      requirement: 5,
      type: 'visits'
    },
    {
      id: 'foodie',
      name: 'Foodie',
      description: 'Verify 10 visits',
      icon: '🍕',
      color: '#FF9800',
      requirement: 10,
      type: 'visits'
    },
    {
      id: 'connoisseur',
      name: 'Connoisseur',
      description: 'Verify 25 visits',
      icon: '🍷',
      color: '#9C27B0',
      requirement: 25,
      type: 'visits'
    },
    {
      id: 'critic',
      name: 'Food Critic',
      description: 'Write 10 detailed reviews',
      icon: '📝',
      color: '#607D8B',
      requirement: 10,
      type: 'reviews'
    },
    {
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Give 5 perfect ratings',
      icon: '⭐',
      color: '#FFD700',
      requirement: 5,
      type: 'perfect_ratings'
    },
    {
      id: 'streak-3',
      name: 'Getting Started',
      description: '3-day verification streak',
      icon: '🔥',
      color: '#FF6B35',
      requirement: 3,
      type: 'streak'
    },
    {
      id: 'streak-7',
      name: 'Week Warrior',
      description: '7-day verification streak',
      icon: '💪',
      color: '#E91E63',
      requirement: 7,
      type: 'streak'
    },
    {
      id: 'streak-30',
      name: 'Month Master',
      description: '30-day verification streak',
      icon: '👑',
      color: '#795548',
      requirement: 30,
      type: 'streak'
    },
    {
      id: 'early-bird',
      name: 'Early Bird',
      description: 'Verify 5 morning visits',
      icon: '🌅',
      color: '#FFC107',
      requirement: 5,
      type: 'morning_visits'
    },
    {
      id: 'night-owl',
      name: 'Night Owl',
      description: 'Verify 5 evening visits',
      icon: '🦉',
      color: '#673AB7',
      requirement: 5,
      type: 'evening_visits'
    }
  ];

  // Calculate user's progress for each achievement type
  const calculateProgress = () => {
    if (!userStats || !verifiedVisits) return {};

    const totalVisits = userStats.totalVerifiedVisits || 0;
    const currentStreak = userStats.currentStreak || 0;
    const perfectRatings = verifiedVisits.filter(visit => visit.rating === 5).length;
    const detailedReviews = verifiedVisits.filter(visit => 
      visit.review && visit.review.length > 50
    ).length;

    // Calculate time-based visits
    const morningVisits = verifiedVisits.filter(visit => {
      const hour = new Date(visit.visitDate).getHours();
      return hour >= 6 && hour < 12;
    }).length;

    const eveningVisits = verifiedVisits.filter(visit => {
      const hour = new Date(visit.visitDate).getHours();
      return hour >= 18 && hour < 24;
    }).length;

    return {
      visits: totalVisits,
      streak: currentStreak,
      perfect_ratings: perfectRatings,
      reviews: detailedReviews,
      morning_visits: morningVisits,
      evening_visits: eveningVisits
    };
  };

  // Check which achievements are earned
  useEffect(() => {
    const progress = calculateProgress();
    const earnedAchievements = allAchievements.map(achievement => {
      const currentProgress = progress[achievement.type] || 0;
      const isEarned = currentProgress >= achievement.requirement;
      const progressPercent = Math.min((currentProgress / achievement.requirement) * 100, 100);

      return {
        ...achievement,
        isEarned,
        progress: currentProgress,
        progressPercent,
        earnedDate: isEarned ? new Date().toISOString() : null
      };
    });

    setAchievements(earnedAchievements);

    // Find next milestone
    const unearnedAchievements = earnedAchievements.filter(a => !a.isEarned);
    const next = unearnedAchievements.reduce((closest, current) => {
      if (!closest || current.progressPercent > closest.progressPercent) {
        return current;
      }
      return closest;
    }, null);

    setNextMilestone(next);
  }, [userStats, verifiedVisits]);

  const earnedCount = achievements.filter(a => a.isEarned).length;
  const totalCount = achievements.length;

  return (
    <div className="achievements-section">
      <div className="achievements-header">
        <h3>Achievements</h3>
        <div className="achievements-progress">
          <span className="progress-text">{earnedCount}/{totalCount}</span>
          <div className="progress-bar">
            <div 
              className="progress-fill"
              style={{ width: `${(earnedCount / totalCount) * 100}%` }}
            ></div>
          </div>
        </div>
      </div>

      {/* Next Milestone */}
      {nextMilestone && (
        <div className="next-milestone">
          <div className="milestone-header">
            <h4>Next Milestone</h4>
            <span className="milestone-progress">
              {nextMilestone.progress}/{nextMilestone.requirement}
            </span>
          </div>
          <div className="milestone-achievement">
            <div 
              className="milestone-icon"
              style={{ backgroundColor: nextMilestone.color }}
            >
              {nextMilestone.icon}
            </div>
            <div className="milestone-info">
              <div className="milestone-name">{nextMilestone.name}</div>
              <div className="milestone-description">{nextMilestone.description}</div>
            </div>
          </div>
          <div className="milestone-progress-bar">
            <div 
              className="milestone-fill"
              style={{ width: `${nextMilestone.progressPercent}%` }}
            ></div>
          </div>
        </div>
      )}

      {/* Achievements Grid */}
      <div className="achievements-grid">
        {achievements.map((achievement) => (
          <div 
            key={achievement.id} 
            className={`achievement-item ${achievement.isEarned ? 'earned' : 'locked'}`}
          >
            <div 
              className="achievement-icon"
              style={{ 
                backgroundColor: achievement.isEarned ? achievement.color : '#333',
                opacity: achievement.isEarned ? 1 : 0.5
              }}
            >
              {achievement.isEarned ? achievement.icon : '🔒'}
            </div>
            <div className="achievement-info">
              <div className="achievement-name">{achievement.name}</div>
              <div className="achievement-description">{achievement.description}</div>
              {!achievement.isEarned && (
                <div className="achievement-progress">
                  {achievement.progress}/{achievement.requirement}
                </div>
              )}
            </div>
            {achievement.isEarned && (
              <div className="achievement-badge">✓</div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default Achievements;
