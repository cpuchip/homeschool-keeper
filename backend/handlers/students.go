package handlers

import (
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"go.mongodb.org/mongo-driver/bson"
)

// StudentHandler handles student endpoints
type StudentHandler struct {
	students *repository.StudentRepository
	logs     *repository.LogRepository
}

// NewStudentHandler creates a new StudentHandler
func NewStudentHandler(students *repository.StudentRepository, logs *repository.LogRepository) *StudentHandler {
	return &StudentHandler{
		students: students,
		logs:     logs,
	}
}

// CreateStudentRequest is the request body for creating a student
type CreateStudentRequest struct {
	Name       string `json:"name"`
	GradeLevel string `json:"gradeLevel"`
}

// UpdateStudentRequest is the request body for updating a student
type UpdateStudentRequest struct {
	Name        *string `json:"name,omitempty"`
	GradeLevel  *string `json:"gradeLevel,omitempty"`
	AvatarColor *string `json:"avatarColor,omitempty"`
}

// List handles GET /api/v1/students
func (h *StudentHandler) List(w http.ResponseWriter, r *http.Request) {
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

	// Incremental sync filter - only return records updated after this time
	var since *time.Time
	if sinceStr := r.URL.Query().Get("since"); sinceStr != "" {
		if parsed, err := time.Parse(time.RFC3339, sinceStr); err == nil {
			since = &parsed
		}
	}

	students, err := h.students.GetByFamilyUpdatedSince(r.Context(), familyID, since)
	if err != nil {
		InternalError(w)
		return
	}

	// Ensure students is never null in JSON response
	if students == nil {
		students = []models.Student{}
	}

	JSON(w, http.StatusOK, students)
}

// Get handles GET /api/v1/students/{id}
func (h *StudentHandler) Get(w http.ResponseWriter, r *http.Request) {
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

	studentID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid student ID")
		return
	}

	student, err := h.students.GetByID(r.Context(), familyID, studentID)
	if err != nil {
		if err == repository.ErrStudentNotFound {
			NotFound(w, "Student not found")
			return
		}
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, student)
}

// Create handles POST /api/v1/students
func (h *StudentHandler) Create(w http.ResponseWriter, r *http.Request) {
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

	var req CreateStudentRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	if req.Name == "" {
		BadRequest(w, "Name is required")
		return
	}

	// Create student
	student := models.NewStudent(familyID, req.Name, req.GradeLevel)

	// Assign a color based on student count
	count, _ := h.students.Count(r.Context(), familyID)
	colorIndex := int(count) % len(models.AvatarColors)
	student.AvatarColor = models.AvatarColors[colorIndex]

	if err := h.students.Create(r.Context(), student); err != nil {
		InternalError(w)
		return
	}

	Created(w, student)
}

// Update handles PATCH /api/v1/students/{id}
func (h *StudentHandler) Update(w http.ResponseWriter, r *http.Request) {
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

	studentID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid student ID")
		return
	}

	var req UpdateStudentRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Build update document
	update := bson.M{}
	if req.Name != nil {
		update["name"] = *req.Name
	}
	if req.GradeLevel != nil {
		update["gradeLevel"] = *req.GradeLevel
	}
	if req.AvatarColor != nil {
		update["avatarColor"] = *req.AvatarColor
	}

	if len(update) == 0 {
		BadRequest(w, "No fields to update")
		return
	}

	if err := h.students.Update(r.Context(), familyID, studentID, update); err != nil {
		if err == repository.ErrStudentNotFound {
			NotFound(w, "Student not found")
			return
		}
		InternalError(w)
		return
	}

	// Return updated student
	student, err := h.students.GetByID(r.Context(), familyID, studentID)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, student)
}

// Delete handles DELETE /api/v1/students/{id}
func (h *StudentHandler) Delete(w http.ResponseWriter, r *http.Request) {
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

	studentID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid student ID")
		return
	}

	if err := h.students.SoftDelete(r.Context(), familyID, studentID); err != nil {
		if err == repository.ErrStudentNotFound {
			NotFound(w, "Student not found")
			return
		}
		InternalError(w)
		return
	}

	NoContent(w)
}

// ListDeleted handles GET /api/v1/students/deleted
func (h *StudentHandler) ListDeleted(w http.ResponseWriter, r *http.Request) {
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

	students, err := h.students.GetDeleted(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	if students == nil {
		students = []models.Student{}
	}

	JSON(w, http.StatusOK, students)
}

// Restore handles POST /api/v1/students/{id}/restore
func (h *StudentHandler) Restore(w http.ResponseWriter, r *http.Request) {
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

	studentID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid student ID")
		return
	}

	if err := h.students.Restore(r.Context(), familyID, studentID); err != nil {
		if err == repository.ErrStudentNotFound {
			NotFound(w, "Student not found in trash")
			return
		}
		InternalError(w)
		return
	}

	NoContent(w)
}

// HardDelete handles DELETE /api/v1/students/{id}/permanent
func (h *StudentHandler) HardDelete(w http.ResponseWriter, r *http.Request) {
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

	studentID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid student ID")
		return
	}

	if err := h.students.HardDelete(r.Context(), familyID, studentID); err != nil {
		if err == repository.ErrStudentNotFound {
			NotFound(w, "Student not found")
			return
		}
		InternalError(w)
		return
	}

	NoContent(w)
}
