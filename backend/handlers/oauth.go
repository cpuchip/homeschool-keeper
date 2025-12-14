package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/config"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
)

// OAuthHandler handles OAuth authentication (Google, etc.)
type OAuthHandler struct {
	users      *repository.UserRepository
	families   *repository.FamilyRepository
	subjects   *repository.SubjectRepository
	jwtManager *auth.JWTManager
	cfg        *config.Config
}

// NewOAuthHandler creates a new OAuth handler
func NewOAuthHandler(
	users *repository.UserRepository,
	families *repository.FamilyRepository,
	subjects *repository.SubjectRepository,
	jwtManager *auth.JWTManager,
	cfg *config.Config,
) *OAuthHandler {
	return &OAuthHandler{
		users:      users,
		families:   families,
		subjects:   subjects,
		jwtManager: jwtManager,
		cfg:        cfg,
	}
}

// GoogleAuthRequest is the request body for Google OAuth
type GoogleAuthRequest struct {
	// IDToken is the Google ID token from the client
	IDToken string `json:"idToken"`
	// For registration - optional family name
	FamilyName string `json:"familyName,omitempty"`
	// State code for the family
	State string `json:"state,omitempty"`
}

// GoogleAuthResponse is returned after successful Google auth
type GoogleAuthResponse struct {
	User        models.UserResponse `json:"user"`
	Family      *models.Family      `json:"family"`
	AccessToken string              `json:"accessToken"`
	ExpiresAt   time.Time           `json:"expiresAt"`
	IsNewUser   bool                `json:"isNewUser"`
}

// GoogleTokenInfo represents the response from Google's tokeninfo endpoint
type GoogleTokenInfo struct {
	Aud           string `json:"aud"`
	Sub           string `json:"sub"`
	Email         string `json:"email"`
	EmailVerified string `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
	Exp           string `json:"exp"`
	Error         string `json:"error_description"`
}

// GoogleAuth handles POST /api/v1/auth/google
// This endpoint accepts a Google ID token, verifies it, and returns a JWT
func (h *OAuthHandler) GoogleAuth(w http.ResponseWriter, r *http.Request) {
	if !h.cfg.GoogleConfigured() {
		Error(w, http.StatusServiceUnavailable, "Google OAuth is not configured")
		return
	}

	var req GoogleAuthRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	if req.IDToken == "" {
		BadRequest(w, "idToken is required")
		return
	}

	// Verify the Google ID token
	tokenInfo, err := verifyGoogleIDToken(r.Context(), req.IDToken)
	if err != nil {
		Error(w, http.StatusUnauthorized, "Invalid Google token: "+err.Error())
		return
	}

	// Verify the audience matches our client ID
	if tokenInfo.Aud != h.cfg.GoogleClientID {
		Error(w, http.StatusUnauthorized, "Token was not issued for this application")
		return
	}

	// Check if email is verified
	if tokenInfo.EmailVerified != "true" {
		Error(w, http.StatusUnauthorized, "Email not verified with Google")
		return
	}

	email := strings.ToLower(tokenInfo.Email)

	// Check if user already exists
	user, err := h.users.GetByEmail(r.Context(), email)
	isNewUser := false

	if err == repository.ErrUserNotFound {
		// New user - create account
		isNewUser = true

		// Determine family name
		familyName := req.FamilyName
		if familyName == "" {
			// Use Google family name or a default
			if tokenInfo.FamilyName != "" {
				familyName = tokenInfo.FamilyName + " Family"
			} else {
				familyName = "My Family"
			}
		}

		// Determine user name
		userName := tokenInfo.Name
		if userName == "" {
			userName = tokenInfo.GivenName
		}
		if userName == "" {
			userName = strings.Split(email, "@")[0]
		}

		// Determine state
		state := req.State
		if state == "" {
			state = "MO" // Default to Missouri
		}

		// Create family
		family := models.NewFamily(familyName, state)
		if err := h.families.Create(r.Context(), family); err != nil {
			InternalError(w)
			return
		}

		// Create user (no password since they're using Google)
		user = &models.User{
			Email:        email,
			PasswordHash: "", // Empty - Google auth only
			Name:         userName,
			FamilyID:     family.ID,
			Role:         models.RoleAdmin,
			GoogleID:     tokenInfo.Sub, // Store Google user ID
		}

		if err := h.users.Create(r.Context(), user); err != nil {
			InternalError(w)
			return
		}
	} else if err != nil {
		InternalError(w)
		return
	} else {
		// Existing user - update Google ID if not set
		if user.GoogleID == "" {
			user.GoogleID = tokenInfo.Sub
			if err := h.users.UpdateGoogleID(r.Context(), user.ID, tokenInfo.Sub); err != nil {
				// Non-fatal, continue
				fmt.Printf("Warning: failed to update GoogleID for user %s: %v\n", user.ID, err)
			}
		}
	}

	// Get family
	family, err := h.families.GetByID(r.Context(), user.FamilyID)
	if err != nil {
		InternalError(w)
		return
	}

	// Generate JWT token pair
	tokenPair, err := h.jwtManager.GenerateTokenPair(
		user.ID.Hex(),
		user.FamilyID.Hex(),
		user.Email,
		user.Role,
	)
	if err != nil {
		InternalError(w)
		return
	}

	// Also set session cookie for backward compatibility
	sessionData := auth.SessionData{
		UserID:   user.ID.Hex(),
		FamilyID: user.FamilyID.Hex(),
		Email:    user.Email,
		Role:     user.Role,
	}
	if err := auth.SetSession(w, sessionData); err != nil {
		// Non-fatal for JWT auth
		fmt.Printf("Warning: failed to set session cookie: %v\n", err)
	}

	JSON(w, http.StatusOK, GoogleAuthResponse{
		User:        user.ToResponse(),
		Family:      family,
		AccessToken: tokenPair.AccessToken,
		ExpiresAt:   tokenPair.ExpiresAt,
		IsNewUser:   isNewUser,
	})
}

// verifyGoogleIDToken verifies a Google ID token using Google's tokeninfo endpoint
// In production, you might want to use google.golang.org/api/idtoken for offline verification
func verifyGoogleIDToken(ctx context.Context, idToken string) (*GoogleTokenInfo, error) {
	// Use Google's tokeninfo endpoint for verification
	// This is simpler than downloading and verifying certs ourselves
	url := "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to verify token: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var tokenInfo GoogleTokenInfo
	if err := json.Unmarshal(body, &tokenInfo); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if tokenInfo.Error != "" {
		return nil, fmt.Errorf("token validation failed: %s", tokenInfo.Error)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("token validation returned status %d", resp.StatusCode)
	}

	return &tokenInfo, nil
}
