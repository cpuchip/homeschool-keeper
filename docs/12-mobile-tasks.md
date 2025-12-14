# Mobile App Development Tasks (Flutter)

**Directory**: `/mobile`

---

## Phase 1: Foundation & Core Logging

### 1.1 Project Setup
- [ ] Create Flutter project: `flutter create --org com.stuffleberry homeschool_keeper`
- [ ] Create directory structure:
  ```
  mobile/
  ├── lib/
  │   ├── main.dart
  │   ├── app.dart
  │   ├── config/
  │   │   ├── env.dart
  │   │   ├── routes.dart
  │   │   └── theme.dart
  │   ├── core/
  │   │   ├── api/
  │   │   ├── database/
  │   │   ├── errors/
  │   │   └── utils/
  │   ├── features/
  │   │   ├── auth/
  │   │   ├── dashboard/
  │   │   ├── students/
  │   │   ├── subjects/
  │   │   ├── logs/
  │   │   └── settings/
  │   ├── models/
  │   ├── providers/
  │   └── widgets/
  ├── assets/
  ├── test/
  ├── android/
  ├── ios/
  └── pubspec.yaml
  ```
- [ ] Add dependencies to pubspec.yaml:
  ```yaml
  dependencies:
    flutter_riverpod: ^2.4.0
    go_router: ^12.0.0
    dio: ^5.3.0
    sqflite: ^2.3.0
    hive_flutter: ^1.1.0
    freezed_annotation: ^2.4.0
    json_annotation: ^4.8.0
    image_picker: ^1.0.0
    cached_network_image: ^3.3.0
    intl: ^0.18.0
    flutter_secure_storage: ^9.0.0
  dev_dependencies:
    freezed: ^2.4.0
    json_serializable: ^6.7.0
    build_runner: ^2.4.0
    flutter_test:
    mocktail: ^1.0.0
  ```
- [ ] Configure app icons and splash screen
- [ ] Set up Android/iOS signing configs

### 1.2 Theme & Design System
- [ ] **lib/config/theme.dart**
  - Define color palette (match web)
  - Typography scale
  - Spacing constants
  - Component themes (buttons, cards, inputs)
- [ ] Light and dark mode support
- [ ] Custom icon set for subjects

### 1.3 Data Models (Freezed)
- [ ] **lib/models/user.dart** - with fromJson/toJson
- [ ] **lib/models/organization.dart**
- [ ] **lib/models/student.dart**
- [ ] **lib/models/subject.dart**
- [ ] **lib/models/log_entry.dart**
- [ ] **lib/models/attachment.dart**
- [ ] Run build_runner to generate code

### 1.4 Local Database Setup
- [ ] **lib/core/database/database_helper.dart**
  - SQLite initialization
  - Migration system
- [ ] Create tables:
  - users, organizations, students, subjects, log_entries, attachments
  - sync_queue (for offline changes)
- [ ] **lib/core/database/daos/**
  - StudentDao, SubjectDao, LogEntryDao
  - CRUD operations

### 1.5 API Client
- [ ] **lib/core/api/api_client.dart**
  - Dio instance with base URL
  - Request interceptor: attach JWT
  - Response interceptor: handle 401, refresh token
  - Offline detection
- [ ] **lib/core/api/auth_api.dart**
- [ ] **lib/core/api/students_api.dart**
- [ ] **lib/core/api/subjects_api.dart**
- [ ] **lib/core/api/logs_api.dart**
- [ ] **lib/core/api/stats_api.dart**

### 1.6 Riverpod Providers
- [ ] **lib/providers/auth_provider.dart**
  - authStateProvider (AsyncNotifier)
  - currentUserProvider
  - isAuthenticatedProvider
- [ ] **lib/providers/organization_provider.dart**
  - organizationProvider
  - settingsProvider
- [ ] **lib/providers/students_provider.dart**
  - studentsListProvider
  - studentByIdProvider(id)
- [ ] **lib/providers/subjects_provider.dart**
  - subjectsListProvider
  - coreSubjectsProvider
  - electiveSubjectsProvider
- [ ] **lib/providers/logs_provider.dart**
  - logsProvider (with filters)
  - createLogProvider
- [ ] **lib/providers/stats_provider.dart**
  - studentStatsProvider(id)
  - orgStatsProvider

### 1.7 Router Setup (GoRouter)
- [ ] **lib/config/routes.dart**
  - / → redirect to /dashboard or /login
  - /login, /register
  - /dashboard
  - /log (quick log)
  - /students, /students/:id
  - /subjects
  - /logs
  - /settings
- [ ] Auth redirect logic
- [ ] Bottom navigation shell route

### 1.8 Common Widgets
- [ ] **lib/widgets/app_button.dart** - Primary, secondary, text variants
- [ ] **lib/widgets/app_text_field.dart** - With label, error, icons
- [ ] **lib/widgets/app_dropdown.dart** - Styled dropdown
- [ ] **lib/widgets/app_card.dart**
- [ ] **lib/widgets/loading_overlay.dart**
- [ ] **lib/widgets/error_widget.dart**
- [ ] **lib/widgets/empty_state.dart**
- [ ] **lib/widgets/hour_picker.dart** ⭐
  - Plus/minus buttons
  - Display current value
  - Quick preset chips (0.5, 1, 1.5, 2, 3)
  - Respects increment setting
  - Haptic feedback

### 1.9 Auth Feature
- [ ] **lib/features/auth/login_screen.dart**
  - Email/password fields
  - Login button with loading state
  - Link to register
  - Biometric login option (future)
- [ ] **lib/features/auth/register_screen.dart**
  - Name, email, password fields
  - Password strength indicator
  - Terms checkbox
- [ ] Secure token storage (flutter_secure_storage)

### 1.10 Dashboard Feature
- [ ] **lib/features/dashboard/dashboard_screen.dart**
  - Today's date header
  - Quick stats row (hours per student today)
  - Large "Quick Log" FAB
  - Week progress section
  - Year progress section
  - Recent logs list
- [ ] **lib/features/dashboard/widgets/progress_card.dart**
- [ ] **lib/features/dashboard/widgets/student_stats_card.dart**
- [ ] Pull-to-refresh

### 1.11 Quick Log Feature ⭐ (Critical Path)
- [ ] **lib/features/logs/quick_log_screen.dart**
  - Student dropdown
  - Subject dropdown with color dots
  - HourPicker widget (center focus)
  - Date picker (defaults today)
  - Description field
  - Add photo button
  - Save button
  - "Save & Add Another" option
- [ ] Auto-focus keyboard on description
- [ ] Haptic feedback on hour changes
- [ ] Success animation/feedback
- [ ] Remember last student selection
- [ ] Offline support: queue for sync

### 1.12 Students Feature
- [ ] **lib/features/students/students_list_screen.dart**
  - List with avatars
  - Tap to view detail
  - FAB to add
- [ ] **lib/features/students/student_detail_screen.dart**
  - Info header
  - Progress rings
  - Subject breakdown
  - Recent logs
- [ ] **lib/features/students/student_form_screen.dart**
  - Add/edit form

### 1.13 Subjects Feature
- [ ] **lib/features/subjects/subjects_screen.dart**
  - Core section
  - Electives section
  - Add button
- [ ] **lib/features/subjects/subject_form_screen.dart**
  - Name, type toggle, hours, color picker

### 1.14 Logs Feature
- [ ] **lib/features/logs/logs_list_screen.dart**
  - Filter chips (student, subject)
  - Date range selector
  - Infinite scroll list
  - Swipe to delete
- [ ] **lib/features/logs/log_detail_screen.dart**
  - View/edit log
  - View attachments

### 1.15 Settings Feature
- [ ] **lib/features/settings/settings_screen.dart**
  - Organization section
    - Hour increment picker
    - School year dates
    - Timezone
  - Account section
    - Edit profile
    - Change password
  - App section
    - Theme (light/dark/system)
    - Notifications
  - About section
  - Logout button

---

## Phase 2: File Uploads & Offline Sync

### 2.1 Image Capture & Upload
- [ ] Camera integration (image_picker)
- [ ] Gallery picker
- [ ] Image compression before upload
- [ ] Upload progress indicator
- [ ] Store locally with log entry
- [ ] Sync to server when online

### 2.2 Attachment Viewer
- [ ] Image gallery viewer
- [ ] Pinch to zoom
- [ ] Share option
- [ ] Delete option

### 2.3 Offline Sync System
- [ ] **lib/core/sync/sync_service.dart**
  - Detect online/offline
  - Queue changes when offline
  - Sync on reconnect
  - Conflict resolution (server wins? last write wins?)
- [ ] Sync status indicator in UI
- [ ] Manual sync button

### 2.4 Export
- [ ] Generate PDF locally (pdf package)
- [ ] Share via system share sheet

---

## Phase 3: Curriculum Planning

### 3.1 Topics
- [ ] Topics list screen
- [ ] Topic form screen
- [ ] Topic detail with progress

### 3.2 Planner
- [ ] Weekly calendar view
- [ ] Daily task list
- [ ] Complete task → log entry

---

## Phase 4: Student Portal & Notifications

### 4.1 Push Notifications
- [ ] Firebase Cloud Messaging setup
- [ ] Daily reminder notifications
- [ ] Parent approval notifications

### 4.2 Student Mode
- [ ] Student login flow
- [ ] Restricted navigation
- [ ] Submit logs for approval
- [ ] View own progress

---

## Testing

### Unit Tests
- [ ] All providers
- [ ] Database DAOs
- [ ] API client error handling
- [ ] Model serialization

### Widget Tests
- [ ] HourPicker widget
- [ ] Form widgets
- [ ] Screen layouts

### Integration Tests
- [ ] Auth flow
- [ ] Quick log flow
- [ ] Offline → online sync

---

## DevOps
- [ ] Fastlane setup for iOS/Android
- [ ] GitHub Actions: test, build
- [ ] App Store / Play Store listings
- [ ] Beta testing (TestFlight, Firebase App Distribution)
