import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useStudentsStore } from '@/stores/students'
import { studentsApi } from '@/api/students'
import type { Student, StudentWithStats } from '@/types'

// Mock the API module
vi.mock('@/api/students', () => ({
  studentsApi: {
    list: vi.fn(),
    get: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockStudent: Student = {
  id: '1',
  familyId: 'family1',
  name: 'Test Student',
  gradeLevel: '3',
  active: true,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
}

const mockStudentWithStats: StudentWithStats = {
  ...mockStudent,
  stats: {
    studentId: '1',
    studentName: 'Test Student',
    totalHours: 10.5,
    bySubject: [],
  },
}

describe('Students Store', () => {
  let store: ReturnType<typeof useStudentsStore>

  beforeEach(() => {
    vi.clearAllMocks()
    store = useStudentsStore()
  })

  describe('initial state', () => {
    it('should have empty students array', () => {
      expect(store.students).toEqual([])
    })

    it('should have null currentStudent', () => {
      expect(store.currentStudent).toBeNull()
    })

    it('should not be loading', () => {
      expect(store.loading).toBe(false)
    })

    it('should have no error', () => {
      expect(store.error).toBeNull()
    })
  })

  describe('computed: activeStudents', () => {
    it('should filter only active students', () => {
      store.students = [
        { ...mockStudent, id: '1', active: true },
        { ...mockStudent, id: '2', active: false },
        { ...mockStudent, id: '3', active: true },
      ]

      expect(store.activeStudents).toHaveLength(2)
      expect(store.activeStudents.every(s => s.active)).toBe(true)
    })
  })

  describe('computed: studentById', () => {
    it('should find student by id', () => {
      store.students = [
        { ...mockStudent, id: '1', name: 'Alice' },
        { ...mockStudent, id: '2', name: 'Bob' },
      ]

      const found = store.studentById('2')
      expect(found?.name).toBe('Bob')
    })

    it('should return undefined for non-existent id', () => {
      store.students = [mockStudent]
      expect(store.studentById('non-existent')).toBeUndefined()
    })
  })

  describe('fetchStudents', () => {
    it('should fetch and store students', async () => {
      const mockStudents = [mockStudent, { ...mockStudent, id: '2', name: 'Student 2' }]
      vi.mocked(studentsApi.list).mockResolvedValue(mockStudents)

      await store.fetchStudents()

      expect(studentsApi.list).toHaveBeenCalled()
      expect(store.students).toEqual(mockStudents)
      expect(store.loading).toBe(false)
    })

    it('should set error on failure', async () => {
      vi.mocked(studentsApi.list).mockRejectedValue(new Error('Network error'))

      await expect(store.fetchStudents()).rejects.toThrow('Network error')
      expect(store.error).toBe('Network error')
      expect(store.loading).toBe(false)
    })
  })

  describe('fetchStudent', () => {
    it('should fetch and set current student with stats', async () => {
      vi.mocked(studentsApi.get).mockResolvedValue(mockStudentWithStats)

      await store.fetchStudent('1')

      expect(studentsApi.get).toHaveBeenCalledWith('1')
      expect(store.currentStudent).toEqual(mockStudentWithStats)
    })
  })

  describe('createStudent', () => {
    it('should create and add student to list', async () => {
      vi.mocked(studentsApi.create).mockResolvedValue(mockStudent)

      const created = await store.createStudent({ name: 'Test Student', gradeLevel: '3' })

      expect(studentsApi.create).toHaveBeenCalledWith({ name: 'Test Student', gradeLevel: '3' })
      expect(store.students).toHaveLength(1)
      expect(store.students[0]).toEqual(mockStudent)
      expect(created).toEqual(mockStudent)
    })
  })

  describe('updateStudent', () => {
    it('should update student in list', async () => {
      store.students = [mockStudent]
      const updated = { ...mockStudent, name: 'Updated Name' }
      vi.mocked(studentsApi.update).mockResolvedValue(updated)

      const result = await store.updateStudent('1', { name: 'Updated Name' })

      expect(store.students[0].name).toBe('Updated Name')
      expect(result.name).toBe('Updated Name')
    })

    it('should update currentStudent if it matches', async () => {
      store.currentStudent = mockStudentWithStats
      const updated = { ...mockStudent, name: 'Updated Name' }
      vi.mocked(studentsApi.update).mockResolvedValue(updated)

      await store.updateStudent('1', { name: 'Updated Name' })

      expect(store.currentStudent?.name).toBe('Updated Name')
    })
  })

  describe('deleteStudent', () => {
    it('should mark student as inactive', async () => {
      store.students = [mockStudent]
      vi.mocked(studentsApi.delete).mockResolvedValue(undefined)

      await store.deleteStudent('1')

      expect(studentsApi.delete).toHaveBeenCalledWith('1')
      expect(store.students[0].active).toBe(false)
    })
  })
})
