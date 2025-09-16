import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import supabase from '../../services/supabaseClient';
import './AuthCallback.css';

const AuthCallback = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // Get the session from the URL hash
        const { data, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('Auth callback error:', error);
          setError(error.message);
          setLoading(false);
          return;
        }

        if (data.session) {
          console.log('Auth callback successful:', data.session.user);
          // Redirect to the main app or dashboard
          navigate('/current');
        } else {
          console.log('No session found in callback');
          setError('Authentication failed. Please try again.');
          setLoading(false);
        }
      } catch (err) {
        console.error('Auth callback exception:', err);
        setError('An unexpected error occurred. Please try again.');
        setLoading(false);
      }
    };

    handleAuthCallback();
  }, [navigate]);

  if (loading) {
    return (
      <div className="auth-callback">
        <div className="callback-container">
          <div className="spinner"></div>
          <h2>Completing sign in...</h2>
          <p>Please wait while we finish setting up your account.</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="auth-callback">
        <div className="callback-container error">
          <div className="error-icon">⚠️</div>
          <h2>Sign in failed</h2>
          <p>{error}</p>
          <button 
            onClick={() => navigate('/auth')}
            className="retry-button"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-callback">
      <div className="callback-container success">
        <div className="success-icon">✅</div>
        <h2>Sign in successful!</h2>
        <p>Redirecting you to the app...</p>
      </div>
    </div>
  );
};

export default AuthCallback;
