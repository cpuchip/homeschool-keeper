import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Student, StudentWithStats } from '@/types'
import { studentsApi, type CreateStudentRequest, type UpdateStudentRequest } from '@/api/students'

export const useStudentsStore = defineStore('students', () => {
  // State
  const students = ref<Student[]>([])
  const currentStudent = ref<StudentWithStats | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const activeStudents = computed(() => students.value.filter(s => s.active))
  const studentById = computed(() => (id: string) => students.value.find(s => s.id === id))

  // Actions
  async function fetchStudents() {
    loading.value = true
    error.value = null
    try {
      students.value = await studentsApi.list()
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load students'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchStudent(id: string) {
    loading.value = true
    error.value = null
    try {
      currentStudent.value = await studentsApi.get(id)
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to load student'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function createStudent(data: CreateStudentRequest) {
    loading.value = true
    error.value = null
    try {
      const student = await studentsApi.create(data)
      students.value.push(student)
      return student
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to create student'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function updateStudent(id: string, data: UpdateStudentRequest) {
    loading.value = true
    error.value = null
    try {
      const updated = await studentsApi.update(id, data)
      const index = students.value.findIndex(s => s.id === id)
      if (index !== -1) {
        students.value[index] = updated
      }
      if (currentStudent.value?.id === id) {
        currentStudent.value = { ...currentStudent.value, ...updated }
      }
      return updated
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to update student'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function deleteStudent(id: string) {
    loading.value = true
    error.value = null
    try {
      await studentsApi.delete(id)
      // Update local state to mark as inactive
      const index = students.value.findIndex(s => s.id === id)
      if (index !== -1) {
        students.value[index].active = false
      }
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } }; message?: string }
      error.value = err.response?.data?.error || err.message || 'Failed to delete student'
      throw e
    } finally {
      loading.value = false
    }
  }

  function clearCurrentStudent() {
    currentStudent.value = null
  }

  return {
    // State
    students,
    currentStudent,
    loading,
    error,
    // Getters
    activeStudents,
    studentById,
    // Actions
    fetchStudents,
    fetchStudent,
    createStudent,
    updateStudent,
    deleteStudent,
    clearCurrentStudent
  }
})
