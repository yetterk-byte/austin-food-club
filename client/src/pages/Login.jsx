import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import AuthOptions from '../components/AuthOptions';

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

  // Redirect to current page if already logged in
  if (user) {
    return <Navigate to="/current" replace />;
  }

  const handleAuthSuccess = (data) => {
    console.log('Authentication initiated:', data);
  };

  const handleAuthError = (error) => {
    console.error('Authentication error:', error);
  };

  return (
    <AuthOptions 
      onSuccess={handleAuthSuccess}
      onError={handleAuthError}
      mode="signin"
    />
  );
};

export default Login;
