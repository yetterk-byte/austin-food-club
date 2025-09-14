import React, { createContext, useContext, useState, useEffect } from 'react';
import supabase from '../services/supabaseClient';

// Create AuthContext
const AuthContext = createContext();

// AuthProvider component
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Initialize auth state and listen for changes
  useEffect(() => {
    // Get initial session
    const getInitialSession = async () => {
      try {
        const { data: { user }, error } = await supabase.auth.getUser();
        if (error) {
          console.error('Error getting initial user:', error);
          setError(error.message);
        } else {
          setUser(user);
        }
      } catch (err) {
        console.error('Error in getInitialSession:', err);
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    getInitialSession();

    // Listen for auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('Auth state changed:', event, session?.user?.id);
        setUser(session?.user || null);
        setLoading(false);
        setError(null);
      }
    );

    // Cleanup subscription on unmount
    return () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    };
  }, []);

  // Sign in with phone number (sends OTP)
  const signInWithPhone = async (phone) => {
    try {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase.auth.signInWithOtp({
        phone,
        options: {
          channel: 'sms'
        }
      });

      if (error) {
        console.error('Phone sign-in error:', error);
        setError(error.message);
        return { success: false, error: error.message };
      }

      console.log('OTP sent to phone:', phone);
      return { success: true, data };
    } catch (err) {
      console.error('Phone sign-in exception:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Verify OTP code
  const verifyOTP = async (phone, token) => {
    try {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase.auth.verifyOtp({
        phone,
        token,
        type: 'sms'
      });

      if (error) {
        console.error('OTP verification error:', error);
        setError(error.message);
        return { success: false, error: error.message };
      }

      console.log('Phone verification successful:', data.user?.id);
      setUser(data.user);
      return { success: true, data };
    } catch (err) {
      console.error('OTP verification exception:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Sign out
  const signOut = async () => {
    try {
      setLoading(true);
      setError(null);

      const { error } = await supabase.auth.signOut();

      if (error) {
        console.error('Sign out error:', error);
        setError(error.message);
        return { success: false, error: error.message };
      }

      console.log('User signed out successfully');
      setUser(null);
      return { success: true };
    } catch (err) {
      console.error('Sign out exception:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Get current user
  const getCurrentUser = async () => {
    try {
      setError(null);

      const { data: { user }, error } = await supabase.auth.getUser();

      if (error) {
        console.error('Get current user error:', error);
        setError(error.message);
        return { success: false, error: error.message, user: null };
      }

      setUser(user);
      return { success: true, user };
    } catch (err) {
      console.error('Get current user exception:', err);
      setError(err.message);
      return { success: false, error: err.message, user: null };
    }
  };

  // Sign in with email (backup method)
  const signInWithEmail = async (email, password) => {
    try {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (error) {
        console.error('Email sign-in error:', error);
        setError(error.message);
        return { success: false, error: error.message };
      }

      console.log('Email sign-in successful:', data.user?.id);
      setUser(data.user);
      return { success: true, data };
    } catch (err) {
      console.error('Email sign-in exception:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Sign up with email
  const signUpWithEmail = async (email, password, metadata = {}) => {
    try {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: metadata
        }
      });

      if (error) {
        console.error('Email sign-up error:', error);
        setError(error.message);
        return { success: false, error: error.message };
      }

      console.log('Email sign-up successful:', data.user?.id);
      setUser(data.user);
      return { success: true, data };
    } catch (err) {
      console.error('Email sign-up exception:', err);
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Clear error
  const clearError = () => {
    setError(null);
  };

  // Context value
  const value = {
    user,
    loading,
    error,
    signInWithPhone,
    verifyOTP,
    signOut,
    getCurrentUser,
    signInWithEmail,
    signUpWithEmail,
    clearError,
    isAuthenticated: !!user
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

// useAuth hook
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Export AuthContext for advanced usage
export { AuthContext };