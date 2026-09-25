package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Student represents a student being homeschooled
type Student struct {
	ID             primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
	FamilyID       primitive.ObjectID  `bson:"familyId" json:"familyId"`
	Name           string              `bson:"name" json:"name"`
	DateOfBirthEnc string              `bson:"dateOfBirthEnc,omitempty" json:"-"`        // Encrypted, never sent to client
	DateOfBirth    *time.Time          `bson:"-" json:"dateOfBirth,omitempty"`           // Decrypted in app, optional
	GradeLevel     string              `bson:"gradeLevel" json:"gradeLevel"`             // K, 1, 2, ... 12
	UserID         *primitive.ObjectID `bson:"userId,omitempty" json:"userId,omitempty"` // nil = no login, set when parent creates student account
	AvatarColor    string              `bson:"avatarColor,omitempty" json:"avatarColor"` // Color for UI display
	Active         bool                `bson:"active" json:"active"`
	CreatedAt      time.Time           `bson:"createdAt" json:"createdAt"`
	UpdatedAt      time.Time           `bson:"updatedAt" json:"updatedAt"`
}

// Note: DateOfBirth is OPTIONAL - parent's choice to track
// COPPA not triggered because parents enter all student info
// UserID links to User record when parent creates student login

// Grade levels
var GradeLevels = []string{"K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"}

// Avatar colors for students
var AvatarColors = []string{
	"#3B82F6", // blue
	"#10B981", // green
	"#F59E0B", // amber
	"#EF4444", // red
	"#8B5CF6", // purple
	"#EC4899", // pink
	"#06B6D4", // cyan
	"#F97316", // orange
}

// NewStudent creates a new Student with default values
func NewStudent(familyID primitive.ObjectID, name string, gradeLevel string) *Student {
	now := time.Now().UTC()
	return &Student{
		ID:         primitive.NewObjectID(),
		FamilyID:   familyID,
		Name:       name,
		GradeLevel: gradeLevel,
		Active:     true,
		CreatedAt:  now,
		UpdatedAt:  now,
	}
}

// StudentWithStats extends Student with computed statistics
type StudentWithStats struct {
	Student
	TotalHours     float64            `json:"totalHours"`
	HoursBySubject map[string]float64 `json:"hoursBySubject"` // subjectId -> hours
	RecentLogCount int                `json:"recentLogCount"` // logs in last 7 days
	LastLogDate    *time.Time         `json:"lastLogDate"`
}
