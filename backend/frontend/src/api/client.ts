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
    // Skip redirect for /me endpoint - that's used to check auth status on page load
    if (error.response?.status === 401) {
      const isAuthCheck = error.config?.url?.endsWith('/auth/me')
      const isAuthPage = window.location.pathname.startsWith('/login') || 
                         window.location.pathname.startsWith('/register')
      
      // Only redirect if not on auth pages and not checking auth status
      if (!isAuthPage && !isAuthCheck) {
        window.location.href = '/login'
      }
    }
    
    return Promise.reject(error)
  }
)

export default api
