import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { StudentStats, FamilyStats } from '@/types'
import { statsApi } from '@/api/stats'

export const useStatsStore = defineStore('stats', () => {
  // State
  const studentStats = ref<Record<string, StudentStats>>({}) // keyed by studentId
  const familyStats = ref<FamilyStats | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Actions
  async function fetchStudentStats(studentId: string, schoolYear?: string) {
    loading.value = true
    error.value = null
    try {
      const stats = await statsApi.getStudentStats(studentId, schoolYear)
      studentStats.value[studentId] = stats
      return stats
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load student stats'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchFamilyStats(schoolYear?: string) {
    loading.value = true
    error.value = null
    try {
      familyStats.value = await statsApi.getFamilyStats(schoolYear)
      return familyStats.value
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load family stats'
      throw e
    } finally {
      loading.value = false
    }
  }

  function getStudentStats(studentId: string): StudentStats | undefined {
    return studentStats.value[studentId]
  }

  function clearStats() {
    studentStats.value = {}
    familyStats.value = null
  }

  return {
    // State
    studentStats,
    familyStats,
    loading,
    error,
    // Actions
    fetchStudentStats,
    fetchFamilyStats,
    getStudentStats,
    clearStats
  }
})
