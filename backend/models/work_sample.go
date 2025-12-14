package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// WorkSample represents a file attached to a log entry (photo, document, etc.)
// For multi-student logs (same groupId), work samples are shared across all logs in the group.
type WorkSample struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	FamilyID    primitive.ObjectID `bson:"familyId" json:"familyId"`
	LogEntryID  primitive.ObjectID `bson:"logEntryId" json:"logEntryId"`               // Primary log entry
	GroupID     *string            `bson:"groupId,omitempty" json:"groupId,omitempty"` // Links to all logs in group
	StudentID   primitive.ObjectID `bson:"studentId" json:"studentId"`                 // Primary student (uploader's context)
	FileName    string             `bson:"fileName" json:"fileName"`                   // Original filename
	StorageKey  string             `bson:"storageKey" json:"storageKey"`               // R2 object key (or local path for mobile)
	ContentType string             `bson:"contentType" json:"contentType"`             // MIME type
	SizeBytes   int64              `bson:"sizeBytes" json:"sizeBytes"`
	UploadedBy  primitive.ObjectID `bson:"uploadedBy" json:"uploadedBy"` // User who uploaded
	Description string             `bson:"description,omitempty" json:"description,omitempty"`
	SyncStatus  string             `bson:"syncStatus,omitempty" json:"syncStatus,omitempty"` // "local", "syncing", "synced"
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
}

// WorkSampleWithURL includes a pre-signed download URL for client access
type WorkSampleWithURL struct {
	WorkSample
	DownloadURL string `json:"downloadUrl"`
	ExpiresAt   string `json:"expiresAt"`
}

// AllowedContentTypes for work sample uploads
var AllowedContentTypes = map[string]bool{
	// Images
	"image/jpeg": true,
	"image/png":  true,
	"image/gif":  true,
	"image/webp": true,
	"image/heic": true,
	"image/heif": true,

	// Documents
	"application/pdf": true,

	// Videos (optional, larger files)
	"video/mp4":       true,
	"video/quicktime": true,
}

// MaxFileSizeBytes is the default max file size (10MB)
const MaxFileSizeBytes = 10 * 1024 * 1024

// DefaultStorageLimitBytes is the default storage limit per family (100MB for free tier)
const DefaultStorageLimitBytes = 100 * 1024 * 1024

// PremiumStorageLimitBytes is the storage limit for premium tier (5GB)
const PremiumStorageLimitBytes = 5 * 1024 * 1024 * 1024

// IsAllowedContentType checks if a content type is allowed for upload
func IsAllowedContentType(contentType string) bool {
	return AllowedContentTypes[contentType]
}

// GetStorageKey generates the R2 storage key for a work sample
func GetStorageKey(familyID, logEntryID primitive.ObjectID, uuid, fileName string) string {
	return "families/" + familyID.Hex() + "/work-samples/" + logEntryID.Hex() + "/" + uuid + "-" + fileName
}
