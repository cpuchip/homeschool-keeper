import api from './client'
import type { Subject } from '@/types'

export interface CreateSubjectRequest {
  name: string
  type: 'core' | 'elective'
  targetHours?: number
  color?: string
}

export interface UpdateSubjectRequest {
  name?: string
  type?: 'core' | 'elective'
  targetHours?: number
  color?: string
  active?: boolean
}

export const subjectsApi = {
  /**
   * Get all subjects for the current family
   */
  async list(): Promise<Subject[]> {
    const response = await api.get('/v1/subjects')
    return response.data
  },

  /**
   * Create a new subject
   */
  async create(data: CreateSubjectRequest): Promise<Subject> {
    const response = await api.post('/v1/subjects', data)
    return response.data
  },

  /**
   * Update a subject
   */
  async update(id: string, data: UpdateSubjectRequest): Promise<Subject> {
    const response = await api.patch(`/v1/subjects/${id}`, data)
    return response.data
  },

  /**
   * Soft delete a subject (sets active=false)
   */
  async delete(id: string): Promise<void> {
    await api.delete(`/v1/subjects/${id}`)
  }
}
