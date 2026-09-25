// Package crypto provides encryption utilities for protecting PII data.
// Uses AES-256-GCM for authenticated encryption with per-family key derivation.
package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"
)

var (
	// ErrInvalidCiphertext is returned when decryption fails due to invalid data
	ErrInvalidCiphertext = errors.New("invalid ciphertext")
	// ErrKeyTooShort is returned when the master key is too short
	ErrKeyTooShort = errors.New("master key must be at least 32 characters")
)

// DeriveKey creates a per-family key from master key + familyId.
// Uses SHA-256 to derive a 32-byte AES-256 key.
func DeriveKey(masterKey string, familyID string) []byte {
	combined := masterKey + ":" + familyID
	hash := sha256.Sum256([]byte(combined))
	return hash[:]
}

// Encrypt encrypts plaintext using AES-256-GCM.
// Returns base64-encoded ciphertext (includes nonce).
// Returns empty string if plaintext is empty.
func Encrypt(plaintext string, key []byte) (string, error) {
	if plaintext == "" {
		return "", nil
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	// Create a nonce (number used once) - GCM standard is 12 bytes
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	// Encrypt and prepend nonce to ciphertext
	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)

	// Encode to base64 for storage
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt decrypts base64 ciphertext using AES-256-GCM.
// Returns empty string if ciphertext is empty.
func Decrypt(ciphertext string, key []byte) (string, error) {
	if ciphertext == "" {
		return "", nil
	}

	// Decode from base64
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", ErrInvalidCiphertext
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", ErrInvalidCiphertext
	}

	// Extract nonce and ciphertext
	nonce, ciphertextBytes := data[:nonceSize], data[nonceSize:]

	// Decrypt
	plaintext, err := gcm.Open(nil, nonce, ciphertextBytes, nil)
	if err != nil {
		return "", ErrInvalidCiphertext
	}

	return string(plaintext), nil
}

// ValidateMasterKey checks if the master key meets minimum requirements
func ValidateMasterKey(key string) error {
	if len(key) < 32 {
		return ErrKeyTooShort
	}
	return nil
}
