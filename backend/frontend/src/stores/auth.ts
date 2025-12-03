import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@/types'
import { authApi } from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const isAuthenticated = computed(() => !!token.value && !!user.value)

  // Actions
  async function login(email: string, password: string) {
    loading.value = true
    error.value = null
    try {
      const response = await authApi.login(email, password)
      token.value = response.accessToken
      user.value = response.user
      localStorage.setItem('token', response.accessToken)
      localStorage.setItem('refreshToken', response.refreshToken)
    } catch (e: any) {
      error.value = e.message || 'Login failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function register(name: string, email: string, password: string) {
    loading.value = true
    error.value = null
    try {
      const response = await authApi.register(name, email, password)
      token.value = response.accessToken
      user.value = response.user
      localStorage.setItem('token', response.accessToken)
      localStorage.setItem('refreshToken', response.refreshToken)
    } catch (e: any) {
      error.value = e.message || 'Registration failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    try {
      await authApi.logout()
    } catch (e) {
      // Ignore logout errors
    } finally {
      token.value = null
      user.value = null
      localStorage.removeItem('token')
      localStorage.removeItem('refreshToken')
    }
  }

  async function refreshToken() {
    const refresh = localStorage.getItem('refreshToken')
    if (!refresh) {
      await logout()
      return
    }
    try {
      const response = await authApi.refresh(refresh)
      token.value = response.accessToken
      localStorage.setItem('token', response.accessToken)
      localStorage.setItem('refreshToken', response.refreshToken)
    } catch (e) {
      await logout()
    }
  }

  async function fetchUser() {
    if (!token.value) return
    try {
      const userData = await authApi.me()
      user.value = userData
    } catch (e) {
      await logout()
    }
  }

  return {
    // State
    user,
    token,
    loading,
    error,
    // Getters
    isAuthenticated,
    // Actions
    login,
    register,
    logout,
    refreshToken,
    fetchUser
  }
})
