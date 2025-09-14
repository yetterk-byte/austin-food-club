import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import './App.css';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import CurrentPage from './pages/app/CurrentPage';
import WishlistPage from './pages/app/WishlistPage';
import ProfilePage from './pages/app/ProfilePage';
import LoginPage from './pages/auth/LoginPage';

const AppContent = () => {
  const location = useLocation();
  const { user, loading } = useAuth();
  const [currentPage, setCurrentPage] = useState('current');
  const [selectedDay, setSelectedDay] = useState(null); // eslint-disable-line no-unused-vars
  const [rsvpStatus, setRsvpStatus] = useState(null);

  const getPageName = (pathname) => {
    switch (pathname) {
      case '/current': return 'Current';
      case '/wishlist': return 'Wishlist';
      case '/profile': return 'Profile';
      case '/login': return 'Login';
      default: return 'Current';
    }
  };

  const getPageId = (pathname) => {
    switch (pathname) {
      case '/current': return 'current';
      case '/wishlist': return 'wishlist';
      case '/profile': return 'profile';
      case '/login': return 'login';
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

  // Show loading spinner while checking authentication
  if (loading) {
    return (
      <div className="app">
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  // Show login page if not authenticated
  if (!user) {
    return (
      <div className="app">
        <Header currentPage={getPageName(location.pathname)} />
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </div>
    );
  }

  // Show main app if authenticated
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
        <Route path="/login" element={<Navigate to="/current" replace />} />
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
    <AuthProvider>
      <Router>
        <AppContent />
      </Router>
    </AuthProvider>
  );
}

export default App;