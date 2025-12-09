# Home School Logs - Copilot Instructions

This file provides context for AI assistants working on this codebase.

---

## 📁 Project Structure

```
homeschool-keeper/
├── backend/                 # Go 1.25.5 server
│   ├── auth/               # Authentication (sessions, passwords, middleware)
│   ├── config/             # Environment configuration
│   ├── db/                 # MongoDB connection
│   ├── handlers/           # HTTP route handlers
│   ├── models/             # Data models (bson + json tags)
│   ├── repository/         # Database operations
│   ├── frontend/           # Vue 3 SPA (embedded in Go binary)
│   │   ├── src/
│   │   │   ├── api/       # Axios API clients
│   │   │   ├── components/# Vue components
│   │   │   ├── pages/     # Page components
│   │   │   ├── stores/    # Pinia stores
│   │   │   └── types/     # TypeScript types
│   │   └── e2e/           # Playwright E2E tests
│   └── main.go            # Entry point
├── mobile/                 # Flutter 3.38 app
│   ├── lib/
│   │   ├── core/          # API client, theme, utils
│   │   ├── features/      # Feature modules
│   │   ├── models/        # Freezed data models
│   │   └── providers/     # Riverpod providers
│   └── test/              # Flutter tests
├── scripts/               # Dev scripts (SSH tunnels, etc.)
├── docs/                  # Planning documents
├── .github/workflows/     # CI/CD
└── HMS_LOGS_IMP.md       # Implementation plan (source of truth)
```

---

## 🏗️ Architecture Overview

### App Purpose
Home School Logs is a homeschool record-keeping app for tracking student hours, subjects, and activities to comply with state education requirements (starting with Missouri).

### Data Model
**Family-first design**: Every entity belongs to a family. Organizations are optional overlays for co-ops.

Key entities:
- **Family** - Core unit, owns users/students/logs/subjects
- **User** - Belongs to one family, has role (admin/parent/student)
- **Student** - Belongs to family, can have multiple logs
- **Subject** - Belongs to family, categorized as core/elective
- **LogEntry** - Belongs to family, tracks hours per student/subject
- **Organization** - Optional co-op, multiple families can join

### Tech Stack
| Layer | Technology |
|-------|------------|
| Backend | Go 1.25.5, gorilla/mux, MongoDB driver |
| Database | MongoDB 8.2 |
| Web Frontend | Vue 3, TypeScript, Vite 7, Pinia, TailwindCSS |
| Mobile | Flutter 3.38, Riverpod, Hive, go_router |
| Deployment | Docker, GitHub Actions, Dokploy |

---

## 💻 Coding Conventions

### Go (Backend)

```go
// Package organization - one file per entity type
// Models use bson + json tags
type Student struct {
    ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    FamilyID primitive.ObjectID `bson:"familyId" json:"familyId"`
    Name     string             `bson:"name" json:"name"`
    Active   bool               `bson:"active" json:"active"`
}

// Repository functions take context first
func (r *StudentRepo) GetByFamily(ctx context.Context, familyID primitive.ObjectID) ([]models.Student, error)

// Handlers use gorilla/mux patterns
func (h *StudentHandler) List(w http.ResponseWriter, r *http.Request) {
    // Extract user from context (set by auth middleware)
    user := auth.GetUserFromContext(r.Context())
    // All queries filter by familyId - NEVER allow cross-family access
    students, err := h.repo.GetByFamily(r.Context(), user.FamilyID)
}

// Tests use testify assertions
func TestGetByFamily(t *testing.T) {
    assert.NoError(t, err)
    assert.Len(t, students, 2)
}
```

### TypeScript/Vue (Frontend)

```typescript
// Use composition API with <script setup>
<script setup lang="ts">
import { ref, computed } from 'vue'
import { useStudentsStore } from '@/stores/students'

const store = useStudentsStore()
const students = computed(() => store.students)
</script>

// Types in src/types/index.ts
interface Student {
  id: string
  familyId: string
  name: string
  active: boolean
}

// API clients return typed responses
export async function getStudents(): Promise<Student[]> {
  const response = await api.get('/api/v1/students')
  return response.data
}

// Pinia stores with actions
export const useStudentsStore = defineStore('students', {
  state: () => ({
    students: [] as Student[],
    loading: false,
  }),
  actions: {
    async fetchAll() {
      this.loading = true
      this.students = await studentsApi.getAll()
      this.loading = false
    }
  }
})
```

### Dart/Flutter (Mobile)

```dart
// Use Riverpod for state management
final studentsProvider = StateNotifierProvider<StudentsNotifier, AsyncValue<List<Student>>>((ref) {
  return StudentsNotifier(ref.read(apiClientProvider));
});

// Models with Freezed for immutability
@freezed
class Student with _$Student {
  const factory Student({
    required String id,
    required String familyId,
    required String name,
    required bool active,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
}

// Feature-based folder structure
// lib/features/students/
//   ├── student_screen.dart
//   ├── student_provider.dart
//   └── widgets/
```

---

## 🧪 Testing Requirements

### Coverage Target
- 60%+ overall coverage
- Higher coverage for critical paths (auth, data isolation, stats)
- Every public function should have at least one test

### Test Stack
| Layer | Tool |
|-------|------|
| Go unit | `testing` + `testify` |
| Go integration | `testcontainers-go` for MongoDB |
| Vue unit | Vitest + Vue Test Utils |
| Vue E2E | Playwright |
| API | Hurl (CI-friendly, supports JWT chaining) |
| Flutter | Flutter `test` package |

### Critical Test Cases
1. **Data isolation**: User cannot access another family's data
2. **Auth flow**: Login, session validation, logout
3. **Stats accuracy**: Hour calculations match expectations
4. **Hour increment**: Log entries respect family's increment setting

---

## 🔒 Security Considerations

### Authentication
- Web: Cookie sessions with `securecookie` (30-day expiry)
- Mobile: JWT tokens (30-day expiry with refresh)
- Passwords: bcrypt hash (cost 12)

### Data Isolation (CRITICAL)
```go
// EVERY repository query must include familyId filter
// This is enforced at the repository layer, not handler

// ❌ WRONG - allows cross-family access
func (r *Repo) GetLog(ctx context.Context, logID primitive.ObjectID) (*LogEntry, error) {
    return r.coll.FindOne(ctx, bson.M{"_id": logID})
}

// ✅ CORRECT - always filter by family
func (r *Repo) GetLog(ctx context.Context, familyID, logID primitive.ObjectID) (*LogEntry, error) {
    return r.coll.FindOne(ctx, bson.M{"_id": logID, "familyId": familyID})
}
```

### Encryption
- TLS for all traffic (HTTPS only)
- AES-256 for PII fields (DOB, addresses)
- Disk encryption on server
- Per-family encryption keys

### COPPA & Privacy (Updated Dec 6, 2025)

**COPPA Status: Not Triggered** ✅

Our parent-controlled model avoids COPPA requirements:
- **Adults-only signup** - Only parents/adults can create accounts
- **Parents enter all student data** - Per FTC FAQ A.8: COPPA only applies to info collected "from children"
- **Parents create student accounts** - From within authenticated family portal
- **DateOfBirth is optional** - Parent's choice to track, not a legal requirement

**What this means for development**:
- No age-gating at signup
- No verifiable parental consent flow needed
- No COPPA-specific data handling requirements
- Still need clear privacy policy and standard security practices

---

## 📝 Reference Documents

- **HMS_LOGS_IMP.md** - Implementation plan with task checklists
- **Q_AND_A.md** - Design decisions and rationale
- **docs/01-missouri-requirements.md** - State compliance rules
- **docs/02-data-model.md** - Entity relationships
- **docs/04-api-endpoints.md** - API documentation

---

## 🚀 Development Workflow

### Running Locally

```bash
# Backend (must be in ./backend folder)
cd backend
go run .

# Frontend dev server (must be in ./backend/frontend folder)
cd backend/frontend
npm run dev

# Mobile
cd mobile
flutter run -d windows  # or chrome, android

# MongoDB tunnel (for prod DB access)
.\scripts\ssh-mongo-start.ps1

# SSH to Dokploy server (for investigating logs/deployments)
ssh cpuchip@172.17.100.31
```

### Before Committing
1. Run tests: `go test ./...` and `npm run test`
2. Run linter: `npm run lint`
3. Format code: Go fmt, Prettier, dart format
4. Check for hardcoded secrets

### CI/CD
- Push to `scaffolding` branch triggers build
- Tests must pass before merge
- Auto-deploy to Dokploy on main branch

---

## ⚠️ Common Pitfalls

1. **Forgetting familyId filter** - Always scope queries to user's family
2. **Hardcoding Missouri** - Use configurable state requirements
3. **Mixing org and family data** - Family owns data, org just has visibility
4. **Skipping tests for "simple" code** - Simple bugs cause data leaks
5. **Using `any` in TypeScript** - Always define proper types

---

*Last Updated: December 6, 2025*
