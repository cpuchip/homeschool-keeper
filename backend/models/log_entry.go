package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LogEntry represents a single log of hours for a student and subject
type LogEntry struct {
	ID             primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
	FamilyID       primitive.ObjectID  `bson:"familyId" json:"familyId"`                                 // always set - primary owner
	OrganizationID *primitive.ObjectID `bson:"organizationId,omitempty" json:"organizationId,omitempty"` // for co-op activities
	StudentID      primitive.ObjectID  `bson:"studentId" json:"studentId"`
	SubjectID      primitive.ObjectID  `bson:"subjectId" json:"subjectId"`
	GroupID        *string             `bson:"groupId,omitempty" json:"groupId,omitempty"` // links multiple log entries created together (multi-student)
	Date           time.Time           `bson:"date" json:"date"`
	Hours          float64             `bson:"hours" json:"hours"`
	Description    string              `bson:"description" json:"description"`
	LocationType   string              `bson:"locationType" json:"locationType"`                     // home, field_trip, co_op, online, other
	LocationID     *primitive.ObjectID `bson:"locationId,omitempty" json:"locationId,omitempty"`     // reference to saved location
	LocationName   string              `bson:"locationName,omitempty" json:"locationName,omitempty"` // e.g., "Science Museum"
	SubmittedBy    primitive.ObjectID  `bson:"submittedBy" json:"submittedBy"`
	Status         string              `bson:"status" json:"status"`         // approved, pending
	SchoolYear     string              `bson:"schoolYear" json:"schoolYear"` // "2024-2025"
	CreatedAt      time.Time           `bson:"createdAt" json:"createdAt"`
	UpdatedAt      time.Time           `bson:"updatedAt" json:"updatedAt"`
}

// Location types
const (
	LocationTypeHome      = "home"
	LocationTypeFieldTrip = "field_trip"
	LocationTypeCoOp      = "co_op"
	LocationTypeOnline    = "online"
	LocationTypeOther     = "other"
)

// Log statuses
const (
	LogStatusApproved = "approved"
	LogStatusPending  = "pending"
)

// LocationTypes lists all valid location types
var LocationTypes = []string{
	LocationTypeHome,
	LocationTypeFieldTrip,
	LocationTypeCoOp,
	LocationTypeOnline,
	LocationTypeOther,
}

// NewLogEntry creates a new LogEntry with default values
func NewLogEntry(familyID, studentID, subjectID, submittedBy primitive.ObjectID, date time.Time, hours float64, schoolYear string) *LogEntry {
	now := time.Now().UTC()
	return &LogEntry{
		ID:           primitive.NewObjectID(),
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         date,
		Hours:        hours,
		LocationType: LocationTypeHome,
		SubmittedBy:  submittedBy,
		Status:       LogStatusApproved, // auto-approve by default
		SchoolYear:   schoolYear,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}

// LogEntryWithDetails extends LogEntry with related names for display
type LogEntryWithDetails struct {
	LogEntry
	StudentName  string `json:"studentName"`
	SubjectName  string `json:"subjectName"`
	SubjectColor string `json:"subjectColor"`
}
