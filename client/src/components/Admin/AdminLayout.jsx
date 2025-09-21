import React from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import './AdminLayout.css';

const AdminLayout = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const navigationItems = [
    { id: 'overview', label: 'Overview', icon: '📊', path: '/admin' },
    { id: 'queue', label: 'Restaurant Queue', icon: '🍽️', path: '/admin/queue' },
    { id: 'current', label: 'Current Week', icon: '⭐', path: '/admin/current' },
    { id: 'users', label: 'Users', icon: '👥', path: '/admin/users' },
    { id: 'analytics', label: 'Analytics', icon: '📈', path: '/admin/analytics' },
    { id: 'settings', label: 'Settings', icon: '⚙️', path: '/admin/settings' }
  ];

  const handleLogout = () => {
    // Clear admin session and redirect
    localStorage.removeItem('adminToken');
    navigate('/admin/login');
  };

  const isActivePath = (path) => {
    return location.pathname === path || (path === '/admin' && location.pathname === '/admin/dashboard');
  };

  return (
    <div className="admin-layout">
      {/* Sidebar Navigation */}
      <div className="admin-sidebar">
        <div className="admin-header">
          <h1 className="admin-title">Austin Food Club</h1>
          <p className="admin-subtitle">Admin Dashboard</p>
        </div>

        <nav className="admin-nav">
          {navigationItems.map(item => (
            <button
              key={item.id}
              className={`admin-nav-item ${isActivePath(item.path) ? 'active' : ''}`}
              onClick={() => navigate(item.path)}
            >
              <span className="admin-nav-icon">{item.icon}</span>
              <span className="admin-nav-label">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="admin-footer">
          <button className="admin-logout-btn" onClick={handleLogout}>
            <span>🚪</span>
            <span>Logout</span>
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="admin-main">
        <div className="admin-content">
          <Outlet />
        </div>
      </div>
    </div>
  );
};

export default AdminLayout;
