import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Subject } from '@/types'
import { subjectsApi, type CreateSubjectRequest, type UpdateSubjectRequest } from '@/api/subjects'

export const useSubjectsStore = defineStore('subjects', () => {
  // State
  const subjects = ref<Subject[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const activeSubjects = computed(() => subjects.value.filter(s => s.active))
  const coreSubjects = computed(() => activeSubjects.value.filter(s => s.type === 'core'))
  const electiveSubjects = computed(() => activeSubjects.value.filter(s => s.type === 'elective'))
  const subjectById = computed(() => (id: string) => subjects.value.find(s => s.id === id))

  // Actions
  async function fetchSubjects() {
    loading.value = true
    error.value = null
    try {
      subjects.value = await subjectsApi.list()
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load subjects'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createSubject(data: CreateSubjectRequest) {
    loading.value = true
    error.value = null
    try {
      const subject = await subjectsApi.create(data)
      subjects.value.push(subject)
      return subject
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to create subject'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function updateSubject(id: string, data: UpdateSubjectRequest) {
    loading.value = true
    error.value = null
    try {
      const updated = await subjectsApi.update(id, data)
      const index = subjects.value.findIndex(s => s.id === id)
      if (index !== -1) {
        subjects.value[index] = updated
      }
      return updated
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to update subject'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function deleteSubject(id: string) {
    loading.value = true
    error.value = null
    try {
      await subjectsApi.delete(id)
      // Update local state to mark as inactive
      const index = subjects.value.findIndex(s => s.id === id)
      if (index !== -1) {
        subjects.value[index].active = false
      }
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to delete subject'
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    // State
    subjects,
    loading,
    error,
    // Getters
    activeSubjects,
    coreSubjects,
    electiveSubjects,
    subjectById,
    // Actions
    fetchSubjects,
    createSubject,
    updateSubject,
    deleteSubject
  }
})
