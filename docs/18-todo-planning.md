# Todo & Lesson Planning Feature

## Purpose

Enhance Home School Logs with integrated planning capabilities that allow families to:
- Plan daily/weekly/monthly lesson schedules
- Track completion of planned activities
- **Auto-log hours when todos are completed** (reduces manual logging friction)
- Tie planning to subjects (optional) or keep it flexible

This addresses a common homeschool pain point: planning what to teach AND tracking what was taught are often separate tools. We can unify them.

---

## User Stories

### Core Use Cases

1. **Structured Curriculum Mom**
   > "I have a set curriculum for Math and Reading. I want to plan out weekly lessons and check them off as we do them."

2. **Relaxed/Unschooling Parent**
   > "I don't plan day-by-day, but I have general goals for the month. I want to jot them down and mark them done when we naturally get to them."

3. **Co-op Coordinator**
   > "I need to track what topics we cover each week so parents know what to prep at home."

4. **Working Parent**
   > "I front-load planning on weekends, then just check off items during the week. Less thinking on busy days."

5. **Multi-Student Household**
   > "My 3rd grader and 7th grader have different plans. I need to see what each kid has to do today."

---

## Feature Brainstorm

### Core Planning Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **Quick Todo** | Fast single-task entry (title, optional subject, optional student) | High |
| **Daily View** | See today's todos grouped by student | High |
| **Weekly View** | 7-day spread, drag to reschedule | High |
| **Auto-Log on Complete** | Completing a todo creates a log entry with preset hours | High |
| **Subject Linking** | Optional: tie todo to a subject for categorized logging | Medium |
| **Recurring Todos** | Daily, weekly, custom patterns | Medium |
| **Monthly View** | Calendar overview of the month | Medium |
| **School Year Plan** | High-level goals per term/semester | Low |
| **Templates** | Save todo sets as reusable templates | Low |

### Auto-Log Mechanics

When a todo is marked complete:
1. **If subject linked**: Create log entry for that subject
2. **If hours preset**: Use those hours (default: family's default increment, e.g., 0.25h)
3. **If student assigned**: Log to that student
4. **If group todo**: Log to multiple students (like multi-student quick log)
5. **Optional description**: Pre-filled from todo title/notes

**User can always edit** the generated log before or after saving.

### Todo Item Fields

```typescript
interface TodoItem {
  id: string;
  familyId: string;          // Always required
  title: string;             // Required - "Read Chapter 5"
  description?: string;      // Optional details
  
  // Assignment
  studentId?: string;        // null = family-wide todo
  studentIds?: string[];     // For multi-student todos
  
  // Subject linking (for auto-log)
  subjectId?: string;        // Optional subject tie
  estimatedHours?: number;   // For auto-log (default: family increment)
  
  // Scheduling
  dueDate?: Date;            // Specific date
  dueTime?: string;          // Optional time of day
  
  // Recurrence
  recurring?: {
    pattern: 'daily' | 'weekly' | 'monthly' | 'custom';
    interval?: number;       // Every N days/weeks/months
    daysOfWeek?: number[];   // [1, 3, 5] = Mon, Wed, Fri
    endDate?: Date;
    endAfterOccurrences?: number;
  };
  
  // Completion
  completed: boolean;
  completedAt?: Date;
  completedBy?: string;      // userId
  
  // Auto-log
  autoLog: boolean;          // Default true
  logEntryId?: string;       // Reference to created log
  
  // Organization
  priority?: 'low' | 'normal' | 'high';
  tags?: string[];           // User-defined tags
  
  // Metadata
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}
```

### Views & UI

#### Daily View (Primary)
```
┌──────────────────────────────────────────┐
│  📅 Friday, December 13, 2025            │
│  ← Yesterday    Today    Tomorrow →      │
├──────────────────────────────────────────┤
│  👧 Emma (3rd Grade)                     │
│  ┌────────────────────────────────────┐  │
│  │ ☐ Math: Fractions Worksheet (0.5h) │  │
│  │ ☐ Reading: Chapter 5              │  │
│  │ ☑ Science: Plant Observation ✓    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  👦 Jake (7th Grade)                     │
│  ┌────────────────────────────────────┐  │
│  │ ☐ Algebra: Section 3.2 (1h)       │  │
│  │ ☐ History: Civil War Essay        │  │
│  │ ☐ PE: 30 min activity             │  │
│  └────────────────────────────────────┘  │
│                                          │
│  🏠 Family                               │
│  ┌────────────────────────────────────┐  │
│  │ ☐ Field trip to Science Museum    │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

#### Weekly View
```
┌────────────────────────────────────────────────────────────┐
│  📅 Week of Dec 9-15, 2025                    ← Week  → │
├─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬───────────┤
│     │ Mon │ Tue │ Wed │ Thu │ Fri │ Sat │ Sun │           │
├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼───────────┤
│Emma │ 3   │ 4   │ 2   │ 4   │ 3   │  -  │  -  │ 16 items  │
│Jake │ 4   │ 3   │ 4   │ 3   │ 4   │  1  │  -  │ 19 items  │
├─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴───────────┤
│ [Tap a day to see todos] [Drag to reschedule]            │
└──────────────────────────────────────────────────────────┘
```

### Completion Flow with Auto-Log

```
User taps ☐ → ☑

┌───────────────────────────────────────────────┐
│  ✅ Complete: Math Fractions Worksheet        │
├───────────────────────────────────────────────┤
│                                               │
│  Log this activity?                           │
│                                               │
│  Student:  Emma                               │
│  Subject:  Math ▼                             │
│  Hours:    [0.5] ← editable                   │
│  Notes:    [Completed worksheet]              │
│                                               │
│  ┌─────────────────┐  ┌─────────────────┐     │
│  │   Skip Log      │  │   Log & Done    │     │
│  └─────────────────┘  └─────────────────┘     │
│                                               │
│  ☐ Don't ask for this todo type              │
└───────────────────────────────────────────────┘
```

### Quick Actions

- **Swipe right**: Complete + auto-log (no dialog)
- **Swipe left**: Reschedule to tomorrow
- **Long press**: Edit / Delete / Duplicate
- **Tap**: View details / Edit

---

## Integration Points

### With Existing Features

| Feature | Integration |
|---------|-------------|
| **Subjects** | Link todos to subjects for categorized logging |
| **Students** | Assign todos per student or family-wide |
| **Log Entries** | Auto-create logs on todo completion |
| **Stats Dashboard** | Show planned vs actual hours |
| **Locations** | Link todos to locations (field trips) |
| **Multi-student logs** | Group todos for multiple students |
| **Export** | Include todo completion in reports |

### New Dashboard Widgets

- **Today's Todos** card: Quick view of incomplete items
- **Planned vs Logged** widget: Show goal tracking
- **Streak** indicator: Days with completed todos

---

## Architecture Considerations

### Data Model

New collections:
- `todo_items` - Individual todo entries
- `todo_templates` - Saved reusable templates (Phase 2)

### Offline Support (Mobile)

- Todos stored in Hive like other entities
- Sync with same pattern as logs
- Conflict resolution: Server wins for sync, but local changes queue

### Recurrence Handling

Two approaches:

**Option A: Generate instances**
- Create individual todo items for each occurrence
- Pros: Simple queries, easy completion tracking
- Cons: Storage growth, cleanup needed

**Option B: Single recurring + instances on demand**
- Store pattern, generate daily view dynamically
- Track completions separately
- Pros: Less storage, cleaner
- Cons: More complex queries

**Recommendation**: Option A with cleanup (archive completed items after school year)

---

## Implementation Phases

### Phase 1: Core Todo (MVP)
- [ ] Todo model and repository (Go backend)
- [ ] CRUD endpoints for todos
- [ ] Daily view (mobile + web)
- [ ] Basic completion (no auto-log yet)
- [ ] Student assignment

### Phase 2: Auto-Log Integration
- [ ] Auto-log dialog on completion
- [ ] Subject linking
- [ ] Hours preset per todo
- [ ] Settings for auto-log behavior

### Phase 3: Views & Scheduling
- [ ] Weekly view
- [ ] Reschedule via drag/drop (web) or swipe (mobile)
- [ ] Tomorrow quick-reschedule

### Phase 4: Recurring & Templates
- [ ] Recurring todo patterns
- [ ] Template creation and use
- [ ] Monthly view

### Phase 5: Advanced
- [ ] Dashboard integration
- [ ] Planned vs actual reporting
- [ ] Streaks and gamification
- [ ] Share templates between families (opt-in)

---

## Open Questions

1. **Separate page or integrated?**
   - New "Plan" tab? Or integrate into Dashboard?
   - Mobile: Bottom nav addition?

New plan tab I think makes sense for clarity and mode switching, allowing focused planning sessions.

2. **Granularity of auto-log?**
   - Every completed todo = log entry? (could be noisy)
   - Batch at end of day?
   - User preference per todo?

I'd lean toward per-todo with an option to skip logging for certain todos.

3. **Recurring todo scope?**
   - Just daily/weekly? Or full calendar recurrence?
   - How to handle "catch up" on missed days?

This is a complex area here. I like full calendar recurrence. I think for missed days we should allow the to choose between bunting them or skipping. Leaving todo's undone is fine too I think. Bunting them should move the todo to the next occurrence date and remove it from the missed date. I think that's important if a user has each day planned out with custom todos in the series. but if they are all idential todos then maybe we can just leave them undone/skipped.

4. **Template sharing?**
   - Allow sharing between families? (community templates)
   - Curated templates from us? (Missouri 3rd grade starter pack)

This isn't a bad idea here. but pass for MVP. we'll need to think through moderation and curation if we go this route. I think custom to do this correctly we allow detailed plans where todo's are lesson outlines with resources and links. that is a bigger feature.

5. **Integration with external curricula?**
   - Import from popular homeschool curricula?
   - API integrations with curriculum providers?

This would be epic! but it's a huge undertaking. we can consider this a long-term goal, not for MVP. But we should research popular homeschool curricula and see if there are any public APIs or data formats we can leverage in the future.

---

## Competitive Analysis

### Competitor Deep Dive

---

### 1. Homeschool Tracker
**Website**: https://www.homeschooltracker.com/  
**Established**: 20+ years in business  
**Pricing**: $8/month, $65/year, $119/2-year (no free trial)

**Strengths**:
- Most mature and feature-complete solution
- Powerful reusable lesson plan library (user-generated + share)
- Drag-and-drop calendar with bulk rescheduling
- Comprehensive grading (weighted, custom scales, partial credit)
- Professional transcripts (Ivy League approved per testimonials)
- Up to 20 students, 3+ teachers per account
- Co-op/school bulk discounts
- Extensive training: webinars, video tutorials, help guides

**Weaknesses**:
- No free trial (must pay monthly to test)
- Web-only (no dedicated mobile app mentioned)
- Complex UI - feels "heavy" and dated
- Higher learning curve ("Getting Started" video series required)
- No offline capability mentioned

**Key Reports**: Attendance, course list, daily task list, report cards, transcripts, time spent, skills, supplies, scope & sequence

---

### 2. Homeschool Manager
**Website**: https://homeschoolmanager.com/  
**Pricing**: $5.99/month or $49/year (30-day free trial)

**Strengths**:
- Simple, focused on ease of use ("simpler than paper")
- Weekly schedule view with drag-and-drop
- Unlimited students & subjects
- Time tracking per course (auto-calculated from course setup)
- Attendance tracking (days with completed assignments)
- Report cards & transcripts
- Volunteer hours tracking (unique feature)
- Book lists feature
- Quick add tasks
- 30-day free trial, no credit card

**Weaknesses**:
- Dated UI (copyright 2020, minimal updates since)
- Web-only (no mobile app)
- Limited feature set compared to Homeschool Tracker
- No lesson plan library/sharing
- Blog/updates seem stale

**Key Differentiator**: Volunteer hours tracking is unique - good for extracurriculars/service hours for college apps

---

### 3. My Home School Grades
**Website**: https://myhomeschoolgrades.com/  
**Pricing**: $5.99/month or $49.99/year (30-day money back guarantee)

**Strengths**:
- Focus on grades and transcripts (college-ready)
- Curriculum library included + add your own
- Copy classes between students (great for similar-age siblings)
- Multi-student class assignments (for multiples/co-ops)
- Lesson plans with notes and print option
- Extracurricular activity tracking
- Attendance tracking (by day OR by hours per day)
- Color-coded attendance by student
- Professional transcripts (accepted by colleges per testimonials)
- Phone support (7 days a week, 6AM-10PM Pacific)
- Event calendar with recurring events
- Auto-reschedule lessons when rescheduling

**Weaknesses**:
- Gradebook-focused (name implies grades, not logging)
- Web-only interface
- UI looks functional but not modern
- No offline support

**Key Differentiator**: Strong transcript focus, excellent phone support hours, curriculum library

---

### 4. Homeschooly (myhomeschooly.com)
**Website**: https://www.myhomeschooly.com/  
**Pricing**: $4.99/month, $26.99/6-month, $49.99/year (30-day free trial - "4x longer than competitors")

**Strengths**:
- **Newest/most modern competitor** - "Built by homeschool parents"
- Drag-and-drop visual calendar
- Vacation auto-rescheduling
- One-click time logging
- Automatic state compliance reports
- Beautiful analytics dashboard
- Unlimited students (no extra charge)
- Student self-service portal with approval workflows
- Real-time family messaging + file sharing
- AI-powered insights (learning patterns, schedule optimization)
- 30-day trial (markets as "4x longer than competitors")
- Secure & private (no ads, no data selling)

**Weaknesses**:
- Very new (2025) - less proven
- Some features "Coming Soon" (student portal)
- AI features may be limited at launch
- No dedicated mobile app mentioned (responsive web?)

**Key Differentiator**: Modern UX, AI features, family collaboration hub, competitive on pricing

**⚠️ DIRECT COMPETITOR** - Similar positioning to Home School Logs

---

### 5. SchoolhouseTeachers.com
**Website**: https://schoolhouseteachers.com/  
**Pricing**: $34.99/month, $89/quarter, $389/year

**Strengths**:
- **Complete curriculum platform** (100s of courses Pre-K-12)
- Virtual School Boxes (complete curriculum by grade)
- Applecore recordkeeping system
- Education Plan Builder
- Transcript & report card generation
- Custom schedule builder
- Scope & sequence guides
- Course certificates
- 25,000+ streaming videos
- World Book Online included
- Christian-focused content
- International support

**Weaknesses**:
- **Different category** - curriculum provider with recordkeeping, not recordkeeping tool
- Expensive ($389/year vs $50-65/year for others)
- Only useful if you use their curriculum
- Record keeping is secondary feature, not core
- No hour logging focus

**Key Differentiator**: Full curriculum platform - you buy the curriculum AND get recordkeeping. Not comparable to standalone logging tools.

---

### 6. MyHomeschoolApp
**Website**: https://myhomeschoolapp.com/  
**Status**: Appears to be login-only, minimal public info

**Notes**: Could not evaluate - website shows only login page. May be discontinued or private beta.

---

### Competitive Matrix

| Feature | Home School Logs | Homeschool Tracker | Homeschool Manager | My HS Grades | Homeschooly |
|---------|-----------------|-------------------|-------------------|--------------|-------------|
| **Pricing (annual)** | TBD (Free?) | $65 | $49 | $50 | $50 |
| **Free Trial** | ✅ Yes | ❌ No | ✅ 30 days | ❌ (30-day refund) | ✅ 30 days |
| **Mobile App** | ✅ Native iOS/Android | ❌ Web only | ❌ Web only | ❌ Web only | ❌ Web only |
| **Offline Mode** | ✅ Full offline | ❌ | ❌ | ❌ | ❌ |
| **Hour Logging** | ✅ Core feature | ⚠️ Time spent report | ⚠️ Course-based | ✅ By day/hours | ✅ One-click |
| **Quick Log** | ✅ | ❌ | ⚠️ Quick add | ❌ | ⚠️ |
| **Multi-Student Log** | ✅ | ❌ | ⚠️ Multi-student tasks | ✅ Multi-student class | ❓ |
| **Grading** | ❌ (not core) | ✅ Advanced | ✅ Basic | ✅ Core feature | ✅ |
| **Transcripts** | ❌ (future) | ✅ Professional | ✅ | ✅ Professional | ⚠️ |
| **Lesson Planning** | ⚠️ (Todo feature) | ✅ Full | ✅ Weekly | ✅ Curriculum | ✅ Drag-drop |
| **Lesson Plan Library** | ❌ | ✅ User-shared | ❌ | ✅ Curriculum | ❌ |
| **Drag-Drop Calendar** | ⚠️ (planned) | ✅ | ✅ | ✅ | ✅ |
| **Recurring Events** | ⚠️ (planned) | ✅ | ⚠️ | ✅ | ✅ |
| **State Compliance** | ⚠️ Missouri only | ⚠️ Generic | ⚠️ Generic | ⚠️ | ✅ Auto reports |
| **PDF Export** | ✅ | ✅ Many reports | ✅ | ✅ | ✅ |
| **CSV Export** | ✅ | ✅ | ❓ | ❓ | ✅ |
| **Student Accounts** | ⚠️ (planned) | ✅ | ❌ | ❌ | ✅ (coming) |
| **Family Messaging** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Work Samples** | ⚠️ (planned) | ❓ | ❌ | ❌ | ✅ File sharing |
| **Volunteer Hours** | ❌ | ❌ | ✅ | ✅ Extracurricular | ❓ |
| **Co-op Support** | ✅ Organizations | ✅ Bulk pricing | ❌ | ✅ Multi-student | ❓ |
| **Established** | 2024 | 20+ years | ~2015 | ~2015 | 2024-2025 |

---

### What They Do That We Don't (Yet)

1. **Grading System**
   - Weighted grades, GPA calculation, grade scales
   - *Decision*: Not our core focus, but could add basic grading later

2. **Transcripts**
   - College-ready formatted transcripts
   - *Decision*: Important for high schoolers - add to roadmap

3. **Lesson Plan Library/Sharing**
   - User-contributed, reusable plans
   - *Decision*: Could be powerful with Todo feature

4. **Curriculum Integration**
   - Pre-loaded curriculum assignments
   - *Decision*: Long-term goal, major undertaking

5. **Volunteer/Extracurricular Hours**
   - Separate tracking for non-academic activities
   - *Decision*: Easy add - could enhance Location feature

6. **Book Lists**
   - Track books read per student
   - *Decision*: Nice-to-have for reading logs

---

### What We Do Better

| Our Advantage | Why It Matters |
|--------------|----------------|
| **Native Mobile App** | No competitor has a true native mobile app. We have Flutter on iOS/Android with full offline support. Parents log on-the-go. |
| **Offline-First** | Works without internet. Sync when connected. Field trips, co-ops, travel - logging never stops. |
| **Hour Logging Focus** | We're built around tracking hours (Missouri 1000/600 requirement). Others bolt it on. |
| **Quick Log UX** | One-tap logging with presets. Reduce friction to seconds. |
| **Multi-Student Logging** | Log one activity for multiple students at once (co-op, group lessons). Others require per-student entry. |
| **Modern Tech Stack** | Vue 3, Flutter, Go, MongoDB - fast, maintainable, scalable. Competitors show their age. |
| **Free/Affordable** | Targeting free tier or low-cost. Competitors $50-65/year. |
| **Co-op/Organization** | First-class support for homeschool co-ops with proper data isolation. |
| **Privacy Focus** | Anonymous telemetry, COPPA-aware design, encryption at rest. |

---

### Our Positioning Statement

> **Home School Logs** is the mobile-first, offline-capable hour logging app for homeschool families who need to track learning hours for state compliance.
> 
> Unlike curriculum-focused tools that treat logging as an afterthought, we make hour tracking effortless with quick logging, multi-student support, and a native mobile app that works anywhere.
> 
> For parents who want to spend more time teaching and less time record-keeping.

---

### Competitive Threats

1. **Homeschooly** is the most direct threat
   - Similar positioning, modern UX, aggressive marketing (30-day trial, AI features)
   - Watch closely for feature releases
   - We beat them on: native mobile, offline, established codebase

2. **Homeschool Tracker** has 20 years of trust
   - Hard to compete on feature depth
   - We beat them on: mobile, modern UX, free tier, simplicity

3. **Generic Tools (Notion/Trello)**
   - Free, flexible, but require setup
   - We beat them on: purpose-built, compliance reports, no configuration

---

### Opportunities to Differentiate

1. **Auto-Log from Todos** (this document!)
   - Complete a todo → log created automatically
   - No competitor does this seamlessly

2. **State-Specific Compliance**
   - Pre-configured for each state's requirements
   - Auto-validate against state minimums
   - Progress bars: "You need 127 more core hours"

3. **Photo Work Samples**
   - Attach photos to log entries
   - Build portfolio evidence for evaluations
   - No competitor does this well on mobile

4. **Location-Based Logging**
   - Suggest subjects/hours based on location
   - "You're at the Science Museum - log a field trip?"

5. **Timer Mode**
   - Start/stop timer for activities
   - Auto-calculate hours (instead of manual entry)
   - Good for unschoolers/relaxed tracking

6. **AI Subject Suggestions**
   - "Based on your description, this sounds like Science (Biology)"
   - Auto-categorize free-form logs

---

## Technical Notes

### One Todo → Many Logs

**Q: Can we have one TODO link to many logs?**

**A: Yes!** This makes sense for several scenarios:

1. **Multi-student todos**: One "Math class" todo → creates log for each student
2. **Recurring todos**: Daily "Reading" → each completion creates a new log
3. **Re-doing a todo**: Student retakes a lesson → logs each attempt

**Implementation**:
```typescript
interface TodoItem {
  // ... existing fields ...
  
  // Links to created logs (1:many relationship)
  logEntryIds?: string[];  // Array instead of single ID
  
  // Track completion instances for recurring todos
  completions?: {
    date: Date;
    logEntryId?: string;
    skipped: boolean;
    notes?: string;
  }[];
}
```

For recurring todos, each occurrence can have its own completion record, allowing:
- Some days completed with logs
- Some days skipped (no log)
- Some days completed without logging (user choice)

### API Endpoints

```
GET    /api/v1/todos              List todos (filters: date, student, completed)
POST   /api/v1/todos              Create todo
GET    /api/v1/todos/:id          Get todo
PUT    /api/v1/todos/:id          Update todo
DELETE /api/v1/todos/:id          Delete todo
PATCH  /api/v1/todos/:id/complete Mark complete (with auto-log option)
POST   /api/v1/todos/batch        Create multiple todos
GET    /api/v1/todos/daily/:date  Get todos for specific date
GET    /api/v1/todos/weekly       Get week view data
```

### Mobile Hive Box

```dart
@HiveType(typeId: 10) // Next available ID
class TodoItem extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String familyId;
  
  @HiveField(2)
  late String title;
  
  // ... etc
}
```

---

## Success Metrics

- **Adoption**: % of active families using todos
- **Engagement**: Avg todos completed per week
- **Auto-log conversion**: % of completions that generate logs
- **Retention**: Correlation between todo usage and app retention
- **Time savings**: User survey on reduced planning/logging time

---

*Created: December 13, 2025*
*Status: Brainstorming - Competitive Analysis Complete*

---

## Strategic Roadmap (Based on Competitive Analysis)

### Phase A: Cement Core Advantage (Current)
**Goal**: Be the best at what we already do well

- [x] Mobile app with offline
- [x] Quick logging UX
- [x] Multi-student logging
- [x] PDF/CSV export
- [ ] Work samples (photos) - **HIGH PRIORITY** (no competitor does this well on mobile)
- [ ] Timer mode for activities

### Phase B: Todo/Planning Feature (This Document)
**Goal**: Reduce friction between planning and logging

- [ ] Todo MVP (daily view, completion, auto-log)
- [ ] Weekly view with drag-drop
- [ ] Recurring todos
- [ ] Templates (save common todo sets)

### Phase C: State Compliance Excellence
**Goal**: Be THE app for state compliance

- [ ] Multi-state requirement database
- [ ] Auto-validate against state minimums
- [ ] Progress visualization ("127 core hours remaining")
- [ ] State-specific export formats
- [ ] Compliance alerts/reminders

### Phase D: Transcript & High School
**Goal**: Serve high schoolers heading to college

- [ ] Basic grading (optional per log)
- [ ] Course credits tracking
- [ ] GPA calculation
- [ ] Transcript generation
- [ ] Volunteer/extracurricular hours

### Phase E: Collaboration & Community
**Goal**: Support co-ops and sharing

- [ ] Enhanced co-op features
- [ ] Template sharing (marketplace?)
- [ ] Curriculum integration research
- [ ] Family messaging (if needed)

---

## Pricing Strategy Research

| Competitor | Monthly | Annual | Free Tier |
|------------|---------|--------|-----------|
| Homeschool Tracker | $8 | $65 | ❌ (free Basic edition, limited) |
| Homeschool Manager | $5.99 | $49 | ❌ |
| My HS Grades | $5.99 | $49.99 | ❌ |
| Homeschooly | $4.99 | $49.99 | ❌ (30-day trial) |

**Pricing Options for Home School Logs**:

1. **Freemium Model**
   - Free: 1-2 students, basic logging, limited exports
   - Pro ($4.99/mo or $39.99/yr): Unlimited students, all exports, sync
   - *Advantage*: Undercuts all competitors, builds user base

2. **Free with Premium Add-ons**
   - Core logging always free
   - Pay for: Transcripts, AI features, priority sync
   - *Advantage*: Lower barrier, revenue from power users

3. **Pay What You Can**
   - Suggested price with slider
   - *Advantage*: Accessible to all, community goodwill

4. **Donation/Sponsor Model**
   - Free for families, seek sponsors/grants
   - *Advantage*: Mission-aligned, but less sustainable

**Recommendation**: Start with generous free tier (3 students, full features). Premium for co-ops/unlimited. Validate demand before complex pricing.
