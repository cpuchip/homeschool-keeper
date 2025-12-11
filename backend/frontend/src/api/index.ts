// API client exports
// All API modules re-exported for convenient imports

export { authApi } from './auth'
export { studentsApi } from './students'
export { subjectsApi } from './subjects'
export { logsApi } from './logs'
export { statsApi } from './stats'
export { onboardingApi } from './onboarding'
export { locationsApi } from './locations'

// Also export the base client for advanced use cases
export { default as api } from './client'
