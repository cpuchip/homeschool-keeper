package handlers

import (
	"net/http"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
)

// StatsHandler handles statistics endpoints
type StatsHandler struct {
	logs     *repository.LogRepository
	students *repository.StudentRepository
	subjects *repository.SubjectRepository
	families *repository.FamilyRepository
}

// NewStatsHandler creates a new StatsHandler
func NewStatsHandler(logs *repository.LogRepository, students *repository.StudentRepository, subjects *repository.SubjectRepository, families *repository.FamilyRepository) *StatsHandler {
	return &StatsHandler{
		logs:     logs,
		students: students,
		subjects: subjects,
		families: families,
	}
}

// StudentStatsResponse contains statistics for a single student
type StudentStatsResponse struct {
	StudentID      string         `json:"studentId"`
	StudentName    string         `json:"studentName"`
	TotalHours     float64        `json:"totalHours"`
	HoursBySubject []SubjectHours `json:"hoursBySubject"`
	LogCount       int64          `json:"logCount"`
	SchoolYear     string         `json:"schoolYear"`
}

// SubjectHours contains hours for a specific subject
type SubjectHours struct {
	SubjectID   string   `json:"subjectId"`
	SubjectName string   `json:"subjectName"`
	Color       string   `json:"color"`
	Hours       float64  `json:"hours"`
	TargetHours *float64 `json:"targetHours,omitempty"`
	Progress    float64  `json:"progress"` // 0-100 percentage
}

// FamilyStatsResponse contains statistics for all students in a family
type FamilyStatsResponse struct {
	TotalHours    float64                `json:"totalHours"`
	StudentStats  []StudentStatsResponse `json:"students"`
	SchoolYear    string                 `json:"schoolYear"`
	TotalLogCount int64                  `json:"totalLogCount"`
}

// StudentStats handles GET /api/v1/stats/student/{id}
func (h *StatsHandler) StudentStats(w http.ResponseWriter, r *http.Request) {
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

	// Verify student belongs to family
	student, err := h.students.GetByID(r.Context(), familyID, studentID)
	if err != nil {
		if err == repository.ErrStudentNotFound {
			NotFound(w, "Student not found")
			return
		}
		InternalError(w)
		return
	}

	// Get family for school year
	family, err := h.families.GetByID(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Allow school year override via query param
	schoolYear := r.URL.Query().Get("schoolYear")
	if schoolYear == "" {
		schoolYear = family.CurrentYear
	}

	// Get total hours
	totalHours, err := h.logs.GetTotalHours(r.Context(), familyID, studentID, schoolYear)
	if err != nil {
		InternalError(w)
		return
	}

	// Get hours by subject
	hoursBySubject, err := h.logs.GetHoursBySubject(r.Context(), familyID, studentID, schoolYear)
	if err != nil {
		InternalError(w)
		return
	}

	// Get all subjects for the family
	subjects, err := h.subjects.GetByFamily(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Build subject hours response
	subjectHours := make([]SubjectHours, 0, len(subjects))
	for _, subject := range subjects {
		hours := hoursBySubject[subject.ID]
		progress := float64(0)
		if subject.TargetHours != nil && *subject.TargetHours > 0 {
			progress = (hours / *subject.TargetHours) * 100
			if progress > 100 {
				progress = 100
			}
		}
		subjectHours = append(subjectHours, SubjectHours{
			SubjectID:   subject.ID.Hex(),
			SubjectName: subject.Name,
			Color:       subject.Color,
			Hours:       hours,
			TargetHours: subject.TargetHours,
			Progress:    progress,
		})
	}

	// Get log count
	logCount, err := h.logs.Count(r.Context(), familyID, repository.LogFilter{
		StudentID:  &studentID,
		SchoolYear: schoolYear,
	})
	if err != nil {
		InternalError(w)
		return
	}

	response := StudentStatsResponse{
		StudentID:      student.ID.Hex(),
		StudentName:    student.Name,
		TotalHours:     totalHours,
		HoursBySubject: subjectHours,
		LogCount:       logCount,
		SchoolYear:     schoolYear,
	}

	JSON(w, http.StatusOK, response)
}

// FamilyStats handles GET /api/v1/stats/family
func (h *StatsHandler) FamilyStats(w http.ResponseWriter, r *http.Request) {
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

	// Get family for school year
	family, err := h.families.GetByID(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Allow school year override via query param
	schoolYear := r.URL.Query().Get("schoolYear")
	if schoolYear == "" {
		schoolYear = family.CurrentYear
	}

	// Get all students
	students, err := h.students.GetByFamily(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Get all subjects for progress calculation
	subjects, err := h.subjects.GetByFamily(r.Context(), familyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Build stats for each student
	var totalFamilyHours float64
	var totalLogCount int64
	studentStats := make([]StudentStatsResponse, 0, len(students))

	for _, student := range students {
		// Get total hours
		totalHours, err := h.logs.GetTotalHours(r.Context(), familyID, student.ID, schoolYear)
		if err != nil {
			InternalError(w)
			return
		}
		totalFamilyHours += totalHours

		// Get hours by subject
		hoursBySubject, err := h.logs.GetHoursBySubject(r.Context(), familyID, student.ID, schoolYear)
		if err != nil {
			InternalError(w)
			return
		}

		// Build subject hours
		subjectHours := make([]SubjectHours, 0, len(subjects))
		for _, subject := range subjects {
			hours := hoursBySubject[subject.ID]
			progress := float64(0)
			if subject.TargetHours != nil && *subject.TargetHours > 0 {
				progress = (hours / *subject.TargetHours) * 100
				if progress > 100 {
					progress = 100
				}
			}
			subjectHours = append(subjectHours, SubjectHours{
				SubjectID:   subject.ID.Hex(),
				SubjectName: subject.Name,
				Color:       subject.Color,
				Hours:       hours,
				TargetHours: subject.TargetHours,
				Progress:    progress,
			})
		}

		// Get log count
		studentIDCopy := student.ID
		logCount, err := h.logs.Count(r.Context(), familyID, repository.LogFilter{
			StudentID:  &studentIDCopy,
			SchoolYear: schoolYear,
		})
		if err != nil {
			InternalError(w)
			return
		}
		totalLogCount += logCount

		studentStats = append(studentStats, StudentStatsResponse{
			StudentID:      student.ID.Hex(),
			StudentName:    student.Name,
			TotalHours:     totalHours,
			HoursBySubject: subjectHours,
			LogCount:       logCount,
			SchoolYear:     schoolYear,
		})
	}

	response := FamilyStatsResponse{
		TotalHours:    totalFamilyHours,
		StudentStats:  studentStats,
		SchoolYear:    schoolYear,
		TotalLogCount: totalLogCount,
	}

	JSON(w, http.StatusOK, response)
}
