package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Subject represents a subject or course that hours can be logged against
type Subject struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	FamilyID    primitive.ObjectID `bson:"familyId" json:"familyId"`
	Name        string             `bson:"name" json:"name"`
	Type        string             `bson:"type" json:"type"`                                   // core, elective
	TargetHours *float64           `bson:"targetHours,omitempty" json:"targetHours,omitempty"` // optional annual target
	Color       string             `bson:"color" json:"color"`
	IsDefault   bool               `bson:"isDefault" json:"isDefault"` // true if seeded during onboarding
	SortOrder   int                `bson:"sortOrder" json:"sortOrder"` // for custom ordering
	Active      bool               `bson:"active" json:"active"`
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// Subject types
const (
	SubjectTypeCore     = "core"
	SubjectTypeElective = "elective"
)

// Subject colors for UI
var SubjectColors = []string{
	"#3B82F6", // blue
	"#10B981", // green
	"#F59E0B", // amber
	"#EF4444", // red
	"#8B5CF6", // purple
	"#EC4899", // pink
	"#06B6D4", // cyan
	"#F97316", // orange
	"#84CC16", // lime
	"#6366F1", // indigo
}

// NewSubject creates a new Subject with default values
func NewSubject(familyID primitive.ObjectID, name string, subjectType string, color string) *Subject {
	now := time.Now().UTC()
	return &Subject{
		ID:        primitive.NewObjectID(),
		FamilyID:  familyID,
		Name:      name,
		Type:      subjectType,
		Color:     color,
		IsDefault: false,
		Active:    true,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

// Missouri default subjects for onboarding
var MissouriDefaultSubjects = []struct {
	Name  string
	Type  string
	Color string
}{
	{"Reading", SubjectTypeCore, "#3B82F6"},
	{"Math", SubjectTypeCore, "#10B981"},
	{"Language Arts", SubjectTypeCore, "#F59E0B"},
	{"Science", SubjectTypeCore, "#8B5CF6"},
	{"Social Studies", SubjectTypeCore, "#EC4899"},
	{"Art", SubjectTypeElective, "#06B6D4"},
	{"Music", SubjectTypeElective, "#F97316"},
	{"Physical Education", SubjectTypeElective, "#84CC16"},
}

// SubjectWithHours extends Subject with logged hours for a period
type SubjectWithHours struct {
	Subject
	LoggedHours float64 `json:"loggedHours"`
	Progress    float64 `json:"progress"` // percentage toward target (0-100)
}
