package handlers

import (
	"net/http"
	"strings"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
)

// MobileAuthHandler handles JWT-based authentication for mobile apps
type MobileAuthHandler struct {
	users      *repository.UserRepository
	families   *repository.FamilyRepository
	subjects   *repository.SubjectRepository
	jwtManager *auth.JWTManager
}

// NewMobileAuthHandler creates a new MobileAuthHandler
func NewMobileAuthHandler(
	users *repository.UserRepository,
	families *repository.FamilyRepository,
	subjects *repository.SubjectRepository,
	jwtManager *auth.JWTManager,
) *MobileAuthHandler {
	return &MobileAuthHandler{
		users:      users,
		families:   families,
		subjects:   subjects,
		jwtManager: jwtManager,
	}
}

// MobileAuthResponse is returned after successful mobile login/register
type MobileAuthResponse struct {
	User         models.UserResponse `json:"user"`
	Family       *models.Family      `json:"family"`
	AccessToken  string              `json:"accessToken"`
	RefreshToken string              `json:"refreshToken"`
	ExpiresAt    int64               `json:"expiresAt"` // Unix timestamp
}

// RefreshRequest is the request body for token refresh
type RefreshRequest struct {
	RefreshToken string `json:"refreshToken"`
}

// RefreshResponse is returned after successful token refresh
type RefreshResponse struct {
	AccessToken string `json:"accessToken"`
	ExpiresAt   int64  `json:"expiresAt"`
}

// Register handles POST /api/v1/mobile/auth/register
func (h *MobileAuthHandler) Register(w http.ResponseWriter, r *http.Request) {
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

	// Generate JWT tokens
	tokenPair, err := h.jwtManager.GenerateTokenPair(
		user.ID.Hex(),
		family.ID.Hex(),
		user.Email,
		user.Role,
	)
	if err != nil {
		InternalError(w)
		return
	}

	Created(w, MobileAuthResponse{
		User:         user.ToResponse(),
		Family:       family,
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.ExpiresAt.Unix(),
	})
}

// Login handles POST /api/v1/mobile/auth/login
func (h *MobileAuthHandler) Login(w http.ResponseWriter, r *http.Request) {
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

	// Generate JWT tokens
	tokenPair, err := h.jwtManager.GenerateTokenPair(
		user.ID.Hex(),
		family.ID.Hex(),
		user.Email,
		user.Role,
	)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, MobileAuthResponse{
		User:         user.ToResponse(),
		Family:       family,
		AccessToken:  tokenPair.AccessToken,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    tokenPair.ExpiresAt.Unix(),
	})
}

// Refresh handles POST /api/v1/mobile/auth/refresh
func (h *MobileAuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	var req RefreshRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	if req.RefreshToken == "" {
		BadRequest(w, "Refresh token is required")
		return
	}

	// Validate refresh token
	claims, err := h.jwtManager.ValidateRefreshToken(req.RefreshToken)
	if err != nil {
		Error(w, http.StatusUnauthorized, "Invalid or expired refresh token")
		return
	}

	// Verify user still exists and is active
	userID, err := auth.GetUserIDFromClaims(claims)
	if err != nil {
		Error(w, http.StatusUnauthorized, "Invalid token")
		return
	}

	user, err := h.users.GetByID(r.Context(), userID)
	if err != nil {
		Error(w, http.StatusUnauthorized, "User not found")
		return
	}

	// Generate new access token
	accessToken, expiresAt, err := h.jwtManager.GenerateAccessToken(
		user.ID.Hex(),
		claims.FamilyID,
		user.Email,
		user.Role,
	)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, RefreshResponse{
		AccessToken: accessToken,
		ExpiresAt:   expiresAt.Unix(),
	})
}

// Me handles GET /api/v1/mobile/auth/me
func (h *MobileAuthHandler) Me(w http.ResponseWriter, r *http.Request) {
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

	// Return without tokens (they already have valid token to call this)
	JSON(w, http.StatusOK, AuthResponse{
		User:   user.ToResponse(),
		Family: family,
	})
}
