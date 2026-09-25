# Parallel Development Strategy

This document outlines how to run Backend, Web, and Mobile development in parallel with minimal blocking.

---

## Agent Assignment

| Agent | Directory | Tech Stack | Focus |
|-------|-----------|------------|-------|
| **Agent 1** | `/backend` | Go + MongoDB | API, Auth, Database |
| **Agent 2** | `/web` | Vue 3 + TypeScript | Web frontend |
| **Agent 3** | `/mobile` | Flutter | Mobile app |

---

## Phase 1 Sprint Plan

### Week 1: Foundation (All Parallel)

#### Backend Agent
1. Project setup & structure
2. MongoDB connection
3. Health endpoint
4. OpenAPI spec draft (share with other agents!)

#### Web Agent
1. Vite + Vue project setup
2. Tailwind configuration
3. TypeScript types (from OpenAPI draft)
4. Router & layout components

#### Mobile Agent
1. Flutter project setup
2. Theme & design system
3. Freezed models
4. GoRouter configuration

**Sync Point**: Share OpenAPI spec → Web/Mobile generate types

---

### Week 2: Auth System

#### Backend Agent
1. Auth endpoints (register, login, refresh, logout)
2. JWT middleware
3. User model & repository

#### Web Agent
1. API client with interceptors
2. Auth store (Pinia)
3. Login & Register pages
4. Auth guard on routes

#### Mobile Agent
1. Dio client with interceptors
2. Auth provider (Riverpod)
3. Login & Register screens
4. Secure token storage

**Sync Point**: Test auth flow end-to-end

---

### Week 3: Core Data Models

#### Backend Agent
1. Organization endpoints
2. Student CRUD endpoints
3. Subject CRUD endpoints
4. Seed default subjects

#### Web Agent
1. Students store & API
2. Subjects store & API
3. Students list/detail pages
4. Subjects management page

#### Mobile Agent
1. SQLite database setup
2. Students provider & screens
3. Subjects provider & screens
4. Local persistence

**Sync Point**: Verify CRUD operations work across all platforms

---

### Week 4: Quick Log (Critical Feature)

#### Backend Agent
1. Log entry CRUD endpoints
2. Hour validation logic
3. Stats endpoints
4. Query filters & pagination

#### Web Agent
1. HourPicker component
2. QuickLog page/modal
3. Logs store with filters
4. Dashboard with stats

#### Mobile Agent
1. HourPicker widget
2. QuickLog screen
3. Logs provider
4. Dashboard screen
5. Offline queue for logs

**Sync Point**: Full quick log flow working on all platforms

---

## Dependency Graph

```
                    ┌─────────────────┐
                    │  OpenAPI Spec   │
                    │  (Backend)      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │TS Types  │  │ Dart     │  │ Go Types │
        │(Web)     │  │ Models   │  │(Backend) │
        └────┬─────┘  └────┬─────┘  └────┬─────┘
             │             │             │
             ▼             ▼             ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ API      │  │ API      │  │ Handlers │
        │ Client   │  │ Client   │  │          │
        └────┬─────┘  └────┬─────┘  └────┬─────┘
             │             │             │
             ▼             ▼             ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ Stores   │  │ Providers│  │ Services │
        └────┬─────┘  └────┬─────┘  └────┬─────┘
             │             │             │
             ▼             ▼             ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ Pages    │  │ Screens  │  │ (done)   │
        └──────────┘  └──────────┘  └──────────┘
```

---

## Contract-First Development

### The OpenAPI Spec is the Source of Truth

1. **Backend** creates/updates `backend/api/openapi.yaml`
2. **Web** generates TypeScript types from spec
3. **Mobile** uses spec to create Dart models

### Mock Server for Frontend Development

While backend is in progress, frontends can use:
- **Prism** (OpenAPI mock server): `prism mock api/openapi.yaml`
- **MSW** (Mock Service Worker) for web
- Local JSON fixtures for mobile

---

## Blocking Dependencies

| Task | Blocked By | Mitigation |
|------|-----------|------------|
| Web/Mobile API calls | Backend endpoints | Use mock server |
| Type generation | OpenAPI spec | Draft spec early |
| E2E testing | All components | Integration tests per layer |
| File uploads | Backend storage | Design API contract first |
| Offline sync | Backend conflict resolution | Define sync protocol |

---

## Communication Checkpoints

### Daily
- Each agent commits to shared repo
- OpenAPI spec changes trigger notification

### Per Feature
- API contract review before implementation
- Cross-platform testing after completion

### Weekly
- Integration testing across all platforms
- Spec updates and type regeneration
- Demo of completed features

---

## Shared Resources

### `/shared` Directory (Optional)
```
shared/
├── api/
│   └── openapi.yaml      # Source of truth
├── docs/                  # These planning docs
└── scripts/
    ├── generate-types.sh  # For web
    └── start-mock.sh      # Mock server
```

### Git Workflow
- `main` - stable, tested
- `backend/feature-x` - backend work
- `web/feature-x` - web work
- `mobile/feature-x` - mobile work
- PR reviews before merge to main

---

## Quick Reference: What Each Agent Needs

### Backend Agent Context
- Read: `04-data-models.md`, `06-compliance-security.md`, `10-backend-tasks.md`
- Create: Go API, MongoDB schemas, OpenAPI spec
- Output: Working API endpoints, documented in OpenAPI

### Web Agent Context
- Read: `07-ui-ux-notes.md`, `11-web-tasks.md`, OpenAPI spec
- Create: Vue 3 app with all pages/components
- Depends on: OpenAPI spec for types, running backend OR mock server

### Mobile Agent Context
- Read: `07-ui-ux-notes.md`, `12-mobile-tasks.md`, OpenAPI spec
- Create: Flutter app with offline support
- Depends on: OpenAPI spec for models, running backend OR mock server
