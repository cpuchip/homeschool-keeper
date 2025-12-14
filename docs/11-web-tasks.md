# Web Frontend Development Tasks (Vue 3 + TypeScript)

**Directory**: `/backend/frontend` (embedded in Go binary for production)

---

## Phase 1: Foundation & Core Logging

### 1.1 Project Setup ✅ COMPLETE
- [x] Initialize Vite project with Vue 3 + TypeScript
- [x] Create directory structure:
  ```
  backend/frontend/
  ├── src/
  │   ├── api/
  │   │   ├── client.ts          # Axios instance
  │   │   ├── auth.ts
  │   │   ├── students.ts
  │   │   ├── subjects.ts
  │   │   └── logs.ts
  │   ├── assets/
  │   ├── components/
  │   │   ├── common/
  │   │   ├── forms/
  │   │   └── layout/
  │   ├── composables/
  │   ├── layouts/
  │   ├── pages/
  │   ├── router/
  │   ├── stores/
  │   ├── types/
  │   └── utils/
  ├── public/
  ├── index.html
  ├── package.json
  ├── tsconfig.json
  ├── tailwind.config.js
  ├── vite.config.ts
  └── .env.example
  ```
- [ ] Install dependencies:
  - Vue Router 4
  - Pinia
  - Axios
  - TailwindCSS + forms plugin
  - Headless UI
  - VueUse
  - date-fns
  - zod (validation)
- [ ] Configure Tailwind with custom theme colors
- [ ] Set up path aliases (@/ → src/)
- [ ] Create .env.example with API_BASE_URL

### 1.2 TypeScript Types
- [ ] Create `/src/types/index.ts` with all interfaces:
  - User, Organization, Student, Subject, LogEntry, Attachment
- [ ] Create API response wrapper types
- [ ] Create form input types (separate from API types)
- [ ] Generate types from OpenAPI spec (optional: openapi-typescript)

### 1.3 API Client Layer
- [ ] **src/api/client.ts**
  - Create Axios instance with baseURL from env
  - Request interceptor: attach JWT from localStorage
  - Response interceptor: handle 401 → refresh token
  - Response interceptor: handle errors uniformly
- [ ] **src/api/auth.ts**
  - register(email, password, name)
  - login(email, password)
  - refresh()
  - logout()
- [ ] **src/api/students.ts**
  - getAll(), getById(id), create(data), update(id, data), delete(id)
- [ ] **src/api/subjects.ts**
  - getAll(), create(data), update(id, data), delete(id)
- [ ] **src/api/logs.ts**
  - getAll(filters), getById(id), create(data), update(id, data), delete(id)
- [ ] **src/api/stats.ts**
  - getStudentStats(id), getOrgStats()

### 1.4 Pinia Stores
- [ ] **src/stores/auth.ts**
  - State: user, token, isAuthenticated
  - Actions: login, logout, refreshToken, fetchUser
  - Persist token to localStorage
- [ ] **src/stores/organization.ts**
  - State: organization, settings
  - Actions: fetch, updateSettings
- [ ] **src/stores/students.ts**
  - State: students, currentStudent
  - Actions: fetchAll, fetchOne, create, update, delete
- [ ] **src/stores/subjects.ts**
  - State: subjects, coreSubjects, electiveSubjects (getters)
- [ ] **src/stores/logs.ts**
  - State: logs, filters, pagination
  - Actions: fetchLogs, createLog, updateLog, deleteLog

### 1.5 Router Setup
- [ ] **src/router/index.ts**
  - Public routes: /login, /register
  - Protected routes: /dashboard, /students, /logs, /settings
  - Navigation guard: check auth, redirect to login
- [ ] Lazy-load all page components
- [ ] 404 catch-all route

### 1.6 Layout Components
- [ ] **AppLayout.vue** - Main authenticated layout
  - Sidebar navigation
  - Top header with user menu
  - Main content area
- [ ] **AuthLayout.vue** - Login/register pages
  - Centered card layout
- [ ] **Sidebar.vue**
  - Nav links: Dashboard, Quick Log, Students, Subjects, Logs, Settings
  - Collapsible on mobile
- [ ] **TopNav.vue**
  - Organization name
  - User dropdown (profile, logout)

### 1.7 Common Components
- [ ] **BaseButton.vue** - Primary, secondary, danger variants
- [ ] **BaseInput.vue** - Text input with label, error state
- [ ] **BaseSelect.vue** - Dropdown with label
- [ ] **BaseModal.vue** - Dialog wrapper
- [ ] **BaseCard.vue** - Content card
- [ ] **LoadingSpinner.vue**
- [ ] **ErrorAlert.vue**
- [ ] **EmptyState.vue** - For empty lists
- [ ] **HourPicker.vue** - Custom hour selector with increment steps

### 1.8 Auth Pages
- [ ] **LoginPage.vue**
  - Email/password form
  - Validation with zod
  - Error handling
  - Link to register
- [ ] **RegisterPage.vue**
  - Name, email, password, confirm password
  - Password strength indicator
  - Terms acceptance checkbox
  - Redirect to dashboard on success

### 1.9 Dashboard Page
- [ ] **DashboardPage.vue**
  - Today's date display
  - Quick stats cards (today's hours per student)
  - Prominent "Quick Log" button
  - Week progress bars per student
  - Year progress (total/core/home hours)
  - Recent log entries list

### 1.10 Quick Log Feature ⭐ (Critical Path)
- [ ] **QuickLogPage.vue** or **QuickLogModal.vue**
  - Student dropdown (default to first/last used)
  - Subject dropdown with color indicators
  - **HourPicker component**:
    - Increment/decrement buttons
    - Direct input
    - Preset quick buttons (0.5, 1, 1.5, 2, 3)
    - Respects org's hourIncrement setting
  - Date picker (defaults to today)
  - Description textarea
  - Photo upload button (Phase 2)
  - "Save" and "Save & Add Another" buttons
- [ ] Auto-focus on subject field
- [ ] Keyboard shortcuts (Enter to save)
- [ ] Success toast notification
- [ ] Remember last student selection

### 1.11 Student Management
- [ ] **StudentsListPage.vue**
  - List of students with avatars
  - Quick stats per student
  - Add student button
- [ ] **StudentDetailPage.vue**
  - Student info header
  - Hour progress charts
  - Subject breakdown
  - Recent logs for this student
- [ ] **StudentFormModal.vue**
  - Create/edit student form

### 1.12 Subject Management
- [ ] **SubjectsPage.vue**
  - List of subjects (core vs elective sections)
  - Add subject button
- [ ] **SubjectFormModal.vue**
  - Name, type, target hours, color picker

### 1.13 Log History
- [ ] **LogsListPage.vue**
  - Filter bar: student, subject, date range
  - Sortable table/list
  - Pagination
  - Click to edit
  - Delete with confirmation
- [ ] **LogEditModal.vue**
  - Edit existing log entry

### 1.14 Settings Page
- [ ] **SettingsPage.vue**
  - Organization settings section:
    - Hour increment (0.25, 0.5, 1.0 radio)
    - School year start/end dates
    - Timezone selector
  - Account settings section:
    - Name, email
    - Change password
  - Danger zone:
    - Delete account

---

## Phase 2: File Uploads & Export

### 2.1 Attachment Upload
- [ ] Add file input to QuickLogPage
- [ ] Drag-and-drop zone component
- [ ] Image preview thumbnails
- [ ] Upload progress indicator
- [ ] Attach to log entry on save

### 2.2 Attachment Viewer
- [ ] View attachments on log detail
- [ ] Image lightbox component
- [ ] Download button for non-images
- [ ] Delete attachment

### 2.3 Export UI
- [ ] **ExportPage.vue**
  - Student selector
  - Date range picker
  - Export format buttons (PDF, Excel, ZIP)
  - Download progress

---

## Phase 3: Curriculum Planning

### 3.1 Topics Management
- [ ] **TopicsPage.vue**
- [ ] **TopicFormModal.vue**
- [ ] Topic detail with planned hours vs logged

### 3.2 Planner Views
- [ ] **WeeklyPlannerPage.vue**
  - Calendar grid
  - Drag tasks to days
- [ ] **DailyPlanPage.vue**
  - Today's tasks checklist
  - Complete → creates log entry

---

## Phase 4: Student Portal & Reports

### 4.1 Reports Dashboard
- [ ] **ReportsPage.vue**
  - Compliance progress
  - Subject breakdown charts
  - Drill-down capabilities

### 4.2 Student Login (separate routes)
- [ ] Student-specific dashboard
- [ ] Submit log entry (pending approval)
- [ ] View own history

---

## Testing

### Unit Tests (Vitest)
- [ ] All Pinia stores
- [ ] API client interceptors
- [ ] Utility functions
- [ ] Form validation

### Component Tests (Vue Test Utils)
- [ ] HourPicker component
- [ ] Form components
- [ ] Modal components

### E2E Tests (Playwright)
- [ ] Register → Login flow
- [ ] Create student flow
- [ ] Quick log entry flow
- [ ] Full CRUD operations

---

## DevOps
- [ ] Dockerfile for production build
- [ ] nginx.conf for SPA routing
- [ ] Environment variable injection at build time
- [ ] GitHub Actions: lint, test, build
