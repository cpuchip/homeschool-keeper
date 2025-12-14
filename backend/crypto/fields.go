package crypto

import (
	"time"
)

// EncryptField encrypts a field value for storage.
// Returns empty string if input is empty (nil-safe).
func EncryptField(value string, masterKey string, familyID string) (string, error) {
	if value == "" {
		return "", nil
	}
	key := DeriveKey(masterKey, familyID)
	return Encrypt(value, key)
}

// DecryptField decrypts a stored field value.
// Returns empty string if input is empty (nil-safe).
func DecryptField(ciphertext string, masterKey string, familyID string) (string, error) {
	if ciphertext == "" {
		return "", nil
	}
	key := DeriveKey(masterKey, familyID)
	return Decrypt(ciphertext, key)
}

// EncryptTime encrypts a time.Time for storage (RFC3339 format).
// Returns empty string if time is nil.
func EncryptTime(t *time.Time, masterKey string, familyID string) (string, error) {
	if t == nil {
		return "", nil
	}
	timeStr := t.Format(time.RFC3339)
	return EncryptField(timeStr, masterKey, familyID)
}

// DecryptTime decrypts a stored time string back to time.Time.
// Returns nil if ciphertext is empty.
func DecryptTime(ciphertext string, masterKey string, familyID string) (*time.Time, error) {
	if ciphertext == "" {
		return nil, nil
	}
	timeStr, err := DecryptField(ciphertext, masterKey, familyID)
	if err != nil {
		return nil, err
	}
	t, err := time.Parse(time.RFC3339, timeStr)
	if err != nil {
		return nil, err
	}
	return &t, nil
}
