import React, { useState, useEffect } from 'react';
import supabase from '../../services/supabaseClient';

const OAuthTest = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    // Check for existing session
    const getSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setUser(session?.user || null);
      setLoading(false);
    };

    getSession();

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('Auth state changed:', event, session?.user?.id);
        setUser(session?.user || null);
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  const handleGoogleSignIn = async () => {
    setLoading(true);
    setError('');

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
      } else {
        console.log('Google sign-in initiated:', data);
        // OAuth redirects, so we don't need to handle success here
      }
    } catch (err) {
      console.error('Google sign-in exception:', err);
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontSize: '18px',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        color: 'white'
      }}>
        <div style={{
          background: 'white',
          color: '#333',
          padding: '40px',
          borderRadius: '12px',
          textAlign: 'center'
        }}>
          <div style={{
            width: '32px',
            height: '32px',
            border: '3px solid #f3f3f3',
            borderTop: '3px solid #667eea',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite',
            margin: '0 auto 20px'
          }}></div>
          Loading...
        </div>
      </div>
    );
  }

  if (user) {
    return (
      <div style={{ 
        padding: '40px', 
        textAlign: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        minHeight: '100vh',
        color: 'white'
      }}>
        <div style={{
          background: 'white',
          color: '#333',
          padding: '40px',
          borderRadius: '16px',
          maxWidth: '600px',
          margin: '0 auto',
          boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)'
        }}>
          <h2>🎉 Google OAuth Success!</h2>
          
          <div style={{
            background: '#f8f9ff',
            padding: '20px',
            borderRadius: '12px',
            margin: '20px 0',
            textAlign: 'left'
          }}>
            <h3>User Details</h3>
            <p><strong>Email:</strong> {user.email}</p>
            <p><strong>Name:</strong> {user.user_metadata?.full_name || 'N/A'}</p>
            <p><strong>Provider:</strong> {user.app_metadata?.provider || 'Unknown'}</p>
            <p><strong>User ID:</strong> {user.id}</p>
            <p><strong>Last sign in:</strong> {new Date(user.last_sign_in_at).toLocaleString()}</p>
            <p><strong>Email confirmed:</strong> {user.email_confirmed_at ? 'Yes' : 'No'}</p>
          </div>

          <div style={{
            background: '#e8f5e8',
            padding: '20px',
            borderRadius: '12px',
            margin: '20px 0',
            border: '1px solid #c3e6c3'
          }}>
            <h3>✅ OAuth Configuration Working!</h3>
            <p>Your Google OAuth setup is working perfectly. Users can now sign in with their Google accounts.</p>
          </div>
          
          <button 
            onClick={handleSignOut}
            style={{
              background: '#e74c3c',
              color: 'white',
              border: 'none',
              padding: '12px 24px',
              borderRadius: '8px',
              fontSize: '16px',
              cursor: 'pointer',
              marginTop: '20px',
              fontWeight: '600'
            }}
          >
            Sign Out
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ 
      padding: '40px', 
      textAlign: 'center',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      minHeight: '100vh',
      color: 'white'
    }}>
      <div style={{
        background: 'white',
        color: '#333',
        padding: '40px',
        borderRadius: '16px',
        maxWidth: '500px',
        margin: '0 auto',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)'
      }}>
        <h2>Google OAuth Test</h2>
        <p style={{ color: '#666', marginBottom: '30px' }}>
          Test your Google OAuth configuration
        </p>

        {error && (
          <div style={{
            background: '#fdf2f2',
            color: '#e74c3c',
            padding: '12px 16px',
            borderRadius: '8px',
            marginBottom: '20px',
            borderLeft: '4px solid #e74c3c'
          }}>
            {error}
          </div>
        )}

        <button 
          onClick={handleGoogleSignIn}
          disabled={loading}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            padding: '12px 20px',
            border: '2px solid #e1e5e9',
            borderRadius: '8px',
            background: 'white',
            color: '#333',
            fontSize: '16px',
            fontWeight: '500',
            cursor: 'pointer',
            width: '100%',
            transition: 'all 0.3s ease'
          }}
          onMouseOver={(e) => {
            e.target.style.borderColor = '#4285f4';
            e.target.style.background = '#f8f9ff';
          }}
          onMouseOut={(e) => {
            e.target.style.borderColor = '#e1e5e9';
            e.target.style.background = 'white';
          }}
        >
          <svg width="20" height="20" viewBox="0 0 24 24">
            <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
            <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
            <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
            <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
          </svg>
          {loading ? 'Signing in...' : 'Continue with Google'}
        </button>

        <div style={{
          background: '#f8f9fa',
          padding: '20px',
          borderRadius: '8px',
          marginTop: '30px',
          textAlign: 'left'
        }}>
          <h4>Setup Instructions:</h4>
          <ol style={{ fontSize: '14px', lineHeight: '1.6' }}>
            <li>Go to Google Cloud Console</li>
            <li>Create OAuth 2.0 credentials</li>
            <li>Add redirect URI: <code>https://your-project-id.supabase.co/auth/v1/callback</code></li>
            <li>Add credentials to Supabase Dashboard</li>
            <li>Test the OAuth flow above</li>
          </ol>
        </div>
      </div>
    </div>
  );
};

export default OAuthTest;
