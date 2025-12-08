import axios from 'axios'

// Create axios instance for API calls
// Web auth uses HttpOnly cookies (set by backend), no manual token handling needed
const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json'
  },
  // Include cookies in requests
  withCredentials: true
})

// Response interceptor - handle errors
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    // If 401, redirect to login (session expired or not authenticated)
    if (error.response?.status === 401) {
      // Only redirect if not already on auth pages
      if (!window.location.pathname.startsWith('/login') && 
          !window.location.pathname.startsWith('/register')) {
        window.location.href = '/login'
      }
    }
    
    return Promise.reject(error)
  }
)

export default api
