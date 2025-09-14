import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Header.css';

const Header = ({ currentPage }) => {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const userMenuRef = useRef(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target)) {
        setShowUserMenu(false);
      }
    };

    if (showUserMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showUserMenu]);

  const handleLogout = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const handleProfileClick = () => {
    navigate('/profile');
    setShowUserMenu(false);
  };

  const handleLoginClick = () => {
    navigate('/login');
  };

  const getUserDisplayName = () => {
    if (!user) return '';
    
    // Prefer name, then phone, then email
    if (user.user_metadata?.name) {
      return user.user_metadata.name;
    }
    if (user.phone) {
      return user.phone;
    }
    if (user.email) {
      return user.email.split('@')[0];
    }
    return 'User';
  };

  return (
    <header className="header">
      <div className="header-content">
        <div className="logo">
          <h1>Austin Food Club</h1>
        </div>
        
        <div className="header-right">
          <div className="page-badge">
            <span className="badge-text">{currentPage}</span>
          </div>
          
          {user ? (
            <div className="user-menu" ref={userMenuRef}>
              <button 
                className="user-button"
                onClick={() => setShowUserMenu(!showUserMenu)}
                aria-label="User menu"
              >
                <div className="user-avatar">
                  {getUserDisplayName().charAt(0).toUpperCase()}
                </div>
                <span className="user-name">{getUserDisplayName()}</span>
                <span className="dropdown-arrow">▼</span>
              </button>
              
              {showUserMenu && (
                <div className="user-dropdown">
                  <button 
                    className="dropdown-item"
                    onClick={handleProfileClick}
                  >
                    Profile
                  </button>
                  <button 
                    className="dropdown-item logout"
                    onClick={handleLogout}
                  >
                    Logout
                  </button>
                </div>
              )}
            </div>
          ) : (
            <button 
              className="login-button"
              onClick={handleLoginClick}
            >
              Login
            </button>
          )}
        </div>
      </div>
    </header>
  );
};

export default Header;
