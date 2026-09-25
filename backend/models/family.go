package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Family is the core unit - every user, student, and log belongs to a family.
// In Phase 1A, Family = standalone. Schema supports multi-family orgs for Phase 1B.
type Family struct {
	ID              primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
	Name            string              `bson:"name" json:"name"`
	OrganizationID  *primitive.ObjectID `bson:"organizationId,omitempty" json:"organizationId,omitempty"` // nil = standalone family
	HourIncrement   float64             `bson:"hourIncrement" json:"hourIncrement"`                       // 0.25 default (15 min)
	SchoolYearStart time.Time           `bson:"schoolYearStart" json:"schoolYearStart"`
	SchoolYearEnd   time.Time           `bson:"schoolYearEnd" json:"schoolYearEnd"`
	CurrentYear     string              `bson:"currentYear" json:"currentYear"` // "2024-2025"
	State           string              `bson:"state" json:"state"`             // MO, etc.
	Timezone        string              `bson:"timezone" json:"timezone"`
	Settings        FamilySettings      `bson:"settings" json:"settings"`
	Premium         PremiumFeatures     `bson:"premium" json:"premium"` // Premium feature flags
	OnboardingDone  bool                `bson:"onboardingDone" json:"onboardingDone"`
	CreatedAt       time.Time           `bson:"createdAt" json:"createdAt"`
	UpdatedAt       time.Time           `bson:"updatedAt" json:"updatedAt"`
}

// FamilySettings contains configurable options for a family
type FamilySettings struct {
	AutoApproveLogs     bool `bson:"autoApproveLogs" json:"autoApproveLogs"`         // default: true
	RequireSubjectGoals bool `bson:"requireSubjectGoals" json:"requireSubjectGoals"` // default: false
}

// PremiumFeatures contains flags for premium/paid features
type PremiumFeatures struct {
	SyncEnabled       bool       `bson:"syncEnabled" json:"syncEnabled"`             // Server sync (mobile)
	UploadsEnabled    bool       `bson:"uploadsEnabled" json:"uploadsEnabled"`       // Work sample uploads
	StorageUsedBytes  int64      `bson:"storageUsedBytes" json:"storageUsedBytes"`   // Current storage usage
	StorageLimitBytes int64      `bson:"storageLimitBytes" json:"storageLimitBytes"` // Storage limit (0 = default)
	SubscriptionTier  string     `bson:"subscriptionTier" json:"subscriptionTier"`   // "free", "basic", "premium"
	SubscriptionEnd   *time.Time `bson:"subscriptionEnd,omitempty" json:"subscriptionEnd,omitempty"`
}

// DefaultHourIncrement is the default hour increment (15 minutes)
const DefaultHourIncrement = 0.25

// NewFamily creates a new Family with default settings
func NewFamily(name string, state string) *Family {
	now := time.Now().UTC()
	return &Family{
		ID:            primitive.NewObjectID(),
		Name:          name,
		HourIncrement: DefaultHourIncrement,
		State:         state,
		Timezone:      "America/Chicago", // Central time as default for Missouri
		Settings: FamilySettings{
			AutoApproveLogs:     true,
			RequireSubjectGoals: false,
		},
		OnboardingDone: false,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

// GetSchoolYear returns the school year string (e.g., "2024-2025")
func (f *Family) GetSchoolYear() string {
	if f.CurrentYear != "" {
		return f.CurrentYear
	}
	// Calculate from dates if not set
	startYear := f.SchoolYearStart.Year()
	endYear := f.SchoolYearEnd.Year()
	if startYear > 0 && endYear > 0 {
		return formatSchoolYear(startYear, endYear)
	}
	return ""
}

func formatSchoolYear(startYear, endYear int) string {
	return string(rune(startYear)) + "-" + string(rune(endYear))
}
