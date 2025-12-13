package handlers

import (
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"github.com/cpuchip/homeschool-keeper/backend/storage"
	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// SuperAdminEmail is the only email allowed to access super admin features
const SuperAdminEmail = "cpuchip@gmail.com"

// AdminHandler handles super admin API endpoints
type AdminHandler struct {
	users       *repository.UserRepository
	families    *repository.FamilyRepository
	orgs        *repository.OrganizationRepository
	students    *repository.StudentRepository
	logs        *repository.LogRepository
	workSamples *repository.WorkSampleRepository
	telemetry   *repository.TelemetryRepository
	r2          *storage.R2Client
}

// NewAdminHandler creates a new admin handler
func NewAdminHandler(
	users *repository.UserRepository,
	families *repository.FamilyRepository,
	orgs *repository.OrganizationRepository,
	students *repository.StudentRepository,
	logs *repository.LogRepository,
	workSamples *repository.WorkSampleRepository,
	telemetry *repository.TelemetryRepository,
	r2 *storage.R2Client,
) *AdminHandler {
	return &AdminHandler{
		users:       users,
		families:    families,
		orgs:        orgs,
		students:    students,
		logs:        logs,
		workSamples: workSamples,
		telemetry:   telemetry,
		r2:          r2,
	}
}

// isSuperAdmin checks if the current user is the super admin
func (h *AdminHandler) isSuperAdmin(r *http.Request) bool {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		return false
	}

	userID, err := primitive.ObjectIDFromHex(session.UserID)
	if err != nil {
		return false
	}

	user, err := h.users.GetByID(r.Context(), userID)
	if err != nil {
		return false
	}

	return user.Email == SuperAdminEmail
}

// requireSuperAdmin is a helper that returns 403 if not super admin
func (h *AdminHandler) requireSuperAdmin(w http.ResponseWriter, r *http.Request) bool {
	if !h.isSuperAdmin(r) {
		Error(w, http.StatusForbidden, "Super admin access required")
		return false
	}
	return true
}

// DashboardStats contains overview statistics for the admin dashboard
type DashboardStats struct {
	TotalFamilies     int64     `json:"totalFamilies"`
	TotalOrgs         int64     `json:"totalOrgs"`
	TotalStudents     int64     `json:"totalStudents"`
	TotalLogs         int64     `json:"totalLogs"`
	TotalWorkSamples  int64     `json:"totalWorkSamples"`
	TotalStorageBytes int64     `json:"totalStorageBytes"`
	TotalStorageMB    float64   `json:"totalStorageMB"`
	SyncEnabled       int64     `json:"syncEnabled"`
	UploadsEnabled    int64     `json:"uploadsEnabled"`
	GeneratedAt       time.Time `json:"generatedAt"`
}

// GetDashboardStats handles GET /api/v1/admin/stats
func (h *AdminHandler) GetDashboardStats(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	ctx := r.Context()

	// Get counts
	familyCount, _ := h.families.Count(ctx)
	orgCount, _ := h.orgs.Count(ctx)
	studentCount, _ := h.students.CountAll(ctx)
	logCount, _ := h.logs.CountAll(ctx)
	workSampleCount, _ := h.workSamples.CountAll(ctx)
	totalStorage, _ := h.workSamples.GetTotalStorageUsed(ctx)
	syncEnabled, uploadsEnabled, _ := h.families.CountPremiumEnabled(ctx)

	stats := DashboardStats{
		TotalFamilies:     familyCount,
		TotalOrgs:         orgCount,
		TotalStudents:     studentCount,
		TotalLogs:         logCount,
		TotalWorkSamples:  workSampleCount,
		TotalStorageBytes: totalStorage,
		TotalStorageMB:    float64(totalStorage) / (1024 * 1024),
		SyncEnabled:       syncEnabled,
		UploadsEnabled:    uploadsEnabled,
		GeneratedAt:       time.Now(),
	}

	JSON(w, http.StatusOK, stats)
}

// FamilySummary is a summary of a family for listing
type FamilySummary struct {
	ID              string    `json:"id"`
	Name            string    `json:"name"`
	State           string    `json:"state"`
	StudentCount    int       `json:"studentCount"`
	LogCount        int64     `json:"logCount"`
	SyncEnabled     bool      `json:"syncEnabled"`
	UploadsEnabled  bool      `json:"uploadsEnabled"`
	StorageUsedMB   float64   `json:"storageUsedMB"`
	OrganizationIDs []string  `json:"organizationIds"`
	CreatedAt       time.Time `json:"createdAt"`
}

// ListFamilies handles GET /api/v1/admin/families
func (h *AdminHandler) ListFamilies(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	ctx := r.Context()

	families, err := h.families.GetAll(ctx)
	if err != nil {
		InternalError(w)
		return
	}

	summaries := make([]FamilySummary, 0, len(families))
	for _, f := range families {
		// Get student count for this family
		students, _ := h.students.GetByFamily(ctx, f.ID)
		logCount, _ := h.logs.CountByFamily(ctx, f.ID)
		storageUsed, _ := h.workSamples.GetTotalSizeByFamily(ctx, f.ID)

		orgIDs := make([]string, 0)
		if f.OrganizationID != nil && !f.OrganizationID.IsZero() {
			orgIDs = append(orgIDs, f.OrganizationID.Hex())
		}

		summaries = append(summaries, FamilySummary{
			ID:              f.ID.Hex(),
			Name:            f.Name,
			State:           f.State,
			StudentCount:    len(students),
			LogCount:        logCount,
			SyncEnabled:     f.Premium.SyncEnabled,
			UploadsEnabled:  f.Premium.UploadsEnabled,
			StorageUsedMB:   float64(storageUsed) / (1024 * 1024),
			OrganizationIDs: orgIDs,
			CreatedAt:       f.CreatedAt,
		})
	}

	JSON(w, http.StatusOK, summaries)
}

// FamilyDetail is detailed info about a family
type FamilyDetail struct {
	ID               string                 `json:"id"`
	Name             string                 `json:"name"`
	State            string                 `json:"state"`
	HourIncrement    float64                `json:"hourIncrement"`
	Premium          models.PremiumFeatures `json:"premium"`
	Students         []StudentInfo          `json:"students"`
	Organizations    []OrgInfo              `json:"organizations"`
	LogCount         int64                  `json:"logCount"`
	WorkSampleCount  int64                  `json:"workSampleCount"`
	StorageUsedBytes int64                  `json:"storageUsedBytes"`
	StorageUsedMB    float64                `json:"storageUsedMB"`
	CreatedAt        time.Time              `json:"createdAt"`
	UpdatedAt        time.Time              `json:"updatedAt"`
}

// StudentInfo is minimal student info for admin view
type StudentInfo struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Active   bool   `json:"active"`
	LogCount int64  `json:"logCount"`
}

// OrgInfo is minimal org info
type OrgInfo struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// GetFamily handles GET /api/v1/admin/families/{id}
func (h *AdminHandler) GetFamily(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	familyID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid family ID")
		return
	}

	ctx := r.Context()

	family, err := h.families.GetByID(ctx, familyID)
	if err != nil {
		NotFound(w, "Family not found")
		return
	}

	// Get students
	students, _ := h.students.GetByFamily(ctx, familyID)
	studentInfos := make([]StudentInfo, 0, len(students))
	for _, s := range students {
		logCount, _ := h.logs.CountByStudent(ctx, familyID, s.ID)
		studentInfos = append(studentInfos, StudentInfo{
			ID:       s.ID.Hex(),
			Name:     s.Name,
			Active:   s.Active,
			LogCount: logCount,
		})
	}

	// Get orgs
	orgs := make([]OrgInfo, 0)
	if family.OrganizationID != nil && !family.OrganizationID.IsZero() {
		org, err := h.orgs.GetByID(ctx, *family.OrganizationID)
		if err == nil {
			orgs = append(orgs, OrgInfo{
				ID:   org.ID.Hex(),
				Name: org.Name,
			})
		}
	}

	// Get counts
	logCount, _ := h.logs.CountByFamily(ctx, familyID)
	workSampleCount, _ := h.workSamples.CountByFamily(ctx, familyID)
	storageUsed, _ := h.workSamples.GetTotalSizeByFamily(ctx, familyID)

	detail := FamilyDetail{
		ID:               family.ID.Hex(),
		Name:             family.Name,
		State:            family.State,
		HourIncrement:    family.HourIncrement,
		Premium:          family.Premium,
		Students:         studentInfos,
		Organizations:    orgs,
		LogCount:         logCount,
		WorkSampleCount:  workSampleCount,
		StorageUsedBytes: storageUsed,
		StorageUsedMB:    float64(storageUsed) / (1024 * 1024),
		CreatedAt:        family.CreatedAt,
		UpdatedAt:        family.UpdatedAt,
	}

	JSON(w, http.StatusOK, detail)
}

// UpdateFamilyPremiumRequest is the request to update premium settings
type UpdateFamilyPremiumRequest struct {
	SyncEnabled       *bool  `json:"syncEnabled"`
	UploadsEnabled    *bool  `json:"uploadsEnabled"`
	StorageLimitBytes *int64 `json:"storageLimitBytes"`
}

// UpdateFamilyPremium handles PATCH /api/v1/admin/families/{id}/premium
func (h *AdminHandler) UpdateFamilyPremium(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	familyID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid family ID")
		return
	}

	var req UpdateFamilyPremiumRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	ctx := r.Context()

	// Get current family
	family, err := h.families.GetByID(ctx, familyID)
	if err != nil {
		NotFound(w, "Family not found")
		return
	}

	// Update fields if provided
	syncEnabled := family.Premium.SyncEnabled
	uploadsEnabled := family.Premium.UploadsEnabled
	storageLimit := family.Premium.StorageLimitBytes

	if req.SyncEnabled != nil {
		syncEnabled = *req.SyncEnabled
	}
	if req.UploadsEnabled != nil {
		uploadsEnabled = *req.UploadsEnabled
	}
	if req.StorageLimitBytes != nil {
		storageLimit = *req.StorageLimitBytes
	}

	err = h.families.SetPremiumFeatures(ctx, familyID, syncEnabled, uploadsEnabled, storageLimit)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, map[string]interface{}{
		"message":           "Premium settings updated",
		"syncEnabled":       syncEnabled,
		"uploadsEnabled":    uploadsEnabled,
		"storageLimitBytes": storageLimit,
	})
}

// OrgSummary is a summary of an organization for listing
type OrgSummary struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	FamilyCount  int64     `json:"familyCount"`
	StudentCount int64     `json:"studentCount"`
	LogCount     int64     `json:"logCount"`
	CreatedAt    time.Time `json:"createdAt"`
}

// ListOrganizations handles GET /api/v1/admin/orgs
func (h *AdminHandler) ListOrganizations(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	ctx := r.Context()

	orgs, err := h.orgs.GetAll(ctx)
	if err != nil {
		InternalError(w)
		return
	}

	summaries := make([]OrgSummary, 0, len(orgs))
	for _, o := range orgs {
		familyCount, _ := h.families.CountByOrg(ctx, o.ID)
		studentCount, _ := h.students.CountByOrg(ctx, o.ID)
		logCount, _ := h.logs.CountByOrg(ctx, o.ID)

		summaries = append(summaries, OrgSummary{
			ID:           o.ID.Hex(),
			Name:         o.Name,
			Description:  o.Description,
			FamilyCount:  familyCount,
			StudentCount: studentCount,
			LogCount:     logCount,
			CreatedAt:    o.CreatedAt,
		})
	}

	JSON(w, http.StatusOK, summaries)
}

// OrgDetail is detailed info about an organization
type OrgDetail struct {
	ID           string       `json:"id"`
	Name         string       `json:"name"`
	Description  string       `json:"description"`
	Families     []FamilyInfo `json:"families"`
	FamilyCount  int64        `json:"familyCount"`
	StudentCount int64        `json:"studentCount"`
	LogCount     int64        `json:"logCount"`
	CreatedAt    time.Time    `json:"createdAt"`
	UpdatedAt    time.Time    `json:"updatedAt"`
}

// FamilyInfo is minimal family info
type FamilyInfo struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	StudentCount int    `json:"studentCount"`
}

// GetOrganization handles GET /api/v1/admin/orgs/{id}
func (h *AdminHandler) GetOrganization(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	orgID, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid organization ID")
		return
	}

	ctx := r.Context()

	org, err := h.orgs.GetByID(ctx, orgID)
	if err != nil {
		NotFound(w, "Organization not found")
		return
	}

	// Get families in this org
	families, _ := h.families.GetByOrg(ctx, orgID)
	familyInfos := make([]FamilyInfo, 0, len(families))
	for _, f := range families {
		students, _ := h.students.GetByFamily(ctx, f.ID)
		familyInfos = append(familyInfos, FamilyInfo{
			ID:           f.ID.Hex(),
			Name:         f.Name,
			StudentCount: len(students),
		})
	}

	familyCount, _ := h.families.CountByOrg(ctx, orgID)
	studentCount, _ := h.students.CountByOrg(ctx, orgID)
	logCount, _ := h.logs.CountByOrg(ctx, orgID)

	detail := OrgDetail{
		ID:           org.ID.Hex(),
		Name:         org.Name,
		Description:  org.Description,
		Families:     familyInfos,
		FamilyCount:  familyCount,
		StudentCount: studentCount,
		LogCount:     logCount,
		CreatedAt:    org.CreatedAt,
		UpdatedAt:    org.UpdatedAt,
	}

	JSON(w, http.StatusOK, detail)
}

// StorageSummary is storage info per family
type StorageSummary struct {
	FamilyID       string  `json:"familyId"`
	FamilyName     string  `json:"familyName"`
	FileCount      int64   `json:"fileCount"`
	TotalBytes     int64   `json:"totalBytes"`
	TotalMB        float64 `json:"totalMB"`
	UploadsEnabled bool    `json:"uploadsEnabled"`
}

// GetStorageStats handles GET /api/v1/admin/storage
func (h *AdminHandler) GetStorageStats(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	ctx := r.Context()

	families, err := h.families.GetAll(ctx)
	if err != nil {
		InternalError(w)
		return
	}

	summaries := make([]StorageSummary, 0)
	for _, f := range families {
		fileCount, _ := h.workSamples.CountByFamily(ctx, f.ID)
		totalBytes, _ := h.workSamples.GetTotalSizeByFamily(ctx, f.ID)

		// Only include families with storage usage or uploads enabled
		if fileCount > 0 || f.Premium.UploadsEnabled {
			summaries = append(summaries, StorageSummary{
				FamilyID:       f.ID.Hex(),
				FamilyName:     f.Name,
				FileCount:      fileCount,
				TotalBytes:     totalBytes,
				TotalMB:        float64(totalBytes) / (1024 * 1024),
				UploadsEnabled: f.Premium.UploadsEnabled,
			})
		}
	}

	JSON(w, http.StatusOK, summaries)
}

// GetTelemetryStats handles GET /api/v1/admin/telemetry
func (h *AdminHandler) GetTelemetryStats(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	if h.telemetry == nil {
		Error(w, http.StatusServiceUnavailable, "Telemetry not configured")
		return
	}

	ctx := r.Context()
	stats, err := h.telemetry.GetStats(ctx)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, stats)
}

// GetTelemetryDAU handles GET /api/v1/admin/telemetry/dau
func (h *AdminHandler) GetTelemetryDAU(w http.ResponseWriter, r *http.Request) {
	if !h.requireSuperAdmin(w, r) {
		return
	}

	if h.telemetry == nil {
		Error(w, http.StatusServiceUnavailable, "Telemetry not configured")
		return
	}

	ctx := r.Context()
	dau, err := h.telemetry.GetDailyActiveUsers(ctx, 30)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, dau)
}

// RegisterAdminRoutes registers admin routes
func RegisterAdminRoutes(r *mux.Router, h *AdminHandler) {
	// All admin routes require authentication (checked in handlers)
	admin := r.PathPrefix("/api/v1/admin").Subrouter()

	admin.HandleFunc("/stats", h.GetDashboardStats).Methods("GET")
	admin.HandleFunc("/families", h.ListFamilies).Methods("GET")
	admin.HandleFunc("/families/{id}", h.GetFamily).Methods("GET")
	admin.HandleFunc("/families/{id}/premium", h.UpdateFamilyPremium).Methods("PATCH")
	admin.HandleFunc("/orgs", h.ListOrganizations).Methods("GET")
	admin.HandleFunc("/orgs/{id}", h.GetOrganization).Methods("GET")
	admin.HandleFunc("/storage", h.GetStorageStats).Methods("GET")
	admin.HandleFunc("/telemetry", h.GetTelemetryStats).Methods("GET")
	admin.HandleFunc("/telemetry/dau", h.GetTelemetryDAU).Methods("GET")
}
