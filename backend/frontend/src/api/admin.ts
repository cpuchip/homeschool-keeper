import client from './client'

export interface DashboardStats {
  totalFamilies: number
  totalOrgs: number
  totalStudents: number
  totalLogs: number
  totalWorkSamples: number
  totalStorageBytes: number
  totalStorageMB: number
  syncEnabled: number
  uploadsEnabled: number
  generatedAt: string
}

export interface FamilySummary {
  id: string
  name: string
  state: string
  studentCount: number
  logCount: number
  syncEnabled: boolean
  uploadsEnabled: boolean
  storageUsedMB: number
  organizationIds: string[]
  createdAt: string
}

export interface PremiumFeatures {
  syncEnabled: boolean
  uploadsEnabled: boolean
  storageLimitBytes: number
  storageUsedBytes: number
}

export interface StudentInfo {
  id: string
  name: string
  active: boolean
  logCount: number
}

export interface OrgInfo {
  id: string
  name: string
}

export interface FamilyDetail {
  id: string
  name: string
  state: string
  hourIncrement: number
  premium: PremiumFeatures
  students: StudentInfo[]
  organizations: OrgInfo[]
  logCount: number
  workSampleCount: number
  storageUsedBytes: number
  storageUsedMB: number
  createdAt: string
  updatedAt: string
}

export interface OrgSummary {
  id: string
  name: string
  description: string
  familyCount: number
  studentCount: number
  logCount: number
  createdAt: string
}

export interface FamilyInfo {
  id: string
  name: string
  studentCount: number
}

export interface OrgDetail {
  id: string
  name: string
  description: string
  families: FamilyInfo[]
  familyCount: number
  studentCount: number
  logCount: number
  createdAt: string
  updatedAt: string
}

export interface StorageSummary {
  familyId: string
  familyName: string
  fileCount: number
  totalBytes: number
  totalMB: number
  uploadsEnabled: boolean
}

export interface UpdatePremiumRequest {
  syncEnabled?: boolean
  uploadsEnabled?: boolean
  storageLimitBytes?: number
}

// Get dashboard stats
export async function getDashboardStats(): Promise<DashboardStats> {
  const response = await client.get('/v1/admin/stats')
  return response.data
}

// Get all families
export async function getFamilies(): Promise<FamilySummary[]> {
  const response = await client.get('/v1/admin/families')
  return response.data
}

// Get family detail
export async function getFamily(id: string): Promise<FamilyDetail> {
  const response = await client.get(`/v1/admin/families/${id}`)
  return response.data
}

// Update family premium settings
export async function updateFamilyPremium(id: string, settings: UpdatePremiumRequest): Promise<void> {
  await client.patch(`/v1/admin/families/${id}/premium`, settings)
}

// Get all organizations
export async function getOrganizations(): Promise<OrgSummary[]> {
  const response = await client.get('/v1/admin/orgs')
  return response.data
}

// Get organization detail
export async function getOrganization(id: string): Promise<OrgDetail> {
  const response = await client.get(`/v1/admin/orgs/${id}`)
  return response.data
}

// Get storage stats
export async function getStorageStats(): Promise<StorageSummary[]> {
  const response = await client.get('/v1/admin/storage')
  return response.data
}

// Telemetry stats types
export interface TelemetryStats {
  totalEvents: number
  uniqueInstalls: number
  activeToday: number
  activeThisWeek: number
  activeThisMonth: number
  platformBreakdown: Record<string, number>
  eventBreakdown: Record<string, number>
  versionBreakdown: Record<string, number>
}

export interface DailyCount {
  date: string
  count: number
}

// Get telemetry stats
export async function getTelemetryStats(): Promise<TelemetryStats> {
  const response = await client.get('/v1/admin/telemetry')
  return response.data
}

// Get daily active users
export async function getTelemetryDAU(): Promise<DailyCount[]> {
  const response = await client.get('/v1/admin/telemetry/dau')
  return response.data
}
