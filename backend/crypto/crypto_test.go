package crypto

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDeriveKey(t *testing.T) {
	masterKey := "my-super-secret-master-key-12345"
	familyID := "507f1f77bcf86cd799439011"

	key := DeriveKey(masterKey, familyID)

	assert.Len(t, key, 32, "derived key should be 32 bytes for AES-256")

	// Same inputs should produce same key
	key2 := DeriveKey(masterKey, familyID)
	assert.Equal(t, key, key2, "same inputs should produce same key")

	// Different family should produce different key
	key3 := DeriveKey(masterKey, "507f1f77bcf86cd799439012")
	assert.NotEqual(t, key, key3, "different family should produce different key")
}

func TestEncryptDecrypt(t *testing.T) {
	key := DeriveKey("my-super-secret-master-key-12345", "testfamily")

	tests := []struct {
		name      string
		plaintext string
	}{
		{"simple text", "Hello, World!"},
		{"empty string", ""},
		{"unicode", "Hello 世界 🌍"},
		{"long text", "This is a much longer piece of text that should still encrypt and decrypt correctly."},
		{"special chars", "!@#$%^&*()_+-=[]{}|;':\",./<>?"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ciphertext, err := Encrypt(tt.plaintext, key)
			require.NoError(t, err)

			if tt.plaintext == "" {
				assert.Equal(t, "", ciphertext, "empty input should return empty output")
				return
			}

			assert.NotEqual(t, tt.plaintext, ciphertext, "ciphertext should differ from plaintext")

			decrypted, err := Decrypt(ciphertext, key)
			require.NoError(t, err)
			assert.Equal(t, tt.plaintext, decrypted, "decrypted text should match original")
		})
	}
}

func TestDecryptWithWrongKey(t *testing.T) {
	key1 := DeriveKey("master-key-one", "family1")
	key2 := DeriveKey("master-key-two", "family2")

	ciphertext, err := Encrypt("secret data", key1)
	require.NoError(t, err)

	// Decrypting with wrong key should fail
	_, err = Decrypt(ciphertext, key2)
	assert.ErrorIs(t, err, ErrInvalidCiphertext, "wrong key should fail decryption")
}

func TestDecryptInvalidCiphertext(t *testing.T) {
	key := DeriveKey("master-key", "family")

	tests := []struct {
		name       string
		ciphertext string
	}{
		{"invalid base64", "not-valid-base64!!!"},
		{"too short", "YWJj"},                                 // "abc" in base64 - too short for nonce
		{"corrupted", "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo="}, // valid base64 but not valid ciphertext
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := Decrypt(tt.ciphertext, key)
			assert.Error(t, err, "invalid ciphertext should fail")
		})
	}
}

func TestValidateMasterKey(t *testing.T) {
	tests := []struct {
		name    string
		key     string
		wantErr bool
	}{
		{"valid key", "12345678901234567890123456789012", false},
		{"too short", "short", true},
		{"exactly 32", "12345678901234567890123456789012", false},
		{"longer than 32", "123456789012345678901234567890123456789", false},
		{"empty", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateMasterKey(tt.key)
			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestEncryptFieldRoundtrip(t *testing.T) {
	masterKey := "my-super-secret-master-key-12345"
	familyID := "507f1f77bcf86cd799439011"

	original := "John's Date of Birth"

	encrypted, err := EncryptField(original, masterKey, familyID)
	require.NoError(t, err)
	assert.NotEmpty(t, encrypted)

	decrypted, err := DecryptField(encrypted, masterKey, familyID)
	require.NoError(t, err)
	assert.Equal(t, original, decrypted)
}

func TestEncryptTimeRoundtrip(t *testing.T) {
	masterKey := "my-super-secret-master-key-12345"
	familyID := "507f1f77bcf86cd799439011"

	original := time.Date(2015, 6, 15, 0, 0, 0, 0, time.UTC)

	encrypted, err := EncryptTime(&original, masterKey, familyID)
	require.NoError(t, err)
	assert.NotEmpty(t, encrypted)

	decrypted, err := DecryptTime(encrypted, masterKey, familyID)
	require.NoError(t, err)
	require.NotNil(t, decrypted)
	assert.Equal(t, original.Unix(), decrypted.Unix())
}

func TestNilTimeHandling(t *testing.T) {
	masterKey := "my-super-secret-master-key-12345"
	familyID := "507f1f77bcf86cd799439011"

	// Encrypt nil time
	encrypted, err := EncryptTime(nil, masterKey, familyID)
	require.NoError(t, err)
	assert.Empty(t, encrypted)

	// Decrypt empty string
	decrypted, err := DecryptTime("", masterKey, familyID)
	require.NoError(t, err)
	assert.Nil(t, decrypted)
}
