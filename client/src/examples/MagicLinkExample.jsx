import React, { useState, useEffect } from 'react';
import MagicLinkAuth from '../components/MagicLinkAuth';
import supabase from '../services/supabaseClient';

const MagicLinkExample = () => {
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

  const handleMagicLinkSuccess = (data) => {
    console.log('Magic link sent successfully:', data);
    // You can add additional logic here, like analytics tracking
  };

  const handleMagicLinkError = (error) => {
    console.error('Magic link error:', error);
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
        fontSize: '18px'
      }}>
        Loading...
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
          borderRadius: '12px',
          maxWidth: '500px',
          margin: '0 auto',
          boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)'
        }}>
          <h2>Welcome! 🎉</h2>
          <p><strong>Email:</strong> {user.email}</p>
          <p><strong>User ID:</strong> {user.id}</p>
          <p><strong>Signed in via:</strong> Magic Link</p>
          <p><strong>Last sign in:</strong> {new Date(user.last_sign_in_at).toLocaleString()}</p>
          
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
              marginTop: '20px'
            }}
          >
            Sign Out
          </button>
        </div>
      </div>
    );
  }

  return (
    <MagicLinkAuth 
      onSuccess={handleMagicLinkSuccess}
      onError={handleMagicLinkError}
    />
  );
};

export default MagicLinkExample;
