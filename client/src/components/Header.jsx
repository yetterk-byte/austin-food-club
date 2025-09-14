import React from 'react';
import './Header.css';

const Header = ({ currentPage }) => {
  return (
    <header className="header">
      <div className="header-content">
        <div className="logo">
          <h1>Austin Food Club</h1>
        </div>
        <div className="page-badge">
          <span className="badge-text">{currentPage}</span>
        </div>
      </div>
    </header>
  );
};

export default Header;
