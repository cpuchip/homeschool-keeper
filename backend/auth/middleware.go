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

// JWTContextKey is the context key for storing JWT claims
const JWTContextKey contextKey = "jwt_claims"

// RequireJWT is middleware that requires a valid JWT Bearer token.
// Used for mobile API authentication.
func RequireJWT(jwtManager *JWTManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, "Authorization header required", http.StatusUnauthorized)
				return
			}

			// Expect "Bearer <token>"
			const bearerPrefix = "Bearer "
			if len(authHeader) < len(bearerPrefix) || authHeader[:len(bearerPrefix)] != bearerPrefix {
				http.Error(w, "Invalid authorization header format", http.StatusUnauthorized)
				return
			}

			tokenString := authHeader[len(bearerPrefix):]
			claims, err := jwtManager.ValidateAccessToken(tokenString)
			if err != nil {
				http.Error(w, "Invalid or expired token", http.StatusUnauthorized)
				return
			}

			// Convert claims to SessionData for compatibility with existing handlers
			session := &SessionData{
				UserID:   claims.UserID,
				FamilyID: claims.FamilyID,
				Email:    claims.Email,
				Role:     claims.Role,
			}

			// Add both claims and session to context
			ctx := context.WithValue(r.Context(), JWTContextKey, claims)
			ctx = context.WithValue(ctx, UserContextKey, session)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireJWTFunc is the http.HandlerFunc version of RequireJWT
func RequireJWTFunc(jwtManager *JWTManager) func(http.HandlerFunc) http.HandlerFunc {
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			RequireJWT(jwtManager)(http.HandlerFunc(next)).ServeHTTP(w, r)
		}
	}
}

// GetJWTClaimsFromContext retrieves JWT claims from the request context
func GetJWTClaimsFromContext(ctx context.Context) *JWTClaims {
	claims, ok := ctx.Value(JWTContextKey).(*JWTClaims)
	if !ok {
		return nil
	}
	return claims
}

// RequireEitherAuth is middleware that allows either session or JWT authentication
// Useful for endpoints that need to work for both web and mobile
func RequireEitherAuth(jwtManager *JWTManager) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Try JWT first (check Authorization header)
			authHeader := r.Header.Get("Authorization")
			if authHeader != "" {
				const bearerPrefix = "Bearer "
				if len(authHeader) >= len(bearerPrefix) && authHeader[:len(bearerPrefix)] == bearerPrefix {
					tokenString := authHeader[len(bearerPrefix):]
					claims, err := jwtManager.ValidateAccessToken(tokenString)
					if err == nil {
						session := &SessionData{
							UserID:   claims.UserID,
							FamilyID: claims.FamilyID,
							Email:    claims.Email,
							Role:     claims.Role,
						}
						ctx := context.WithValue(r.Context(), JWTContextKey, claims)
						ctx = context.WithValue(ctx, UserContextKey, session)
						next.ServeHTTP(w, r.WithContext(ctx))
						return
					}
				}
			}

			// Fall back to session auth (cookies)
			session, err := GetSession(r)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), UserContextKey, session)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireEitherAuthFunc is the http.HandlerFunc version of RequireEitherAuth
func RequireEitherAuthFunc(jwtManager *JWTManager) func(http.HandlerFunc) http.HandlerFunc {
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			RequireEitherAuth(jwtManager)(http.HandlerFunc(next)).ServeHTTP(w, r)
		}
	}
}
