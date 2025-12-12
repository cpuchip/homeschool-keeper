import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useAuthStore } from '@/stores/auth'
import { authApi } from '@/api/auth'
import type { User, Family } from '@/types'

// Mock the API module
vi.mock('@/api/auth', () => ({
  authApi: {
    login: vi.fn(),
    register: vi.fn(),
    logout: vi.fn(),
    me: vi.fn(),
  },
}))

const mockUser: User = {
  id: 'user1',
  email: 'test@example.com',
  name: 'Test User',
  familyId: 'family1',
  role: 'parent',
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
}

const mockFamily: Family = {
  id: 'family1',
  name: 'Test Family',
  hourIncrement: 0.25,
  schoolYearStart: '2024-08-01T00:00:00Z',
  schoolYearEnd: '2025-05-31T00:00:00Z',
  currentYear: '2024-2025',
  state: 'MO',
  timezone: 'America/Chicago',
  settings: {
    autoApproveLogs: true,
    requireSubjectGoals: false,
  },
  premium: {
    syncEnabled: false,
    uploadsEnabled: false,
    storageUsedBytes: 0,
    storageLimitBytes: 104857600, // 100MB
    subscriptionTier: 'free',
  },
  onboardingDone: true,
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
}

describe('Auth Store', () => {
  let store: ReturnType<typeof useAuthStore>

  beforeEach(() => {
    vi.clearAllMocks()
    store = useAuthStore()
  })

  describe('initial state', () => {
    it('should have null user', () => {
      expect(store.user).toBeNull()
    })

    it('should have null family', () => {
      expect(store.family).toBeNull()
    })

    it('should not be authenticated', () => {
      expect(store.isAuthenticated).toBe(false)
    })

    it('should not be loading', () => {
      expect(store.loading).toBe(false)
    })
  })

  describe('computed: isAuthenticated', () => {
    it('should be true when user is set', () => {
      store.user = mockUser
      expect(store.isAuthenticated).toBe(true)
    })

    it('should be false when user is null', () => {
      store.user = null
      expect(store.isAuthenticated).toBe(false)
    })
  })

  describe('computed: currentSchoolYear', () => {
    it('should return currentYear from family', () => {
      store.family = mockFamily
      expect(store.currentSchoolYear).toBe('2024-2025')
    })

    it('should return empty string when no family', () => {
      expect(store.currentSchoolYear).toBe('')
    })
  })

  describe('computed: availableSchoolYears', () => {
    it('should return array of 6 school years', () => {
      expect(store.availableSchoolYears).toHaveLength(6)
    })

    it('should have correct format', () => {
      const years = store.availableSchoolYears
      years.forEach((year: string) => {
        expect(year).toMatch(/^\d{4}-\d{4}$/)
      })
    })
  })

  describe('computed: effectiveSchoolYear', () => {
    it('should return selectedSchoolYear if set', () => {
      store.family = mockFamily
      store.setSelectedSchoolYear('2023-2024')
      expect(store.effectiveSchoolYear).toBe('2023-2024')
    })

    it('should return currentSchoolYear if no selection', () => {
      store.family = mockFamily
      expect(store.effectiveSchoolYear).toBe('2024-2025')
    })
  })

  describe('computed: isViewingPastYear', () => {
    it('should return false when no selection', () => {
      store.family = mockFamily
      expect(store.isViewingPastYear).toBe(false)
    })

    it('should return false when viewing current year', () => {
      store.family = mockFamily
      store.setSelectedSchoolYear('2024-2025')
      expect(store.isViewingPastYear).toBe(false)
    })

    it('should return true when viewing a past year', () => {
      store.family = mockFamily
      store.setSelectedSchoolYear('2023-2024')
      expect(store.isViewingPastYear).toBe(true)
    })
  })

  describe('login', () => {
    it('should set user and family on success', async () => {
      vi.mocked(authApi.login).mockResolvedValue({
        user: mockUser,
        family: mockFamily,
      })

      await store.login('test@example.com', 'password123')

      expect(authApi.login).toHaveBeenCalledWith('test@example.com', 'password123')
      expect(store.user).toEqual(mockUser)
      expect(store.family).toEqual(mockFamily)
      expect(store.isAuthenticated).toBe(true)
    })

    it('should set error on failure', async () => {
      vi.mocked(authApi.login).mockRejectedValue({
        response: { data: { error: 'Invalid credentials' } },
      })

      await expect(store.login('test@example.com', 'wrong')).rejects.toBeDefined()
      expect(store.error).toBe('Invalid credentials')
      expect(store.isAuthenticated).toBe(false)
    })
  })

  describe('register', () => {
    it('should set user and family on success', async () => {
      vi.mocked(authApi.register).mockResolvedValue({
        user: mockUser,
        family: mockFamily,
      })

      await store.register({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        familyName: 'Test Family',
      })

      expect(store.user).toEqual(mockUser)
      expect(store.family).toEqual(mockFamily)
    })
  })

  describe('logout', () => {
    it('should clear user and family', async () => {
      store.user = mockUser
      store.family = mockFamily
      vi.mocked(authApi.logout).mockResolvedValue(undefined)

      await store.logout()

      expect(store.user).toBeNull()
      expect(store.family).toBeNull()
      expect(store.isAuthenticated).toBe(false)
    })
  })

  describe('setSelectedSchoolYear', () => {
    it('should set selectedSchoolYear', () => {
      store.setSelectedSchoolYear('2023-2024')
      expect(store.selectedSchoolYear).toBe('2023-2024')
    })
  })
})
