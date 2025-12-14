# Development Phases

## Phase 1: Core Logging MVP
**Goal**: Parents can log daily hours for each student

### Features
- [ ] User registration/login (parent accounts)
- [ ] Create organization/family
- [ ] Add students to organization
- [ ] Configure subjects (preset core + custom electives)
- [ ] **Quick Log Entry** (primary workflow)
  - Select student
  - Select subject
  - Enter hours (spinner with configurable increments: 0.25, 0.5, 1.0)
  - Add description
  - Optional: attach photo
  - Auto-fill today's date
- [ ] View log history by student/date
- [ ] Basic hour totals (core vs elective)
- [ ] Account settings (hour increment preference)

### Phase 1 Deliverables
- Flutter mobile app (Android + iOS)
- Flutter web app
- Go backend API
- MongoDB schema
- Local SQLite for offline

---

## Phase 2: Export & Work Samples
**Goal**: Generate compliance documents

### Features
- [ ] Upload photos/documents per log entry
- [ ] Bulk photo upload
- [ ] Export options:
  - PDF report (hours by subject)
  - Excel spreadsheet (detailed logs)
  - ZIP of work samples per student
- [ ] Date range filtering for exports
- [ ] School year summary view

---

## Phase 3: Curriculum Planning
**Goal**: Plan ahead, then log against plans

### Features
- [ ] Create Topics (curriculum units)
  - Name, subject, description, target hours
  - Assign to students
- [ ] Weekly/daily planner view
- [ ] Drag-and-drop task scheduling
- [ ] Quick-log from planned tasks
- [ ] **Off-the-cuff logging** still fully supported
- [ ] Plan vs actual hours tracking

### Example Workflow
1. Create topic: "Story of the World" → History → 50 hours
2. Schedule: Week 1, Monday, 1 hour
3. Day of: Mark complete → auto-creates log entry
4. OR: Kid goes jogging → quick log 0.5 hours PE (unplanned)

---

## Phase 4: Reporting & Student Portal
**Goal**: Compliance dashboards + student self-service

### Features
- [ ] Student login accounts
- [ ] Students submit their own log entries
- [ ] Parent approval workflow
- [ ] Dashboard views:
  - Hours by student (progress to 1,000)
  - Hours by subject (progress to 600 core)
  - At-home hours (progress to 400)
- [ ] Drill-down reports
- [ ] Alerts for students falling behind
- [ ] Multi-state law presets (future)

---

## Phase 5: Cloud Sync (Paid Tier)
**Goal**: Multi-device, multi-user sync

### Features
- [ ] Account upgrade flow
- [ ] Conflict resolution for offline edits
- [ ] Real-time sync across devices
- [ ] Invite other parents/admins
- [ ] Student accounts with sync
- [ ] Backup/restore from cloud
