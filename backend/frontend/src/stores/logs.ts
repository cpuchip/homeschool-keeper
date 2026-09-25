import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { LogEntry, CreateLogEntry, UpdateLogEntry, LogFilters, CreateMultiStudentLog } from '@/types'
import { logsApi } from '@/api/logs'
import { v4 as uuidv4 } from 'uuid'

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

  // Create log entries for multiple students (same activity)
  async function createMultiStudentLog(data: CreateMultiStudentLog): Promise<LogEntry[]> {
    if (data.studentIds.length === 0) {
      throw new Error('No students selected')
    }

    // Single student - no group needed
    if (data.studentIds.length === 1) {
      const log = await createLog({
        studentId: data.studentIds[0],
        subjectId: data.subjectId,
        date: data.date,
        hours: data.hours,
        description: data.description,
        locationType: data.locationType,
        locationName: data.locationName,
      })
      return [log]
    }

    // Multiple students - generate groupId and create each log
    loading.value = true
    error.value = null
    const groupId = uuidv4()
    const createdLogs: LogEntry[] = []

    try {
      for (const studentId of data.studentIds) {
        const log = await logsApi.create({
          studentId,
          subjectId: data.subjectId,
          date: data.date,
          hours: data.hours,
          description: data.description,
          locationType: data.locationType,
          locationName: data.locationName,
          groupId,
        })
        createdLogs.push(log)
      }

      // Add all to beginning of list
      logs.value.unshift(...createdLogs)
      total.value += createdLogs.length

      return createdLogs
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to create logs'
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
    createMultiStudentLog,
    updateLog,
    deleteLog,
    clearCurrentLog,
    clearFilters
  }
})
