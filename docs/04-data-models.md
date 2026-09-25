# Data Models (Draft)

## Organization/Family
```
Organization {
  id: ObjectId
  name: string
  createdAt: DateTime
  settings: {
    hourIncrement: 0.25 | 0.5 | 1.0  // default 0.25
    schoolYearStart: Date
    schoolYearEnd: Date
    timezone: string
  }
}
```

## Users
```
User {
  id: ObjectId
  organizationId: ObjectId
  email: string
  passwordHash: string
  role: "admin" | "student"
  name: string
  dateOfBirth: Date  // for COPPA compliance
  createdAt: DateTime
  parentalConsentGiven: boolean  // required for under-13
}
```

## Students (Profile, not login)
```
Student {
  id: ObjectId
  organizationId: ObjectId
  userId: ObjectId?  // linked if student has login
  name: string
  dateOfBirth: Date
  gradeLevel: string
  active: boolean
}
```

## Subjects
```
Subject {
  id: ObjectId
  organizationId: ObjectId
  name: string
  type: "core" | "elective"
  targetHours: number  // annual goal
  color: string  // for UI
}
```

## Log Entry
```
LogEntry {
  id: ObjectId
  organizationId: ObjectId
  studentId: ObjectId
  subjectId: ObjectId
  topicId: ObjectId?  // optional link to curriculum plan
  date: Date
  hours: number
  description: string
  location: "home" | "other"
  status: "pending" | "approved"  // for student-submitted
  submittedBy: ObjectId  // user who created
  approvedBy: ObjectId?
  attachments: Attachment[]
  createdAt: DateTime
}
```

## Attachment (Work Samples)
```
Attachment {
  id: ObjectId
  logEntryId: ObjectId
  filename: string
  mimeType: string
  size: number
  storagePath: string  // encrypted file location
  thumbnail: string?
}
```

## Curriculum Plan (Phase 3)
```
Topic {
  id: ObjectId
  organizationId: ObjectId
  name: string  // e.g., "Story of the World"
  subjectId: ObjectId
  description: string
  targetHours: number
  studentIds: ObjectId[]  // which students
  schoolYear: string
}

PlannedTask {
  id: ObjectId
  topicId: ObjectId
  studentId: ObjectId
  scheduledDate: Date
  estimatedHours: number
  completed: boolean
  logEntryId: ObjectId?  // linked when logged
}
```
