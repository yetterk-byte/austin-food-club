import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const restaurantAPI = {
  getCurrent: () => api.get('/api/restaurants/current'),
  getAll: () => api.get('/api/restaurants'),
  getById: (id) => api.get(`/api/restaurants/${id}`),
};

export const authAPI = {
  login: (credentials) => api.post('/api/auth/login', credentials),
  register: (userData) => api.post('/api/auth/register', userData),
  logout: () => api.post('/api/auth/logout'),
  getProfile: () => api.get('/api/auth/profile'),
};

export const rsvpAPI = {
  create: (rsvpData) => api.post('/api/rsvp', rsvpData),
  update: (id, rsvpData) => api.put(`/api/rsvp/${id}`, rsvpData),
  delete: (id) => api.delete(`/api/rsvp/${id}`),
  getByUser: () => api.get('/api/rsvp/user'),
};

export default api;

