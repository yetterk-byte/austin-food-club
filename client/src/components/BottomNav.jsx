import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './BottomNav.css';

const BottomNav = ({ currentPage, setCurrentPage }) => {
  const navigate = useNavigate();
  const { user, signOut } = useAuth();
  
  const navItems = [
    { id: 'current', label: 'Current', path: '/current' },
    { id: 'discover', label: 'Discover', path: '/discover' },
    { id: 'wishlist', label: 'Wishlist', path: '/wishlist' },
    { id: 'profile', label: 'Profile', path: '/profile' },
  ];

  const handleLogout = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (err) {
      console.error('Error signing out:', err);
    }
  };

  const getInitials = (name) => {
    if (!name || typeof name !== 'string') {
      return 'U'; // Default fallback
    }
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  };

  const handleTabClick = (tabId, path) => {
    setCurrentPage(tabId);
    navigate(path);
  };

  return (
    <nav className="bottom-nav">
      {navItems.map((item) => (
        <button
          key={item.id}
          className={`nav-item ${currentPage === item.id ? 'active' : ''}`}
          onClick={() => handleTabClick(item.id, item.path)}
        >
          <span className="nav-icon">
            {item.id === 'current' && '●'}
            {item.id === 'discover' && '🔍'}
            {item.id === 'wishlist' && '○'}
            {item.id === 'profile' && (user ? '👤' : '○')}
          </span>
          <span className="nav-label">{item.label}</span>
        </button>
      ))}
      
      {/* User Info Section */}
      {user && (
        <div className="user-info">
          <div className="user-avatar">
            {user.avatar ? (
              <img src={user.avatar} alt={user.name || 'User'} />
            ) : (
              getInitials(user.name)
            )}
          </div>
          <div className="user-details">
            <span className="user-name">{user.name || 'User'}</span>
            <span className="user-provider">{user.provider || 'email'}</span>
          </div>
          <button onClick={handleLogout} className="logout-btn" title="Logout">
            🚪
          </button>
        </div>
      )}
    </nav>
  );
};

export default BottomNav;