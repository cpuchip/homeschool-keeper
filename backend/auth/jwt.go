package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TokenType distinguishes between access and refresh tokens
type TokenType string

const (
	AccessToken  TokenType = "access"
	RefreshToken TokenType = "refresh"
)

// JWTClaims represents the claims in our JWT tokens
type JWTClaims struct {
	jwt.RegisteredClaims
	UserID    string    `json:"userId"`
	FamilyID  string    `json:"familyId"`
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	TokenType TokenType `json:"tokenType"`
}

// TokenPair contains both access and refresh tokens
type TokenPair struct {
	AccessToken  string    `json:"accessToken"`
	RefreshToken string    `json:"refreshToken"`
	ExpiresAt    time.Time `json:"expiresAt"`
}

// JWTManager handles JWT token generation and validation
type JWTManager struct {
	secret        []byte
	accessExpiry  time.Duration
	refreshExpiry time.Duration
}

// NewJWTManager creates a new JWT manager
func NewJWTManager(secret string, accessExpiry, refreshExpiry time.Duration) *JWTManager {
	return &JWTManager{
		secret:        []byte(secret),
		accessExpiry:  accessExpiry,
		refreshExpiry: refreshExpiry,
	}
}

// GenerateTokenPair creates both access and refresh tokens for a user
func (m *JWTManager) GenerateTokenPair(userID, familyID, email, role string) (*TokenPair, error) {
	accessToken, accessExp, err := m.generateToken(userID, familyID, email, role, AccessToken, m.accessExpiry)
	if err != nil {
		return nil, err
	}

	refreshToken, _, err := m.generateToken(userID, familyID, email, role, RefreshToken, m.refreshExpiry)
	if err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresAt:    accessExp,
	}, nil
}

// GenerateAccessToken creates a new access token (used during refresh)
func (m *JWTManager) GenerateAccessToken(userID, familyID, email, role string) (string, time.Time, error) {
	return m.generateToken(userID, familyID, email, role, AccessToken, m.accessExpiry)
}

// generateToken creates a single JWT token
func (m *JWTManager) generateToken(userID, familyID, email, role string, tokenType TokenType, expiry time.Duration) (string, time.Time, error) {
	now := time.Now()
	expiresAt := now.Add(expiry)

	claims := JWTClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    "hmslogs",
			Subject:   userID,
		},
		UserID:    userID,
		FamilyID:  familyID,
		Email:     email,
		Role:      role,
		TokenType: tokenType,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedToken, err := token.SignedString(m.secret)
	if err != nil {
		return "", time.Time{}, err
	}

	return signedToken, expiresAt, nil
}

// ValidateToken parses and validates a JWT token
func (m *JWTManager) ValidateToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return m.secret, nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}

// ValidateAccessToken validates an access token specifically
func (m *JWTManager) ValidateAccessToken(tokenString string) (*JWTClaims, error) {
	claims, err := m.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	if claims.TokenType != AccessToken {
		return nil, errors.New("not an access token")
	}

	return claims, nil
}

// ValidateRefreshToken validates a refresh token specifically
func (m *JWTManager) ValidateRefreshToken(tokenString string) (*JWTClaims, error) {
	claims, err := m.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	if claims.TokenType != RefreshToken {
		return nil, errors.New("not a refresh token")
	}

	return claims, nil
}

// GetUserIDFromClaims converts the string userID to ObjectID
func GetUserIDFromClaims(claims *JWTClaims) (primitive.ObjectID, error) {
	return primitive.ObjectIDFromHex(claims.UserID)
}

// GetFamilyIDFromClaims converts the string familyID to ObjectID
func GetFamilyIDFromClaims(claims *JWTClaims) (primitive.ObjectID, error) {
	return primitive.ObjectIDFromHex(claims.FamilyID)
}
