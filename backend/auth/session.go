// Package auth provides authentication and session management for the application.
package auth

import (
	"net/http"
	"time"

	"github.com/gorilla/securecookie"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

const (
	// SessionCookieName is the name of the session cookie
	SessionCookieName = "hmslogs_session"
	// SessionDuration is how long sessions last (30 days)
	SessionDuration = 30 * 24 * time.Hour
)

// SessionData holds the data stored in the session cookie
type SessionData struct {
	UserID   string `json:"userId"`
	FamilyID string `json:"familyId"`
	Email    string `json:"email"`
	Role     string `json:"role"`
}

var cookieHandler *securecookie.SecureCookie

// InitSession initializes the session handler with the given secret.
// The secret should be at least 32 bytes long.
func InitSession(secret string) {
	hashKey := []byte(secret)
	// Block key is optional but provides additional encryption
	blockKey := []byte(secret[:32]) // Use first 32 bytes for AES-256
	cookieHandler = securecookie.New(hashKey, blockKey)
	cookieHandler.MaxAge(int(SessionDuration.Seconds()))
}

// SetSession creates a session for the user and sets the cookie on the response
func SetSession(w http.ResponseWriter, userData SessionData) error {
	encoded, err := cookieHandler.Encode(SessionCookieName, userData)
	if err != nil {
		return err
	}

	cookie := &http.Cookie{
		Name:     SessionCookieName,
		Value:    encoded,
		Path:     "/",
		HttpOnly: true,
		Secure:   true, // Always use secure in production
		SameSite: http.SameSiteLaxMode,
		MaxAge:   int(SessionDuration.Seconds()),
	}
	http.SetCookie(w, cookie)
	return nil
}

// GetSession retrieves the session data from the request cookie
func GetSession(r *http.Request) (*SessionData, error) {
	cookie, err := r.Cookie(SessionCookieName)
	if err != nil {
		return nil, err
	}

	var userData SessionData
	if err := cookieHandler.Decode(SessionCookieName, cookie.Value, &userData); err != nil {
		return nil, err
	}

	return &userData, nil
}

// ClearSession removes the session cookie
func ClearSession(w http.ResponseWriter) {
	cookie := &http.Cookie{
		Name:     SessionCookieName,
		Value:    "",
		Path:     "/",
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   -1, // Delete immediately
	}
	http.SetCookie(w, cookie)
}

// UserIDToObjectID converts the string user ID from session to ObjectID
func UserIDToObjectID(session *SessionData) (primitive.ObjectID, error) {
	return primitive.ObjectIDFromHex(session.UserID)
}

// FamilyIDToObjectID converts the string family ID from session to ObjectID
func FamilyIDToObjectID(session *SessionData) (primitive.ObjectID, error) {
	return primitive.ObjectIDFromHex(session.FamilyID)
}
