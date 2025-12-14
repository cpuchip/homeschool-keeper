import axios from 'axios'

// Token storage key
const ACCESS_TOKEN_KEY = 'hmslogs_access_token'

// Create axios instance for API calls
// Supports both cookie sessions (legacy) and JWT Bearer tokens
const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json'
  },
  // Include cookies in requests (for legacy cookie auth)
  withCredentials: true
})

// Request interceptor - add JWT if available
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(ACCESS_TOKEN_KEY)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
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
      
      // Clear stored token on 401
      localStorage.removeItem(ACCESS_TOKEN_KEY)
      
      // Only redirect if not on auth pages and not checking auth status
      if (!isAuthPage && !isAuthCheck) {
        window.location.href = '/login'
      }
    }
    
    return Promise.reject(error)
  }
)

// Helper functions for token management
export function setAccessToken(token: string) {
  localStorage.setItem(ACCESS_TOKEN_KEY, token)
}

export function getAccessToken(): string | null {
  return localStorage.getItem(ACCESS_TOKEN_KEY)
}

export function clearAccessToken() {
  localStorage.removeItem(ACCESS_TOKEN_KEY)
}

export default api
