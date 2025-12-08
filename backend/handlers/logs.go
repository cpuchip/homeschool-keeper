package handlers

import (
	"fmt"
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LogHandler handles log entry endpoints
type LogHandler struct {
	logs     *repository.LogRepository
	students *repository.StudentRepository
	subjects *repository.SubjectRepository
	families *repository.FamilyRepository
}

// NewLogHandler creates a new LogHandler
func NewLogHandler(logs *repository.LogRepository, students *repository.StudentRepository, subjects *repository.SubjectRepository, families *repository.FamilyRepository) *LogHandler {
	return &LogHandler{
		logs:     logs,
		students: students,
		subjects: subjects,
		families: families,
	}
}

// CreateLogRequest is the request body for creating a log entry
type CreateLogRequest struct {
	StudentID    string  `json:"studentId"`
	SubjectID    string  `json:"subjectId"`
	Date         string  `json:"date"` // YYYY-MM-DD
	Hours        float64 `json:"hours"`
	Description  string  `json:"description"`
	LocationType string  `json:"locationType"`
	LocationName string  `json:"locationName,omitempty"`
}

// UpdateLogRequest is the request body for updating a log entry
type UpdateLogRequest struct {
	SubjectID    *string  `json:"subjectId,omitempty"`
	Date         *string  `json:"date,omitempty"`
	Hours        *float64 `json:"hours,omitempty"`
	Description  *string  `json:"description,omitempty"`
	LocationType *string  `json:"locationType,omitempty"`
	LocationName *string  `json:"locationName,omitempty"`
	Status       *string  `json:"status,omitempty"`
}

// List handles GET /api/v1/logs
func (h *LogHandler) List(w http.ResponseWriter, r *http.Request) {
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

	// Parse filter parameters
	filter := repository.LogFilter{}
	pagination := GetPagination(r)
	filter.Limit = pagination.Limit
	filter.Skip = pagination.Offset

	// Student filter
	if studentIDStr := r.URL.Query().Get("studentId"); studentIDStr != "" {
		studentID, err := primitive.ObjectIDFromHex(studentIDStr)
		if err == nil {
			filter.StudentID = &studentID
		}
	}

	// Subject filter
	if subjectIDStr := r.URL.Query().Get("subjectId"); subjectIDStr != "" {
		subjectID, err := primitive.ObjectIDFromHex(subjectIDStr)
		if err == nil {
			filter.SubjectID = &subjectID
		}
	}

	// School year filter
	filter.SchoolYear = r.URL.Query().Get("schoolYear")

	// Date range filter
	if startStr := r.URL.Query().Get("startDate"); startStr != "" {
		if start, err := time.Parse("2006-01-02", startStr); err == nil {
			filter.StartDate = &start
		}
	}
	if endStr := r.URL.Query().Get("endDate"); endStr != "" {
		if end, err := time.Parse("2006-01-02", endStr); err == nil {
			filter.EndDate = &end
		}
	}

	logs, err := h.logs.GetByFamily(r.Context(), familyID, filter)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, logs)
}

// Get handles GET /api/v1/logs/{id}
func (h *LogHandler) Get(w http.ResponseWriter, r *http.Request) {
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

	logID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid log ID")
		return
	}

	log, err := h.logs.GetByID(r.Context(), familyID, logID)
	if err != nil {
		if err == repository.ErrLogNotFound {
			NotFound(w, "Log entry not found")
			return
		}
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, log)
}

// Create handles POST /api/v1/logs
func (h *LogHandler) Create(w http.ResponseWriter, r *http.Request) {
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

	var req CreateLogRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Validate required fields
	if req.StudentID == "" || req.SubjectID == "" || req.Hours <= 0 {
		BadRequest(w, "Student ID, subject ID, and positive hours are required")
		return
	}

	// Parse IDs
	studentID, err := primitive.ObjectIDFromHex(req.StudentID)
	if err != nil {
		BadRequest(w, "Invalid student ID")
		return
	}

	subjectID, err := primitive.ObjectIDFromHex(req.SubjectID)
	if err != nil {
		BadRequest(w, "Invalid subject ID")
		return
	}

	// Verify student belongs to family
	_, err = h.students.GetByID(r.Context(), familyID, studentID)
	if err != nil {
		if err == repository.ErrStudentNotFound {
			BadRequest(w, "Student not found")
			return
		}
		InternalError(w)
		return
	}

	// Verify subject belongs to family
	_, err = h.subjects.GetByID(r.Context(), familyID, subjectID)
	if err != nil {
		if err == repository.ErrSubjectNotFound {
			BadRequest(w, "Subject not found")
			return
		}
		InternalError(w)
		return
	}

	// Get family for hour increment validation and school year
	family, err := h.families.GetByID(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Validate hours against family's increment
	if !validateHourIncrement(req.Hours, family.HourIncrement) {
		BadRequest(w, "Hours must be a multiple of the configured increment")
		return
	}

	// Parse date
	var logDate time.Time
	if req.Date != "" {
		logDate, err = time.Parse("2006-01-02", req.Date)
		if err != nil {
			BadRequest(w, "Invalid date format (use YYYY-MM-DD)")
			return
		}
	} else {
		logDate = time.Now().UTC().Truncate(24 * time.Hour)
	}

	// Validate location type
	if req.LocationType == "" {
		req.LocationType = models.LocationTypeHome
	}
	if !isValidLocationType(req.LocationType) {
		BadRequest(w, "Invalid location type")
		return
	}

	// Determine school year
	schoolYear := family.CurrentYear
	if schoolYear == "" {
		schoolYear = calculateSchoolYear(logDate)
	}

	// Create log entry
	log := models.NewLogEntry(familyID, studentID, subjectID, userID, logDate, req.Hours, schoolYear)
	log.Description = req.Description
	log.LocationType = req.LocationType
	log.LocationName = req.LocationName

	// Set status based on family settings
	if family.Settings.AutoApproveLogs {
		log.Status = models.LogStatusApproved
	} else {
		log.Status = models.LogStatusPending
	}

	if err := h.logs.Create(r.Context(), log); err != nil {
		InternalError(w)
		return
	}

	Created(w, log)
}

// Update handles PATCH /api/v1/logs/{id}
func (h *LogHandler) Update(w http.ResponseWriter, r *http.Request) {
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

	logID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid log ID")
		return
	}

	var req UpdateLogRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Build update document
	update := bson.M{}

	if req.SubjectID != nil {
		subjectID, err := primitive.ObjectIDFromHex(*req.SubjectID)
		if err != nil {
			BadRequest(w, "Invalid subject ID")
			return
		}
		// Verify subject belongs to family
		_, err = h.subjects.GetByID(r.Context(), familyID, subjectID)
		if err != nil {
			BadRequest(w, "Subject not found")
			return
		}
		update["subjectId"] = subjectID
	}

	if req.Date != nil {
		date, err := time.Parse("2006-01-02", *req.Date)
		if err != nil {
			BadRequest(w, "Invalid date format")
			return
		}
		update["date"] = date
	}

	if req.Hours != nil {
		family, err := h.families.GetByID(r.Context(), familyID)
		if err != nil {
			InternalError(w)
			return
		}
		if !validateHourIncrement(*req.Hours, family.HourIncrement) {
			BadRequest(w, "Hours must be a multiple of the configured increment")
			return
		}
		update["hours"] = *req.Hours
	}

	if req.Description != nil {
		update["description"] = *req.Description
	}

	if req.LocationType != nil {
		if !isValidLocationType(*req.LocationType) {
			BadRequest(w, "Invalid location type")
			return
		}
		update["locationType"] = *req.LocationType
	}

	if req.LocationName != nil {
		update["locationName"] = *req.LocationName
	}

	if req.Status != nil {
		if *req.Status != models.LogStatusApproved && *req.Status != models.LogStatusPending {
			BadRequest(w, "Invalid status")
			return
		}
		update["status"] = *req.Status
	}

	if len(update) == 0 {
		BadRequest(w, "No fields to update")
		return
	}

	if err := h.logs.Update(r.Context(), familyID, logID, update); err != nil {
		if err == repository.ErrLogNotFound {
			NotFound(w, "Log entry not found")
			return
		}
		InternalError(w)
		return
	}

	// Return updated log
	log, err := h.logs.GetByID(r.Context(), familyID, logID)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, log)
}

// Delete handles DELETE /api/v1/logs/{id}
func (h *LogHandler) Delete(w http.ResponseWriter, r *http.Request) {
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

	logID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid log ID")
		return
	}

	if err := h.logs.Delete(r.Context(), familyID, logID); err != nil {
		if err == repository.ErrLogNotFound {
			NotFound(w, "Log entry not found")
			return
		}
		InternalError(w)
		return
	}

	NoContent(w)
}

// Helper functions

func validateHourIncrement(hours float64, increment float64) bool {
	if increment <= 0 {
		increment = 0.25 // default
	}
	// Check if hours is a multiple of increment (with small epsilon for floating point)
	remainder := hours / increment
	return remainder == float64(int(remainder))
}

func isValidLocationType(locationType string) bool {
	for _, lt := range models.LocationTypes {
		if lt == locationType {
			return true
		}
	}
	return false
}

func calculateSchoolYear(date time.Time) string {
	year := date.Year()
	month := date.Month()

	// School year typically starts in August/September
	// If month is Aug-Dec, use current year - next year
	// If month is Jan-Jul, use previous year - current year
	if month >= time.August {
		return formatSchoolYearStr(year, year+1)
	}
	return formatSchoolYearStr(year-1, year)
}

func formatSchoolYearStr(start, end int) string {
	return fmt.Sprintf("%d-%d", start, end)
}
