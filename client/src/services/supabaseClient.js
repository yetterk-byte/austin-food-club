import { createClient } from '@supabase/supabase-js';

// Get Supabase URL and key from environment variables
const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;

// Create Supabase client or mock client
let supabase;

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Missing Supabase environment variables. Please check REACT_APP_SUPABASE_URL and REACT_APP_SUPABASE_ANON_KEY');
  console.warn('Using mock Supabase client for development');
  
  // Create a mock client for development
  supabase = {
    auth: {
      signInWithOtp: async () => ({ data: null, error: { message: 'Supabase not configured' } }),
      verifyOtp: async () => ({ data: null, error: { message: 'Supabase not configured' } }),
      signOut: async () => ({ error: { message: 'Supabase not configured' } }),
      getUser: async () => ({ data: { user: null }, error: { message: 'Supabase not configured' } }),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } })
    }
  };
} else {
  // Create Supabase client
  supabase = createClient(supabaseUrl, supabaseAnonKey);
}

export default supabase;
