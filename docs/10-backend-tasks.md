# Backend Development Tasks (Go + MongoDB)

**Directory**: `/backend`

---

## Phase 1: Foundation & Core Logging

### 1.1 Project Setup
- [ ] Initialize Go module: `go mod init github.com/cpuchip/homeschool-keeper/backend`
- [ ] Create directory structure:
  ```
  backend/
  ├── cmd/
  │   └── server/
  │       └── main.go
  ├── internal/
  │   ├── config/
  │   ├── handlers/
  │   ├── middleware/
  │   ├── models/
  │   ├── repository/
  │   └── services/
  ├── pkg/
  │   └── utils/
  ├── api/
  │   └── openapi.yaml
  ├── go.mod
  ├── go.sum
  └── Dockerfile
  ```
- [ ] Add dependencies: gin, mongo-driver, jwt-go, godotenv, validator
- [ ] Create config loader (env vars, .env file)
- [ ] Set up MongoDB connection with retry logic
- [ ] Create health check endpoint: `GET /health`

### 1.2 OpenAPI Specification
- [ ] Define OpenAPI 3.0 spec in `api/openapi.yaml`
- [ ] Document all Phase 1 endpoints
- [ ] Include request/response schemas
- [ ] Add authentication schemes (Bearer JWT)
- [ ] Generate Go types from spec (oapi-codegen)

### 1.3 Authentication System
- [ ] **POST /api/v1/auth/register**
  - Input: email, password, name
  - Validation: email format, password strength (12+ chars)
  - Hash password with bcrypt (cost 12)
  - Create organization automatically
  - Return JWT + refresh token
- [ ] **POST /api/v1/auth/login**
  - Input: email, password
  - Verify credentials
  - Return JWT (15 min expiry) + refresh token (7 days)
- [ ] **POST /api/v1/auth/refresh**
  - Input: refresh token
  - Validate and rotate refresh token
  - Return new JWT + refresh token
- [ ] **POST /api/v1/auth/logout**
  - Invalidate refresh token
- [ ] JWT middleware for protected routes
- [ ] Rate limiting middleware (10 req/min for auth routes)

### 1.4 Organization & User Management
- [ ] **GET /api/v1/organization**
  - Return current user's organization
- [ ] **PATCH /api/v1/organization**
  - Update org settings (hourIncrement, schoolYear dates, timezone)
- [ ] **GET /api/v1/users/me**
  - Return current user profile
- [ ] **PATCH /api/v1/users/me**
  - Update name, email, password

### 1.5 Student Management
- [ ] **POST /api/v1/students**
  - Input: name, dateOfBirth, gradeLevel
  - Create student in organization
- [ ] **GET /api/v1/students**
  - List all students in organization
- [ ] **GET /api/v1/students/:id**
  - Get single student with stats
- [ ] **PATCH /api/v1/students/:id**
  - Update student details
- [ ] **DELETE /api/v1/students/:id**
  - Soft delete (set active=false)

### 1.6 Subject Management
- [ ] **POST /api/v1/subjects**
  - Input: name, type (core/elective), targetHours, color
- [ ] **GET /api/v1/subjects**
  - List all subjects in organization
  - Include default core subjects on first load
- [ ] **PATCH /api/v1/subjects/:id**
  - Update subject
- [ ] **DELETE /api/v1/subjects/:id**
  - Soft delete
- [ ] Seed default core subjects on org creation:
  - Reading, Math, Social Studies, Language Arts, Science

### 1.7 Log Entry CRUD
- [ ] **POST /api/v1/logs**
  - Input: studentId, subjectId, date, hours, description, location
  - Validate hours match org increment setting
  - Auto-set submittedBy, createdAt
  - Status = "approved" if admin creates
- [ ] **GET /api/v1/logs**
  - Query params: studentId, subjectId, startDate, endDate, status
  - Pagination: page, limit (default 50)
  - Sort by date descending
- [ ] **GET /api/v1/logs/:id**
  - Single log entry with relations
- [ ] **PATCH /api/v1/logs/:id**
  - Update log entry
- [ ] **DELETE /api/v1/logs/:id**
  - Hard delete (or soft delete?)

### 1.8 Hour Statistics
- [ ] **GET /api/v1/stats/student/:id**
  - Return for current school year:
    - totalHours
    - coreHours
    - electiveHours
    - homeLocationHours
    - hoursBySubject (array)
- [ ] **GET /api/v1/stats/organization**
  - Summary across all students

---

## Phase 2: File Uploads & Export

### 2.1 File Upload System
- [ ] **POST /api/v1/logs/:id/attachments**
  - Accept multipart/form-data
  - Validate file type (images, PDF, doc)
  - Max file size: 10MB
  - Encrypt file before storage
  - Generate thumbnail for images
  - Store in local filesystem (cloud later)
- [ ] **GET /api/v1/attachments/:id**
  - Stream decrypted file
  - Validate user has access
- [ ] **DELETE /api/v1/attachments/:id**
  - Remove file and DB record

### 2.2 Export Endpoints
- [ ] **GET /api/v1/export/pdf**
  - Query: studentId, startDate, endDate
  - Generate PDF report with hours summary
- [ ] **GET /api/v1/export/excel**
  - Query: studentId, startDate, endDate
  - Generate XLSX with detailed logs
- [ ] **GET /api/v1/export/attachments**
  - Query: studentId, startDate, endDate
  - Generate ZIP of all work samples

---

## Phase 3: Curriculum Planning

### 3.1 Topic/Curriculum Management
- [ ] **POST /api/v1/topics**
- [ ] **GET /api/v1/topics**
- [ ] **PATCH /api/v1/topics/:id**
- [ ] **DELETE /api/v1/topics/:id**

### 3.2 Planned Tasks
- [ ] **POST /api/v1/tasks**
- [ ] **GET /api/v1/tasks** (with date range filters)
- [ ] **PATCH /api/v1/tasks/:id**
- [ ] **POST /api/v1/tasks/:id/complete** (creates log entry)
- [ ] **DELETE /api/v1/tasks/:id**

---

## Phase 4: Student Portal & Reporting

### 4.1 Student Accounts
- [ ] **POST /api/v1/students/:id/enable-login**
  - Generate invite, trigger COPPA flow if under 13
- [ ] Student-specific login endpoint
- [ ] Student-scoped JWT claims

### 4.2 Approval Workflow
- [ ] **GET /api/v1/logs/pending**
  - List logs with status=pending
- [ ] **POST /api/v1/logs/:id/approve**
- [ ] **POST /api/v1/logs/:id/reject**

### 4.3 Advanced Reports
- [ ] **GET /api/v1/reports/compliance**
  - Progress toward state requirements
- [ ] **GET /api/v1/reports/subject-breakdown**
- [ ] **GET /api/v1/reports/weekly-summary**

---

## Testing Requirements

### Unit Tests
- [ ] All service layer functions
- [ ] Password hashing/verification
- [ ] JWT generation/validation
- [ ] Hour increment validation

### Integration Tests
- [ ] Auth flow (register → login → refresh → logout)
- [ ] CRUD operations with real MongoDB (testcontainers)
- [ ] File upload/download

### Load Tests
- [ ] 100 concurrent users
- [ ] Log entry creation under load

---

## DevOps Tasks
- [ ] Dockerfile with multi-stage build
- [ ] docker-compose.yml with MongoDB
- [ ] GitHub Actions CI pipeline
- [ ] Environment variable documentation
