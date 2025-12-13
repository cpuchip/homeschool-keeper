# Home School Logs - Implementation Plan

**App Name**: Home School Logs  
**Domain**: hmslogs.com  
**Database**: hmslogs (MongoDB)  
**Generated**: December 6, 2025  
**Last Updated**: December 13, 2025  
**Status**: Phase 1B Complete → Phase 2 (Beta Testing)  
**Reference Project**: [ForKirk](C:\Users\cpuch\Documents\code\stuffleberry\forkirk)

---

## 📋 Confirmed Decisions (from Q&A - Final)

### Authentication
| Decision | Value |
|----------|-------|
| Web Auth | Email/Password with cookie sessions (Google OAuth Phase 2) |
| Mobile Auth | JWT tokens (standard approach) |
| Session Duration | 30 days |
| Signup Model | **Adults-only signup** - parents create student accounts from within family portal |
| COPPA | **Not triggered** - parents enter all student data, not children (see COPPA section below) |

### User Model
| Decision | Value |
|----------|-------|
| Roles | admin, parent/adult, student |
| Signup | Adults only - students cannot self-register |
| Student Accounts | Created by parents within family portal (username/password or email invite) |
| Multi-Family | Yes - families can join organizations (co-ops) |
| Data Ownership | **Family-first with org overlay** - logs always belong to family |
| Org Exit | Clone/snapshot data to family when leaving org (both keep copies) |

### Hour Logging
| Decision | Value |
|----------|-------|
| Default Increment | 0.25 hours (15 minutes), configurable per family |
| Log Status | Auto-approved by default, configurable per family/org |
| Locations | Managed collection per family, quick-add on the fly |
| Org Logging | Creates individual copies per student's family (write-through) |

### Subjects & School Year
| Decision | Value |
|----------|-------|
| Default Subjects | Ask during onboarding (Missouri defaults as starting point) |
| Target Hours | Optional per-subject targets, configurable per family |
| School Year | Fully configurable per family during onboarding |
| Multi-Year | Full history with year switching, archivable/read-only |

### UI/Branding
| Decision | Value |
|----------|-------|
| App Name | Home School Logs |
| Theme | Blue/teal, elegant and simple |
| Domain | hmslogs.com (root) |

### Mobile
| Decision | Value |
|----------|-------|
| Platforms | Both Android & iOS (iOS CI disabled until Mac available) |
| Offline | Basic offline with sync (Phase 1B), full offline (Phase 2) |

### Quality & Security
| Decision | Value |
|----------|-------|
| Testing | Testing-first, 60%+ coverage, critical paths higher |
| Test Stack | Go testify, testcontainers-go, Vitest, Playwright, Hurl, Flutter test |
| Encryption | AES-256 for all data at rest, TLS in transit |
| Backups | Hourly for 24h, daily for 30 days (investigate Dokploy options) |
| Data Isolation | Strict family/org boundaries, thoroughly tested |

### Timeline
| Decision | Value |
|----------|-------|
| Pace | No rush - do it right |
| Priority | Auth → Students → Subjects → Logs → Stats → Dashboard → Mobile |

---

## 🏛️ Architecture: Family-First Data Model

### Core Principle
**Family is the atomic unit of data ownership.** Every student, log, and subject belongs to exactly one family. Organizations are optional overlays for co-op features.

### Entity Relationships
```
Family (core unit)
├── Users (admin, parent roles)
├── Students
├── Subjects
├── Locations
├── Log Entries (always owned by family)
└── School Years

Organization (optional co-op)
├── Member Families (many-to-many)
├── Shared Subjects (optional)
└── Org-level Log References (not ownership)
```

### Log Ownership Pattern (Write-Through)

When an org admin logs hours for students from multiple families:

**Scenario**: Family A's admin teaches Math at co-op for students A.01 and B.01

**What happens**:
1. Admin submits one "org log" for the session
2. System creates **individual LogEntry records** for each student, owned by their family
3. Each family's log has `familyId` set to their family
4. Each log has `organizationId` set to show it was a co-op activity
5. Org can query all logs with their `organizationId` for reporting

**When Family B leaves the org**:
1. Family B's logs remain unchanged (they own them via `familyId`)
2. Org loses visibility to Family B's logs (filter by `organizationId` excludes them)
3. Any org-level metadata (teacher name, etc.) is snapshotted into Family B's logs at exit time
4. No data loss for either party

### Data Isolation Rules

| Query Type | Filter Applied |
|------------|----------------|
| Family viewing their logs | `familyId == user.familyId` |
| Org admin viewing org logs | `organizationId == org.id` AND family is still member |
| Stats calculation | Always scoped to `familyId` (family's own numbers) |
| Cross-family access | **NEVER** - enforced at repository layer |

### Encryption Strategy

**Tiered Approach** (balancing security vs. performance):

| Tier | Data | Encryption |
|------|------|------------|
| **Tier 1** (Always) | Passwords | bcrypt hash (not reversible) |
| **Tier 2** (PII) | DOB, addresses, file attachments | AES-256 field-level encryption |
| **Tier 3** (Content) | Log descriptions, notes | AES-256 field-level encryption |
| **Tier 4** (Metadata) | Names, timestamps, IDs | Disk encryption (server-level) |

**Key Management**: 
- Per-family encryption key derived from master key + familyId
- Master key stored in environment variable (not in DB)
- Enables data portability (family can decrypt their own data on export)

### COPPA & FERPA Analysis (Updated Dec 6, 2025)

#### COPPA (Children's Online Privacy Protection Act)

**Status: Not Triggered** ✅

Our parent-controlled model avoids COPPA requirements:

| Scenario | COPPA Status | Reason |
|----------|--------------|--------|
| Parent signs up | ✅ Not triggered | Adult providing own info |
| Parent adds student info | ✅ Not triggered | Per FTC FAQ A.8: "COPPA only applies to info collected **from children**" |
| Parent creates student login | ✅ Not triggered | Parent is the one creating the account |
| Student logs in (read-only) | ⚠️ Minimal risk | Only persistent identifiers - "internal operations" exception |
| Student logs in and enters data | ✅ Covered | Parent already consented by creating the account |

**Key Implementation Points**:
1. **Adults-only public signup** - No direct child registration
2. **Parent creates student accounts** - From within authenticated family portal
3. **Parent enters all student PII** - Name, DOB (optional), grade level
4. **No age-gating at signup** - Only adults can sign up
5. **DateOfBirth is optional** - Parent's choice to track, not legal requirement

**Student Account Creation Flow**:
```
Parent (logged in) → Family Portal → Students → Create Student Login
  ├── Option A: Set username + password directly
  └── Option B: Send email invite to student's email address
```

**Still Required**:
- Clear privacy policy explaining data practices
- Statement that parents control all student accounts  
- Data retention and deletion policies
- Standard security practices (encryption, access control)

#### FERPA (Family Educational Rights and Privacy Act)

**Status: Not Applicable** ✅

FERPA applies to **educational agencies receiving federal funds**:
- We're a private app used by families directly
- No federal funding or school contracts
- FERPA would only apply if schools/co-ops contract with us AND receive federal funds

**If supporting school/co-op integrations later**:
- May need Data Processing Agreement (DPA) templates
- Schools would be "school officials" under FERPA
- Research state student privacy laws (SOPIPA, etc.)

---

## 📊 Current State Assessment

### What's Done (Scaffolded)
| Component | Status | Notes |
|-----------|--------|-------|
| Project structure | ✅ | Backend, frontend, mobile, CI/CD, Docker |
| CI/CD Pipeline | ✅ | GitHub Actions → GHCR → Dokploy |
| Backend Go skeleton | ✅ | Compiles, health endpoint works |
| Vue 3 SPA | ✅ | Builds, routes, static UI shells |
| Flutter app | ✅ | Builds for Windows/Android |
| SSH tunnel scripts | ✅ | MongoDB access via Dokploy |
| Planning docs | ✅ | 12 comprehensive documents |

### What's NOT Functional
| Component | Issue |
|-----------|-------|
| Backend API endpoints | Only `/api/health` - all CRUD is TODO stubs |
| Authentication | No login/register - just comments |
| Frontend data binding | Static mockups, no API calls |
| Mobile data layer | No API client, no local DB |
| Tests | No tests exist yet |

---

## 🏗️ Implementation Phases

### Phase 1A: MVP Core (Current Focus)

**Goal**: Working web app with auth, students, subjects, logs, and basic stats.

**Scope Decisions**:
- Single family model for simplicity (schema ready for multi-family)
- Email/password auth only (Google OAuth in Phase 2)
- Web only (mobile in Phase 1B)
- Basic locations (home, field_trip, co_op, online, other)
- Missouri defaults for subjects during onboarding

---

## Phase 1A Tasks

### 1.1 Testing Infrastructure (Do First!)
**Rationale**: Testing-first approach as requested

- [x] **1.1.1** Set up Go test structure *(Completed Dec 7, 2025)*
  - `backend/*_test.go` files
  - Add `testify` to go.mod
  - Create test MongoDB container helper (testutil package)

- [ ] **1.1.2** Set up Vue/Vitest *(Deferred - Playwright E2E covers critical paths)*
  - Configure vitest in `backend/frontend/`
  - Add vue-test-utils
  - Create test utilities for stores/components

- [x] **1.1.3** Set up Playwright E2E *(Completed Dec 8, 2025)*
  - Install playwright in `backend/frontend/`
  - Create basic E2E test structure (15 smoke tests)
  - Added test scripts: `npm run test:e2e`, `test:e2e:ui`, `test:e2e:headed`
  - Tests cover: auth, onboarding, dashboard, logs, students, subjects, settings

- [ ] **1.1.4** Set up Flutter tests *(Deferred to Phase 1B)*
  - Organize `mobile/test/` structure
  - Create mock providers for testing

### 1.2 Crypto Package (Foundation for PII Protection)
**Location**: `backend/crypto/`  
**Purpose**: Application-level field encryption for PII (free, no enterprise deps)

- [x] **1.2.1** Create `backend/crypto/crypto.go` *(Completed Dec 7, 2025)*
  ```go
  package crypto
  
  // DeriveKey creates a per-family key from master key + familyId
  // Uses SHA-256 to derive AES-256 key (32 bytes)
  func DeriveKey(masterKey string, familyID string) []byte
  
  // Encrypt encrypts plaintext using AES-256-GCM
  // Returns base64-encoded ciphertext (includes nonce)
  func Encrypt(plaintext string, key []byte) (string, error)
  
  // Decrypt decrypts base64 ciphertext using AES-256-GCM
  func Decrypt(ciphertext string, key []byte) (string, error)
  ```
  - Uses Go standard library only (`crypto/aes`, `crypto/cipher`, `crypto/sha256`)
  - AES-256-GCM for authenticated encryption
  - Per-family key derivation (SHA256 of masterKey + familyId)
  - **Tests**: Encrypt/decrypt roundtrip, wrong key fails, empty string handling

- [x] **1.2.2** Create `backend/crypto/fields.go` *(Completed Dec 7, 2025)*
  ```go
  // EncryptField encrypts a field value for storage
  // Returns empty string if input is empty (nil-safe)
  func EncryptField(value string, masterKey string, familyID string) (string, error)
  
  // DecryptField decrypts a stored field value
  // Returns empty string if input is empty (nil-safe)  
  func DecryptField(ciphertext string, masterKey string, familyID string) (string, error)
  
  // EncryptTime encrypts a time.Time for storage (RFC3339 format)
  func EncryptTime(t *time.Time, masterKey string, familyID string) (string, error)
  
  // DecryptTime decrypts a stored time string back to time.Time
  func DecryptTime(ciphertext string, masterKey string, familyID string) (*time.Time, error)
  ```
  - Helper functions for common field types
  - Nil-safe (handles empty/nil gracefully)
  - **Tests**: Time roundtrip, nil handling, invalid ciphertext

- [x] **1.2.3** Add `ENCRYPTION_MASTER_KEY` to config *(Completed Dec 7, 2025)*
  - Add to `backend/config/env.go`
  - Document in `.env.example`
  - Minimum 32 characters, validated at startup

### 1.3 Auth Package
**Location**: `backend/auth/`  
**Pattern**: Follow ForKirk `backend/auth/auth.go`

- [x] **1.3.1** Create `backend/auth/session.go` *(Completed Dec 7, 2025)*
  - Session management with `gorilla/securecookie`
  - Cookie-based session (30-day expiry)
  - `InitSession(secret string)`, `SetUser()`, `GetUser()`, `ClearSession()`
  - **Tests**: Session encoding/decoding, expiry

- [x] **1.3.2** Create `backend/auth/password.go` *(Completed Dec 7, 2025)*
  - `HashPassword(password string)` - bcrypt cost 12
  - `CheckPassword(hash, password string)` - timing-safe comparison
  - **Tests**: Hash/check roundtrip, invalid password rejection

- [x] **1.3.3** Create `backend/auth/middleware.go` *(Completed Dec 7, 2025)*
  - `RequireAuth` middleware that checks session
  - `OptionalAuth` middleware for public routes
  - Extract user from context with `GetUserFromContext(ctx)`
  - **Tests**: Middleware with/without valid session

- [x] **1.3.4** Auth handlers moved to `backend/handlers/auth.go` *(Completed Dec 7, 2025)*
  - `POST /api/v1/auth/register` - email/password registration
    - Creates user + family in one transaction
    - Seeds default subjects based on onboarding selections
  - `POST /api/v1/auth/login` - email/password login
  - `POST /api/v1/auth/logout` - clear session
  - `GET /api/v1/auth/me` - current user info
  - **Tests**: Register flow, login flow, session validation

### 1.4 Models Package
**Location**: `backend/models/`  
**Pattern**: Follow ForKirk `backend/quotes/models.go` (bson + json tags)

- [x] **1.4.1** Create `backend/models/user.go` *(Completed Dec 7, 2025)*
  ```go
  type User struct {
      ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      Email          string             `bson:"email" json:"email"`
      PasswordHash   string             `bson:"passwordHash" json:"-"`
      Name           string             `bson:"name" json:"name"`
      FamilyID       primitive.ObjectID `bson:"familyId" json:"familyId"`
      Role           string             `bson:"role" json:"role"` // admin, parent, student
      CreatedAt      time.Time          `bson:"createdAt" json:"createdAt"`
      UpdatedAt      time.Time          `bson:"updatedAt" json:"updatedAt"`
  }
  ```

- [x] **1.4.2** Create `backend/models/family.go` *(Completed Dec 7, 2025)*
  ```go
  // Family is the core unit - every user, student, and log belongs to a family
  // In Phase 1A, Family = Organization (1:1), but schema supports multi-family orgs
  type Family struct {
      ID              primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
      Name            string              `bson:"name" json:"name"`
      OrganizationID  *primitive.ObjectID `bson:"organizationId,omitempty" json:"organizationId,omitempty"` // nil = standalone family
      HourIncrement   float64             `bson:"hourIncrement" json:"hourIncrement"` // 0.25 default
      SchoolYearStart time.Time           `bson:"schoolYearStart" json:"schoolYearStart"`
      SchoolYearEnd   time.Time           `bson:"schoolYearEnd" json:"schoolYearEnd"`
      State           string              `bson:"state" json:"state"` // MO, etc.
      Timezone        string              `bson:"timezone" json:"timezone"`
      Settings        FamilySettings      `bson:"settings" json:"settings"`
      CreatedAt       time.Time           `bson:"createdAt" json:"createdAt"`
      UpdatedAt       time.Time           `bson:"updatedAt" json:"updatedAt"`
  }

  type FamilySettings struct {
      AutoApproveLogs     bool `bson:"autoApproveLogs" json:"autoApproveLogs"`         // default: true
      RequireSubjectGoals bool `bson:"requireSubjectGoals" json:"requireSubjectGoals"` // default: false
  }
  ```

- [x] **1.4.3** Create `backend/models/organization.go` *(Completed Dec 7, 2025)*
  ```go
  // Organization represents a co-op or group of families
  // Phase 1A: Not used, but schema ready
  type Organization struct {
      ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      Name        string             `bson:"name" json:"name"`
      Description string             `bson:"description" json:"description"`
      CreatedBy   primitive.ObjectID `bson:"createdBy" json:"createdBy"`
      CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
  }
  ```

- [x] **1.4.4** Create `backend/models/student.go` *(Completed Dec 7, 2025)*
  ```go
  type Student struct {
      ID             primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
      FamilyID       primitive.ObjectID  `bson:"familyId" json:"familyId"`
      Name           string              `bson:"name" json:"name"`
      DateOfBirthEnc string              `bson:"dateOfBirthEnc,omitempty" json:"-"`      // Encrypted, never sent to client
      DateOfBirth    *time.Time          `bson:"-" json:"dateOfBirth,omitempty"`         // Decrypted in app, optional
      GradeLevel     string              `bson:"gradeLevel" json:"gradeLevel"`
      UserID         *primitive.ObjectID `bson:"userId,omitempty" json:"userId,omitempty"` // nil = no login, set when parent creates student account
      Active         bool                `bson:"active" json:"active"`
      CreatedAt      time.Time           `bson:"createdAt" json:"createdAt"`
      UpdatedAt      time.Time           `bson:"updatedAt" json:"updatedAt"`
  }
  // Note: DateOfBirth is OPTIONAL - parent's choice to track
  // COPPA not triggered because parents enter all student info
  // UserID links to User record when parent creates student login
  ```

- [x] **1.4.5** Create `backend/models/subject.go` *(Completed Dec 7, 2025)*
  ```go
  type Subject struct {
      ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      FamilyID    primitive.ObjectID `bson:"familyId" json:"familyId"`
      Name        string             `bson:"name" json:"name"`
      Type        string             `bson:"type" json:"type"` // core, elective
      TargetHours *float64           `bson:"targetHours,omitempty" json:"targetHours,omitempty"` // optional
      Color       string             `bson:"color" json:"color"`
      IsDefault   bool               `bson:"isDefault" json:"isDefault"`
      Active      bool               `bson:"active" json:"active"`
      CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
  }
  ```

- [x] **1.4.6** Create `backend/models/log_entry.go` *(Completed Dec 7, 2025)*
  ```go
  type LogEntry struct {
      ID             primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
      FamilyID       primitive.ObjectID  `bson:"familyId" json:"familyId"`           // always set
      OrganizationID *primitive.ObjectID `bson:"organizationId,omitempty" json:"organizationId,omitempty"` // for co-op activities
      StudentID      primitive.ObjectID  `bson:"studentId" json:"studentId"`
      SubjectID      primitive.ObjectID  `bson:"subjectId" json:"subjectId"`
      Date           time.Time           `bson:"date" json:"date"`
      Hours          float64             `bson:"hours" json:"hours"`
      Description    string              `bson:"description" json:"description"`
      LocationType   string              `bson:"locationType" json:"locationType"` // home, field_trip, co_op, online, other
      LocationName   string              `bson:"locationName,omitempty" json:"locationName,omitempty"` // e.g., "Science Museum"
      SubmittedBy    primitive.ObjectID  `bson:"submittedBy" json:"submittedBy"`
      Status         string              `bson:"status" json:"status"` // approved, pending
      SchoolYear     string              `bson:"schoolYear" json:"schoolYear"` // "2024-2025"
      CreatedAt      time.Time           `bson:"createdAt" json:"createdAt"`
      UpdatedAt      time.Time           `bson:"updatedAt" json:"updatedAt"`
  }
  ```

- [x] **1.4.7** Create `backend/models/location.go` *(Completed Dec 7, 2025)*
  ```go
  // Location represents a saved location for quick selection
  type Location struct {
      ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
      FamilyID  primitive.ObjectID `bson:"familyId" json:"familyId"`
      Type      string             `bson:"type" json:"type"` // field_trip, co_op, other
      Name      string             `bson:"name" json:"name"` // "Science Museum"
      Address   string             `bson:"address,omitempty" json:"address,omitempty"`
      CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
  }
  ```

### 1.5 Repository Package
**Location**: `backend/repository/`  
**Pattern**: Follow ForKirk `backend/quotes/store.go`

- [x] **1.5.1** Create `backend/repository/repository.go` *(Completed Dec 7, 2025)*
  - Common interface and MongoDB collection helpers
  - Context timeout wrappers
  - **Tests**: Collection access, context handling

- [x] **1.5.2** Create `backend/repository/users.go` *(Completed Dec 7, 2025)*
  - `CreateUser(ctx, user)` - with email uniqueness check
  - `GetUserByEmail(ctx, email)` - for login
  - `GetUserByID(ctx, id)` - for session
  - `UpdateUser(ctx, id, update)`
  - **Tests**: CRUD operations, duplicate email handling

- [x] **1.5.3** Create `backend/repository/families.go` *(Completed Dec 7, 2025)*
  - `CreateFamily(ctx, family)`
  - `GetFamilyByID(ctx, id)`
  - `UpdateFamily(ctx, id, update)`
  - `GetFamilyWithUsers(ctx, id)` - includes users for display
  - **Tests**: CRUD, settings updates

- [x] **1.5.4** Create `backend/repository/students.go` *(Completed Dec 7, 2025)*
  - `CreateStudent(ctx, student)`
  - `GetStudentsByFamily(ctx, familyID)`
  - `GetStudentByID(ctx, id)`
  - `UpdateStudent(ctx, id, update)`
  - `SoftDeleteStudent(ctx, id)` - sets active=false
  - **Tests**: CRUD, soft delete, family isolation

- [x] **1.5.5** Create `backend/repository/subjects.go` *(Completed Dec 7, 2025)*
  - `CreateSubject(ctx, subject)`
  - `GetSubjectsByFamily(ctx, familyID)`
  - `UpdateSubject(ctx, id, update)`
  - `SeedDefaultSubjects(ctx, familyID, selectedSubjects)` - from onboarding
  - **Tests**: CRUD, seeding

- [x] **1.5.6** Create `backend/repository/logs.go` *(Completed Dec 7, 2025)*
  - `CreateLogEntry(ctx, log)`
  - `GetLogsByFamily(ctx, familyID, filters, pagination)`
  - `GetLogsByStudent(ctx, studentID, dateRange)`
  - `UpdateLogEntry(ctx, id, update)`
  - `DeleteLogEntry(ctx, id)`
  - **Tests**: CRUD, filtering, date range queries

- [x] **1.5.7** Stats functions in `backend/repository/logs.go` *(Completed Dec 7, 2025)*
  - `GetStudentStats(ctx, studentID, schoolYear)` - aggregation
  - `GetFamilyStats(ctx, familyID, schoolYear)` - all students
  - **Tests**: Aggregation accuracy

### 1.6 Handlers Package
**Location**: `backend/handlers/`

- [x] **1.6.1** Create `backend/handlers/helpers.go` *(Completed Dec 7, 2025)*
  - JSON response helpers
  - Error response helpers
  - Request parsing helpers
  - **Tests**: Response formatting

- [x] **1.6.2** Create `backend/handlers/students.go` *(Completed Dec 7, 2025)*
  - `POST /api/v1/students` - create student
  - `GET /api/v1/students` - list students in family
  - `GET /api/v1/students/{id}` - get student with stats
  - `PATCH /api/v1/students/{id}` - update student
  - `DELETE /api/v1/students/{id}` - soft delete
  - **Tests**: All endpoints with auth, validation

- [x] **1.6.3** Create `backend/handlers/subjects.go` *(Completed Dec 7, 2025)*
  - `POST /api/v1/subjects`
  - `GET /api/v1/subjects`
  - `PATCH /api/v1/subjects/{id}`
  - `DELETE /api/v1/subjects/{id}`
  - **Tests**: All endpoints

- [x] **1.6.4** Create `backend/handlers/logs.go` *(Completed Dec 7, 2025)*
  - `POST /api/v1/logs` - create log entry (quick log)
  - `GET /api/v1/logs` - list with filters (studentId, subjectId, date range, schoolYear)
  - `GET /api/v1/logs/{id}` - single log
  - `PATCH /api/v1/logs/{id}` - update
  - `DELETE /api/v1/logs/{id}` - delete
  - **Tests**: All endpoints, filtering, hour increment validation

- [x] **1.6.5** Create `backend/handlers/stats.go` *(Completed Dec 7, 2025)*
  - `GET /api/v1/stats/student/{id}` - hours by subject, totals, progress
  - `GET /api/v1/stats/family` - all students summary
  - **Tests**: Stat calculations, school year boundaries

- [x] **1.6.6** Create `backend/handlers/onboarding.go` *(Completed Dec 7, 2025)*
  - `POST /api/v1/onboarding/complete` - finish onboarding with settings
  - Seeds subjects, sets school year
  - **Tests**: Full onboarding flow

### 1.7 Wire Up Main.go *(Completed Dec 7, 2025)*
- [x] **1.7.1** Initialize auth session
- [x] **1.7.2** Register all routes with appropriate middleware
- [x] **1.7.3** Add request validation middleware
- [x] **1.7.4** Update health check with version and DB status
- [x] **1.7.5** Add graceful shutdown (already exists, verify)

---

## Phase 1A: Frontend Tasks

### 1.8 API Client Layer *(Completed Dec 7, 2025)*
**Location**: `backend/frontend/src/api/`

- [x] **1.8.1** Update `auth.ts` - connect to real endpoints (cookie-based sessions)
- [x] **1.8.2** Create `students.ts` - CRUD operations
- [x] **1.8.3** Create `subjects.ts` - CRUD operations
- [x] **1.8.4** Create `logs.ts` - CRUD with filters
- [x] **1.8.5** Create `stats.ts` - stats endpoints
- [x] **1.8.6** Create `onboarding.ts` - onboarding flow
- [x] **1.8.7** Create `index.ts` - barrel exports for all API modules

### 1.9 Pinia Stores *(Completed Dec 7, 2025)*
**Location**: `backend/frontend/src/stores/`

- [x] **1.9.1** Complete `auth.ts` - login/register/logout/session (cookie-based)
- [x] **1.9.2** Family state integrated into `auth.ts` store
- [x] **1.9.3** Create `students.ts` - student list, CRUD
- [x] **1.9.4** Create `subjects.ts` - subject list, core/elective getters
- [x] **1.9.5** Create `logs.ts` - log list, filters, CRUD
- [x] **1.9.6** Create `stats.ts` - computed stats
- [x] **1.9.7** Create `index.ts` - barrel exports for all stores

### 1.10 Pages *(Completed Dec 7, 2025)*
**Location**: `backend/frontend/src/pages/`

- [x] **1.10.1** Wire `LoginPage.vue` - form validation, error handling
- [x] **1.10.2** Wire `RegisterPage.vue` - form validation, redirect to onboarding
- [x] **1.10.3** Create `OnboardingPage.vue` - school year, subjects, settings
- [x] **1.10.4** Wire `DashboardPage.vue` - real stats, progress bars
- [x] **1.10.5** Wire `StudentsPage.vue` - list, add/edit modals
- [x] **1.10.6** Wire `StudentDetailPage.vue` - student info, logs, stats
- [x] **1.10.7** Wire `SubjectsPage.vue` - list, add/edit modals
- [x] **1.10.8** Wire `LogsPage.vue` - filterable list, date range, edit/delete
- [x] **1.10.9** Wire `QuickLogPage.vue` - streamlined log entry form
- [x] **1.10.10** Wire `SettingsPage.vue` - family settings

### 1.11 Components *(Completed Dec 7, 2025)*
**Location**: `backend/frontend/src/components/`

- [x] **1.11.1** Create `components/common/` folder
- [x] **1.11.2** `BaseButton.vue` - primary, secondary, danger, loading
- [x] **1.11.3** `BaseInput.vue` - text, email, password with validation
- [x] **1.11.4** `BaseSelect.vue` - dropdown with options
- [x] **1.11.5** `BaseModal.vue` - dialog wrapper
- [x] **1.11.6** `HourPicker.vue` - increment-aware hour selector (0.25, 0.5, etc.)
- [x] **1.11.7** `ProgressBar.vue` - hours progress display
- [x] **1.11.8** `DateRangePicker.vue` - for filtering logs
- [x] **1.11.9** `StudentCard.vue` - dashboard student summary
- [x] **1.11.10** `LogEntryRow.vue` - log list item
- [x] **1.11.11** `index.ts` - barrel exports for all components

---

## Phase 1B: Mobile & Polish (After 1A)

### Mobile App
- [x] JWT auth implementation (backend: auth/jwt.go, handlers/mobile_auth.go)
- [x] API client with Dio (mobile: lib/core/api/api_client.dart)
- [x] Auth service (mobile: lib/core/api/auth_service.dart)
- [x] Auth provider updated (mobile: lib/providers/auth_provider.dart)
- [x] Login/Register screens wired to real API
- [x] Riverpod providers for data (students, subjects, logs, stats)
- [x] Freezed data models (student.dart, subject.dart, log_entry.dart, stats.dart)
- [x] Data services (students_service.dart, subjects_service.dart, logs_service.dart, stats_service.dart)
- [x] All screens wired to real data:
  - [x] Dashboard screen (uses statsProvider, studentsProvider)
  - [x] Students screen (uses studentsProvider, add/edit dialogs)
  - [x] Subjects screen (uses subjectsProvider, add/edit dialogs)
  - [x] Logs screen (uses logsProvider, grouped by date)
  - [x] Quick Log screen (uses logsProvider, studentsProvider, subjectsProvider)
  - [x] Settings screen (logout functionality)
- [x] CI/CD: Flutter Android build in GitHub Actions
  - [x] Flutter analyze, tests, debug APK build
  - [x] APK artifacts uploaded (download from Actions)
  - [ ] Release signing configuration (future)

### Offline-First Architecture (NEW - Dec 8, 2025)
- [x] Hive database layer (core/database/)
  - [x] Hive entities: StudentEntity, SubjectEntity, LogEntryEntity, FamilySettingsEntity, SyncMetaEntity
  - [x] DatabaseService for initialization and box management
  - [x] Generated adapters via hive_generator
- [x] Local repositories (repositories/)
  - [x] StudentRepository - full CRUD with sync tracking
  - [x] SubjectRepository - full CRUD with sync tracking  
  - [x] LogEntryRepository - full CRUD with sync tracking
  - [x] LocalStatsService - calculate stats from local Hive data
- [x] Providers updated to local-first
  - [x] studentsProvider uses StudentRepository
  - [x] subjectsProvider uses SubjectRepository
  - [x] logsProvider uses LogEntryRepository
  - [x] statsProvider uses LocalStatsService
- [x] Export/Import feature (features/export/)
  - [x] ExportImportService - JSON and CSV exports
  - [x] JSON export for phone transfer/backup
  - [x] CSV export for state submission
  - [x] JSON import for data recovery
- [x] Failsafe backup service (dead man's switch)
  - [x] Auto-backup every 15 minutes to external storage
  - [x] Keeps last 5 backups, cleans up older ones
  - [x] Saves to /Documents/HomeSchoolLogs/backups/ (user accessible)
- [x] Default subjects on first launch (Missouri core + common electives)
- [x] App works fully offline - no account required!
- [ ] Optional cloud sync (when user creates account)
- [ ] Sync status indicator in UI

### Web Polish ✅ COMPLETE
- [x] Location management CRUD *(Completed Dec 10, 2025)*
- [x] Multi-year switching *(Completed Dec 10, 2025)*
- [x] Archive school year - warning banner for past years *(Completed Dec 10, 2025)*
- [x] Trash/Recycle bin view *(Completed Dec 11, 2025)*
- [x] PDF/CSV export *(Completed Dec 11, 2025)*

### Multi-Student Logs ✅ COMPLETE (Dec 11, 2025)
- [x] Added `groupId` field to LogEntry model (backend + mobile + web)
- [x] QuickLogScreen/QuickLogPage with multi-student chip selection
- [x] Creates N log entries with shared groupId
- [x] Grouped log display (Mobile: _GroupedLogCard, Web: GroupedLogRow)

### Work Samples / File Attachments ✅ COMPLETE (Dec 12, 2025)
- [x] R2 storage integration for file uploads
- [x] Backend: WorkSampleHandler with upload/download/delete
- [x] Mobile: Work sample UI with image picker and gallery
- [x] Web: Work sample upload in log detail
- [x] Premium gating (requires subscription)

### Super Admin Portal ✅ COMPLETE (Dec 12, 2025)
- [x] Admin dashboard with overview stats
- [x] Family management (list, search, view details)
- [x] Organization management
- [x] Storage/database stats
- [x] Routes protected by isSuperAdmin check

### Anonymous Telemetry ✅ COMPLETE (Dec 12, 2025)
- [x] Backend: TelemetryEvent model, repository, handlers
- [x] Mobile: TelemetryService (Hive-based, Dio HTTP, 30s flush)
- [x] Web: TelemetryService (localStorage, batch sending)
- [x] Settings toggle for opt-out
- [x] Admin telemetry dashboard (/admin/telemetry)
- [x] Rate limiting (500 events/install/day)
- [x] Tier 1 & 2 events (install, session, feature usage)
- See docs/17-telemetry-analytics.md for full spec

---

## Phase 2: Advanced Features (Future)

- [ ] Google OAuth
- [ ] Multi-state compliance rules
- [ ] Student accounts (COPPA compliance)
- [ ] Approval workflow
- [ ] Email notifications
- [ ] Todo/Lesson Planning (see docs/18-todo-planning.md)
- [ ] Subscription/Payment system (see docs/16-payments-research.md)

---

## 📁 Target Directory Structure

```
homeschool-keeper/
├── backend/
│   ├── auth/
│   │   ├── auth.go           # Session management
│   │   ├── auth_test.go
│   │   ├── password.go       # Bcrypt hashing
│   │   ├── password_test.go
│   │   ├── middleware.go     # Auth middleware
│   │   ├── middleware_test.go
│   │   ├── handlers.go       # Login/register endpoints
│   │   └── handlers_test.go
│   ├── models/
│   │   ├── user.go
│   │   ├── family.go
│   │   ├── organization.go   # For Phase 1B
│   │   ├── student.go
│   │   ├── subject.go
│   │   ├── log_entry.go
│   │   └── location.go
│   ├── repository/
│   │   ├── repository.go     # Common helpers
│   │   ├── users.go
│   │   ├── users_test.go
│   │   ├── families.go
│   │   ├── students.go
│   │   ├── subjects.go
│   │   ├── logs.go
│   │   └── stats.go
│   ├── handlers/
│   │   ├── helpers.go
│   │   ├── students.go
│   │   ├── subjects.go
│   │   ├── logs.go
│   │   ├── stats.go
│   │   └── onboarding.go
│   ├── config/
│   │   └── env.go            # ✅ Exists
│   ├── db/
│   │   └── mongo.go          # ✅ Exists
│   ├── frontend/             # Vue SPA
│   │   ├── src/
│   │   │   ├── api/
│   │   │   ├── components/
│   │   │   │   └── common/
│   │   │   ├── pages/
│   │   │   ├── stores/
│   │   │   └── types/
│   │   ├── e2e/              # Playwright tests
│   │   └── vitest.config.ts
│   ├── main.go               # ✅ Exists
│   └── Dockerfile            # ✅ Exists
├── mobile/                   # Flutter
│   ├── lib/
│   │   ├── core/
│   │   │   └── api/          # Dio client
│   │   ├── models/           # Freezed models
│   │   ├── providers/        # Riverpod
│   │   └── features/
│   └── test/
├── scripts/                  # ✅ SSH tunnels exist
├── docs/                     # ✅ Planning docs
├── .github/workflows/        # ✅ CI/CD
├── .vscode/
│   ├── copilot-instructions.md  # To create
│   └── AGENTS.md                # To create
├── HMS_LOGS_IMP.md           # This file
├── Q_AND_A.md                # Q&A tracking
└── docker-compose.yml        # ✅ Exists
```

---

## ✅ Acceptance Criteria for Phase 1A

1. ✅ User can register with email/password
2. ✅ User completes onboarding (school year, subjects)
3. ✅ User can login and see their dashboard
4. ✅ User can add/edit/remove students
5. ✅ User can add/edit/remove subjects
6. ✅ User can create log entries (quick log)
7. ✅ User can see hour statistics on dashboard
8. ✅ All data persists to MongoDB
9. ✅ All code has tests (80%+ coverage for business logic)
10. ✅ CI/CD deploys successfully to Dokploy

---

## 🔒 Security Checklist

- [ ] Passwords hashed with bcrypt (cost 12+)
- [ ] Session cookies: HttpOnly, Secure, SameSite=Lax
- [ ] All endpoints check family ownership (no cross-family data leaks)
- [ ] Rate limiting on auth endpoints
- [ ] Input validation on all endpoints
- [ ] CORS configured for production domain only
- [ ] Sensitive fields (DOB) encrypted at rest (Phase 1B)
- [ ] MongoDB auth enabled in production
- [ ] Environment variables for all secrets

---

## 📝 Notes

- **Family-First Design**: Every entity (student, log, subject) belongs to a `familyId`. This makes data ownership clear and enables future co-op support.
- **School Year Tracking**: Each log has a `schoolYear` field ("2024-2025") for easy filtering and multi-year support.
- **Hour Increment**: Must validate log hours match family's increment setting (0.25, 0.5, 1.0).
- **Missouri Defaults**: Reading, Math, Social Studies, Language Arts, Science as core subjects.

---

## 🚀 Next Steps

1. **Answer remaining Q&A questions** (Q23-Q32)
2. **Create copilot-instructions.md** in `.vscode/`
3. **Create AGENTS.md** for specialized development prompts
4. **Begin Phase 1A Task 1.1** (Testing Infrastructure)

---

*Last Updated: December 6, 2025*
