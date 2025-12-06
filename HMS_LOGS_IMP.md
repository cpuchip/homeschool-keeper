# Homeschool Keeper - Implementation Plan

**Generated**: December 6, 2025  
**Status**: Scaffolding Complete → Phase 1 Implementation  
**Reference Project**: [ForKirk](C:\Users\cpuch\Documents\code\stuffleberry\forkirk)

---

## 📊 Current State Assessment

### What's Done (Scaffolded)
| Component | Status | Notes |
|-----------|--------|-------|
| Project structure | ✅ | Backend, frontend, mobile, CI/CD, Docker |
| CI/CD Pipeline | ✅ | GitHub Actions → GHCR → Dokploy |
| Backend Go skeleton | ✅ | Compiles, health endpoint works |
| Vue 3 SPA | ✅ | Builds, routes, static UI shells |
| Flutter app | ✅ | Builds for Windows/Android/iOS |
| SSH tunnel scripts | ✅ | MongoDB access via Dokploy |
| Planning docs | ✅ | 12 comprehensive documents |

### What's NOT Functional
| Component | Issue |
|-----------|-------|
| Backend API endpoints | Only `/api/health` - all CRUD is TODO stubs |
| Authentication | No login/register/JWT - just comments |
| Frontend data binding | Static mockups, no API calls |
| Mobile data layer | No API client, no local DB |

---

## 🏗️ Implementation Phases

Following ForKirk patterns: feature-based packages under `/backend/`, models with bson/json tags, OAuth + cookie sessions.

---

## Phase 1: Backend Core API (Priority: CRITICAL)

### 1.1 Auth Package
**Location**: `backend/auth/`  
**Pattern**: Follow ForKirk `backend/auth/auth.go`

- [ ] **1.1.1** Create `backend/auth/auth.go`
  - Session management with `gorilla/securecookie`
  - Cookie-based session (not JWT for web, keep simple like ForKirk)
  - `InitSession(secret string)`, `SetUser()`, `GetUser()`, `ClearSession()`
  
- [ ] **1.1.2** Create `backend/auth/middleware.go`
  - `RequireAuth` middleware that checks session
  - `OptionalAuth` middleware for public routes
  - Extract user from context

- [ ] **1.1.3** Create `backend/auth/handlers.go`
  - `POST /api/v1/auth/register` - email/password registration
  - `POST /api/v1/auth/login` - email/password login
  - `POST /api/v1/auth/logout` - clear session
  - `GET /api/v1/auth/me` - current user info
  - Password hashing with bcrypt

### 1.2 Models Package
**Location**: `backend/models/`  
**Pattern**: Follow ForKirk `backend/quotes/models.go` (bson + json tags)

- [ ] **1.2.1** Create `backend/models/user.go`
  ```go
  type User struct {
      ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      Email          string             `bson:"email" json:"email"`
      PasswordHash   string             `bson:"passwordHash" json:"-"`
      Name           string             `bson:"name" json:"name"`
      OrganizationID primitive.ObjectID `bson:"organizationId" json:"organizationId"`
      Role           string             `bson:"role" json:"role"` // admin, parent, student
      CreatedAt      time.Time          `bson:"createdAt" json:"createdAt"`
      UpdatedAt      time.Time          `bson:"updatedAt" json:"updatedAt"`
  }
  ```

- [ ] **1.2.2** Create `backend/models/organization.go`
  ```go
  type Organization struct {
      ID              primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      Name            string             `bson:"name" json:"name"`
      HourIncrement   float64            `bson:"hourIncrement" json:"hourIncrement"` // 0.25, 0.5, 1.0
      SchoolYearStart time.Time          `bson:"schoolYearStart" json:"schoolYearStart"`
      SchoolYearEnd   time.Time          `bson:"schoolYearEnd" json:"schoolYearEnd"`
      State           string             `bson:"state" json:"state"` // MO, etc.
      Timezone        string             `bson:"timezone" json:"timezone"`
      CreatedAt       time.Time          `bson:"createdAt" json:"createdAt"`
  }
  ```

- [ ] **1.2.3** Create `backend/models/student.go`
  ```go
  type Student struct {
      ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      OrganizationID primitive.ObjectID `bson:"organizationId" json:"organizationId"`
      Name           string             `bson:"name" json:"name"`
      DateOfBirth    time.Time          `bson:"dateOfBirth" json:"dateOfBirth"`
      GradeLevel     string             `bson:"gradeLevel" json:"gradeLevel"`
      Active         bool               `bson:"active" json:"active"`
      CreatedAt      time.Time          `bson:"createdAt" json:"createdAt"`
      UpdatedAt      time.Time          `bson:"updatedAt" json:"updatedAt"`
  }
  ```

- [ ] **1.2.4** Create `backend/models/subject.go`
  ```go
  type Subject struct {
      ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      OrganizationID primitive.ObjectID `bson:"organizationId" json:"organizationId"`
      Name           string             `bson:"name" json:"name"`
      Type           string             `bson:"type" json:"type"` // core, elective
      TargetHours    float64            `bson:"targetHours" json:"targetHours"`
      Color          string             `bson:"color" json:"color"`
      IsDefault      bool               `bson:"isDefault" json:"isDefault"`
      Active         bool               `bson:"active" json:"active"`
      CreatedAt      time.Time          `bson:"createdAt" json:"createdAt"`
  }
  ```

- [ ] **1.2.5** Create `backend/models/log_entry.go`
  ```go
  type LogEntry struct {
      ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      OrganizationID primitive.ObjectID `bson:"organizationId" json:"organizationId"`
      StudentID      primitive.ObjectID `bson:"studentId" json:"studentId"`
      SubjectID      primitive.ObjectID `bson:"subjectId" json:"subjectId"`
      Date           time.Time          `bson:"date" json:"date"`
      Hours          float64            `bson:"hours" json:"hours"`
      Description    string             `bson:"description" json:"description"`
      Location       string             `bson:"location" json:"location"` // home, field_trip, co_op
      SubmittedBy    primitive.ObjectID `bson:"submittedBy" json:"submittedBy"`
      Status         string             `bson:"status" json:"status"` // approved, pending
      CreatedAt      time.Time          `bson:"createdAt" json:"createdAt"`
      UpdatedAt      time.Time          `bson:"updatedAt" json:"updatedAt"`
  }
  ```

### 1.3 Repository Package
**Location**: `backend/repository/`  
**Pattern**: Follow ForKirk `backend/quotes/store.go`

- [ ] **1.3.1** Create `backend/repository/users.go`
  - `CreateUser(ctx, user)` - with password hashing
  - `GetUserByEmail(ctx, email)` - for login
  - `GetUserByID(ctx, id)` - for session
  - `UpdateUser(ctx, id, update)`

- [ ] **1.3.2** Create `backend/repository/organizations.go`
  - `CreateOrganization(ctx, org)`
  - `GetOrganizationByID(ctx, id)`
  - `UpdateOrganization(ctx, id, update)`

- [ ] **1.3.3** Create `backend/repository/students.go`
  - `CreateStudent(ctx, student)`
  - `GetStudentsByOrg(ctx, orgID)`
  - `GetStudentByID(ctx, id)`
  - `UpdateStudent(ctx, id, update)`
  - `DeleteStudent(ctx, id)` - soft delete

- [ ] **1.3.4** Create `backend/repository/subjects.go`
  - `CreateSubject(ctx, subject)`
  - `GetSubjectsByOrg(ctx, orgID)`
  - `UpdateSubject(ctx, id, update)`
  - `SeedDefaultSubjects(ctx, orgID)` - Reading, Math, etc.

- [ ] **1.3.5** Create `backend/repository/logs.go`
  - `CreateLogEntry(ctx, log)`
  - `GetLogsByOrg(ctx, orgID, filters, pagination)`
  - `GetLogsByStudent(ctx, studentID, dateRange)`
  - `UpdateLogEntry(ctx, id, update)`
  - `DeleteLogEntry(ctx, id)`

### 1.4 Handlers Package
**Location**: `backend/handlers/`

- [ ] **1.4.1** Create `backend/handlers/students.go`
  - `POST /api/v1/students` - create student
  - `GET /api/v1/students` - list students
  - `GET /api/v1/students/{id}` - get student
  - `PATCH /api/v1/students/{id}` - update student
  - `DELETE /api/v1/students/{id}` - soft delete

- [ ] **1.4.2** Create `backend/handlers/subjects.go`
  - `POST /api/v1/subjects`
  - `GET /api/v1/subjects`
  - `PATCH /api/v1/subjects/{id}`
  - `DELETE /api/v1/subjects/{id}`

- [ ] **1.4.3** Create `backend/handlers/logs.go`
  - `POST /api/v1/logs` - create log entry
  - `GET /api/v1/logs` - list with filters (studentId, subjectId, date range)
  - `GET /api/v1/logs/{id}` - single log
  - `PATCH /api/v1/logs/{id}` - update
  - `DELETE /api/v1/logs/{id}` - delete

- [ ] **1.4.4** Create `backend/handlers/stats.go`
  - `GET /api/v1/stats/student/{id}` - hours by subject, totals
  - `GET /api/v1/stats/organization` - all students summary

### 1.5 Wire Up Main.go
- [ ] **1.5.1** Register all routes in `main.go`
- [ ] **1.5.2** Apply auth middleware to protected routes
- [ ] **1.5.3** Add request validation
- [ ] **1.5.4** Update health check with version info

---

## Phase 2: Frontend API Integration

### 2.1 API Client Layer
**Location**: `backend/frontend/src/api/`

- [ ] **2.1.1** Create `students.ts`
  - `getAll()`, `getById(id)`, `create(data)`, `update(id, data)`, `remove(id)`

- [ ] **2.1.2** Create `subjects.ts`
  - `getAll()`, `create(data)`, `update(id, data)`, `remove(id)`

- [ ] **2.1.3** Create `logs.ts`
  - `getAll(filters)`, `getById(id)`, `create(data)`, `update(id, data)`, `remove(id)`

- [ ] **2.1.4** Create `stats.ts`
  - `getStudentStats(id)`, `getOrgStats()`

### 2.2 Pinia Stores
**Location**: `backend/frontend/src/stores/`

- [ ] **2.2.1** Complete `auth.ts` store
  - Connect to real login/register/logout endpoints
  - Persist session properly

- [ ] **2.2.2** Create `students.ts` store
  - State: students array, currentStudent
  - Actions: fetchAll, create, update, delete

- [ ] **2.2.3** Create `subjects.ts` store
  - State: subjects, computed coreSubjects/electiveSubjects

- [ ] **2.2.4** Create `logs.ts` store
  - State: logs, filters, pagination
  - Actions: fetchLogs with date range

- [ ] **2.2.5** Create `stats.ts` store
  - State: studentStats, orgStats

### 2.3 Page Components
**Location**: `backend/frontend/src/pages/`

- [ ] **2.3.1** Wire `LoginPage.vue` to auth store
- [ ] **2.3.2** Wire `RegisterPage.vue` to auth store
- [ ] **2.3.3** Wire `DashboardPage.vue` to stats store
- [ ] **2.3.4** Wire `StudentsPage.vue` to students store
- [ ] **2.3.5** Wire `SubjectsPage.vue` to subjects store
- [ ] **2.3.6** Wire `LogsPage.vue` to logs store
- [ ] **2.3.7** Implement `QuickLogPage.vue` form

### 2.4 Common Components
**Location**: `backend/frontend/src/components/`

- [ ] **2.4.1** Create `components/common/` folder
- [ ] **2.4.2** Create `BaseButton.vue`
- [ ] **2.4.3** Create `BaseInput.vue`
- [ ] **2.4.4** Create `BaseModal.vue`
- [ ] **2.4.5** Create `HourPicker.vue` - increment-aware hour selector

---

## Phase 3: Mobile App Integration

### 3.1 API Client
**Location**: `mobile/lib/core/api/`

- [ ] **3.1.1** Create `api_client.dart` with Dio
- [ ] **3.1.2** Create `auth_api.dart`
- [ ] **3.1.3** Create `students_api.dart`
- [ ] **3.1.4** Create `subjects_api.dart`
- [ ] **3.1.5** Create `logs_api.dart`

### 3.2 Data Models
**Location**: `mobile/lib/models/`

- [ ] **3.2.1** Create models with Freezed
- [ ] **3.2.2** Run `flutter pub run build_runner build`

### 3.3 Riverpod Providers
**Location**: `mobile/lib/providers/`

- [ ] **3.3.1** Create `auth_provider.dart`
- [ ] **3.3.2** Create `students_provider.dart`
- [ ] **3.3.3** Create `subjects_provider.dart`
- [ ] **3.3.4** Create `logs_provider.dart`
- [ ] **3.3.5** Create `stats_provider.dart`

### 3.4 Feature Screens
- [ ] **3.4.1** Wire all screens to providers
- [ ] **3.4.2** Implement forms with validation

---

## Phase 4: Advanced Features (Future)

### 4.1 File Attachments
- [ ] File upload endpoint
- [ ] File encryption at rest
- [ ] Image thumbnails

### 4.2 Export/Reports
- [ ] PDF generation
- [ ] Excel export
- [ ] Compliance reports

### 4.3 Multi-state Compliance
- [ ] State requirement configurations
- [ ] Flexible hour rules

### 4.4 Student Portal
- [ ] Student login with COPPA
- [ ] Approval workflow

---

## 🔧 Development Commands

```powershell
# Backend
cd backend
go run main.go

# Frontend (dev mode)
cd backend/frontend
npm run dev

# Frontend (build for embed)
npm run build

# Mobile
cd mobile
flutter run -d windows
flutter run -d chrome

# SSH tunnel to MongoDB
.\scripts\ssh-mongo-start.ps1
.\scripts\ssh-mongo-stop.ps1
```

---

## 📁 Target Directory Structure

Following ForKirk patterns:

```
homeschool-keeper/
├── backend/
│   ├── auth/
│   │   ├── auth.go          # Session management
│   │   ├── handlers.go      # Login/register handlers
│   │   └── middleware.go    # Auth middleware
│   ├── config/
│   │   └── env.go           # ✅ Already exists
│   ├── db/
│   │   └── mongo.go         # ✅ Already exists
│   ├── handlers/
│   │   ├── students.go
│   │   ├── subjects.go
│   │   ├── logs.go
│   │   └── stats.go
│   ├── models/
│   │   ├── user.go
│   │   ├── organization.go
│   │   ├── student.go
│   │   ├── subject.go
│   │   └── log_entry.go
│   ├── repository/
│   │   ├── users.go
│   │   ├── organizations.go
│   │   ├── students.go
│   │   ├── subjects.go
│   │   └── logs.go
│   ├── frontend/            # ✅ Vue app (embed)
│   ├── main.go              # ✅ Entry point
│   └── Dockerfile           # ✅ Multi-stage build
├── mobile/                  # ✅ Flutter app
├── scripts/                 # ✅ SSH tunnels
├── docs/                    # ✅ Planning docs
├── .github/workflows/       # ✅ CI/CD
└── docker-compose.yml       # ✅ Local dev
```

---

## ✅ Acceptance Criteria for Phase 1

1. User can register with email/password
2. User can login and see their dashboard
3. User can add/edit/remove students
4. User can add/edit/remove subjects
5. User can create log entries (quick log)
6. User can see hour statistics on dashboard
7. All data persists to MongoDB
8. CI/CD deploys successfully to Dokploy

---

## 📝 Notes

- **Auth Strategy**: Using cookie sessions like ForKirk (simpler than JWT for web)
- **Mobile Auth**: Will need token-based auth since mobile can't use cookies easily
- **Hour Increment**: Must respect org setting (0.25, 0.5, 1.0 hours)
- **School Year**: Configurable start/end dates for stats
- **Missouri Default**: 1,000 total, 600 core, 400 at home

---

*Last Updated: December 6, 2025*
