import api from './client'
import type { AuthResponse, User } from '@/types'

export const authApi = {
  async register(name: string, email: string, password: string): Promise<AuthResponse> {
    const response = await api.post('/v1/auth/register', { name, email, password })
    return response.data
  },

  async login(email: string, password: string): Promise<AuthResponse> {
    const response = await api.post('/v1/auth/login', { email, password })
    return response.data
  },

  async refresh(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    const response = await api.post('/v1/auth/refresh', { refreshToken })
    return response.data
  },

  async logout(): Promise<void> {
    const refreshToken = localStorage.getItem('refreshToken')
    await api.post('/v1/auth/logout', { refreshToken })
  },

  async me(): Promise<User> {
    const response = await api.get('/v1/users/me')
    return response.data
  }
}
