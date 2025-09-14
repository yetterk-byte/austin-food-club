import React from 'react';
import { useNavigate } from 'react-router-dom';
import './BottomNav.css';

const BottomNav = ({ currentPage, setCurrentPage }) => {
  const navigate = useNavigate();
  
  const navItems = [
    { id: 'current', label: 'Current', path: '/current' },
    { id: 'wishlist', label: 'Wishlist', path: '/wishlist' },
    { id: 'profile', label: 'Profile', path: '/profile' },
  ];

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
            {item.id === 'wishlist' && '○'}
            {item.id === 'profile' && '○'}
          </span>
          <span className="nav-label">{item.label}</span>
        </button>
      ))}
    </nav>
  );
};

export default BottomNav;