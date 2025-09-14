import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import './App.css';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import ProtectedRoute from './components/ProtectedRoute';
import CurrentPage from './pages/app/CurrentPage';
import WishlistPage from './pages/app/WishlistPage';
import ProfilePage from './pages/app/ProfilePage';
import Login from './pages/Login';

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

  return (
    <div className="app">
      <Header currentPage={getPageName(location.pathname)} />
      
      <Routes>
        {/* Public routes */}
        <Route path="/login" element={<Login />} />
        
        {/* Protected routes */}
        <Route path="/current" element={
          <ProtectedRoute>
            <CurrentPage 
              onDayChange={handleDayChange}
              onStatusChange={handleStatusChange}
            />
          </ProtectedRoute>
        } />
        <Route path="/wishlist" element={
          <ProtectedRoute>
            <WishlistPage />
          </ProtectedRoute>
        } />
        <Route path="/profile" element={
          <ProtectedRoute>
            <ProfilePage 
              rsvpStatus={rsvpStatus}
              setCurrentPage={setCurrentPage}
            />
          </ProtectedRoute>
        } />
        
        {/* Default redirects */}
        <Route path="/" element={<Navigate to="/current" replace />} />
        <Route path="*" element={<Navigate to="/current" replace />} />
      </Routes>
      
      {/* Only show bottom nav on protected routes */}
      {location.pathname !== '/login' && (
        <BottomNav 
          currentPage={currentPage}
          setCurrentPage={setCurrentPage}
        />
      )}
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