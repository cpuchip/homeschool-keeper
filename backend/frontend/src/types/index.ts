// User & Auth
export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'student'
  organizationId: string
}

export interface AuthResponse {
  user: User
  accessToken: string
  refreshToken: string
  expiresIn: number
}

// Organization
export interface OrganizationSettings {
  hourIncrement: 0.25 | 0.5 | 1.0
  schoolYearStart: string
  schoolYearEnd: string
  timezone: string
}

export interface Organization {
  id: string
  name: string
  settings: OrganizationSettings
  createdAt: string
}

// Student
export interface Student {
  id: string
  organizationId: string
  name: string
  dateOfBirth: string
  gradeLevel: string
  active: boolean
}

export interface StudentWithStats extends Student {
  stats: {
    totalHours: number
    coreHours: number
    electiveHours: number
    homeHours: number
  }
}

// Subject
export interface Subject {
  id: string
  organizationId: string
  name: string
  type: 'core' | 'elective'
  targetHours: number
  color: string
}

// Log Entry
export interface LogEntry {
  id: string
  organizationId: string
  studentId: string
  subjectId: string
  date: string
  hours: number
  description: string
  location: 'home' | 'other'
  status: 'pending' | 'approved'
  submittedBy: string
  approvedBy?: string
  createdAt: string
  attachments: Attachment[]
}

export interface CreateLogEntry {
  studentId: string
  subjectId: string
  date: string
  hours: number
  description: string
  location: 'home' | 'other'
}

// Attachment
export interface Attachment {
  id: string
  logEntryId: string
  filename: string
  mimeType: string
  size: number
  thumbnail?: string
}

// Stats
export interface StudentStats {
  studentId: string
  schoolYear: string
  totalHours: number
  coreHours: number
  electiveHours: number
  homeHours: number
  bySubject: SubjectHours[]
  requirements: {
    totalRequired: number
    coreRequired: number
    homeRequired: number
    totalRemaining: number
    coreRemaining: number
    homeRemaining: number
  }
}

export interface SubjectHours {
  subjectId: string
  name: string
  type: 'core' | 'elective'
  hours: number
  targetHours: number
  percentComplete: number
}

// API Error
export interface ApiError {
  error: {
    code: string
    message: string
    details?: Array<{
      field: string
      message: string
    }>
  }
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
