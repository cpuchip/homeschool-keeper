// User & Auth
export interface User {
  id: string
  email: string
  name: string
  familyId: string
  role: 'admin' | 'parent' | 'student'
  createdAt: string
  updatedAt: string
}

// Web auth uses cookies, so no tokens in response
export interface AuthResponse {
  user: User
  family: Family
}

// Family - core unit of ownership
export interface FamilySettings {
  autoApproveLogs: boolean
  requireSubjectGoals: boolean
}

// Premium feature flags
export interface PremiumFeatures {
  syncEnabled: boolean
  uploadsEnabled: boolean
  storageUsedBytes: number
  storageLimitBytes: number
  subscriptionTier: 'free' | 'basic' | 'premium'
  subscriptionEnd?: string
}

export interface Family {
  id: string
  name: string
  organizationId?: string // optional, for co-ops
  hourIncrement: number // 0.25, 0.5, 1.0
  schoolYearStart: string // ISO date string from backend
  schoolYearEnd: string // ISO date string from backend
  currentYear: string // e.g., "2024-2025"
  state: string // e.g., 'MO'
  timezone: string
  settings: FamilySettings
  premium: PremiumFeatures // Premium feature flags
  onboardingDone: boolean
  createdAt: string
  updatedAt: string
}

// Organization (for Phase 1B co-op support)
export interface Organization {
  id: string
  name: string
  description: string
  createdBy: string
  createdAt: string
}

// Student
export interface Student {
  id: string
  familyId: string
  name: string
  dateOfBirth?: string // optional, parent's choice
  gradeLevel: string
  userId?: string // set when student has login
  active: boolean
  createdAt: string
  updatedAt: string
}

export interface StudentWithStats extends Student {
  stats: StudentStats
}

// Subject
export interface Subject {
  id: string
  familyId: string
  name: string
  type: 'core' | 'elective'
  targetHours?: number // optional
  color: string
  isDefault: boolean
  active: boolean
  createdAt: string
}

// Location types
export type LocationType = 'home' | 'field_trip' | 'co_op' | 'online' | 'other'

// Log Entry
export interface LogEntry {
  id: string
  familyId: string
  organizationId?: string // for co-op activities
  studentId: string
  subjectId: string
  groupId?: string // links multiple log entries created together (multi-student)
  date: string
  hours: number
  description: string
  locationType: LocationType
  locationName?: string // e.g., "Science Museum"
  submittedBy: string
  status: 'pending' | 'approved'
  schoolYear: string // "2024-2025"
  createdAt: string
  updatedAt: string
}

export interface CreateLogEntry {
  studentId: string
  subjectId: string
  date: string
  hours: number
  description: string
  locationType: LocationType
  locationName?: string
  groupId?: string // for multi-student logs
}

// Multi-student log creation request
export interface CreateMultiStudentLog {
  studentIds: string[]
  subjectId: string
  date: string
  hours: number
  description: string
  locationType: LocationType
  locationName?: string
}

export interface UpdateLogEntry {
  studentId?: string
  subjectId?: string
  date?: string
  hours?: number
  description?: string
  locationType?: LocationType
  locationName?: string
}

// Location (saved locations for quick selection)
export interface Location {
  id: string
  familyId: string
  type: string // field_trip, co_op, other
  name: string
  address?: string
  createdAt: string
}

// Stats
export interface SubjectHours {
  subjectId: string
  subjectName: string
  hours: number
}

export interface StudentStats {
  studentId: string
  studentName: string
  totalHours: number
  bySubject: SubjectHours[]
}

export interface FamilyStats {
  familyId: string
  schoolYear: string
  students: StudentStats[]
  totalHours: number
}

// Onboarding
export interface OnboardingData {
  familyName: string
  state: string
  timezone: string
  schoolYearStart: string
  schoolYearEnd: string
  hourIncrement: number
  subjects: string[] // subject names to seed (matches backend field name)
  students: Array<{
    name: string
    gradeLevel: string
  }>
}

// API Error
export interface ApiError {
  error: string
  message?: string
  details?: Record<string, string>
}

// Pagination
export interface PaginatedResponse<T> {
  data: T[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
}

// Log filters
export interface LogFilters {
  studentId?: string
  subjectId?: string
  startDate?: string
  endDate?: string
  schoolYear?: string
  status?: 'pending' | 'approved'
  page?: number
  limit?: number
}

// Work Sample (file attached to log entry)
export interface WorkSample {
  id: string
  familyId: string
  logEntryId: string
  studentId: string
  fileName: string
  storageKey: string
  contentType: string
  sizeBytes: number
  uploadedBy: string
  description?: string
  createdAt: string
  downloadUrl?: string
  expiresAt?: string
}

// Storage usage info
export interface StorageUsage {
  usedBytes: number
  limitBytes: number
  usedPercent: number
  fileCount: number
  uploadsEnabled: boolean
  usedMB: number
  limitMB: number
  remainingBytes: number
}

// Upload URL response
export interface UploadURLResponse {
  uploadUrl: string
  workSampleId: string
  storageKey: string
  expiresAt: string
}
