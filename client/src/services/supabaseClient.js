import { createClient } from '@supabase/supabase-js';

// Get Supabase URL and key from environment variables
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

// Create Supabase client or mock client
let supabase;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Missing Supabase environment variables. Using mock Supabase client for development');
  
  // Create a working mock client for development
  supabase = {
    auth: {
      signInWithOtp: async ({ phone }) => {
        console.log(`Mock: Sending OTP to ${phone}`);
        return { 
          data: { user: null, session: null }, 
          error: null 
        };
      },
      verifyOtp: async ({ phone, token }) => {
        console.log(`Mock: Verifying OTP ${token} for ${phone}`);
        // Create a mock user and session
        const mockUser = {
          id: 'mock-user-' + Date.now(),
          phone: phone,
          email: null,
          user_metadata: {
            phone: phone,
            name: phone.replace('+1', '').replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3')
          }
        };
        const mockSession = {
          access_token: 'mock-token-' + Date.now(),
          refresh_token: 'mock-refresh-' + Date.now(),
          user: mockUser
        };
        return { 
          data: { user: mockUser, session: mockSession }, 
          error: null 
        };
      },
      signOut: async () => {
        console.log('Mock: Signing out user');
        return { error: null };
      },
      getSession: async () => {
        // Return stored session if available
        const storedSession = localStorage.getItem('mock-session');
        if (storedSession) {
          return { data: { session: JSON.parse(storedSession) }, error: null };
        }
        return { data: { session: null }, error: null };
      },
      getUser: async () => {
        const storedSession = localStorage.getItem('mock-session');
        if (storedSession) {
          const session = JSON.parse(storedSession);
          return { data: { user: session.user }, error: null };
        }
        return { data: { user: null }, error: null };
      },
      onAuthStateChange: (callback) => {
        // Mock auth state change listener
        const storedSession = localStorage.getItem('mock-session');
        if (storedSession) {
          const session = JSON.parse(storedSession);
          callback('SIGNED_IN', session);
        } else {
          callback('SIGNED_OUT', null);
        }
        return { data: { subscription: { unsubscribe: () => {} } } };
      }
    }
  };
} else {
  // Create Supabase client
  supabase = createClient(supabaseUrl, supabaseAnonKey);
}

export default supabase;
