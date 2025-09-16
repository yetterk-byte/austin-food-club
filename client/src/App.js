import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import './App.css';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import ProtectedRoute from './components/ProtectedRoute';
import AuthTest from './components/AuthTest';
import AuthOptions from './components/AuthOptions';
import AuthCallback from './pages/auth/AuthCallback';
import OAuthTest from './pages/auth/OAuthTest';
import CurrentPage from './pages/app/CurrentPage';
import ProfilePage from './pages/app/ProfilePage';
import RestaurantDetail from './pages/RestaurantDetail';
import Wishlist from './pages/Wishlist';
import Discover from './pages/Discover';
import Login from './pages/Login';
import StaticMapTest from './components/StaticMapTest';

const AppContent = () => {
  const location = useLocation();
  const [currentPage, setCurrentPage] = useState('current');
  const [selectedDay, setSelectedDay] = useState(null); // eslint-disable-line no-unused-vars
  const [rsvpStatus, setRsvpStatus] = useState(null);

  const getPageName = (pathname) => {
    switch (pathname) {
      case '/current': return 'Current';
      case '/discover': return 'Discover';
      case '/wishlist': return 'Wishlist';
      case '/profile': return 'Profile';
      case '/login': return 'Login';
      case '/auth': return 'Sign In';
      case '/auth/callback': return 'Signing In...';
      case '/oauth-test': return 'OAuth Test';
      case '/test-auth': return 'Auth Test';
      case '/map-test': return 'Map Test';
      default: return 'Current';
    }
  };

  const getPageId = (pathname) => {
    switch (pathname) {
      case '/current': return 'current';
      case '/discover': return 'discover';
      case '/wishlist': return 'wishlist';
      case '/profile': return 'profile';
      case '/login': return 'login';
      case '/auth': return 'auth';
      case '/auth/callback': return 'auth-callback';
      case '/oauth-test': return 'oauth-test';
      case '/map-test': return 'map-test';
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
        <Route path="/auth" element={<AuthOptions />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
            <Route path="/oauth-test" element={<OAuthTest />} />
            <Route path="/test-auth" element={<AuthTest />} />
            <Route path="/map-test" element={<StaticMapTest />} />
        
        {/* Public routes with conditional content */}
        <Route path="/current" element={
          <CurrentPage 
            onDayChange={handleDayChange}
            onStatusChange={handleStatusChange}
          />
        } />
        <Route path="/discover" element={<Discover />} />
        <Route path="/wishlist" element={
          <ProtectedRoute>
            <Wishlist />
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
        <Route path="/restaurant/:restaurantId" element={<RestaurantDetail />} />
        
        {/* Default redirects */}
        <Route path="/" element={<Navigate to="/current" replace />} />
        <Route path="*" element={<Navigate to="/current" replace />} />
      </Routes>
      
      {/* Only show bottom nav on protected routes */}
      {location.pathname !== '/login' && 
       location.pathname !== '/auth' && 
       location.pathname !== '/auth/callback' &&
           location.pathname !== '/oauth-test' &&
           location.pathname !== '/test-auth' &&
           location.pathname !== '/map-test' && 
           !location.pathname.startsWith('/restaurant/') && (
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