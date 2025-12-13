import api, { setAccessToken, clearAccessToken } from './client'
import type { AuthResponse, User, Family } from '@/types'

export interface RegisterRequest {
  name: string
  email: string
  password: string
  familyName: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface GoogleAuthRequest {
  idToken: string
  familyName?: string
  state?: string
}

export interface GoogleAuthResponse {
  user: User
  family: Family
  accessToken: string
  expiresAt: string
  isNewUser: boolean
}

export const authApi = {
  /**
   * Register a new user and family
   * Creates both user and family in one request
   */
  async register(data: RegisterRequest): Promise<AuthResponse> {
    const response = await api.post('/v1/auth/register', data)
    return response.data
  },

  /**
   * Login with email and password
   * Sets HttpOnly session cookie
   */
  async login(email: string, password: string): Promise<AuthResponse> {
    const response = await api.post('/v1/auth/login', { email, password })
    return response.data
  },

  /**
   * Login or register with Google OAuth
   * Returns JWT token for subsequent requests
   */
  async googleAuth(data: GoogleAuthRequest): Promise<GoogleAuthResponse> {
    const response = await api.post('/v1/auth/google', data)
    // Store the JWT token for future requests
    if (response.data.accessToken) {
      setAccessToken(response.data.accessToken)
    }
    return response.data
  },

  /**
   * Logout and clear session
   */
  async logout(): Promise<void> {
    // Clear JWT token
    clearAccessToken()
    // Also clear server-side session
    await api.post('/v1/auth/logout')
  },

  /**
   * Get current authenticated user
   */
  async me(): Promise<{ user: User; family: Family }> {
    const response = await api.get('/v1/auth/me')
    return response.data
  }
}
