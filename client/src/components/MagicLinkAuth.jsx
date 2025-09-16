import React, { useState } from 'react';
import supabase from '../services/supabaseClient';
import './MagicLinkAuth.css';

const MagicLinkAuth = ({ onSuccess, onError }) => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const handleMagicLink = async (e) => {
    e.preventDefault();
    
    if (!email) {
      setError('Please enter your email address');
      return;
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setError('Please enter a valid email address');
      return;
    }

    setLoading(true);
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
      setLoading(false);
    }
  };

  const handleEmailChange = (e) => {
    setEmail(e.target.value);
    // Clear error when user starts typing
    if (error) setError('');
  };

  return (
    <div className="magic-link-auth">
      <div className="magic-link-container">
        <h2>Sign in with Magic Link</h2>
        <p className="magic-link-description">
          Enter your email address and we'll send you a secure login link. No password required!
        </p>
        
        <form onSubmit={handleMagicLink} className="magic-link-form">
          <div className="form-group">
            <label htmlFor="email">Email Address</label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={handleEmailChange}
              placeholder="Enter your email address"
              disabled={loading}
              className={error ? 'error' : ''}
              required
            />
          </div>

          {error && (
            <div className="error-message">
              {error}
            </div>
          )}

          {message && (
            <div className="success-message">
              {message}
            </div>
          )}

          <button 
            type="submit" 
            disabled={loading || !email}
            className="magic-link-button"
          >
            {loading ? 'Sending...' : 'Send Magic Link'}
          </button>
        </form>

        <div className="magic-link-info">
          <h4>How it works:</h4>
          <ol>
            <li>Enter your email address above</li>
            <li>Check your email for a secure login link</li>
            <li>Click the link to sign in automatically</li>
            <li>You'll be redirected back to the app, signed in!</li>
          </ol>
        </div>

        <div className="magic-link-tips">
          <h4>Tips:</h4>
          <ul>
            <li>Check your spam folder if you don't see the email</li>
            <li>The link expires after 1 hour for security</li>
            <li>You can request a new link anytime</li>
            <li>No password needed - just click and go!</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default MagicLinkAuth;
