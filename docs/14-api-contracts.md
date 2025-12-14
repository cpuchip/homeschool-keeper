# API Contracts (Pre-OpenAPI Draft)

This document defines the API contracts before the full OpenAPI spec is written.
Use this as reference for all three agents.

---

## Base URL
- Development: `http://localhost:8080/api/v1`
- Production: `https://api.homeschoolkeeper.com/api/v1`

## Authentication
- All protected routes require: `Authorization: Bearer <jwt_token>`
- JWT expires in 15 minutes
- Refresh token expires in 7 days

---

## Endpoints

### Auth

#### POST /auth/register
```json
// Request
{
  "name": "John Parent",
  "email": "john@example.com",
  "password": "SecurePassword123!"
}

// Response 201
{
  "user": {
    "id": "abc123",
    "name": "John Parent",
    "email": "john@example.com",
    "role": "admin",
    "organizationId": "org456"
  },
  "accessToken": "eyJhbG...",
  "refreshToken": "eyJhbG...",
  "expiresIn": 900
}
```

#### POST /auth/login
```json
// Request
{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}

// Response 200 - same as register
```

#### POST /auth/refresh
```json
// Request
{
  "refreshToken": "eyJhbG..."
}

// Response 200
{
  "accessToken": "eyJhbG...",
  "refreshToken": "eyJhbG...",  // rotated
  "expiresIn": 900
}
```

#### POST /auth/logout
```json
// Request
{
  "refreshToken": "eyJhbG..."
}

// Response 204 No Content
```

---

### Mobile Auth (JWT-based)

Mobile apps use JWT tokens instead of cookies. These endpoints are at `/mobile/auth/*`.

#### POST /mobile/auth/register
```json
// Request
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "name": "John Parent",
  "familyName": "Smith Family"
}

// Response 201
{
  "user": { /* user object */ },
  "family": { /* family object */ },
  "accessToken": "eyJhbG...",
  "refreshToken": "eyJhbG..."
}
```

#### POST /mobile/auth/login
```json
// Request
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}

// Response 200
{
  "user": { /* user object */ },
  "family": { /* family object */ },
  "accessToken": "eyJhbG...",
  "refreshToken": "eyJhbG..."
}
```

#### POST /mobile/auth/refresh
```json
// Request
{
  "refreshToken": "eyJhbG..."
}

// Response 200
{
  "accessToken": "eyJhbG...",
  "refreshToken": "eyJhbG..."
}
```

#### GET /mobile/auth/me
```json
// Headers: Authorization: Bearer <accessToken>

// Response 200
{
  "user": { /* user object */ },
  "family": { /* family object */ }
}
```

---

### Incremental Sync

All list endpoints support incremental sync using the `since` query parameter:

- `since` - ISO 8601 timestamp to fetch records updated after this time

Example: `GET /v1/students?since=2025-12-10T10:30:00Z`

This returns only records with `updatedAt > since`, useful for mobile sync.

---

### Organization

#### GET /organization
```json
// Response 200
{
  "id": "org456",
  "name": "Smith Family",
  "settings": {
    "hourIncrement": 0.25,
    "schoolYearStart": "2025-08-01",
    "schoolYearEnd": "2026-05-31",
    "timezone": "America/Chicago"
  },
  "createdAt": "2025-01-15T10:30:00Z"
}
```

#### PATCH /organization
```json
// Request
{
  "name": "Smith Homeschool",
  "settings": {
    "hourIncrement": 0.5
  }
}

// Response 200 - updated organization
```

---

### Students

#### GET /students
Query params:
- `since` (optional, ISO timestamp for incremental sync)

```json
// Response 200
{
  "students": [
    {
      "id": "stu789",
      "name": "Johnny Smith",
      "dateOfBirth": "2015-03-20",
      "gradeLevel": "4th",
      "active": true
    }
  ]
}
```

#### POST /students
```json
// Request
{
  "name": "Johnny Smith",
  "dateOfBirth": "2015-03-20",
  "gradeLevel": "4th"
}

// Response 201
{
  "id": "stu789",
  "name": "Johnny Smith",
  "dateOfBirth": "2015-03-20",
  "gradeLevel": "4th",
  "active": true,
  "organizationId": "org456"
}
```

#### GET /students/:id
```json
// Response 200
{
  "id": "stu789",
  "name": "Johnny Smith",
  "dateOfBirth": "2015-03-20",
  "gradeLevel": "4th",
  "active": true,
  "stats": {
    "totalHours": 450.5,
    "coreHours": 280.25,
    "electiveHours": 170.25,
    "homeHours": 220.0
  }
}
```

#### PATCH /students/:id
```json
// Request
{
  "gradeLevel": "5th"
}

// Response 200 - updated student
```

#### DELETE /students/:id
```json
// Response 204 No Content
```

---

### Subjects

#### GET /subjects
Query params:
- `since` (optional, ISO timestamp for incremental sync)

```json
// Response 200
{
  "subjects": [
    {
      "id": "sub001",
      "name": "Math",
      "type": "core",
      "targetHours": 200,
      "color": "#3B82F6"
    },
    {
      "id": "sub002",
      "name": "Physical Education",
      "type": "elective",
      "targetHours": 100,
      "color": "#10B981"
    }
  ]
}
```

#### POST /subjects
```json
// Request
{
  "name": "Art",
  "type": "elective",
  "targetHours": 50,
  "color": "#F59E0B"
}

// Response 201 - created subject
```

---

### Log Entries

#### GET /logs
Query params:
- `studentId` (optional)
- `subjectId` (optional)
- `startDate` (optional, ISO date)
- `endDate` (optional, ISO date)
- `status` (optional: pending, approved)
- `since` (optional, ISO timestamp for incremental sync)
- `page` (default: 1)
- `limit` (default: 50, max: 100)

```json
// Response 200
{
  "logs": [
    {
      "id": "log123",
      "studentId": "stu789",
      "subjectId": "sub001",
      "date": "2025-12-02",
      "hours": 1.5,
      "description": "Practiced multiplication tables",
      "location": "home",
      "status": "approved",
      "submittedBy": "user123",
      "approvedBy": "user123",
      "createdAt": "2025-12-02T14:30:00Z",
      "attachments": []
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 127,
    "totalPages": 3
  }
}
```

#### POST /logs
```json
// Request
{
  "studentId": "stu789",
  "subjectId": "sub001",
  "date": "2025-12-02",
  "hours": 1.5,
  "description": "Practiced multiplication tables",
  "location": "home"
}

// Response 201 - created log
```

#### PATCH /logs/:id
```json
// Request
{
  "hours": 2.0,
  "description": "Updated description"
}

// Response 200 - updated log
```

#### DELETE /logs/:id
```json
// Response 204 No Content
```

---

### Stats

#### GET /stats/student/:id
Query params:
- `schoolYear` (optional, defaults to current)

```json
// Response 200
{
  "studentId": "stu789",
  "schoolYear": "2025-2026",
  "totalHours": 450.5,
  "coreHours": 280.25,
  "electiveHours": 170.25,
  "homeHours": 220.0,
  "bySubject": [
    {
      "subjectId": "sub001",
      "name": "Math",
      "type": "core",
      "hours": 85.5,
      "targetHours": 200,
      "percentComplete": 42.75
    }
  ],
  "requirements": {
    "totalRequired": 1000,
    "coreRequired": 600,
    "homeRequired": 400,
    "totalRemaining": 549.5,
    "coreRemaining": 319.75,
    "homeRemaining": 180.0
  }
}
```

---

### Locations

Saved locations for quick selection during log entry (field trips, co-ops, etc.)

#### GET /locations
Query params:
- `since` (optional, ISO timestamp) - For incremental sync, returns only records updated after this time

```json
// Response 200
{
  "locations": [
    {
      "id": "loc123",
      "familyId": "fam456",
      "type": "field_trip",  // field_trip, co_op, other
      "name": "Science City Museum",
      "address": "4601 State Ave, Kansas City, KS 66102",
      "active": true,
      "createdAt": "2025-12-10T18:30:00Z",
      "updatedAt": "2025-12-10T18:30:00Z"
    }
  ]
}
```

#### POST /locations
```json
// Request
{
  "type": "field_trip",
  "name": "Science City Museum",
  "address": "4601 State Ave, Kansas City, KS 66102"
}

// Response 201
{
  "id": "loc123",
  "familyId": "fam456",
  "type": "field_trip",
  "name": "Science City Museum",
  "address": "4601 State Ave, Kansas City, KS 66102",
  "active": true,
  "createdAt": "2025-12-10T18:30:00Z",
  "updatedAt": "2025-12-10T18:30:00Z"
}
```

#### GET /locations/:id
```json
// Response 200 - single location
```

#### PATCH /locations/:id
```json
// Request - any combination of:
{
  "type": "co_op",
  "name": "New Name",
  "address": "New Address"
}

// Response 200 - updated location
```

#### DELETE /locations/:id
```json
// Response 204 No Content
// Note: Soft delete (sets active=false)
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {
        "field": "hours",
        "message": "Hours must be a multiple of 0.25"
      }
    ]
  }
}
```

### Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Pagination

All list endpoints support:
- `page` - 1-indexed page number
- `limit` - items per page (max 100)

Response includes:
```json
{
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 127,
    "totalPages": 3
  }
}
```

---

## Validation Rules

### Hours
- Must be positive
- Must be multiple of organization's `hourIncrement` (0.25, 0.5, or 1.0)
- Max: 24 hours per entry

### Passwords
- Minimum 12 characters
- At least one uppercase, lowercase, number

### Dates
- ISO 8601 format: `YYYY-MM-DD` for dates
- ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ` for timestamps
