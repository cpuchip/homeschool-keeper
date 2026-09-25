# UI/UX Design Notes

## Primary Workflow: Quick Logging
This is the **most important** screen. Must be < 30 seconds to log an entry.

### Quick Log Screen
```
┌─────────────────────────────────────┐
│  [<] Quick Log              [Save]  │
├─────────────────────────────────────┤
│                                     │
│  Student:  [▼ Johnny        ]       │
│                                     │
│  Subject:  [▼ Math          ]       │
│                                     │
│  Hours:    [ - ]  1.5  [ + ]        │
│            (spinner with presets)   │
│                                     │
│  Date:     [Today ▼]                │
│                                     │
│  Notes:    ┌───────────────────┐    │
│            │ Practiced         │    │
│            │ multiplication... │    │
│            └───────────────────┘    │
│                                     │
│  📷 Add Photo                       │
│                                     │
│        [ Save & Add Another ]       │
│                                     │
└─────────────────────────────────────┘
```

### Hour Increment Settings
Account setting for hour steps:
- 0.25 (15 min) - default
- 0.5 (30 min)
- 1.0 (1 hour)

Common presets in spinner:
`0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0`

---

## Dashboard (Home Screen)
```
┌─────────────────────────────────────┐
│  Homeschool Keeper        [⚙] [👤]  │
├─────────────────────────────────────┤
│                                     │
│  Today: Dec 2, 2025                 │
│  ────────────────────               │
│  Johnny: 2.5 hrs | Sarah: 1.0 hrs   │
│                                     │
│  ┌─────────────────────────────┐    │
│  │    [ + Quick Log ]          │    │
│  └─────────────────────────────┘    │
│                                     │
│  This Week                          │
│  ├─ Johnny ████████░░ 18/25 hrs     │
│  └─ Sarah  ██████░░░░ 14/25 hrs     │
│                                     │
│  Year Progress (Johnny)             │
│  ├─ Total  ████░░░░░░ 450/1000      │
│  ├─ Core   █████░░░░░ 280/600       │
│  └─ Home   ██████░░░░ 220/400       │
│                                     │
│  Recent Logs                        │
│  ├─ Johnny | Math | 1.5 hrs | Today │
│  ├─ Sarah  | PE   | 0.5 hrs | Today │
│  └─ ...                             │
│                                     │
└─────────────────────────────────────┘
```

---

## Navigation Structure
```
Bottom Nav:
[Home] [Log] [Students] [Reports] [More]

Home     → Dashboard, recent activity
Log      → Quick log entry
Students → List, per-student details
Reports  → Export, compliance views
More     → Settings, account, help
```

---

## Color Coding Subjects
- Core subjects: Blue tones
- Electives: Green/purple tones
- Behind schedule: Orange/red warning

---

## Accessibility
- Minimum touch target: 48x48dp
- High contrast mode
- Screen reader labels
- Keyboard navigation (web)
