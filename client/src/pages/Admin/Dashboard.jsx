import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import StatsCard from '../../components/Admin/StatsCard';
import './Dashboard.css';

const AdminDashboard = () => {
  const [dashboardData, setDashboardData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('adminToken');
      
      if (!token) {
        navigate('/admin/login');
        return;
      }

      const response = await fetch('/api/admin/dashboard', {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.status === 401 || response.status === 403) {
        navigate('/admin/login');
        return;
      }

      if (!response.ok) {
        throw new Error('Failed to fetch dashboard data');
      }

      const data = await response.json();
      setDashboardData(data);
    } catch (err) {
      console.error('Dashboard fetch error:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="admin-loading">
        <div className="admin-loading-spinner"></div>
        <span style={{ marginLeft: '1rem' }}>Loading dashboard...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="admin-error">
        <h3>Error Loading Dashboard</h3>
        <p>{error}</p>
        <button onClick={fetchDashboardData} className="retry-btn">
          Retry
        </button>
      </div>
    );
  }

  const { stats, currentRestaurant, rsvpsByDay, recentActions } = dashboardData;

  return (
    <div className="admin-dashboard">
      <div className="dashboard-header">
        <h1>Admin Dashboard</h1>
        <p>Manage your Austin Food Club community</p>
      </div>

      {/* Stats Overview */}
      <div className="stats-grid">
        <StatsCard
          title="Total Users"
          value={stats.totalUsers}
          icon="👥"
          change={`+${stats.newUsersThisWeek} this week`}
          changeType="positive"
        />
        <StatsCard
          title="This Week's RSVPs"
          value={stats.thisWeekRSVPs}
          icon="📅"
          change={`${Object.values(rsvpsByDay).reduce((a, b) => a + b, 0)} total`}
          changeType="neutral"
        />
        <StatsCard
          title="Total Restaurants"
          value={stats.totalRestaurants}
          icon="🍽️"
          change={`${stats.queueLength} in queue`}
          changeType="neutral"
        />
        <StatsCard
          title="Verified Visits"
          value={stats.totalVerifiedVisits}
          icon="✅"
          change={`${stats.activeFriendships} friendships`}
          changeType="positive"
        />
      </div>

      {/* Current Week Section */}
      <div className="dashboard-section">
        <h2>This Week's Featured Restaurant</h2>
        {currentRestaurant ? (
          <div className="current-restaurant-card">
            <div className="restaurant-image">
              <img 
                src={currentRestaurant.imageUrl || '/placeholder-restaurant.jpg'} 
                alt={currentRestaurant.name}
                onError={(e) => e.target.src = '/placeholder-restaurant.jpg'}
              />
            </div>
            <div className="restaurant-info">
              <h3>{currentRestaurant.name}</h3>
              <p className="restaurant-address">{currentRestaurant.address}</p>
              <div className="restaurant-stats">
                <span className="rating">⭐ {currentRestaurant.rating}</span>
                <span className="price">{currentRestaurant.price}</span>
              </div>
              <div className="restaurant-actions">
                <button 
                  onClick={() => navigate('/admin/current')}
                  className="btn-primary"
                >
                  Manage Current Week
                </button>
                <button 
                  onClick={() => navigate('/admin/queue')}
                  className="btn-secondary"
                >
                  View Queue
                </button>
              </div>
            </div>
          </div>
        ) : (
          <div className="no-restaurant">
            <p>No restaurant currently featured</p>
            <button 
              onClick={() => navigate('/admin/queue')}
              className="btn-primary"
            >
              Set Featured Restaurant
            </button>
          </div>
        )}
      </div>

      {/* RSVP Breakdown */}
      <div className="dashboard-section">
        <h2>This Week's RSVP Breakdown</h2>
        <div className="rsvp-breakdown">
          {['Thursday', 'Friday', 'Saturday', 'Sunday'].map(day => (
            <div key={day} className="rsvp-day">
              <div className="rsvp-day-name">{day}</div>
              <div className="rsvp-day-count">{rsvpsByDay[day] || 0}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Recent Admin Actions */}
      <div className="dashboard-section">
        <h2>Recent Admin Actions</h2>
        <div className="recent-actions">
          {recentActions.length > 0 ? (
            recentActions.map(action => (
              <div key={action.id} className="action-item">
                <div className="action-info">
                  <span className="action-admin">{action.admin.name}</span>
                  <span className="action-description">{action.action.replace(/_/g, ' ')}</span>
                  <span className="action-time">
                    {new Date(action.createdAt).toLocaleDateString()} {new Date(action.createdAt).toLocaleTimeString()}
                  </span>
                </div>
              </div>
            ))
          ) : (
            <p className="no-actions">No recent admin actions</p>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="dashboard-section">
        <h2>Quick Actions</h2>
        <div className="quick-actions">
          <button 
            onClick={() => navigate('/admin/queue')}
            className="quick-action-btn"
          >
            <span>🍽️</span>
            <span>Manage Queue</span>
          </button>
          <button 
            onClick={() => navigate('/admin/current')}
            className="quick-action-btn"
          >
            <span>⭐</span>
            <span>Change Featured</span>
          </button>
          <button 
            onClick={() => navigate('/admin/users')}
            className="quick-action-btn"
          >
            <span>👥</span>
            <span>View Users</span>
          </button>
          <button 
            onClick={() => navigate('/admin/analytics')}
            className="quick-action-btn"
          >
            <span>📈</span>
            <span>Analytics</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default AdminDashboard;
