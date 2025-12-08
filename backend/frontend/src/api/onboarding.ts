import api from './client'
import type { OnboardingData, Family } from '@/types'

export const onboardingApi = {
  /**
   * Complete the onboarding process
   * Sets up family settings, seeds subjects, creates initial students
   */
  async complete(data: OnboardingData): Promise<{ family: Family }> {
    const response = await api.post('/v1/onboarding/complete', data)
    return response.data
  },

  /**
   * Get default subjects for a state (used during onboarding)
   */
  async getDefaultSubjects(state: string): Promise<string[]> {
    const response = await api.get(`/v1/onboarding/subjects?state=${state}`)
    return response.data.subjects
  }
}
