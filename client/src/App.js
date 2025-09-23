import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { AdminProvider } from './contexts/AdminContext';
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
import Login from './pages/Login';
import StaticMapTest from './components/StaticMapTest';

// Admin Components - Removed (using HTML admin dashboard instead)
const CatchAllRoute = () => {
  const location = useLocation();
  
  // Don't redirect admin-dashboard.html - let it be served as static file
  if (location.pathname === '/admin-dashboard.html') {
    return <div>Loading admin dashboard...</div>;
  }
  
  // Redirect everything else to /current
  return <Navigate to="/current" replace />;
};

const AdminStaticPage = () => {
  // For now, just show a message with direct links
  return (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      height: '100vh',
      background: '#0a0a0a',
      color: 'white',
      fontFamily: 'Arial, sans-serif',
      padding: '2rem'
    }}>
      <div style={{ textAlign: 'center', maxWidth: '600px' }}>
        <h1 style={{ color: '#20b2aa', marginBottom: '1rem' }}>Austin Food Club</h1>
        <h2 style={{ marginBottom: '2rem' }}>Admin Dashboard</h2>
        <p style={{ marginBottom: '2rem', opacity: 0.8 }}>
          React Router is intercepting the static HTML files. Please use these direct links:
        </p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <button 
            onClick={() => window.open('http://localhost:3000/admin-dashboard.html', '_blank')}
            style={{ 
              color: '#20b2aa', 
              textDecoration: 'none', 
              padding: '1rem', 
              border: '1px solid #20b2aa', 
              borderRadius: '8px',
              transition: 'all 0.3s ease',
              background: 'transparent',
              cursor: 'pointer',
              fontSize: '1rem',
              width: '100%'
            }}
            onMouseOver={(e) => {
              e.target.style.background = '#20b2aa';
              e.target.style.color = '#0a0a0a';
            }}
            onMouseOut={(e) => {
              e.target.style.background = 'transparent';
              e.target.style.color = '#20b2aa';
            }}
          >
            🍽️ Admin Dashboard (Full Features) - Opens in New Tab
          </button>
          <button 
            onClick={() => window.open('http://localhost:3000/admin-redirect.html', '_blank')}
            style={{ 
              color: '#20b2aa', 
              textDecoration: 'none', 
              padding: '1rem', 
              border: '1px solid #20b2aa', 
              borderRadius: '8px',
              transition: 'all 0.3s ease',
              background: 'transparent',
              cursor: 'pointer',
              fontSize: '1rem',
              width: '100%'
            }}
            onMouseOver={(e) => {
              e.target.style.background = '#20b2aa';
              e.target.style.color = '#0a0a0a';
            }}
            onMouseOut={(e) => {
              e.target.style.background = 'transparent';
              e.target.style.color = '#20b2aa';
            }}
          >
            🔗 Admin Redirect Page - Opens in New Tab
          </button>
        </div>
        <p style={{ marginTop: '2rem', fontSize: '0.9rem', opacity: 0.6 }}>
          Login: admin@austinfoodclub.com / admin123
        </p>
      </div>
    </div>
  );
};

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
        
        {/* Admin redirect to HTML admin dashboard */}
        <Route path="/admin" element={<AdminStaticPage />} />
        
        {/* Admin HTML files - serve as static content */}
        <Route path="/admin.html" element={<AdminStaticPage />} />
        <Route path="/admin-redirect.html" element={<AdminStaticPage />} />
        
        {/* Default redirects */}
        <Route path="/" element={<Navigate to="/current" replace />} />
        <Route path="*" element={<CatchAllRoute />} />
      </Routes>
      
      {/* Only show bottom nav on protected routes (exclude admin pages) */}
      {location.pathname !== '/login' && 
       location.pathname !== '/auth' && 
       location.pathname !== '/auth/callback' &&
           location.pathname !== '/oauth-test' &&
           location.pathname !== '/test-auth' &&
           location.pathname !== '/map-test' && 
           !location.pathname.startsWith('/restaurant/') &&
           !location.pathname.startsWith('/admin') && (
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
        <AdminProvider>
          <AppContent />
        </AdminProvider>
      </Router>
    </AuthProvider>
  );
}

export default App;