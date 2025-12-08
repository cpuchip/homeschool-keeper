import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, Family } from '@/types'
import { authApi, type RegisterRequest } from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const family = ref<Family | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const initialized = ref(false)

  // Getters
  const isAuthenticated = computed(() => !!user.value)
  const currentSchoolYear = computed(() => {
    if (!family.value) return ''
    // Use the currentYear field from the backend if available
    if (family.value.currentYear) {
      return family.value.currentYear
    }
    // Fallback: calculate from dates
    if (family.value.schoolYearStart && family.value.schoolYearEnd) {
      const start = new Date(family.value.schoolYearStart)
      const end = new Date(family.value.schoolYearEnd)
      if (!isNaN(start.getTime()) && !isNaN(end.getTime())) {
        return `${start.getFullYear()}-${end.getFullYear()}`
      }
    }
    return ''
  })

  // Actions
  async function login(email: string, password: string) {
    loading.value = true
    error.value = null
    try {
      const response = await authApi.login(email, password)
      user.value = response.user
      family.value = response.family
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Login failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function register(data: RegisterRequest) {
    loading.value = true
    error.value = null
    try {
      const response = await authApi.register(data)
      user.value = response.user
      family.value = response.family
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Registration failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    try {
      await authApi.logout()
    } catch {
      // Ignore logout errors
    } finally {
      user.value = null
      family.value = null
    }
  }

  async function fetchUser() {
    if (initialized.value) return
    
    try {
      const data = await authApi.me()
      user.value = data.user
      family.value = data.family
    } catch {
      // Not authenticated
      user.value = null
      family.value = null
    } finally {
      initialized.value = true
    }
  }

  function updateFamily(updates: Partial<Family>) {
    if (family.value) {
      family.value = { ...family.value, ...updates }
    }
  }

  return {
    // State
    user,
    family,
    loading,
    error,
    initialized,
    // Getters
    isAuthenticated,
    currentSchoolYear,
    // Actions
    login,
    register,
    logout,
    fetchUser,
    updateFamily
  }
})
