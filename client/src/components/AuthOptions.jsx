import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import supabase from '../services/supabaseClient';
import './AuthOptions.css';

const AuthOptions = ({ onSuccess, onError, mode = 'signin' }) => {
  const navigate = useNavigate();
  const { checkStoredSession } = useAuth();
  const [loading, setLoading] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  // Primary: Magic Link Authentication
  const handleMagicLink = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const email = formData.get('email');

    if (!email) {
      setError('Please enter your email address');
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setError('Please enter a valid email address');
      return;
    }

    setLoading('magic-link');
    setError('');
    setMessage('');

    try {
      const { data, error } = await supabase.auth.signInWithOtp({
        email: email,
        options: {
          shouldCreateUser: true
        }
      });

      if (error) {
        console.error('Magic link error:', error);
        setError(error.message);
        if (onError) onError(error);
      } else {
        setMessage('Check your email for the login link!');
        console.log('Magic link sent successfully:', data);
        if (onSuccess) onSuccess(data);
      }
    } catch (err) {
      console.error('Magic link exception:', err);
      setError('An unexpected error occurred. Please try again.');
      if (onError) onError(err);
    } finally {
      setLoading('');
    }
  };

  // Secondary: Google Sign In
  const handleGoogleSignIn = async () => {
    setLoading('google');
    setError('');
    setMessage('');

    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/auth/callback`
        }
      });

      if (error) {
        console.error('Google sign-in error:', error);
        setError(error.message);
        if (onError) onError(error);
      } else {
        console.log('Google sign-in initiated:', data);
        // OAuth redirects, so we don't need to handle success here
      }
    } catch (err) {
      console.error('Google sign-in exception:', err);
      setError('An unexpected error occurred. Please try again.');
      if (onError) onError(err);
    } finally {
      setLoading('');
    }
  };

  // Secondary: Apple Sign In
  const handleAppleSignIn = async () => {
    setLoading('apple');
    setError('');
    setMessage('');

    try {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'apple',
        options: {
          redirectTo: `${window.location.origin}/auth/callback`
        }
      });

      if (error) {
        console.error('Apple sign-in error:', error);
        setError(error.message);
        if (onError) onError(error);
      } else {
        console.log('Apple sign-in initiated:', data);
        // OAuth redirects, so we don't need to handle success here
      }
    } catch (err) {
      console.error('Apple sign-in exception:', err);
      setError('An unexpected error occurred. Please try again.');
      if (onError) onError(err);
    } finally {
      setLoading('');
    }
  };

  // Future: SMS Authentication (placeholder for when Twilio is approved)
  const handleSMSSignIn = () => {
    setError('SMS authentication coming soon! Please use email or social sign-in for now.');
  };

  // Development: Test Login (for testing without real auth)
  const handleTestLogin = async () => {
    console.log('Test login button clicked');
    setLoading('test');
    setError('');
    setMessage('');

    try {
      // Create a mock session for testing
      const mockUser = {
        id: 'test-user-' + Date.now(),
        email: 'test@example.com',
        phone: '+1234567890',
        name: 'Test User', // Direct name property for components
        provider: 'mock', // Provider type
        user_metadata: {
          name: 'Test User'
        }
      };
      
      const mockSession = {
        access_token: 'mock-token-consistent',
        refresh_token: 'mock-refresh-consistent',
        user: mockUser
      };
      
      console.log('Created mock session:', mockSession);
      
      // Store session in localStorage
      localStorage.setItem('mock-session', JSON.stringify(mockSession));
      console.log('Stored session in localStorage');
      
      setMessage('Test login successful! Redirecting to current page...');
      
      // Check the stored session to trigger auth state change
      const sessionFound = checkStoredSession();
      console.log('Session found:', sessionFound);
      
      if (sessionFound) {
        // Redirect to current page after successful login
        setTimeout(() => {
          console.log('Navigating to /current');
          navigate('/current');
        }, 1000); // Give a moment for the success message to show
        
        if (onSuccess) onSuccess({ user: mockUser, session: mockSession });
      } else {
        console.error('Failed to find session after storing');
        setError('Failed to authenticate. Please try again.');
      }
    } catch (err) {
      console.error('Test login error:', err);
      setError('Test login failed. Please try again.');
      if (onError) onError(err);
    } finally {
      setLoading('');
    }
  };

  const clearMessages = () => {
    setError('');
    setMessage('');
  };

  return (
    <div className="auth-options">
      <div className="auth-container">
        <div className="auth-header">
          <h2>{mode === 'signin' ? 'Welcome Back!' : 'Join Austin Food Club'}</h2>
          <p className="auth-subtitle">
            {mode === 'signin' 
              ? 'Sign in to continue your food journey' 
              : 'Create your account to start exploring amazing restaurants'
            }
          </p>
        </div>

        {/* Primary: Magic Link */}
        <div className="auth-section primary">
          <div className="section-header">
            <h3>📧 Email Magic Link</h3>
            <span className="badge recommended">Recommended</span>
          </div>
          <p className="section-description">
            Enter your email and we'll send you a secure login link. No password needed!
          </p>
          
          <form onSubmit={handleMagicLink} className="magic-link-form">
            <div className="form-group">
              <input
                type="email"
                name="email"
                placeholder="Enter your email address"
                disabled={loading === 'magic-link'}
                onChange={clearMessages}
                className={error ? 'error' : ''}
                required
              />
            </div>
            <button 
              type="submit" 
              disabled={loading === 'magic-link'}
              className="btn-primary"
            >
              {loading === 'magic-link' ? 'Sending...' : 'Send Magic Link'}
            </button>
          </form>
        </div>

        {/* Divider */}
        <div className="divider">
          <span>or continue with</span>
        </div>

        {/* Secondary: Social Sign In */}
        <div className="auth-section secondary">
          <div className="section-header">
            <h3>🔐 Social Sign In</h3>
            <span className="badge familiar">Familiar</span>
          </div>
          <p className="section-description">
            Sign in with your existing Google or Apple account
          </p>
          
          <div className="social-buttons">
            <button 
              onClick={handleGoogleSignIn}
              disabled={loading === 'google'}
              className="btn-social google"
            >
              {loading === 'google' ? (
                <div className="spinner"></div>
              ) : (
                <>
                  <svg className="social-icon" viewBox="0 0 24 24">
                    <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                    <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                    <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                    <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                  </svg>
                  Continue with Google
                </>
              )}
            </button>

            <button 
              onClick={handleAppleSignIn}
              disabled={loading === 'apple'}
              className="btn-social apple"
            >
              {loading === 'apple' ? (
                <div className="spinner"></div>
              ) : (
                <>
                  <svg className="social-icon" viewBox="0 0 24 24">
                    <path fill="#000000" d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  Continue with Apple
                </>
              )}
            </button>
          </div>
        </div>

        {/* Development: Test Login */}
        <div className="auth-section test">
          <div className="section-header">
            <h3>🧪 Test Login</h3>
            <span className="badge development">Development</span>
          </div>
          <p className="section-description">
            Quick login for testing without real authentication
          </p>
          
          <button 
            onClick={handleTestLogin}
            disabled={loading === 'test'}
            className="btn-secondary"
          >
            {loading === 'test' ? (
              <div className="spinner"></div>
            ) : (
              <>
                <svg className="social-icon" viewBox="0 0 24 24">
                  <path fill="#6c757d" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                </svg>
                Test Login
              </>
            )}
          </button>
        </div>

        {/* Future: SMS Authentication */}
        <div className="auth-section future">
          <div className="section-header">
            <h3>📱 SMS Authentication</h3>
            <span className="badge coming-soon">Coming Soon</span>
          </div>
          <p className="section-description">
            Sign in with your phone number (currently in development)
          </p>
          
          <button 
            onClick={handleSMSSignIn}
            className="btn-secondary disabled"
            disabled
          >
            <svg className="social-icon" viewBox="0 0 24 24">
              <path fill="#6c757d" d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/>
            </svg>
            SMS Sign In (Coming Soon)
          </button>
        </div>

        {/* Messages */}
        {error && (
          <div className="message error">
            {error}
          </div>
        )}

        {message && (
          <div className="message success">
            {message}
          </div>
        )}

        {/* Footer */}
        <div className="auth-footer">
          <p>
            By continuing, you agree to our{' '}
            <a href="/terms" target="_blank" rel="noopener noreferrer">Terms of Service</a>
            {' '}and{' '}
            <a href="/privacy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>
          </p>
        </div>
      </div>
    </div>
  );
};

export default AuthOptions;
