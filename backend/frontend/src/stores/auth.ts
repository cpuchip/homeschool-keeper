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
  const selectedSchoolYear = ref<string>('')

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

  // Generate list of available school years (current year + past 5 years)
  const availableSchoolYears = computed(() => {
    const years: string[] = []
    const currentYear = new Date().getFullYear()
    // Generate years from current back to 5 years ago
    for (let i = 0; i <= 5; i++) {
      const startYear = currentYear - i
      years.push(`${startYear}-${startYear + 1}`)
    }
    return years
  })

  // Get the effective school year to use for API calls
  const effectiveSchoolYear = computed(() => {
    return selectedSchoolYear.value || currentSchoolYear.value
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

  function setSelectedSchoolYear(year: string) {
    selectedSchoolYear.value = year
  }

  return {
    // State
    user,
    family,
    loading,
    error,
    initialized,
    selectedSchoolYear,
    // Getters
    isAuthenticated,
    currentSchoolYear,
    availableSchoolYears,
    effectiveSchoolYear,
    // Actions
    login,
    register,
    logout,
    fetchUser,
    updateFamily,
    setSelectedSchoolYear
  }
})
