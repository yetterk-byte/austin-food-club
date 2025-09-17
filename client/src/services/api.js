const API_BASE_URL = 'http://localhost:3001/api';

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL;
  }

  // Get auth token from Supabase
  async getAuthToken() {
    try {
      // Check for mock session first
      const storedSession = localStorage.getItem('mock-session');
      if (storedSession) {
        const session = JSON.parse(storedSession);
        return session.access_token || null;
      }

      // Import Supabase client dynamically to avoid circular imports
      const { createClient } = await import('@supabase/supabase-js');
      
      const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
      const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;
      
      if (!supabaseUrl || !supabaseAnonKey) {
        console.warn('Supabase not configured, using mock auth');
        return 'mock-token-consistent';
      }
      
      const supabase = createClient(supabaseUrl, supabaseAnonKey);
      const { data: { session } } = await supabase.auth.getSession();
      
      return session?.access_token || null;
    } catch (error) {
      console.error('Error getting auth token:', error);
      return null;
    }
  }

  // Get headers with auth token
  async getHeaders() {
    const token = await this.getAuthToken();
    const headers = {
      'Content-Type': 'application/json',
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    return headers;
  }

  // Generic request method
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const headers = await this.getHeaders();
    
    const config = {
      ...options,
      headers: {
        ...headers,
        ...options.headers,
      },
    };

    try {
      const response = await fetch(url, config);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        
        // Handle 401 Unauthorized
        if (response.status === 401) {
          // Clear any stored auth state
          try {
            const { createClient } = await import('@supabase/supabase-js');
            const supabaseUrl = process.env.REACT_APP_SUPABASE_URL;
            const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY;
            
            if (supabaseUrl && supabaseAnonKey) {
              const supabase = createClient(supabaseUrl, supabaseAnonKey);
              await supabase.auth.signOut();
            }
          } catch (authError) {
            console.error('Error clearing auth state:', authError);
          }
          
          throw new Error('Authentication required. Please log in again.');
        }
        
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error(`API request failed for ${endpoint}:`, error);
      throw error;
    }
  }

  // Restaurant endpoints
  async getCurrentRestaurant() {
    return this.request('/restaurants/current');
  }

  async getFeaturedRestaurant() {
    return this.request('/restaurants/featured');
  }

  async getRestaurant(restaurantId) {
    return this.request(`/restaurants/${restaurantId}`);
  }

  async getRestaurants() {
    return this.request('/restaurants');
  }

  // Yelp-specific endpoints
  async getYelpRestaurant(yelpId) {
    return this.request(`/restaurants/yelp/${yelpId}`);
  }

  async getYelpReviews(yelpId) {
    return this.request(`/restaurants/yelp/${yelpId}/reviews`);
  }

  // RSVP endpoints (require authentication)
  async createRSVP(rsvpData) {
    return this.request('/rsvp', {
      method: 'POST',
      body: JSON.stringify(rsvpData),
    });
  }

  async getRSVPs() {
    return this.request('/rsvp');
  }

  async updateRSVP(rsvpId, rsvpData) {
    return this.request(`/rsvp/${rsvpId}`, {
      method: 'PUT',
      body: JSON.stringify(rsvpData),
    });
  }

  async deleteRSVP(rsvpId) {
    return this.request(`/rsvp/${rsvpId}`, {
      method: 'DELETE',
    });
  }

  async getRSVPCounts(restaurantId) {
    return this.request(`/rsvp/counts?restaurantId=${restaurantId}`);
  }

  // Wishlist endpoints (require authentication)
  async getWishlist() {
    return this.request('/wishlist');
  }

  async addToWishlist(restaurantId) {
    return this.request('/wishlist', {
      method: 'POST',
      body: JSON.stringify({ restaurantId }),
    });
  }

  async removeFromWishlist(restaurantId) {
    return this.request(`/wishlist/${restaurantId}`, {
      method: 'DELETE',
    });
  }

  // User endpoints (require authentication)
  async getCurrentUser() {
    return this.request('/user/profile');
  }

  async updateUserProfile(userData) {
    return this.request('/user/profile', {
      method: 'PUT',
      body: JSON.stringify(userData),
    });
  }

  // Test endpoint
  async testConnection() {
    return this.request('/test');
  }

  // Get user's verified visits
  async getVerifiedVisits() {
    return this.request('/verified-visits');
  }

  // Submit verification data
  async submitVerification(verificationData) {
    return this.request('/verified-visits', {
      method: 'POST',
      body: JSON.stringify(verificationData),
    });
  }
}

// Create and export a singleton instance
export const apiService = new ApiService();

// Export the class for testing
export default ApiService;