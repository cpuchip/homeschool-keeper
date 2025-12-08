import api from './client'
import type { StudentStats, FamilyStats } from '@/types'

export const statsApi = {
  /**
   * Get statistics for a single student
   */
  async getStudentStats(studentId: string, schoolYear?: string): Promise<StudentStats> {
    const params = schoolYear ? `?schoolYear=${schoolYear}` : ''
    const response = await api.get(`/v1/stats/student/${studentId}${params}`)
    return response.data
  },

  /**
   * Get statistics for the entire family (all students)
   */
  async getFamilyStats(schoolYear?: string): Promise<FamilyStats> {
    const params = schoolYear ? `?schoolYear=${schoolYear}` : ''
    const response = await api.get(`/v1/stats/family${params}`)
    return response.data
  }
}
