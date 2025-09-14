import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import './App.css';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import CurrentPage from './pages/app/CurrentPage';
import WishlistPage from './pages/app/WishlistPage';
import ProfilePage from './pages/app/ProfilePage';

const AppContent = () => {
  const location = useLocation();
  const [currentPage, setCurrentPage] = useState('current');
  const [selectedDay, setSelectedDay] = useState(null); // eslint-disable-line no-unused-vars
  const [rsvpStatus, setRsvpStatus] = useState(null);

  const getPageName = (pathname) => {
    switch (pathname) {
      case '/current': return 'Current';
      case '/wishlist': return 'Wishlist';
      case '/profile': return 'Profile';
      default: return 'Current';
    }
  };

  const getPageId = (pathname) => {
    switch (pathname) {
      case '/current': return 'current';
      case '/wishlist': return 'wishlist';
      case '/profile': return 'profile';
      default: return 'current';
    }
  };

  React.useEffect(() => {
    setCurrentPage(getPageId(location.pathname));
  }, [location.pathname]);

  const handleDayChange = (day) => {
    setSelectedDay(day);
    console.log('Selected day:', day);
  };

  const handleStatusChange = (status) => {
    setRsvpStatus(status);
    console.log('RSVP status:', status);
  };

  return (
    <div className="app">
      <Header currentPage={getPageName(location.pathname)} />
      
      <Routes>
        <Route path="/current" element={
          <CurrentPage 
            onDayChange={handleDayChange}
            onStatusChange={handleStatusChange}
          />
        } />
        <Route path="/wishlist" element={<WishlistPage />} />
        <Route path="/profile" element={
          <ProfilePage 
            rsvpStatus={rsvpStatus}
            setCurrentPage={setCurrentPage}
          />
        } />
        <Route path="/" element={<Navigate to="/current" replace />} />
      </Routes>
      
      <BottomNav 
        currentPage={currentPage}
        setCurrentPage={setCurrentPage}
      />
    </div>
  );
};

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

export default App;