package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"github.com/cpuchip/homeschool-keeper/backend/storage"
	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UploadHandler handles file upload operations
type UploadHandler struct {
	r2          *storage.R2Client
	workSamples *repository.WorkSampleRepository
	families    *repository.FamilyRepository
	logs        *repository.LogRepository
}

// NewUploadHandler creates a new UploadHandler
func NewUploadHandler(
	r2 *storage.R2Client,
	workSamples *repository.WorkSampleRepository,
	families *repository.FamilyRepository,
	logs *repository.LogRepository,
) *UploadHandler {
	return &UploadHandler{
		r2:          r2,
		workSamples: workSamples,
		families:    families,
		logs:        logs,
	}
}

// GetUploadURLRequest is the request body for generating an upload URL
type GetUploadURLRequest struct {
	LogEntryID  string `json:"logEntryId"`
	FileName    string `json:"fileName"`
	ContentType string `json:"contentType"`
	SizeBytes   int64  `json:"sizeBytes"`
	Description string `json:"description,omitempty"`
}

// GetUploadURLResponse is the response with pre-signed upload URL
type GetUploadURLResponse struct {
	UploadURL    string `json:"uploadUrl"`
	WorkSampleID string `json:"workSampleId"`
	StorageKey   string `json:"storageKey"`
	ExpiresAt    string `json:"expiresAt"`
}

// GetUploadURL handles POST /api/v1/uploads/url
// Generates a pre-signed URL for uploading a file to R2
func (h *UploadHandler) GetUploadURL(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	userID, err := auth.UserIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	// Check if R2 client is configured
	if h.r2 == nil {
		Error(w, http.StatusServiceUnavailable, "File uploads are not configured")
		return
	}

	// Check premium feature access
	family, err := h.families.GetByID(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	if !family.Premium.UploadsEnabled {
		Error(w, http.StatusForbidden, "File uploads require a premium subscription")
		return
	}

	// Parse request
	var req GetUploadURLRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Validate request
	if req.LogEntryID == "" {
		BadRequest(w, "logEntryId is required")
		return
	}
	if req.FileName == "" {
		BadRequest(w, "fileName is required")
		return
	}
	if req.ContentType == "" {
		BadRequest(w, "contentType is required")
		return
	}
	if req.SizeBytes <= 0 {
		BadRequest(w, "sizeBytes must be positive")
		return
	}

	// Validate content type
	if !models.IsAllowedContentType(req.ContentType) {
		BadRequest(w, "Content type not allowed. Allowed types: JPEG, PNG, GIF, WebP, HEIC, PDF, MP4")
		return
	}

	// Validate file size
	if req.SizeBytes > models.MaxFileSizeBytes {
		BadRequest(w, "File size exceeds maximum of 10MB")
		return
	}

	// Parse log entry ID
	logEntryID, err := primitive.ObjectIDFromHex(req.LogEntryID)
	if err != nil {
		BadRequest(w, "Invalid logEntryId")
		return
	}

	// Verify log entry exists and belongs to family
	log, err := h.logs.GetByID(r.Context(), familyID, logEntryID)
	if err != nil {
		if err == repository.ErrLogNotFound {
			NotFound(w, "Log entry not found")
			return
		}
		InternalError(w)
		return
	}

	// Check storage quota
	currentUsage, err := h.workSamples.GetTotalSizeByFamily(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	storageLimit := family.Premium.StorageLimitBytes
	if storageLimit == 0 {
		storageLimit = models.DefaultStorageLimitBytes
	}

	if currentUsage+req.SizeBytes > storageLimit {
		Error(w, http.StatusPaymentRequired, "Storage quota exceeded. Please upgrade your subscription.")
		return
	}

	// Generate storage key
	fileUUID := uuid.New().String()
	storageKey := models.GetStorageKey(familyID, logEntryID, fileUUID, req.FileName)

	// Create work sample record (pending upload)
	sample := &models.WorkSample{
		FamilyID:    familyID,
		LogEntryID:  logEntryID,
		StudentID:   log.StudentID,
		FileName:    req.FileName,
		StorageKey:  storageKey,
		ContentType: req.ContentType,
		SizeBytes:   req.SizeBytes,
		UploadedBy:  userID,
		Description: req.Description,
	}

	if err := h.workSamples.Create(r.Context(), sample); err != nil {
		InternalError(w)
		return
	}

	// Generate pre-signed upload URL
	uploadURL, expiresAt, err := h.r2.GenerateUploadURL(r.Context(), storageKey, req.ContentType, req.SizeBytes)
	if err != nil {
		// Clean up the work sample record
		h.workSamples.Delete(r.Context(), familyID, sample.ID)
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, GetUploadURLResponse{
		UploadURL:    uploadURL,
		WorkSampleID: sample.ID.Hex(),
		StorageKey:   storageKey,
		ExpiresAt:    expiresAt.Format(time.RFC3339),
	})
}

// ConfirmUploadRequest confirms a file was uploaded successfully
type ConfirmUploadRequest struct {
	WorkSampleID string `json:"workSampleId"`
}

// ConfirmUpload handles POST /api/v1/uploads/confirm
// Called after a successful upload to verify the file exists
func (h *UploadHandler) ConfirmUpload(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	// Check if R2 client is configured
	if h.r2 == nil {
		Error(w, http.StatusServiceUnavailable, "File uploads are not configured")
		return
	}

	var req ConfirmUploadRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	workSampleID, err := primitive.ObjectIDFromHex(req.WorkSampleID)
	if err != nil {
		BadRequest(w, "Invalid workSampleId")
		return
	}

	// Get work sample
	sample, err := h.workSamples.GetByID(r.Context(), familyID, workSampleID)
	if err != nil {
		if err == repository.ErrWorkSampleNotFound {
			NotFound(w, "Work sample not found")
			return
		}
		InternalError(w)
		return
	}

	// Verify file exists in R2
	size, _, err := h.r2.HeadObject(r.Context(), sample.StorageKey)
	if err != nil {
		// File doesn't exist, upload may have failed
		Error(w, http.StatusConflict, "File not found in storage. Upload may have failed.")
		return
	}

	// Update size if different (in case of compression, etc.)
	if size != sample.SizeBytes {
		// Update the record with actual size
		sample.SizeBytes = size
	}

	// Update family storage usage
	h.families.UpdateStorageUsage(r.Context(), familyID, sample.SizeBytes)

	JSON(w, http.StatusOK, sample)
}

// ListByLogEntry handles GET /api/v1/logs/{id}/work-samples
func (h *UploadHandler) ListByLogEntry(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	logEntryID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid log entry ID")
		return
	}

	// Get work samples for this log entry
	samples, err := h.workSamples.GetByLogEntry(r.Context(), familyID, logEntryID)
	if err != nil {
		InternalError(w)
		return
	}

	if samples == nil {
		samples = []models.WorkSample{}
	}

	// Generate download URLs if R2 is configured
	if h.r2 != nil {
		samplesWithURLs := make([]models.WorkSampleWithURL, len(samples))
		for i, sample := range samples {
			downloadURL, expiresAt, err := h.r2.GenerateDownloadURL(r.Context(), sample.StorageKey)
			if err != nil {
				// Return sample without URL if generation fails
				samplesWithURLs[i] = models.WorkSampleWithURL{
					WorkSample: sample,
				}
				continue
			}
			samplesWithURLs[i] = models.WorkSampleWithURL{
				WorkSample:  sample,
				DownloadURL: downloadURL,
				ExpiresAt:   expiresAt.Format(time.RFC3339),
			}
		}
		JSON(w, http.StatusOK, samplesWithURLs)
		return
	}

	JSON(w, http.StatusOK, samples)
}

// Delete handles DELETE /api/v1/work-samples/{id}
func (h *UploadHandler) Delete(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	sampleID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid work sample ID")
		return
	}

	// Get work sample to get storage key
	sample, err := h.workSamples.GetByID(r.Context(), familyID, sampleID)
	if err != nil {
		if err == repository.ErrWorkSampleNotFound {
			NotFound(w, "Work sample not found")
			return
		}
		InternalError(w)
		return
	}

	// Delete from R2 if configured
	if h.r2 != nil {
		if err := h.r2.DeleteObject(r.Context(), sample.StorageKey); err != nil {
			// Log error but continue with database deletion
			// File may already be deleted
		}
	}

	// Delete from database
	if err := h.workSamples.Delete(r.Context(), familyID, sampleID); err != nil {
		InternalError(w)
		return
	}

	// Update family storage usage (subtract)
	h.families.UpdateStorageUsage(r.Context(), familyID, -sample.SizeBytes)

	NoContent(w)
}

// GetStorageUsage handles GET /api/v1/uploads/usage
func (h *UploadHandler) GetStorageUsage(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	family, err := h.families.GetByID(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Get actual usage from work samples
	usedBytes, err := h.workSamples.GetTotalSizeByFamily(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	limitBytes := family.Premium.StorageLimitBytes
	if limitBytes == 0 {
		limitBytes = models.DefaultStorageLimitBytes
	}

	count, err := h.workSamples.CountByFamily(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, map[string]interface{}{
		"usedBytes":       usedBytes,
		"limitBytes":      limitBytes,
		"usedPercent":     float64(usedBytes) / float64(limitBytes) * 100,
		"fileCount":       count,
		"uploadsEnabled":  family.Premium.UploadsEnabled,
		"usedMB":          float64(usedBytes) / 1024 / 1024,
		"limitMB":         float64(limitBytes) / 1024 / 1024,
		"remainingBytes":  limitBytes - usedBytes,
	})
}

// formatBytes formats bytes to human readable string
func formatBytes(bytes int64) string {
	const unit = 1024
	if bytes < unit {
		return strconv.FormatInt(bytes, 10) + " B"
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return strconv.FormatFloat(float64(bytes)/float64(div), 'f', 1, 64) + " " + []string{"KB", "MB", "GB", "TB"}[exp]
}
