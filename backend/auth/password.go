package auth

import (
	"golang.org/x/crypto/bcrypt"
)

const (
	// BcryptCost is the cost factor for bcrypt hashing (12 is recommended)
	BcryptCost = 12
)

// HashPassword hashes a password using bcrypt with a cost of 12
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), BcryptCost)
	return string(bytes), err
}

// CheckPassword compares a password with a hash using timing-safe comparison
func CheckPassword(hash, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// ValidatePassword checks if a password meets minimum requirements
func ValidatePassword(password string) bool {
	// Minimum 8 characters
	return len(password) >= 8
}
