import api from './client'
import type { LogEntry, CreateLogEntry, UpdateLogEntry, LogFilters } from '@/types'

export interface LogListResponse {
  logs: LogEntry[]
  total: number
  page: number
  limit: number
}

export const logsApi = {
  /**
   * Get log entries with optional filters
   */
  async list(filters?: LogFilters): Promise<LogListResponse> {
    const params = new URLSearchParams()
    
    if (filters?.studentId) params.append('studentId', filters.studentId)
    if (filters?.subjectId) params.append('subjectId', filters.subjectId)
    if (filters?.startDate) params.append('startDate', filters.startDate)
    if (filters?.endDate) params.append('endDate', filters.endDate)
    if (filters?.schoolYear) params.append('schoolYear', filters.schoolYear)
    if (filters?.status) params.append('status', filters.status)
    if (filters?.page) params.append('page', String(filters.page))
    if (filters?.limit) params.append('limit', String(filters.limit))

    const response = await api.get(`/v1/logs?${params.toString()}`)
    return response.data
  },

  /**
   * Get a single log entry by ID
   */
  async get(id: string): Promise<LogEntry> {
    const response = await api.get(`/v1/logs/${id}`)
    return response.data
  },

  /**
   * Create a new log entry
   */
  async create(data: CreateLogEntry): Promise<LogEntry> {
    const response = await api.post('/v1/logs', data)
    return response.data
  },

  /**
   * Update a log entry
   */
  async update(id: string, data: UpdateLogEntry): Promise<LogEntry> {
    const response = await api.patch(`/v1/logs/${id}`, data)
    return response.data
  },

  /**
   * Delete a log entry
   */
  async delete(id: string): Promise<void> {
    await api.delete(`/v1/logs/${id}`)
  }
}
