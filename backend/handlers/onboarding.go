package handlers

import (
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"go.mongodb.org/mongo-driver/bson"
)

// OnboardingHandler handles onboarding endpoints
type OnboardingHandler struct {
	families *repository.FamilyRepository
	subjects *repository.SubjectRepository
	students *repository.StudentRepository
}

// NewOnboardingHandler creates a new OnboardingHandler
func NewOnboardingHandler(families *repository.FamilyRepository, subjects *repository.SubjectRepository, students *repository.StudentRepository) *OnboardingHandler {
	return &OnboardingHandler{
		families: families,
		subjects: subjects,
		students: students,
	}
}

// OnboardingStudent represents a student being added during onboarding
type OnboardingStudent struct {
	Name       string `json:"name"`
	GradeLevel string `json:"gradeLevel"`
}

// CompleteOnboardingRequest is the request body for completing onboarding
type CompleteOnboardingRequest struct {
	SchoolYearStart string              `json:"schoolYearStart"` // YYYY-MM-DD
	SchoolYearEnd   string              `json:"schoolYearEnd"`   // YYYY-MM-DD
	Subjects        []string            `json:"subjects"`        // List of subject names to seed
	Students        []OnboardingStudent `json:"students"`        // Students to create
	Timezone        string              `json:"timezone"`
	HourIncrement   float64             `json:"hourIncrement,omitempty"` // 0.25 default
}

// DefaultSubjectsResponse lists available default subjects
type DefaultSubjectsResponse struct {
	Subjects []DefaultSubject `json:"subjects"`
}

// DefaultSubject represents a selectable default subject
type DefaultSubject struct {
	Name  string `json:"name"`
	Type  string `json:"type"`
	Color string `json:"color"`
}

// GetDefaultSubjects handles GET /api/v1/onboarding/subjects
func (h *OnboardingHandler) GetDefaultSubjects(w http.ResponseWriter, r *http.Request) {
	// Return Missouri default subjects
	subjects := make([]DefaultSubject, len(models.MissouriDefaultSubjects))
	for i, s := range models.MissouriDefaultSubjects {
		subjects[i] = DefaultSubject{
			Name:  s.Name,
			Type:  s.Type,
			Color: s.Color,
		}
	}

	JSON(w, http.StatusOK, DefaultSubjectsResponse{Subjects: subjects})
}

// Complete handles POST /api/v1/onboarding/complete
func (h *OnboardingHandler) Complete(w http.ResponseWriter, r *http.Request) {
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

	var req CompleteOnboardingRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Validate dates
	if req.SchoolYearStart == "" || req.SchoolYearEnd == "" {
		BadRequest(w, "School year start and end dates are required")
		return
	}

	startDate, err := time.Parse("2006-01-02", req.SchoolYearStart)
	if err != nil {
		BadRequest(w, "Invalid school year start date format (use YYYY-MM-DD)")
		return
	}

	endDate, err := time.Parse("2006-01-02", req.SchoolYearEnd)
	if err != nil {
		BadRequest(w, "Invalid school year end date format (use YYYY-MM-DD)")
		return
	}

	if endDate.Before(startDate) {
		BadRequest(w, "School year end date must be after start date")
		return
	}

	// Validate subjects
	if len(req.Subjects) == 0 {
		BadRequest(w, "At least one subject must be selected")
		return
	}

	// Default hour increment
	hourIncrement := req.HourIncrement
	if hourIncrement <= 0 {
		hourIncrement = models.DefaultHourIncrement
	}

	// Default timezone
	timezone := req.Timezone
	if timezone == "" {
		timezone = "America/Chicago"
	}

	// Calculate school year string
	schoolYear := calculateSchoolYear(startDate)

	// Update family settings
	update := bson.M{
		"schoolYearStart": startDate,
		"schoolYearEnd":   endDate,
		"currentYear":     schoolYear,
		"hourIncrement":   hourIncrement,
		"timezone":        timezone,
		"onboardingDone":  true,
	}

	if err := h.families.Update(r.Context(), familyID, update); err != nil {
		InternalError(w)
		return
	}

	// Seed selected subjects
	if err := h.subjects.SeedDefaults(r.Context(), familyID, req.Subjects); err != nil {
		InternalError(w)
		return
	}

	// Create students
	for _, s := range req.Students {
		if s.Name == "" {
			continue // Skip empty students
		}
		student := &models.Student{
			FamilyID:   familyID,
			Name:       s.Name,
			GradeLevel: s.GradeLevel,
			Active:     true,
		}
		if err := h.students.Create(r.Context(), student); err != nil {
			InternalError(w)
			return
		}
	}

	// Return updated family
	family, err := h.families.GetByID(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, family)
}

// GetOnboardingStatus handles GET /api/v1/onboarding/status
func (h *OnboardingHandler) GetStatus(w http.ResponseWriter, r *http.Request) {
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

	JSON(w, http.StatusOK, map[string]bool{
		"onboardingDone": family.OnboardingDone,
	})
}
