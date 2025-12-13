package handlers

import (
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
)

// TelemetryHandler handles anonymous telemetry events
// This is completely separate from user authentication
type TelemetryHandler struct {
	telemetry *repository.TelemetryRepository
}

// NewTelemetryHandler creates a new telemetry handler
func NewTelemetryHandler(telemetry *repository.TelemetryRepository) *TelemetryHandler {
	return &TelemetryHandler{
		telemetry: telemetry,
	}
}

// Rate limit: max events per install per day
const maxEventsPerInstallPerDay = 500

// TrackEventRequest is the request body for tracking an event
type TrackEventRequest struct {
	InstallID  string                 `json:"installId"`
	AppVersion string                 `json:"appVersion"`
	Platform   string                 `json:"platform"`
	Event      string                 `json:"event"`
	Data       map[string]interface{} `json:"data,omitempty"`
	Timestamp  string                 `json:"timestamp,omitempty"`
}

// TrackBatchRequest is the request for tracking multiple events
type TrackBatchRequest struct {
	Events []TrackEventRequest `json:"events"`
}

// Track handles POST /api/v1/telemetry - no auth required
func (h *TelemetryHandler) Track(w http.ResponseWriter, r *http.Request) {
	var req TrackEventRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Validate required fields
	if req.InstallID == "" {
		BadRequest(w, "installId is required")
		return
	}
	if req.Event == "" {
		BadRequest(w, "event is required")
		return
	}
	if len(req.InstallID) > 100 {
		BadRequest(w, "installId too long")
		return
	}

	// Rate limiting check
	count, err := h.telemetry.CountByInstallToday(r.Context(), req.InstallID)
	if err == nil && count >= maxEventsPerInstallPerDay {
		Error(w, http.StatusTooManyRequests, "Rate limit exceeded")
		return
	}

	// Parse timestamp or use current time
	var timestamp time.Time
	if req.Timestamp != "" {
		parsed, err := time.Parse(time.RFC3339, req.Timestamp)
		if err != nil {
			timestamp = time.Now().UTC()
		} else {
			timestamp = parsed
		}
	} else {
		timestamp = time.Now().UTC()
	}

	// Sanitize platform
	platform := sanitizePlatform(req.Platform)

	// Create event
	event := &models.TelemetryEvent{
		InstallID:  req.InstallID,
		AppVersion: sanitizeVersion(req.AppVersion),
		Platform:   platform,
		Event:      sanitizeEventName(req.Event),
		Data:       sanitizeData(req.Data),
		Timestamp:  timestamp,
	}

	if err := h.telemetry.Create(r.Context(), event); err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// TrackBatch handles POST /api/v1/telemetry/batch - no auth required
func (h *TelemetryHandler) TrackBatch(w http.ResponseWriter, r *http.Request) {
	var req TrackBatchRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	if len(req.Events) == 0 {
		BadRequest(w, "No events provided")
		return
	}
	if len(req.Events) > 100 {
		BadRequest(w, "Too many events (max 100)")
		return
	}

	// Check install IDs are consistent and rate limit
	installIDs := make(map[string]bool)
	for _, e := range req.Events {
		if e.InstallID == "" {
			BadRequest(w, "installId is required for all events")
			return
		}
		installIDs[e.InstallID] = true
	}

	// Check rate limit for each install
	for installID := range installIDs {
		count, err := h.telemetry.CountByInstallToday(r.Context(), installID)
		if err == nil && count >= maxEventsPerInstallPerDay {
			Error(w, http.StatusTooManyRequests, "Rate limit exceeded for install "+installID)
			return
		}
	}

	// Convert to models
	events := make([]models.TelemetryEvent, len(req.Events))
	for i, e := range req.Events {
		var timestamp time.Time
		if e.Timestamp != "" {
			parsed, err := time.Parse(time.RFC3339, e.Timestamp)
			if err != nil {
				timestamp = time.Now().UTC()
			} else {
				timestamp = parsed
			}
		} else {
			timestamp = time.Now().UTC()
		}

		events[i] = models.TelemetryEvent{
			InstallID:  e.InstallID,
			AppVersion: sanitizeVersion(e.AppVersion),
			Platform:   sanitizePlatform(e.Platform),
			Event:      sanitizeEventName(e.Event),
			Data:       sanitizeData(e.Data),
			Timestamp:  timestamp,
		}
	}

	if err := h.telemetry.CreateBatch(r.Context(), events); err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, map[string]interface{}{
		"status":   "ok",
		"received": len(events),
	})
}

// Sanitization helpers

func sanitizePlatform(p string) string {
	switch p {
	case "ios", "android", "windows", "macos", "linux", "web":
		return p
	default:
		return "unknown"
	}
}

func sanitizeVersion(v string) string {
	if len(v) > 20 {
		return v[:20]
	}
	return v
}

func sanitizeEventName(e string) string {
	if len(e) > 50 {
		return e[:50]
	}
	return e
}

func sanitizeData(data map[string]interface{}) map[string]interface{} {
	if data == nil {
		return nil
	}
	
	// Limit to 10 keys, simple values only
	sanitized := make(map[string]interface{})
	count := 0
	for k, v := range data {
		if count >= 10 {
			break
		}
		// Only allow simple types
		switch val := v.(type) {
		case string:
			if len(val) > 100 {
				sanitized[k] = val[:100]
			} else {
				sanitized[k] = val
			}
		case float64, int, int64, bool:
			sanitized[k] = val
		}
		count++
	}
	return sanitized
}
