import api from './client'
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
   * Logout and clear session
   */
  async logout(): Promise<void> {
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
