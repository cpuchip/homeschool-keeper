package auth

import (
	"context"
	"net/http"
)

// contextKey is a custom type for context keys to avoid collisions
type contextKey string

const (
	// UserContextKey is the context key for storing user session data
	UserContextKey contextKey = "user"
)

// RequireAuth is middleware that requires a valid session.
// Returns 401 Unauthorized if no valid session exists.
func RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		session, err := GetSession(r)
		if err != nil {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		// Add session to context
		ctx := context.WithValue(r.Context(), UserContextKey, session)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequireAuthFunc is the http.HandlerFunc version of RequireAuth
func RequireAuthFunc(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		session, err := GetSession(r)
		if err != nil {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		ctx := context.WithValue(r.Context(), UserContextKey, session)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}

// OptionalAuth is middleware that adds session to context if present,
// but allows the request to proceed even without authentication.
func OptionalAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		session, err := GetSession(r)
		if err == nil && session != nil {
			ctx := context.WithValue(r.Context(), UserContextKey, session)
			r = r.WithContext(ctx)
		}
		next.ServeHTTP(w, r)
	})
}

// GetUserFromContext retrieves the session data from the request context.
// Returns nil if no session is present.
func GetUserFromContext(ctx context.Context) *SessionData {
	session, ok := ctx.Value(UserContextKey).(*SessionData)
	if !ok {
		return nil
	}
	return session
}

// RequireRole is middleware that requires a specific role (in addition to authentication)
func RequireRole(role string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return RequireAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			session := GetUserFromContext(r.Context())
			if session == nil || session.Role != role {
				http.Error(w, "Forbidden", http.StatusForbidden)
				return
			}
			next.ServeHTTP(w, r)
		}))
	}
}

// RequireRoles is middleware that requires one of the specified roles
func RequireRoles(roles ...string) func(http.Handler) http.Handler {
	roleSet := make(map[string]bool)
	for _, r := range roles {
		roleSet[r] = true
	}

	return func(next http.Handler) http.Handler {
		return RequireAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			session := GetUserFromContext(r.Context())
			if session == nil || !roleSet[session.Role] {
				http.Error(w, "Forbidden", http.StatusForbidden)
				return
			}
			next.ServeHTTP(w, r)
		}))
	}
}
