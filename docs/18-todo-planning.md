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
*Status: Brainstorming*

*See [19-market-analysis.md](19-market-analysis.md) for competitive analysis and pricing strategy.*
