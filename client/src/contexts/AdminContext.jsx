import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

// Admin Context
const AdminContext = createContext();

// Action types
const ADMIN_ACTIONS = {
  SET_LOADING: 'SET_LOADING',
  SET_ERROR: 'SET_ERROR',
  SET_USER: 'SET_USER',
  SET_DASHBOARD_DATA: 'SET_DASHBOARD_DATA',
  SET_QUEUE: 'SET_QUEUE',
  SET_USERS: 'SET_USERS',
  LOGOUT: 'LOGOUT',
  CLEAR_ERROR: 'CLEAR_ERROR'
};

// Initial state
const initialState = {
  user: null,
  isAuthenticated: false,
  loading: false,
  error: null,
  dashboardData: null,
  queue: [],
  users: [],
  pagination: null
};

// Reducer
const adminReducer = (state, action) => {
  switch (action.type) {
    case ADMIN_ACTIONS.SET_LOADING:
      return { ...state, loading: action.payload };
    
    case ADMIN_ACTIONS.SET_ERROR:
      return { ...state, error: action.payload, loading: false };
    
    case ADMIN_ACTIONS.SET_USER:
      return { 
        ...state, 
        user: action.payload, 
        isAuthenticated: !!action.payload,
        loading: false 
      };
    
    case ADMIN_ACTIONS.SET_DASHBOARD_DATA:
      return { ...state, dashboardData: action.payload, loading: false };
    
    case ADMIN_ACTIONS.SET_QUEUE:
      return { ...state, queue: action.payload, loading: false };
    
    case ADMIN_ACTIONS.SET_USERS:
      return { 
        ...state, 
        users: action.payload.users, 
        pagination: action.payload.pagination,
        loading: false 
      };
    
    case ADMIN_ACTIONS.LOGOUT:
      return { ...initialState };
    
    case ADMIN_ACTIONS.CLEAR_ERROR:
      return { ...state, error: null };
    
    default:
      return state;
  }
};

// Admin Provider Component
export const AdminProvider = ({ children }) => {
  const [state, dispatch] = useReducer(adminReducer, initialState);
  const navigate = useNavigate();

  // API helper function
  const apiCall = async (endpoint, options = {}) => {
    const token = localStorage.getItem('adminToken');
    
    if (!token && endpoint !== '/api/admin/login') {
      navigate('/admin/login');
      throw new Error('No admin token');
    }

    const response = await fetch(endpoint, {
      ...options,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    if (response.status === 401 || response.status === 403) {
      dispatch({ type: ADMIN_ACTIONS.LOGOUT });
      localStorage.removeItem('adminToken');
      navigate('/admin/login');
      throw new Error('Authentication failed');
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || 'API request failed');
    }

    return response.json();
  };

  // Action creators
  const actions = {
    setLoading: (loading) => dispatch({ type: ADMIN_ACTIONS.SET_LOADING, payload: loading }),
    
    setError: (error) => dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error }),
    
    clearError: () => dispatch({ type: ADMIN_ACTIONS.CLEAR_ERROR }),

    // Authentication
    login: async (credentials) => {
      try {
        dispatch({ type: ADMIN_ACTIONS.SET_LOADING, payload: true });
        
        const data = await apiCall('/api/admin/login', {
          method: 'POST',
          body: JSON.stringify(credentials)
        });

        localStorage.setItem('adminToken', data.token);
        dispatch({ type: ADMIN_ACTIONS.SET_USER, payload: data.user });
        navigate('/admin');
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    logout: () => {
      localStorage.removeItem('adminToken');
      dispatch({ type: ADMIN_ACTIONS.LOGOUT });
      navigate('/admin/login');
    },

    // Dashboard
    fetchDashboardData: async () => {
      try {
        dispatch({ type: ADMIN_ACTIONS.SET_LOADING, payload: true });
        const data = await apiCall('/api/admin/dashboard');
        dispatch({ type: ADMIN_ACTIONS.SET_DASHBOARD_DATA, payload: data });
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    // Queue Management
    fetchQueue: async () => {
      try {
        dispatch({ type: ADMIN_ACTIONS.SET_LOADING, payload: true });
        const data = await apiCall('/api/admin/queue');
        dispatch({ type: ADMIN_ACTIONS.SET_QUEUE, payload: data.queue });
        return data.queue;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    reorderQueue: async (newOrder) => {
      try {
        await apiCall('/api/admin/queue/reorder', {
          method: 'POST',
          body: JSON.stringify({ newOrder })
        });
        // Refresh queue after reorder
        return actions.fetchQueue();
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    addToQueue: async (restaurantData) => {
      try {
        const data = await apiCall('/api/admin/queue', {
          method: 'POST',
          body: JSON.stringify(restaurantData)
        });
        // Refresh queue after adding
        actions.fetchQueue();
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    removeFromQueue: async (queueItemId) => {
      try {
        await apiCall(`/api/admin/queue/${queueItemId}`, {
          method: 'DELETE'
        });
        // Refresh queue after removal
        actions.fetchQueue();
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    // Restaurant Management
    searchYelp: async (query, cuisine) => {
      try {
        const data = await apiCall('/api/admin/restaurants/search-yelp', {
          method: 'POST',
          body: JSON.stringify({ query, cuisine })
        });
        return data.restaurants;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    addRestaurantFromYelp: async (yelpId, notes) => {
      try {
        const data = await apiCall('/api/admin/restaurants/add-from-yelp', {
          method: 'POST',
          body: JSON.stringify({ yelpId, notes, addToQueue: true })
        });
        // Refresh queue after adding
        actions.fetchQueue();
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    setCurrentRestaurant: async (restaurantId) => {
      try {
        const data = await apiCall('/api/admin/current-restaurant', {
          method: 'PUT',
          body: JSON.stringify({ restaurantId })
        });
        // Refresh dashboard data
        actions.fetchDashboardData();
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    // User Management
    fetchUsers: async (page = 1, search = '') => {
      try {
        dispatch({ type: ADMIN_ACTIONS.SET_LOADING, payload: true });
        const params = new URLSearchParams({ page, limit: 20 });
        if (search) params.append('search', search);
        
        const data = await apiCall(`/api/admin/users?${params}`);
        dispatch({ type: ADMIN_ACTIONS.SET_USERS, payload: data });
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    updateUser: async (userId, updates) => {
      try {
        const data = await apiCall(`/api/admin/users/${userId}`, {
          method: 'PUT',
          body: JSON.stringify(updates)
        });
        // Refresh users after update
        actions.fetchUsers();
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    },

    // Analytics
    fetchAnalytics: async (timeframe = '30d') => {
      try {
        const data = await apiCall(`/api/admin/analytics?timeframe=${timeframe}`);
        return data;
      } catch (error) {
        dispatch({ type: ADMIN_ACTIONS.SET_ERROR, payload: error.message });
        throw error;
      }
    }
  };

  // Check for existing admin session on mount
  useEffect(() => {
    const token = localStorage.getItem('adminToken');
    if (token) {
      // Verify token is still valid by fetching dashboard
      actions.fetchDashboardData().catch(() => {
        // Token is invalid, logout
        actions.logout();
      });
    }
  }, []);

  const value = {
    ...state,
    actions
  };

  return (
    <AdminContext.Provider value={value}>
      {children}
    </AdminContext.Provider>
  );
};

// Custom hook to use admin context
export const useAdmin = () => {
  const context = useContext(AdminContext);
  if (!context) {
    throw new Error('useAdmin must be used within an AdminProvider');
  }
  return context;
};

export default AdminContext;
