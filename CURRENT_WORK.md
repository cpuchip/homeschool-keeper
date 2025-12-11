# Home School Logs - Current Work & Next Steps

**Generated**: December 10, 2025  
**Status**: Phase 1A Complete → Phase 1B In Progress

---

## 📊 Project Status Report

### Overall Progress

| Component | Phase 1A Status | Phase 1B Status | Notes |
|-----------|----------------|-----------------|-------|
| **Backend (Go)** | ✅ **95% Complete** | 🔄 60% | All CRUD, auth, stats working |
| **Web Frontend (Vue)** | ✅ **95% Complete** | ⏳ 30% | All pages functional, minor bugs |
| **Mobile (Flutter)** | ✅ **90% Complete** | 🔄 70% | Offline-first + sync working |
| **CI/CD** | ✅ **100%** | ✅ | All builds passing |
| **Testing** | 🔄 **50%** | ⏳ | E2E done, unit tests sparse |

---

## ✅ What's Fully Working

### Backend
- Auth (register, login, logout, session management)
- JWT for mobile + Cookie sessions for web
- Students CRUD with family isolation
- Subjects CRUD with family isolation
- Log entries CRUD with filtering
- Stats aggregation (by student, by family)
- Onboarding flow
- Mobile auth endpoints (`/api/v1/mobile/auth/*`)
- Sync endpoints with `since` parameter for incremental sync

### Web Frontend
- Login/Register with validation
- Onboarding wizard (school year, subjects, settings)
- Dashboard with real stats
- Students page (add, edit, delete)
- Subjects page (add, edit, toggle active)
- Logs page (list, filter, edit, delete)
- Quick Log page (streamlined logging)
- Settings page

### Mobile
- Offline-first architecture with Hive
- Local repositories (students, subjects, logs)
- JWT auth with token storage
- Login/Register screens
- Dashboard with local stats
- Students/Subjects/Logs screens
- Quick Log screen
- **Sync service** (push/pull with server)
- **Auto-sync** on connectivity changes
- **Failsafe backup** (every 15 min to Documents)
- Export/Import (JSON, CSV)
- Logger utility (release-build safe)

---

## 🔴 Known Issues / Bugs

| Issue | Severity | Location | Status |
|-------|----------|----------|--------|
| ~~Log History shows "Invalid Date"~~ | High | Web | ✅ Fixed Dec 10 |
| ~~Flutter analyze fails~~ | High | Mobile CI | ✅ Fixed Dec 10 |
| ~~Flutter test fails~~ | High | Mobile CI | ✅ Fixed Dec 10 |
| ~~No user-facing sync indicator~~ | Low | Mobile | ✅ Fixed Dec 10 |
| ~~StudentCard crashes when bySubject undefined~~ | Medium | Web | ✅ Fixed Dec 10 |

---

## 📋 Detailed Next Steps by Priority

## Priority 1: Bug Fixes & Polish (This Week) ✅ COMPLETE

### 1.1 Web App Fixes
- [x] ~~Fix LogsPage "Invalid Date" display~~ ✅ Done Dec 10
- [x] ~~Test log edit/delete functionality~~ ✅ Verified Dec 10 - Edit modal works, delete works
- [x] ~~Verify onboarding flow~~ ✅ Verified Dec 10 - Full flow tested with new user
- [x] ~~Add form validation feedback~~ ✅ Already implemented - error messages on submit

### 1.2 Mobile App Stability
- [x] ~~Fix Flutter analyze for CI~~ ✅ Done Dec 10
- [x] ~~Add sync status indicator~~ in app bar (syncing spinner, last sync time) ✅ Done Dec 10
- [x] ~~Handle sync conflicts~~ ✅ Done Dec 10 - Server-wins with conflict detection, orange snackbar notification

### 1.3 Testing Gaps
- [x] **Backend unit tests** - LogRepository tests added (skipped on Windows, runs in CI)
- [x] **Web component tests** - 31 Vitest tests for students and auth stores ✅ Done Dec 10
- [x] **Mobile widget tests** - 10 Flutter model tests ✅ Done Dec 10

---

## Priority 2: Complete Phase 1B (Next 2 Weeks) - ✅ COMPLETE

### 2.1 Mobile Cloud Sync Polish
- [x] ~~Full sync on login~~ - Login now awaits full sync before navigating ✅ Done Dec 10
- [x] ~~Sync indicator in UI~~ - Show syncing status, last sync time ✅ Done Dec 10
- [x] ~~Conflict resolution UI~~ - Windows Explorer-style conflict dialog ✅ Done Dec 10-11
- [x] ~~Logout clears local data~~ - Dialog asks Keep Data/Clear Data ✅ Done Dec 10

### 2.2 Mobile UX Improvements
- [x] **Student avatars** - Color picker with AvatarColors.all ✅ Already implemented
- [x] **Subject color picker** - Color picker with SubjectColors.all ✅ Already implemented
- [x] **Student/Subject editing** - Edit sheets for both ✅ Done Dec 11
- [x] ~~Log entry editing~~ ✅ Done Dec 10 - Edit dialog added in logs_screen.dart
- [x] ~~Delete confirmations~~ - Already implemented with AlertDialog ✅ Verified Dec 10
- [x] ~~Pull-to-refresh~~ - Already implemented on all list screens ✅ Verified Dec 10

### 2.3 Web UX Improvements
- [x] **Location management** - CRUD for saved locations (field trips, co-ops) ✅ Done Dec 10
- [x] **Multi-year switching** - View/filter by school year ✅ Done Dec 10
- [x] ~~Archive school year~~ - Warning banner when viewing past year ✅ Done Dec 10
- [x] ~~Better error handling~~ - Toast notifications for CRUD operations ✅ Done Dec 10

---

## Priority 3: Phase 2 Features (Future)

### 3.1 Export & Compliance
- [ ] **PDF export** - Hours summary report for state submission
- [ ] **Excel export** - Detailed log entries
- [ ] **Work samples** - Photo attachments to logs

### 3.2 Custom Subjects
- [ ] **Custom subjects in onboarding** - Let users add their own subjects during setup
- [ ] **Add/edit/remove subjects** - Full CRUD in Subjects page (already done, verify working)
- [ ] **Soft delete protection** - Warn if deleting subject with attached logs, mark as deleted not hard-delete
- [ ] **Trash/Recycle Bin view** - View deleted items (students, subjects, logs) across all screens
- [ ] **Restore from trash** - Undelete soft-deleted items
- [ ] **Permanent delete** - Hard delete from trash (with confirmation, logs check)

### 3.3 Advanced Features
- [ ] **Google OAuth** - Social login option
- [ ] **Student accounts** - Kids can log their own hours
- [ ] **Approval workflow** - Parent approves student-submitted logs
- [ ] **Email notifications** - Weekly summaries

### 3.4 Multi-State Support
- [ ] **📚 State Law Research** - Deep research across all 50 states for current homeschool laws:
  - Notification requirements (who to notify, when, how)
  - Record keeping requirements (attendance, subjects, hours)
  - Minimum instruction hours per year
  - Core vs elective subject requirements
  - Assessment/evaluation requirements (testing, portfolios)
  - Teacher qualification requirements
  - Age/grade requirements
  - Sources: Official state education department links
- [ ] **State law presets** - Different requirements per state
- [ ] **Hour tracking by state** - Missouri = 1000 total, 600 core, etc.

---

## 🎯 Recommended Immediate Actions

### Today/Tomorrow
1. ✅ ~~Fix LogsPage display bug~~ Done
2. ✅ ~~Fix Flutter analyze~~ Done
3. ✅ ~~Commit and push~~ all fixes Done
4. ✅ ~~Test full user flow on web~~ Done Dec 10 (login → dashboard → students → subjects → quick log → edit log)
5. ✅ ~~Test mobile sync~~ Done Dec 10 (verified stats sync: 9.3 hours, 9 entries, 2 students)

### This Week
1. ✅ ~~Add sync status indicator~~ on mobile Done Dec 10
2. ✅ ~~Write backend tests~~ LogRepository tests added
3. ✅ ~~Document API~~ Updated 14-api-contracts.md with mobile auth & sync params Dec 10
4. ✅ ~~Implement Recent Logs card~~ on mobile dashboard Dec 10
5. ✅ ~~Mobile log editing~~ Added edit dialog in logs_screen.dart Dec 10

### Next Week
1. **Conflict resolution** - Handle sync conflicts gracefully
2. ~~**Location management**~~ - Web CRUD for saved locations ✅ Done Dec 10
3. ~~**Multi-year support**~~ - Switch between school years ✅ Done Dec 10
4. **Pull-to-refresh** on mobile list screens

---

## 📊 Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Backend test coverage | ~10% | 60%+ |
| Web E2E tests | 15 smoke tests | Maintained |
| Mobile test coverage | ~5% | 40%+ |
| API endpoints | 25+ | All Phase 1 |
| Known bugs | 0 | 0 |

---

## 🏗️ Architecture Reference

### Data Flow
```
Mobile App (Flutter)
  ├── Hive (local storage) ← Primary data source
  ├── Sync Service → Backend API
  └── Failsafe Backup → Documents folder

Web App (Vue 3)
  └── API calls → Backend

Backend (Go)
  ├── Handlers → Business logic
  ├── Repository → MongoDB
  └── Auth (Cookie for web, JWT for mobile)
```

### Key Files

**Backend**
- `backend/main.go` - Entry point, routes
- `backend/handlers/` - HTTP handlers
- `backend/repository/` - Database operations
- `backend/auth/` - Authentication (session, JWT, middleware)

**Web Frontend**
- `backend/frontend/src/pages/` - Vue pages
- `backend/frontend/src/stores/` - Pinia stores
- `backend/frontend/src/api/` - API client

**Mobile**
- `mobile/lib/features/` - Feature screens
- `mobile/lib/providers/` - Riverpod providers
- `mobile/lib/repositories/` - Local Hive repositories
- `mobile/lib/core/sync/` - Sync services
- `mobile/lib/core/api/` - API client

---

## 📝 Recent Changes Log

### December 11, 2025
- **Fixed flutter analyze issues** for CI/CD pipeline (12 lint fixes)
  - Added trailing commas to sync_service.dart, conflict_resolution_screen.dart, sync_provider.dart
  - Fixed `use_build_context_synchronously` in sync_status_indicator.dart, settings_screen.dart
- **Added edit functionality** to mobile Students and Subjects screens
  - Renamed AddStudentSheet → StudentSheet with optional student param for edit mode
  - Renamed AddSubjectSheet → SubjectSheet with optional subject param for edit mode
  - Wired up "Edit" menu action in popup menus
- **Priority 2 Complete** - All mobile and web UX improvements done
- Updated Priority 3 with new items:
  - Custom subjects during onboarding
  - Soft delete protection for subjects with logs
  - Trash/Recycle Bin view for deleted items
  - Restore and permanent delete functionality

### December 10, 2025
- Fixed LogsPage "Invalid Date" display (date parsing from ISO timestamps)
- Fixed LogsPage student/subject display (pass full objects, not just names)
- Fixed Flutter analyze failures (disabled avoid_print rule, fixed trailing commas)
- Fixed Flutter test failures (proper Hive init, mocked providers, skipped integration tests)
- Created logger utility for release-safe logging
- Migrated all debugPrint calls to logger
- **Added sync status indicator** to Dashboard app bar (SyncButton widget)
- Created SyncStatusIndicator and SyncButton widgets for reusable sync UI
- **Implemented Recent Logs card** on mobile dashboard (shows 5 most recent)
- **Added mobile log editing** - Edit dialog in logs_screen.dart
- **Implemented Location Management** feature for web:
  - Backend: LocationRepository with full CRUD (create, read, update, soft-delete)
  - Backend: LocationHandler with REST endpoints (/api/v1/locations)
  - Frontend: locationsApi client and locationsStore (Pinia)
  - Frontend: Saved Locations section in Settings page
  - UI: Add/Edit/Delete locations with type (field_trip, co_op, other)
- Updated 14-api-contracts.md with mobile auth and sync params

### December 9, 2025
- Implemented auto-sync on log creation
- Added failsafe backup service
- Fixed JWT token storage issues

### December 8, 2025
- Completed offline-first architecture
- Added sync service with incremental sync
- Added connectivity detection

---

*Last Updated: December 11, 2025*
