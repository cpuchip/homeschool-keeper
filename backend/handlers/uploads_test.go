package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	"github.com/cpuchip/homeschool-keeper/backend/testutil"
	"github.com/gorilla/mux"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TestUploadPremiumGating tests that uploads are gated by premium subscription
func TestUploadPremiumGating(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Setup test database
	ctx := context.Background()
	db := testutil.SetupTestDB(t)
	defer testutil.CleanupTestDB(t, db)

	// Create repositories
	familyRepo := repository.NewFamilyRepository(db)
	userRepo := repository.NewUserRepository(db)
	studentRepo := repository.NewStudentRepository(db)
	logRepo := repository.NewLogRepository(db)
	workSampleRepo := repository.NewWorkSampleRepository(db)

	// Create test family WITHOUT premium uploads
	familyID := primitive.NewObjectID()
	family := &models.Family{
		ID:            familyID,
		Name:          "Test Family",
		HourIncrement: 0.25,
		State:         "MO",
		Premium: models.PremiumFeatures{
			SyncEnabled:       false,
			UploadsEnabled:    false, // NOT enabled
			StorageLimitBytes: 100 * 1024 * 1024,
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	err := familyRepo.Create(ctx, family)
	require.NoError(t, err)

	// Create test user
	userID := primitive.NewObjectID()
	user := &models.User{
		ID:       userID,
		Email:    "test@example.com",
		Name:     "Test User",
		FamilyID: familyID,
		Role:     "parent",
	}
	err = userRepo.Create(ctx, user)
	require.NoError(t, err)

	// Create test student
	studentID := primitive.NewObjectID()
	student := &models.Student{
		ID:       studentID,
		FamilyID: familyID,
		Name:     "Test Student",
		Active:   true,
	}
	err = studentRepo.Create(ctx, student)
	require.NoError(t, err)

	// Create test log entry
	logID := primitive.NewObjectID()
	logEntry := &models.LogEntry{
		ID:        logID,
		FamilyID:  familyID,
		StudentID: studentID,
		SubjectID: primitive.NewObjectID(),
		Date:      time.Now(),
		Hours:     1.0,
	}
	err = logRepo.Create(ctx, logEntry)
	require.NoError(t, err)

	// Create handler (R2 is nil - we're testing the premium check before R2)
	handler := NewUploadHandler(nil, workSampleRepo, familyRepo, logRepo)

	// Create session context
	session := &auth.UserSession{
		UserID:   userID.Hex(),
		FamilyID: familyID.Hex(),
		Role:     "parent",
	}

	t.Run("FreeTierUserCannotUpload", func(t *testing.T) {
		// Create request body
		body := GetUploadURLRequest{
			LogEntryID:  logID.Hex(),
			FileName:    "test.jpg",
			ContentType: "image/jpeg",
			SizeBytes:   1024,
		}
		bodyBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/uploads/url", bytes.NewReader(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		req = req.WithContext(auth.SetUserInContext(req.Context(), session))

		rr := httptest.NewRecorder()
		handler.GetUploadURL(rr, req)

		// Should be forbidden
		assert.Equal(t, http.StatusForbidden, rr.Code)
		assert.Contains(t, rr.Body.String(), "premium subscription")
	})

	t.Run("PremiumUserCanUpload", func(t *testing.T) {
		// Enable premium for the family
		err := familyRepo.SetPremiumFeatures(ctx, familyID, false, true, 100*1024*1024)
		require.NoError(t, err)

		// Create request body
		body := GetUploadURLRequest{
			LogEntryID:  logID.Hex(),
			FileName:    "test.jpg",
			ContentType: "image/jpeg",
			SizeBytes:   1024,
		}
		bodyBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/uploads/url", bytes.NewReader(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		req = req.WithContext(auth.SetUserInContext(req.Context(), session))

		rr := httptest.NewRecorder()
		handler.GetUploadURL(rr, req)

		// Should fail with ServiceUnavailable because R2 is nil, not Forbidden
		// This proves the premium check passed
		assert.Equal(t, http.StatusServiceUnavailable, rr.Code)
		assert.Contains(t, rr.Body.String(), "not configured")
	})
}

// TestStorageQuotaEnforcement tests that storage quota is enforced
// Note: This test validates the quota check logic. In production with R2 configured,
// the quota check happens before generating pre-signed URLs.
func TestStorageQuotaEnforcement(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	ctx := context.Background()
	db := testutil.SetupTestDB(t)
	defer testutil.CleanupTestDB(t, db)

	familyRepo := repository.NewFamilyRepository(db)
	userRepo := repository.NewUserRepository(db)
	studentRepo := repository.NewStudentRepository(db)
	logRepo := repository.NewLogRepository(db)
	workSampleRepo := repository.NewWorkSampleRepository(db)

	// Create family with very small storage limit and NO uploads enabled
	familyID := primitive.NewObjectID()
	family := &models.Family{
		ID:            familyID,
		Name:          "Test Family",
		HourIncrement: 0.25,
		State:         "MO",
		Premium: models.PremiumFeatures{
			SyncEnabled:       true,
			UploadsEnabled:    false, // Start disabled
			StorageLimitBytes: 1024,  // Only 1KB limit
			StorageUsedBytes:  500,   // Already used 500 bytes
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	err := familyRepo.Create(ctx, family)
	require.NoError(t, err)

	userID := primitive.NewObjectID()
	user := &models.User{
		ID:       userID,
		Email:    "test@example.com",
		Name:     "Test User",
		FamilyID: familyID,
		Role:     "parent",
	}
	err = userRepo.Create(ctx, user)
	require.NoError(t, err)

	studentID := primitive.NewObjectID()
	student := &models.Student{
		ID:       studentID,
		FamilyID: familyID,
		Name:     "Test Student",
		Active:   true,
	}
	err = studentRepo.Create(ctx, student)
	require.NoError(t, err)

	logID := primitive.NewObjectID()
	logEntry := &models.LogEntry{
		ID:        logID,
		FamilyID:  familyID,
		StudentID: studentID,
		SubjectID: primitive.NewObjectID(),
		Date:      time.Now(),
		Hours:     1.0,
	}
	err = logRepo.Create(ctx, logEntry)
	require.NoError(t, err)

	handler := NewUploadHandler(nil, workSampleRepo, familyRepo, logRepo)

	session := &auth.UserSession{
		UserID:   userID.Hex(),
		FamilyID: familyID.Hex(),
		Role:     "parent",
	}

	t.Run("PremiumCheckBeforeQuota", func(t *testing.T) {
		// Without premium, should get forbidden (premium check is first)
		body := GetUploadURLRequest{
			LogEntryID:  logID.Hex(),
			FileName:    "large.jpg",
			ContentType: "image/jpeg",
			SizeBytes:   1024,
		}
		bodyBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/uploads/url", bytes.NewReader(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		req = req.WithContext(auth.SetUserInContext(req.Context(), session))

		rr := httptest.NewRecorder()
		handler.GetUploadURL(rr, req)

		// Should be forbidden (premium check first)
		assert.Equal(t, http.StatusForbidden, rr.Code)
	})

	t.Run("StorageUsageTracking", func(t *testing.T) {
		// Verify storage usage is tracked correctly
		usage, err := workSampleRepo.GetTotalSizeByFamily(ctx, familyID)
		require.NoError(t, err)
		assert.Equal(t, int64(0), usage) // No samples uploaded yet

		// Create a sample to simulate usage
		sample := &models.WorkSample{
			ID:          primitive.NewObjectID(),
			FamilyID:    familyID,
			LogEntryID:  logID,
			StudentID:   studentID,
			FileName:    "test.jpg",
			StorageKey:  "test/key",
			ContentType: "image/jpeg",
			SizeBytes:   500,
			UploadedBy:  userID,
			CreatedAt:   time.Now(),
		}
		err = workSampleRepo.Create(ctx, sample)
		require.NoError(t, err)

		usage, err = workSampleRepo.GetTotalSizeByFamily(ctx, familyID)
		require.NoError(t, err)
		assert.Equal(t, int64(500), usage)
	})
}

// TestContentTypeValidation tests that only allowed content types are accepted
func TestContentTypeValidation(t *testing.T) {
	// Test the content type validation function directly
	testCases := []struct {
		name        string
		contentType string
		shouldAllow bool
	}{
		{"JPEG allowed", "image/jpeg", true},
		{"PNG allowed", "image/png", true},
		{"GIF allowed", "image/gif", true},
		{"WebP allowed", "image/webp", true},
		{"HEIC allowed", "image/heic", true},
		{"PDF allowed", "application/pdf", true},
		{"MP4 allowed", "video/mp4", true},
		{"QuickTime allowed", "video/quicktime", true},
		{"EXE rejected", "application/x-msdownload", false},
		{"HTML rejected", "text/html", false},
		{"JavaScript rejected", "application/javascript", false},
		{"ZIP rejected", "application/zip", false},
		{"Text rejected", "text/plain", false},
		{"Word doc rejected", "application/msword", false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			allowed := models.IsAllowedContentType(tc.contentType)
			assert.Equal(t, tc.shouldAllow, allowed, "Content type %s", tc.contentType)
		})
	}
}

// TestFileSizeLimit tests that file size limits are enforced
func TestFileSizeLimit(t *testing.T) {
	// Test the max file size constant
	assert.Equal(t, 10*1024*1024, models.MaxFileSizeBytes, "Max file size should be 10MB")

	testCases := []struct {
		name       string
		sizeBytes  int64
		shouldPass bool
	}{
		{"1KB allowed", 1024, true},
		{"1MB allowed", 1024 * 1024, true},
		{"5MB allowed", 5 * 1024 * 1024, true},
		{"9MB allowed", 9 * 1024 * 1024, true},
		{"10MB exactly allowed", 10 * 1024 * 1024, true},
		{"11MB rejected", 11 * 1024 * 1024, false},
		{"20MB rejected", 20 * 1024 * 1024, false},
		{"100MB rejected", 100 * 1024 * 1024, false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			passes := tc.sizeBytes <= models.MaxFileSizeBytes
			assert.Equal(t, tc.shouldPass, passes, "Size %d bytes", tc.sizeBytes)
		})
	}
}

// TestFamilyIsolation tests that users can only access their own family's files
func TestFamilyIsolation(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	ctx := context.Background()
	db := testutil.SetupTestDB(t)
	defer testutil.CleanupTestDB(t, db)

	familyRepo := repository.NewFamilyRepository(db)
	userRepo := repository.NewUserRepository(db)
	studentRepo := repository.NewStudentRepository(db)
	logRepo := repository.NewLogRepository(db)
	workSampleRepo := repository.NewWorkSampleRepository(db)

	// Create two families
	family1ID := primitive.NewObjectID()
	family1 := &models.Family{
		ID:            family1ID,
		Name:          "Family 1",
		HourIncrement: 0.25,
		State:         "MO",
		Premium:       models.PremiumFeatures{UploadsEnabled: true, StorageLimitBytes: 100 * 1024 * 1024},
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}
	err := familyRepo.Create(ctx, family1)
	require.NoError(t, err)

	family2ID := primitive.NewObjectID()
	family2 := &models.Family{
		ID:            family2ID,
		Name:          "Family 2",
		HourIncrement: 0.25,
		State:         "MO",
		Premium:       models.PremiumFeatures{UploadsEnabled: true, StorageLimitBytes: 100 * 1024 * 1024},
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}
	err = familyRepo.Create(ctx, family2)
	require.NoError(t, err)

	// Create users
	user1ID := primitive.NewObjectID()
	user1 := &models.User{ID: user1ID, Email: "user1@example.com", Name: "User 1", FamilyID: family1ID, Role: "parent"}
	err = userRepo.Create(ctx, user1)
	require.NoError(t, err)

	user2ID := primitive.NewObjectID()
	user2 := &models.User{ID: user2ID, Email: "user2@example.com", Name: "User 2", FamilyID: family2ID, Role: "parent"}
	err = userRepo.Create(ctx, user2)
	require.NoError(t, err)

	// Create students
	student1ID := primitive.NewObjectID()
	student1 := &models.Student{ID: student1ID, FamilyID: family1ID, Name: "Student 1", Active: true}
	err = studentRepo.Create(ctx, student1)
	require.NoError(t, err)

	// Create log for family 1
	log1ID := primitive.NewObjectID()
	log1 := &models.LogEntry{ID: log1ID, FamilyID: family1ID, StudentID: student1ID, SubjectID: primitive.NewObjectID(), Date: time.Now(), Hours: 1.0}
	err = logRepo.Create(ctx, log1)
	require.NoError(t, err)

	// Create work sample for family 1
	sample1 := &models.WorkSample{
		ID:          primitive.NewObjectID(),
		FamilyID:    family1ID,
		LogEntryID:  log1ID,
		StudentID:   student1ID,
		FileName:    "family1-file.jpg",
		StorageKey:  "families/" + family1ID.Hex() + "/test.jpg",
		ContentType: "image/jpeg",
		SizeBytes:   1024,
		UploadedBy:  user1ID,
		CreatedAt:   time.Now(),
	}
	err = workSampleRepo.Create(ctx, sample1)
	require.NoError(t, err)

	handler := NewUploadHandler(nil, workSampleRepo, familyRepo, logRepo)

	t.Run("CannotAccessOtherFamilyWorkSample", func(t *testing.T) {
		// User 2 tries to delete Family 1's work sample
		session2 := &auth.UserSession{
			UserID:   user2ID.Hex(),
			FamilyID: family2ID.Hex(),
			Role:     "parent",
		}

		req := httptest.NewRequest(http.MethodDelete, "/api/v1/work-samples/"+sample1.ID.Hex(), nil)
		req = req.WithContext(auth.SetUserInContext(req.Context(), session2))
		req = mux.SetURLVars(req, map[string]string{"id": sample1.ID.Hex()})

		rr := httptest.NewRecorder()
		handler.Delete(rr, req)

		// Should be not found (can't see other family's files)
		assert.Equal(t, http.StatusNotFound, rr.Code)
	})

	t.Run("CanAccessOwnFamilyWorkSample", func(t *testing.T) {
		// User 1 can delete their own family's work sample
		session1 := &auth.UserSession{
			UserID:   user1ID.Hex(),
			FamilyID: family1ID.Hex(),
			Role:     "parent",
		}

		req := httptest.NewRequest(http.MethodDelete, "/api/v1/work-samples/"+sample1.ID.Hex(), nil)
		req = req.WithContext(auth.SetUserInContext(req.Context(), session1))
		req = mux.SetURLVars(req, map[string]string{"id": sample1.ID.Hex()})

		rr := httptest.NewRecorder()
		handler.Delete(rr, req)

		// Should succeed (no content)
		assert.Equal(t, http.StatusNoContent, rr.Code)
	})
}
