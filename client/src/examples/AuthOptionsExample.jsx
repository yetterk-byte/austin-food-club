import React, { useState, useEffect } from 'react';
import AuthOptions from '../components/AuthOptions';
import supabase from '../services/supabaseClient';

const AuthOptionsExample = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

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

  const handleAuthSuccess = (data) => {
    console.log('Authentication initiated:', data);
    // You can add additional logic here, like analytics tracking
  };

  const handleAuthError = (error) => {
    console.error('Authentication error:', error);
    // You can add additional error handling here
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
          <div className="spinner" style={{
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
          <h2>Welcome to Austin Food Club! 🎉</h2>
          
          <div style={{
            background: '#f8f9ff',
            padding: '20px',
            borderRadius: '12px',
            margin: '20px 0',
            textAlign: 'left'
          }}>
            <h3>Account Details</h3>
            <p><strong>Email:</strong> {user.email}</p>
            <p><strong>User ID:</strong> {user.id}</p>
            <p><strong>Provider:</strong> {user.app_metadata?.provider || 'Email'}</p>
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
            <h3>🎯 Next Steps</h3>
            <ul style={{ textAlign: 'left', margin: '10px 0' }}>
              <li>Explore current restaurant picks</li>
              <li>RSVP for upcoming events</li>
              <li>Add restaurants to your wishlist</li>
              <li>Connect with friends</li>
            </ul>
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
    <AuthOptions 
      onSuccess={handleAuthSuccess}
      onError={handleAuthError}
      mode="signin"
    />
  );
};

export default AuthOptionsExample;
