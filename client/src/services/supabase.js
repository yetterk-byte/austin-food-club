import { createClient } from '@supabase/supabase-js';

// Get Supabase URL and key from environment variables
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

// Validate environment variables
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Please check REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY');
}

// Create Supabase client
export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Authentication functions
export const auth = {
  /**
   * Sign in with phone number using OTP
   * @param {string} phone - Phone number in international format (e.g., +1234567890)
   * @returns {Promise<{data: any, error: any}>} - Supabase response
   */
  async signInWithPhone(phone) {
    try {
      const { data, error } = await supabase.auth.signInWithOtp({
        phone,
        options: {
          channel: 'sms'
        }
      });
      
      if (error) {
        console.error('Phone sign-in error:', error);
        return { data: null, error };
      }
      
      console.log('OTP sent to phone:', phone);
      return { data, error: null };
    } catch (err) {
      console.error('Phone sign-in exception:', err);
      return { data: null, error: err };
    }
  },

  /**
   * Verify OTP code for phone authentication
   * @param {string} phone - Phone number used for sign-in
   * @param {string} token - OTP code received via SMS
   * @returns {Promise<{data: any, error: any}>} - Supabase response
   */
  async verifyOTP(phone, token) {
    try {
      const { data, error } = await supabase.auth.verifyOtp({
        phone,
        token,
        type: 'sms'
      });
      
      if (error) {
        console.error('OTP verification error:', error);
        return { data: null, error };
      }
      
      console.log('Phone verification successful:', data.user?.id);
      return { data, error: null };
    } catch (err) {
      console.error('OTP verification exception:', err);
      return { data: null, error: err };
    }
  },

  /**
   * Sign out the current user
   * @returns {Promise<{error: any}>} - Supabase response
   */
  async signOut() {
    try {
      const { error } = await supabase.auth.signOut();
      
      if (error) {
        console.error('Sign out error:', error);
        return { error };
      }
      
      console.log('User signed out successfully');
      return { error: null };
    } catch (err) {
      console.error('Sign out exception:', err);
      return { error: err };
    }
  },

  /**
   * Get the current authenticated user
   * @returns {Promise<{data: any, error: any}>} - Supabase response
   */
  async getCurrentUser() {
    try {
      const { data: { user }, error } = await supabase.auth.getUser();
      
      if (error) {
        console.error('Get current user error:', error);
        return { data: null, error };
      }
      
      return { data: user, error: null };
    } catch (err) {
      console.error('Get current user exception:', err);
      return { data: null, error: err };
    }
  },

  /**
   * Sign in with email and password (backup method)
   * @param {string} email - User's email address
   * @param {string} password - User's password
   * @returns {Promise<{data: any, error: any}>} - Supabase response
   */
  async signInWithEmail(email, password) {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });
      
      if (error) {
        console.error('Email sign-in error:', error);
        return { data: null, error };
      }
      
      console.log('Email sign-in successful:', data.user?.id);
      return { data, error: null };
    } catch (err) {
      console.error('Email sign-in exception:', err);
      return { data: null, error: err };
    }
  },

  /**
   * Sign up with email and password (bonus function)
   * @param {string} email - User's email address
   * @param {string} password - User's password
   * @param {Object} metadata - Optional user metadata
   * @returns {Promise<{data: any, error: any}>} - Supabase response
   */
  async signUpWithEmail(email, password, metadata = {}) {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: metadata
        }
      });
      
      if (error) {
        console.error('Email sign-up error:', error);
        return { data: null, error };
      }
      
      console.log('Email sign-up successful:', data.user?.id);
      return { data, error: null };
    } catch (err) {
      console.error('Email sign-up exception:', err);
      return { data: null, error: err };
    }
  },

  /**
   * Listen to authentication state changes
   * @param {Function} callback - Callback function to handle auth state changes
   * @returns {Function} - Unsubscribe function
   */
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback);
  }
};

// Export default auth object
export default auth;
