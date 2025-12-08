import api from './client'
import type { Student, StudentWithStats } from '@/types'

export interface CreateStudentRequest {
  name: string
  gradeLevel: string
  dateOfBirth?: string
}

export interface UpdateStudentRequest {
  name?: string
  gradeLevel?: string
  dateOfBirth?: string
  active?: boolean
}

export const studentsApi = {
  /**
   * Get all students for the current family
   */
  async list(): Promise<Student[]> {
    const response = await api.get('/v1/students')
    return response.data
  },

  /**
   * Get a single student by ID (includes stats)
   */
  async get(id: string): Promise<StudentWithStats> {
    const response = await api.get(`/v1/students/${id}`)
    return response.data
  },

  /**
   * Create a new student
   */
  async create(data: CreateStudentRequest): Promise<Student> {
    const response = await api.post('/v1/students', data)
    return response.data
  },

  /**
   * Update a student
   */
  async update(id: string, data: UpdateStudentRequest): Promise<Student> {
    const response = await api.patch(`/v1/students/${id}`, data)
    return response.data
  },

  /**
   * Soft delete a student (sets active=false)
   */
  async delete(id: string): Promise<void> {
    await api.delete(`/v1/students/${id}`)
  }
}
