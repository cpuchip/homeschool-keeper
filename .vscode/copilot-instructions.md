# Homeschool Keeper - Copilot Instructions

## Project Overview
Homeschool Keeper is an offline-first app to help parents track, plan, and journal their children's homeschool education. It helps families comply with state record-keeping laws (e.g., Missouri's 1,000 hours requirement).

## North Star
- **Simplify homeschool record-keeping** for parents managing multiple children's education
- **Quick logging is king** - the daily log entry must take < 30 seconds
- **Offline-first** - full functionality without internet, with optional cloud sync
- **Compliance-focused** - help families meet state requirements (hours, subjects, records)
- **Privacy-first** - FERPA, COPPA compliance for student data protection

## Architecture

### Directory Structure
```
homeschool-keeper/
├── backend/                 # Go backend service
│   ├── auth/               # Authentication (JWT, sessions)
│   ├── config/             # Environment configuration
│   ├── db/                 # MongoDB connection & helpers
│   ├── handlers/           # HTTP route handlers
│   ├── models/             # Data models
│   ├── services/           # Business logic
│   ├── frontend/           # Vue 3 frontend (embedded)
│   │   ├── src/
│   │   └── dist/           # Built assets (served by Go)
│   └── main.go             # Server entrypoint
├── mobile/                  # Flutter mobile app
│   └── lib/
│       ├── features/       # Feature-based organization
│       ├── models/         # Freezed data models
│       ├── providers/      # Riverpod state
│       └── core/           # Shared utilities
├── docs/                    # Planning & documentation
└── scripts/                 # Development scripts
```

### Tech Stack
- **Backend**: Go 1.25.5 + MongoDB 8.2 + gorilla/mux
- **Frontend**: Vue 3 + TypeScript + Vite 7 + TailwindCSS 3
- **Mobile**: Flutter 3.38 + Riverpod + sqflite

## Coding Conventions

### Go Backend
- Use `gorilla/mux` for routing
- Context timeouts on all DB operations (5-10 seconds)
- Structured error responses: `{"error": "message"}`
- JSON responses with `Content-Type: application/json`
- Environment config via `config/env.go`
- MongoDB connection in `db/mongo.go`
- Feature-based packages (auth, logs, students, subjects)

### Vue Frontend
- Composition API with `<script setup lang="ts">`
- Pinia stores for state management
- Feature-based directory structure under `src/`
- TailwindCSS for styling (no custom CSS unless necessary)
- API calls through `src/api/` layer
- Types in `src/types/`

### Flutter Mobile
- Riverpod for state management (AsyncNotifier pattern)
- Freezed for immutable models with JSON serialization
- GoRouter for navigation
- Feature-first directory structure under `lib/features/`
- Offline-first: local SQLite + sync queue

## Key Features

### Phase 1 (MVP)
1. **Authentication** - Register/login with email/password
2. **Organization/Family** - Create family, add students
3. **Subjects** - Core (Reading, Math, Social Studies, Language Arts, Science) + electives
4. **Quick Log Entry** - Student, subject, hours (increment steps), description, date
5. **Hour Tracking** - Total/core/home hours with progress indicators

### Phase 2
- File uploads (work samples)
- Export (PDF, Excel, ZIP)

### Phase 3
- Curriculum planning
- Weekly/daily task scheduling

### Phase 4
- Student portal with approval workflow
- Compliance reports

## API Conventions

### Endpoints Pattern
```
GET    /api/v1/{resource}          # List
POST   /api/v1/{resource}          # Create
GET    /api/v1/{resource}/{id}     # Get one
PATCH  /api/v1/{resource}/{id}     # Update
DELETE /api/v1/{resource}/{id}     # Delete
```

### Authentication
- JWT in `Authorization: Bearer <token>` header
- 15-minute access token, 7-day refresh token
- Refresh via `POST /api/v1/auth/refresh`

### Error Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human readable message",
    "details": [{"field": "hours", "message": "Must be positive"}]
  }
}
```

## Development Workflow

### Running Locally
```bash
# Backend (from repo root)
cd backend && go run .

# Frontend dev (hot reload)
cd backend/frontend && npm run dev

# Full build
cd backend/frontend && npm run build
cd .. && go build -o homeschool-keeper .
```

### Testing
- Go: `go test ./...`
- Vue: `npm run test`
- Flutter: `flutter test`

## State Requirements (Missouri Example)
- **1,000 hours** total instruction per year
- **600 hours** in core subjects (Reading, Math, Social Studies, Language Arts, Science)
- **400 hours** must be at home location
- **Records**: Plan book, work samples, evaluations (keep 2+ years)

## Guiding Principles
1. **Quick logging** - Most common action, optimize for speed
2. **Offline-first** - Local storage, sync when connected
3. **Privacy** - Encrypt student data, COPPA consent for under-13
4. **Compliance** - Track hours toward state requirements
5. **Multi-child** - Easy switching between students
