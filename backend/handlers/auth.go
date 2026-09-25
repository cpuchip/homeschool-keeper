package handlers

import (
	"net/http"
	"strings"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
)

// AuthHandler handles authentication endpoints
type AuthHandler struct {
	users    *repository.UserRepository
	families *repository.FamilyRepository
	subjects *repository.SubjectRepository
}

// NewAuthHandler creates a new AuthHandler
func NewAuthHandler(users *repository.UserRepository, families *repository.FamilyRepository, subjects *repository.SubjectRepository) *AuthHandler {
	return &AuthHandler{
		users:    users,
		families: families,
		subjects: subjects,
	}
}

// RegisterRequest is the request body for registration
type RegisterRequest struct {
	Email      string `json:"email"`
	Password   string `json:"password"`
	Name       string `json:"name"`
	FamilyName string `json:"familyName"`
	State      string `json:"state"` // e.g., "MO"
}

// LoginRequest is the request body for login
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// AuthResponse is returned after successful login/register
type AuthResponse struct {
	User   models.UserResponse `json:"user"`
	Family *models.Family      `json:"family"`
}

// Register handles POST /api/v1/auth/register
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Validate required fields
	if req.Email == "" || req.Password == "" || req.Name == "" || req.FamilyName == "" {
		BadRequest(w, "Email, password, name, and family name are required")
		return
	}

	// Validate email format (basic check)
	if !strings.Contains(req.Email, "@") {
		BadRequest(w, "Invalid email format")
		return
	}

	// Validate password
	if !auth.ValidatePassword(req.Password) {
		BadRequest(w, "Password must be at least 8 characters")
		return
	}

	// Hash password
	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		InternalError(w)
		return
	}

	// Create family first
	family := models.NewFamily(req.FamilyName, req.State)
	if err := h.families.Create(r.Context(), family); err != nil {
		InternalError(w)
		return
	}

	// Create user as admin of the family
	user := &models.User{
		Email:        strings.ToLower(req.Email),
		PasswordHash: hash,
		Name:         req.Name,
		FamilyID:     family.ID,
		Role:         models.RoleAdmin,
	}

	if err := h.users.Create(r.Context(), user); err != nil {
		if err == repository.ErrUserExists {
			BadRequest(w, "An account with this email already exists")
			return
		}
		InternalError(w)
		return
	}

	// Set session
	sessionData := auth.SessionData{
		UserID:   user.ID.Hex(),
		FamilyID: family.ID.Hex(),
		Email:    user.Email,
		Role:     user.Role,
	}
	if err := auth.SetSession(w, sessionData); err != nil {
		InternalError(w)
		return
	}

	Created(w, AuthResponse{
		User:   user.ToResponse(),
		Family: family,
	})
}

// Login handles POST /api/v1/auth/login
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	if req.Email == "" || req.Password == "" {
		BadRequest(w, "Email and password are required")
		return
	}

	// Find user by email
	user, err := h.users.GetByEmail(r.Context(), strings.ToLower(req.Email))
	if err != nil {
		if err == repository.ErrUserNotFound {
			Error(w, http.StatusUnauthorized, "Invalid email or password")
			return
		}
		InternalError(w)
		return
	}

	// Check password
	if !auth.CheckPassword(user.PasswordHash, req.Password) {
		Error(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	// Get family
	family, err := h.families.GetByID(r.Context(), user.FamilyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Update last login
	_ = h.users.UpdateLastLogin(r.Context(), user.ID)

	// Set session
	sessionData := auth.SessionData{
		UserID:   user.ID.Hex(),
		FamilyID: family.ID.Hex(),
		Email:    user.Email,
		Role:     user.Role,
	}
	if err := auth.SetSession(w, sessionData); err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, AuthResponse{
		User:   user.ToResponse(),
		Family: family,
	})
}

// Logout handles POST /api/v1/auth/logout
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	auth.ClearSession(w)
	NoContent(w)
}

// Me handles GET /api/v1/auth/me
func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	userID, err := auth.UserIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	user, err := h.users.GetByID(r.Context(), userID)
	if err != nil {
		if err == repository.ErrUserNotFound {
			Unauthorized(w)
			return
		}
		InternalError(w)
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

	JSON(w, http.StatusOK, AuthResponse{
		User:   user.ToResponse(),
		Family: family,
	})
}
