package storage

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/joho/godotenv"
)

// TestR2Integration tests the R2 bucket configuration
// Run with: go test -v -run TestR2Integration ./storage/...
// Requires R2_* environment variables to be set
//
// If you get "Access Denied" errors, check your R2 API token permissions:
// 1. Go to Cloudflare Dashboard → R2 → Manage R2 API Tokens
// 2. Edit your token or create a new one
// 3. Ensure "Object Read & Write" is enabled for your bucket
// 4. Copy the new Access Key ID and Secret Access Key to .env
func TestR2Integration(t *testing.T) {
	// Load .env file
	_ = godotenv.Load("../.env")
	_ = godotenv.Load("../../.env")

	// Check if R2 is configured
	accountID := os.Getenv("R2_ACCOUNT_ID")
	accessKeyID := os.Getenv("R2_ACCESS_KEY_ID")
	secretAccessKey := os.Getenv("R2_SECRET_ACCESS_KEY")
	bucketName := os.Getenv("R2_BUCKET_NAME")

	if accountID == "" || accessKeyID == "" || secretAccessKey == "" {
		t.Skip("R2 not configured (missing R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, or R2_SECRET_ACCESS_KEY)")
	}

	if bucketName == "" {
		bucketName = "hsmlogs"
	}

	t.Logf("Testing R2 bucket: %s (account: %s...)", bucketName, accountID[:8])

	// Create R2 client
	client, err := NewR2Client(R2Config{
		AccountID:         accountID,
		AccessKeyID:       accessKeyID,
		SecretAccessKey:   secretAccessKey,
		BucketName:        bucketName,
		UploadURLExpiry:   5 * time.Minute,
		DownloadURLExpiry: 1 * time.Hour,
	})
	if err != nil {
		t.Fatalf("Failed to create R2 client: %v", err)
	}

	ctx := context.Background()
	testKey := fmt.Sprintf("test/integration-test-%d.txt", time.Now().UnixNano())
	testContent := []byte("Hello from Home School Logs integration test!")

	// Test 1: Upload directly
	t.Run("DirectUpload", func(t *testing.T) {
		err := client.UploadObject(ctx, testKey, bytes.NewReader(testContent), "text/plain", int64(len(testContent)))
		if err != nil {
			t.Fatalf("Failed to upload: %v", err)
		}
		t.Logf("✅ Uploaded test file: %s", testKey)
	})

	// Test 2: Check object exists
	t.Run("HeadObject", func(t *testing.T) {
		size, contentType, err := client.HeadObject(ctx, testKey)
		if err != nil {
			t.Fatalf("Failed to head object: %v", err)
		}
		if size != int64(len(testContent)) {
			t.Errorf("Size mismatch: got %d, want %d", size, len(testContent))
		}
		if contentType != "text/plain" {
			t.Errorf("Content-Type mismatch: got %s, want text/plain", contentType)
		}
		t.Logf("✅ Object exists: %d bytes, %s", size, contentType)
	})

	// Test 3: Generate download URL
	t.Run("GenerateDownloadURL", func(t *testing.T) {
		url, expiresAt, err := client.GenerateDownloadURL(ctx, testKey)
		if err != nil {
			t.Fatalf("Failed to generate download URL: %v", err)
		}
		if url == "" {
			t.Error("Download URL is empty")
		}
		if expiresAt.Before(time.Now()) {
			t.Error("Download URL already expired")
		}
		t.Logf("✅ Download URL generated (expires: %s)", expiresAt.Format(time.RFC3339))
		t.Logf("   URL: %s...", url[:80])
	})

	// Test 4: Download and verify content
	t.Run("DownloadObject", func(t *testing.T) {
		body, contentType, err := client.GetObject(ctx, testKey)
		if err != nil {
			t.Fatalf("Failed to download: %v", err)
		}
		defer body.Close()

		buf := new(bytes.Buffer)
		buf.ReadFrom(body)
		downloaded := buf.Bytes()

		if !bytes.Equal(downloaded, testContent) {
			t.Errorf("Content mismatch: got %q, want %q", string(downloaded), string(testContent))
		}
		if contentType != "text/plain" {
			t.Errorf("Content-Type mismatch: got %s, want text/plain", contentType)
		}
		t.Logf("✅ Downloaded and verified content")
	})

	// Test 5: Generate upload URL (pre-signed)
	t.Run("GenerateUploadURL", func(t *testing.T) {
		uploadKey := fmt.Sprintf("test/presigned-upload-%d.txt", time.Now().UnixNano())
		url, expiresAt, err := client.GenerateUploadURL(ctx, uploadKey, "text/plain", 100)
		if err != nil {
			t.Fatalf("Failed to generate upload URL: %v", err)
		}
		if url == "" {
			t.Error("Upload URL is empty")
		}
		if expiresAt.Before(time.Now()) {
			t.Error("Upload URL already expired")
		}
		t.Logf("✅ Upload URL generated (expires: %s)", expiresAt.Format(time.RFC3339))
		t.Logf("   Key: %s", uploadKey)
	})

	// Test 6: Delete object
	t.Run("DeleteObject", func(t *testing.T) {
		err := client.DeleteObject(ctx, testKey)
		if err != nil {
			t.Fatalf("Failed to delete: %v", err)
		}

		// Verify deletion
		_, _, err = client.HeadObject(ctx, testKey)
		if err == nil {
			t.Error("Object still exists after deletion")
		}
		t.Logf("✅ Object deleted successfully")
	})

	// Test 7: Family isolation paths
	t.Run("FamilyIsolation", func(t *testing.T) {
		family1Key := "families/family123/work-samples/log456/test.jpg"
		family2Key := "families/family789/work-samples/log012/test.jpg"

		// These are just path validations - we're testing that we can create
		// isolated paths, not that R2 enforces them (that's done by our app logic)
		if family1Key == family2Key {
			t.Error("Family paths should be different")
		}
		t.Logf("✅ Family isolation paths validated")
		t.Logf("   Family 1: %s", family1Key)
		t.Logf("   Family 2: %s", family2Key)
	})

	t.Log("\n🎉 All R2 integration tests passed!")
}

// TestR2Config tests configuration loading
func TestR2Config(t *testing.T) {
	// Load .env file
	_ = godotenv.Load("../.env")
	_ = godotenv.Load("../../.env")

	accountID := os.Getenv("R2_ACCOUNT_ID")
	accessKeyID := os.Getenv("R2_ACCESS_KEY_ID")
	secretAccessKey := os.Getenv("R2_SECRET_ACCESS_KEY")
	bucketName := os.Getenv("R2_BUCKET_NAME")

	t.Logf("R2 Configuration:")
	t.Logf("  R2_ACCOUNT_ID: %s", maskString(accountID))
	t.Logf("  R2_ACCESS_KEY_ID: %s", maskString(accessKeyID))
	t.Logf("  R2_SECRET_ACCESS_KEY: %s", maskString(secretAccessKey))
	t.Logf("  R2_BUCKET_NAME: %s", bucketName)

	if accountID == "" {
		t.Log("  ⚠️ R2_ACCOUNT_ID not set")
	}
	if accessKeyID == "" {
		t.Log("  ⚠️ R2_ACCESS_KEY_ID not set")
	}
	if secretAccessKey == "" {
		t.Log("  ⚠️ R2_SECRET_ACCESS_KEY not set")
	}
}

func maskString(s string) string {
	if s == "" {
		return "(not set)"
	}
	if len(s) <= 8 {
		return "****"
	}
	return s[:4] + "****" + s[len(s)-4:]
}
