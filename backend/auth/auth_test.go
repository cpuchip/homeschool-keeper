package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestHashPassword(t *testing.T) {
	password := "mySecurePassword123"

	hash, err := HashPassword(password)
	require.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)

	// Hash should be different each time (due to salt)
	hash2, err := HashPassword(password)
	require.NoError(t, err)
	assert.NotEqual(t, hash, hash2)
}

func TestCheckPassword(t *testing.T) {
	password := "mySecurePassword123"
	hash, err := HashPassword(password)
	require.NoError(t, err)

	// Correct password should match
	assert.True(t, CheckPassword(hash, password))

	// Wrong password should not match
	assert.False(t, CheckPassword(hash, "wrongPassword"))

	// Empty password should not match
	assert.False(t, CheckPassword(hash, ""))
}

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name     string
		password string
		valid    bool
	}{
		{"valid password", "password123", true},
		{"exactly 8 chars", "12345678", true},
		{"too short", "1234567", false},
		{"empty", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.valid, ValidatePassword(tt.password))
		})
	}
}

func TestSession(t *testing.T) {
	// Initialize session with a test secret
	secret := "test-secret-key-that-is-at-least-32-bytes-long"
	InitSession(secret)

	// Create test session data
	userData := SessionData{
		UserID:   "507f1f77bcf86cd799439011",
		FamilyID: "507f1f77bcf86cd799439012",
		Email:    "test@example.com",
		Role:     "admin",
	}

	// Create a response recorder
	w := httptest.NewRecorder()

	// Set session
	err := SetSession(w, userData)
	require.NoError(t, err)

	// Get the cookie from the response
	cookies := w.Result().Cookies()
	require.Len(t, cookies, 1)
	assert.Equal(t, SessionCookieName, cookies[0].Name)

	// Create a request with the cookie
	req := httptest.NewRequest("GET", "/", nil)
	req.AddCookie(cookies[0])

	// Get session from request
	session, err := GetSession(req)
	require.NoError(t, err)
	assert.Equal(t, userData.UserID, session.UserID)
	assert.Equal(t, userData.FamilyID, session.FamilyID)
	assert.Equal(t, userData.Email, session.Email)
	assert.Equal(t, userData.Role, session.Role)
}

func TestClearSession(t *testing.T) {
	secret := "test-secret-key-that-is-at-least-32-bytes-long"
	InitSession(secret)

	w := httptest.NewRecorder()
	ClearSession(w)

	cookies := w.Result().Cookies()
	require.Len(t, cookies, 1)
	assert.Equal(t, SessionCookieName, cookies[0].Name)
	assert.Equal(t, -1, cookies[0].MaxAge)
}

func TestRequireAuthMiddleware(t *testing.T) {
	secret := "test-secret-key-that-is-at-least-32-bytes-long"
	InitSession(secret)

	// Handler that should only be called if authenticated
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		session := GetUserFromContext(r.Context())
		if session == nil {
			t.Error("Session should be in context")
		}
		w.WriteHeader(http.StatusOK)
	})

	protected := RequireAuth(handler)

	t.Run("without session", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/", nil)
		w := httptest.NewRecorder()

		protected.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("with valid session", func(t *testing.T) {
		// First, set a session
		sessionW := httptest.NewRecorder()
		err := SetSession(sessionW, SessionData{
			UserID:   "507f1f77bcf86cd799439011",
			FamilyID: "507f1f77bcf86cd799439012",
			Email:    "test@example.com",
			Role:     "admin",
		})
		require.NoError(t, err)

		// Create request with the session cookie
		req := httptest.NewRequest("GET", "/", nil)
		req.AddCookie(sessionW.Result().Cookies()[0])
		w := httptest.NewRecorder()

		protected.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
	})
}

func TestOptionalAuthMiddleware(t *testing.T) {
	secret := "test-secret-key-that-is-at-least-32-bytes-long"
	InitSession(secret)

	var sessionFromContext *SessionData
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sessionFromContext = GetUserFromContext(r.Context())
		w.WriteHeader(http.StatusOK)
	})

	optional := OptionalAuth(handler)

	t.Run("without session", func(t *testing.T) {
		sessionFromContext = nil
		req := httptest.NewRequest("GET", "/", nil)
		w := httptest.NewRecorder()

		optional.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.Nil(t, sessionFromContext)
	})

	t.Run("with valid session", func(t *testing.T) {
		sessionFromContext = nil
		sessionW := httptest.NewRecorder()
		err := SetSession(sessionW, SessionData{
			UserID:   "507f1f77bcf86cd799439011",
			FamilyID: "507f1f77bcf86cd799439012",
			Email:    "test@example.com",
			Role:     "admin",
		})
		require.NoError(t, err)

		req := httptest.NewRequest("GET", "/", nil)
		req.AddCookie(sessionW.Result().Cookies()[0])
		w := httptest.NewRecorder()

		optional.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		assert.NotNil(t, sessionFromContext)
		assert.Equal(t, "test@example.com", sessionFromContext.Email)
	})
}
