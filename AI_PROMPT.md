# AI Session State - December 9, 2025

This document captures the current state of development to resume work in a new location after moving the project away from OneDrive to avoid sync conflicts with build artifacts.

---

## Project Overview

**Home School Logs** - A homeschool record-keeping app for tracking student hours, subjects, and activities to comply with state education requirements (starting with Missouri).

### Tech Stack
| Layer | Technology |
|-------|------------|
| Backend | Go 1.25.5, gorilla/mux, MongoDB 8.2, JWT auth for mobile |
| Database | MongoDB (hmslogs) |
| Web Frontend | Vue 3, TypeScript, Vite 7, Pinia, TailwindCSS |
| Mobile | Flutter 3.38, Riverpod, Hive (local storage), go_router |

---

## Current Development Phase: 1B - Mobile App Foundation

### Completed Features

#### Backend (Go)
- ✅ JWT-based mobile authentication (`/api/v1/mobile/auth/*`)
- ✅ Session-based web authentication
- ✅ CRUD endpoints for students, subjects, logs, stats
- ✅ Family-first data isolation (all queries filter by familyId)

#### Mobile App (Flutter)
- ✅ **Offline-First Architecture** - Hive local storage as primary data source
  - `StudentEntity`, `SubjectEntity`, `LogEntryEntity`, `FamilySettingsEntity`, `SyncMetaEntity`
  - Type IDs 0-4 for Hive adapters
  - Default Missouri subjects seeded on first launch
  
- ✅ **Authentication**
  - JWT login/register with server
  - "Continue without account" button for offline-only mode
  - `isOfflineMode` flag in AuthState
  - Router redirects allow access when `isAuthenticated || isOfflineMode`

- ✅ **Local Repositories**
  - `StudentRepository`, `SubjectRepository`, `LogEntryRepository`
  - `LocalStatsService` for calculating stats from Hive data
  - All have `needsSync` flags ready for future server sync

- ✅ **Failsafe Backup Service (Dead Man's Switch)**
  - Auto-backup every 15 minutes to user-accessible location
  - Backup on app background/close (lifecycle-aware via `WidgetsBindingObserver`)
  - User subfolders: `/HomeSchoolLogs/backups/offline/` or `/HomeSchoolLogs/backups/user_<hash>/`
  - Opt-out setting: `autoBackupEnabled` in `FamilySettingsEntity`
  - Settings UI: toggle auto-backup, manual backup, open backup folder
  - Export formats: JSON (reimportable), CSV (for state submission)

- ✅ **UI/UX**
  - Portrait mode locked (`SystemChrome.setPreferredOrientations`)
  - Single-handed UI optimizations (buttons toward bottom)
  - Login screen with skip account option

- ✅ **API Client**
  - Dio with JWT interceptor (auto-refresh tokens)
  - `SensitiveDataLogInterceptor` - redacts passwords/tokens from debug logs

### NOT Yet Implemented
- ❌ **Data Sync Service** - No sync between local Hive and server yet
  - Repositories have `needsSync`, `remoteId`, `lastSyncedAt` fields ready
  - No `SyncService` class exists
  - Login shows server data in dashboard but local CRUD only affects Hive

---

## Key Files Modified This Session

### Mobile App
| File | Changes |
|------|---------|
| `lib/main.dart` | Portrait lock, lifecycle backup, database init |
| `lib/core/router.dart` | Allow navigation when `isOfflineMode` |
| `lib/core/database/hive_entities.dart` | Added `autoBackupEnabled` field |
| `lib/core/database/hive_entities.g.dart` | Fixed null-safety for new field: `fields[9] as bool? ?? true` |
| `lib/core/api/api_client.dart` | `SensitiveDataLogInterceptor` for redacting passwords |
| `lib/providers/auth_provider.dart` | `skipAccountForOfflineMode()`, backup service integration |
| `lib/features/auth/presentation/login_screen.dart` | "Continue without account" button, single-handed layout |
| `lib/features/export/failsafe_backup_service.dart` | User subfolders, opt-out check, file browser launch |
| `lib/features/settings/presentation/settings_screen.dart` | Backup controls UI section |
| `pubspec.yaml` | Added `open_filex: ^4.5.0` |

### Documentation
| File | Purpose |
|------|---------|
| `mobile/README.md` | Dev setup, server targeting, SSH tunnel instructions |
| `.github/copilot-instructions.md` | Project structure, coding conventions, security rules |
| `AGENTS.md` | Specialized AI agent prompts for different tasks |

---

## Environment Setup Required

### Backend
1. Create `.env` file in project root with:
```env
PORT=8080
MONGODB_URI=mongodb://localhost:27017/hmslogs
JWT_SECRET=your-secret-here
SESSION_SECRET=your-32-char-session-secret
DEV_MODE=true
```

2. For remote MongoDB, use SSH tunnel:
```powershell
ssh -L 27017:localhost:27017 user@your-server
```

### Mobile
- **Server Targeting**: Set at build time
```powershell
# Local development
flutter run -d windows

# Custom server
flutter run --dart-define=API_URL=https://your-server.com/api/v1
```

- **Default API URL**: `http://localhost:8080/api/v1` (in `lib/core/constants.dart`)

---

## Known Issues / Bugs Fixed This Session

1. **Hive null-safety on new fields** - When adding `autoBackupEnabled` to existing Hive data, cast to nullable first: `fields[9] as bool? ?? true`

2. **Password logging** - Fixed by replacing `LogInterceptor` with custom `SensitiveDataLogInterceptor`

3. **Mobile auth returning HTML** - Backend needs `JWT_SECRET` env var set or routes aren't registered

4. **Login not redirecting** - Router needed `isLoading` check and `isOfflineMode` support

---

## Next Steps (Suggested)

1. **Implement SyncService** - Push/pull data between Hive and server
   - Use `needsSync` flag to find local changes
   - Conflict resolution strategy needed
   - Sync on login, manual trigger, and periodic background

2. **Complete Settings Screen** - Wire up remaining TODOs (state selection, school year, dark mode)

3. **Add more tests** - Current coverage is minimal

4. **State Requirements** - Add more states beyond Missouri

---

## Git Status

- **Branch**: `scaffolding`
- **PR**: #1 (Scaffolding) against `main`
- **Recent commits**: Offline-first architecture, backup improvements, auth fixes

---

## Commands Reference

```powershell
# Backend
cd backend
go run .

# Frontend dev server
cd backend/frontend
npm run dev

# Mobile
cd mobile
flutter run -d windows
flutter analyze
flutter test

# Hive code generation (after modifying entities)
dart run build_runner build --delete-conflicting-outputs
```

---

*Generated: December 9, 2025*
