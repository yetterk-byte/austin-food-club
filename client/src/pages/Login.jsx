import React, { useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import PhoneAuth from '../components/PhoneAuth';

const Login = () => {
  const { user, loading } = useAuth();

  // Show loading spinner while checking authentication
  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading...</p>
      </div>
    );
  }

  // Redirect to home if already logged in
  if (user) {
    return <Navigate to="/current" replace />;
  }

  return (
    <div className="login-page">
      <PhoneAuth />
      
      {/* Future: Add email auth option */}
      <div className="auth-options" style={{ 
        textAlign: 'center', 
        marginTop: '20px',
        color: '#b0b0b0',
        fontSize: '14px'
      }}>
        <p>Phone authentication is currently available</p>
        <p style={{ fontSize: '12px', marginTop: '8px' }}>
          Email authentication coming soon
        </p>
      </div>
    </div>
  );
};

export default Login;
