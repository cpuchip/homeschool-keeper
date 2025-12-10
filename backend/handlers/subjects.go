package handlers

import (
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"go.mongodb.org/mongo-driver/bson"
)

// SubjectHandler handles subject endpoints
type SubjectHandler struct {
	subjects *repository.SubjectRepository
}

// NewSubjectHandler creates a new SubjectHandler
func NewSubjectHandler(subjects *repository.SubjectRepository) *SubjectHandler {
	return &SubjectHandler{
		subjects: subjects,
	}
}

// CreateSubjectRequest is the request body for creating a subject
type CreateSubjectRequest struct {
	Name        string   `json:"name"`
	Type        string   `json:"type"` // core, elective
	TargetHours *float64 `json:"targetHours,omitempty"`
	Color       string   `json:"color"`
}

// UpdateSubjectRequest is the request body for updating a subject
type UpdateSubjectRequest struct {
	Name        *string  `json:"name,omitempty"`
	Type        *string  `json:"type,omitempty"`
	TargetHours *float64 `json:"targetHours,omitempty"`
	Color       *string  `json:"color,omitempty"`
	SortOrder   *int     `json:"sortOrder,omitempty"`
}

// List handles GET /api/v1/subjects
func (h *SubjectHandler) List(w http.ResponseWriter, r *http.Request) {
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

	// Optional filter by type
	subjectType := r.URL.Query().Get("type")

	// Incremental sync filter - only return records updated after this time
	var since *time.Time
	if sinceStr := r.URL.Query().Get("since"); sinceStr != "" {
		if parsed, err := time.Parse(time.RFC3339, sinceStr); err == nil {
			since = &parsed
		}
	}

	var subjects []models.Subject
	if subjectType != "" {
		subjects, err = h.subjects.GetByType(r.Context(), familyID, subjectType)
	} else {
		subjects, err = h.subjects.GetByFamilyUpdatedSince(r.Context(), familyID, since)
	}

	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, subjects)
}

// Get handles GET /api/v1/subjects/{id}
func (h *SubjectHandler) Get(w http.ResponseWriter, r *http.Request) {
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

	subjectID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid subject ID")
		return
	}

	subject, err := h.subjects.GetByID(r.Context(), familyID, subjectID)
	if err != nil {
		if err == repository.ErrSubjectNotFound {
			NotFound(w, "Subject not found")
			return
		}
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, subject)
}

// Create handles POST /api/v1/subjects
func (h *SubjectHandler) Create(w http.ResponseWriter, r *http.Request) {
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

	var req CreateSubjectRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	if req.Name == "" {
		BadRequest(w, "Name is required")
		return
	}

	// Validate type
	if req.Type != models.SubjectTypeCore && req.Type != models.SubjectTypeElective {
		req.Type = models.SubjectTypeElective // default to elective
	}

	// Assign color if not provided
	if req.Color == "" {
		count, _ := h.subjects.Count(r.Context(), familyID)
		colorIndex := int(count) % len(models.SubjectColors)
		req.Color = models.SubjectColors[colorIndex]
	}

	subject := models.NewSubject(familyID, req.Name, req.Type, req.Color)
	subject.TargetHours = req.TargetHours

	if err := h.subjects.Create(r.Context(), subject); err != nil {
		InternalError(w)
		return
	}

	Created(w, subject)
}

// Update handles PATCH /api/v1/subjects/{id}
func (h *SubjectHandler) Update(w http.ResponseWriter, r *http.Request) {
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

	subjectID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid subject ID")
		return
	}

	var req UpdateSubjectRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Build update document
	update := bson.M{}
	if req.Name != nil {
		update["name"] = *req.Name
	}
	if req.Type != nil {
		update["type"] = *req.Type
	}
	if req.TargetHours != nil {
		update["targetHours"] = *req.TargetHours
	}
	if req.Color != nil {
		update["color"] = *req.Color
	}
	if req.SortOrder != nil {
		update["sortOrder"] = *req.SortOrder
	}

	if len(update) == 0 {
		BadRequest(w, "No fields to update")
		return
	}

	if err := h.subjects.Update(r.Context(), familyID, subjectID, update); err != nil {
		if err == repository.ErrSubjectNotFound {
			NotFound(w, "Subject not found")
			return
		}
		InternalError(w)
		return
	}

	// Return updated subject
	subject, err := h.subjects.GetByID(r.Context(), familyID, subjectID)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, subject)
}

// Delete handles DELETE /api/v1/subjects/{id}
func (h *SubjectHandler) Delete(w http.ResponseWriter, r *http.Request) {
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

	subjectID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid subject ID")
		return
	}

	if err := h.subjects.SoftDelete(r.Context(), familyID, subjectID); err != nil {
		if err == repository.ErrSubjectNotFound {
			NotFound(w, "Subject not found")
			return
		}
		InternalError(w)
		return
	}

	NoContent(w)
}
