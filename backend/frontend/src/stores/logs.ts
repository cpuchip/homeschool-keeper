import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { LogEntry, CreateLogEntry, UpdateLogEntry, LogFilters } from '@/types'
import { logsApi } from '@/api/logs'

export const useLogsStore = defineStore('logs', () => {
  // State
  const logs = ref<LogEntry[]>([])
  const currentLog = ref<LogEntry | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const total = ref(0)
  const page = ref(1)
  const limit = ref(20)
  const filters = ref<LogFilters>({})

  // Getters
  const hasMore = computed(() => logs.value.length < total.value)
  const logsByStudent = computed(() => (studentId: string) => 
    logs.value.filter(l => l.studentId === studentId)
  )
  const logsBySubject = computed(() => (subjectId: string) => 
    logs.value.filter(l => l.subjectId === subjectId)
  )

  // Actions
  async function fetchLogs(newFilters?: LogFilters, append = false) {
    loading.value = true
    error.value = null
    try {
      if (newFilters) {
        filters.value = newFilters
      }
      
      const response = await logsApi.list({
        ...filters.value,
        page: append ? page.value + 1 : 1,
        limit: limit.value
      })
      
      if (append) {
        logs.value = [...logs.value, ...response.logs]
        page.value += 1
      } else {
        logs.value = response.logs
        page.value = 1
      }
      total.value = response.total
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load logs'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchLog(id: string) {
    loading.value = true
    error.value = null
    try {
      currentLog.value = await logsApi.get(id)
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load log'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createLog(data: CreateLogEntry) {
    loading.value = true
    error.value = null
    try {
      const log = await logsApi.create(data)
      // Add to beginning of list (most recent first)
      logs.value.unshift(log)
      total.value += 1
      return log
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to create log'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function updateLog(id: string, data: UpdateLogEntry) {
    loading.value = true
    error.value = null
    try {
      const updated = await logsApi.update(id, data)
      const index = logs.value.findIndex(l => l.id === id)
      if (index !== -1) {
        logs.value[index] = updated
      }
      if (currentLog.value?.id === id) {
        currentLog.value = updated
      }
      return updated
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to update log'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function deleteLog(id: string) {
    loading.value = true
    error.value = null
    try {
      await logsApi.delete(id)
      logs.value = logs.value.filter(l => l.id !== id)
      total.value -= 1
      if (currentLog.value?.id === id) {
        currentLog.value = null
      }
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to delete log'
      throw e
    } finally {
      loading.value = false
    }
  }

  function clearCurrentLog() {
    currentLog.value = null
  }

  function clearFilters() {
    filters.value = {}
  }

  return {
    // State
    logs,
    currentLog,
    loading,
    error,
    total,
    page,
    limit,
    filters,
    // Getters
    hasMore,
    logsByStudent,
    logsBySubject,
    // Actions
    fetchLogs,
    fetchLog,
    createLog,
    updateLog,
    deleteLog,
    clearCurrentLog,
    clearFilters
  }
})
