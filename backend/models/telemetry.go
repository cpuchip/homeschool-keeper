package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TelemetryEvent represents an anonymous analytics event
// This is completely disconnected from user accounts
type TelemetryEvent struct {
	ID         primitive.ObjectID     `bson:"_id,omitempty" json:"id"`
	InstallID  string                 `bson:"installId" json:"installId"`   // Random UUID per install
	AppVersion string                 `bson:"appVersion" json:"appVersion"` // e.g., "1.2.3"
	Platform   string                 `bson:"platform" json:"platform"`     // ios, android, windows, web
	Event      string                 `bson:"event" json:"event"`           // Event name
	Data       map[string]interface{} `bson:"data,omitempty" json:"data,omitempty"`
	Timestamp  time.Time              `bson:"timestamp" json:"timestamp"`
	ReceivedAt time.Time              `bson:"receivedAt" json:"receivedAt"` // Server receive time
}

// Standard event names (Tier 1 - Essential)
const (
	EventAppInstall   = "app_install"    // First launch
	EventSessionStart = "session_start"  // App opened
	EventSessionEnd   = "session_end"    // App closed (with duration in data)
)

// Tier 2 - Usage events
const (
	EventScreenView          = "screen_view"           // data: {screen: "dashboard"}
	EventOnboardingStarted   = "onboarding_started"
	EventOnboardingCompleted = "onboarding_completed"
	EventAccountCreated      = "account_created"
	EventSyncEnabled         = "sync_enabled"
	EventLogCreated          = "log_created"           // Just count, no content
	EventLogEdited           = "log_edited"
	EventStudentAdded        = "student_added"
	EventSubjectAdded        = "subject_added"
	EventWorkSampleAdded     = "work_sample_added"
	EventExportGenerated     = "export_generated"      // data: {format: "pdf"}
	EventTelemetryOptOut     = "telemetry_opt_out"     // User disabled telemetry
	EventTelemetryOptIn      = "telemetry_opt_in"      // User re-enabled telemetry
)
