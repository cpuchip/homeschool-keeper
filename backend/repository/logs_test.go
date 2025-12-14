package repository

import (
	"os"
	"testing"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.mongodb.org/mongo-driver/bson"
)

// These tests require Docker to be running and use testcontainers.
// Run with: go test -tags=integration ./repository/...
// Or set INTEGRATION_TESTS=true in the environment.

func skipIfNoDocker(t *testing.T) {
	t.Helper()
	if os.Getenv("INTEGRATION_TESTS") != "true" && os.Getenv("CI") != "true" {
		t.Skip("skipping integration test - set INTEGRATION_TESTS=true or run in CI")
	}
}

func TestLogRepository_Create(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	// Create indexes first
	err := repo.EnsureIndexes(ctx)
	require.NoError(t, err)

	familyID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	log := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        1.5,
		Description:  "Completed math worksheet",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "approved",
		SchoolYear:   "2024-2025",
	}

	err = repo.Create(ctx, log)
	require.NoError(t, err)
	assert.False(t, log.ID.IsZero(), "ID should be set after creation")
	assert.False(t, log.CreatedAt.IsZero(), "CreatedAt should be set")
	assert.False(t, log.UpdatedAt.IsZero(), "UpdatedAt should be set")
}

func TestLogRepository_GetByID(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	familyID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Create a log entry
	log := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        2.0,
		Description:  "Reading session",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "approved",
		SchoolYear:   "2024-2025",
	}

	err := repo.Create(ctx, log)
	require.NoError(t, err)

	// Test retrieval with correct familyID
	retrieved, err := repo.GetByID(ctx, familyID, log.ID)
	require.NoError(t, err)
	assert.Equal(t, log.ID, retrieved.ID)
	assert.Equal(t, log.Hours, retrieved.Hours)
	assert.Equal(t, log.Description, retrieved.Description)

	// Test retrieval with wrong familyID (data isolation)
	wrongFamilyID := testutil.NewObjectID()
	retrieved, err = repo.GetByID(ctx, wrongFamilyID, log.ID)
	assert.ErrorIs(t, err, ErrLogNotFound, "should not find log with wrong familyID")
	assert.Nil(t, retrieved)
}

func TestLogRepository_GetByFamily_DataIsolation(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	// Create logs for two different families
	family1ID := testutil.NewObjectID()
	family2ID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Family 1's logs
	for i := 0; i < 3; i++ {
		log := &models.LogEntry{
			FamilyID:     family1ID,
			StudentID:    studentID,
			SubjectID:    subjectID,
			Date:         time.Now().UTC().Truncate(24 * time.Hour),
			Hours:        1.0,
			Description:  "Family 1 log",
			LocationType: "home",
			SubmittedBy:  userID,
			Status:       "approved",
			SchoolYear:   "2024-2025",
		}
		err := repo.Create(ctx, log)
		require.NoError(t, err)
	}

	// Family 2's logs
	for i := 0; i < 2; i++ {
		log := &models.LogEntry{
			FamilyID:     family2ID,
			StudentID:    studentID,
			SubjectID:    subjectID,
			Date:         time.Now().UTC().Truncate(24 * time.Hour),
			Hours:        1.5,
			Description:  "Family 2 log",
			LocationType: "home",
			SubmittedBy:  userID,
			Status:       "approved",
			SchoolYear:   "2024-2025",
		}
		err := repo.Create(ctx, log)
		require.NoError(t, err)
	}

	// Family 1 should only see their 3 logs
	family1Logs, err := repo.GetByFamily(ctx, family1ID, LogFilter{})
	require.NoError(t, err)
	assert.Len(t, family1Logs, 3)
	for _, log := range family1Logs {
		assert.Equal(t, family1ID, log.FamilyID, "all logs should belong to family 1")
		assert.Equal(t, "Family 1 log", log.Description)
	}

	// Family 2 should only see their 2 logs
	family2Logs, err := repo.GetByFamily(ctx, family2ID, LogFilter{})
	require.NoError(t, err)
	assert.Len(t, family2Logs, 2)
	for _, log := range family2Logs {
		assert.Equal(t, family2ID, log.FamilyID, "all logs should belong to family 2")
		assert.Equal(t, "Family 2 log", log.Description)
	}
}

func TestLogRepository_GetByFamily_WithFilters(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	familyID := testutil.NewObjectID()
	student1ID := testutil.NewObjectID()
	student2ID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Create logs for student 1
	for i := 0; i < 3; i++ {
		log := &models.LogEntry{
			FamilyID:     familyID,
			StudentID:    student1ID,
			SubjectID:    subjectID,
			Date:         time.Now().UTC().Truncate(24 * time.Hour),
			Hours:        1.0,
			Description:  "Student 1 log",
			LocationType: "home",
			SubmittedBy:  userID,
			Status:       "approved",
			SchoolYear:   "2024-2025",
		}
		err := repo.Create(ctx, log)
		require.NoError(t, err)
	}

	// Create logs for student 2
	for i := 0; i < 2; i++ {
		log := &models.LogEntry{
			FamilyID:     familyID,
			StudentID:    student2ID,
			SubjectID:    subjectID,
			Date:         time.Now().UTC().Truncate(24 * time.Hour),
			Hours:        1.5,
			Description:  "Student 2 log",
			LocationType: "home",
			SubmittedBy:  userID,
			Status:       "approved",
			SchoolYear:   "2024-2025",
		}
		err := repo.Create(ctx, log)
		require.NoError(t, err)
	}

	// Filter by student 1
	student1Logs, err := repo.GetByFamily(ctx, familyID, LogFilter{
		StudentID: &student1ID,
	})
	require.NoError(t, err)
	assert.Len(t, student1Logs, 3)

	// Filter by student 2
	student2Logs, err := repo.GetByFamily(ctx, familyID, LogFilter{
		StudentID: &student2ID,
	})
	require.NoError(t, err)
	assert.Len(t, student2Logs, 2)

	// Test limit
	limitedLogs, err := repo.GetByFamily(ctx, familyID, LogFilter{
		Limit: 2,
	})
	require.NoError(t, err)
	assert.Len(t, limitedLogs, 2)
}

func TestLogRepository_Update(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	familyID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Create a log entry
	log := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        1.0,
		Description:  "Original description",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "pending",
		SchoolYear:   "2024-2025",
	}

	err := repo.Create(ctx, log)
	require.NoError(t, err)
	originalUpdatedAt := log.UpdatedAt

	// Wait a bit so updatedAt will be different
	time.Sleep(10 * time.Millisecond)

	// Update the log using bson.M
	err = repo.Update(ctx, familyID, log.ID, bson.M{
		"hours":       2.0,
		"description": "Updated description",
		"status":      "approved",
	})
	require.NoError(t, err)

	// Retrieve and verify
	updated, err := repo.GetByID(ctx, familyID, log.ID)
	require.NoError(t, err)
	assert.Equal(t, 2.0, updated.Hours)
	assert.Equal(t, "Updated description", updated.Description)
	assert.Equal(t, "approved", updated.Status)
	assert.True(t, updated.UpdatedAt.After(originalUpdatedAt), "updatedAt should be updated")
}

func TestLogRepository_Delete(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	familyID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Create a log entry
	log := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        1.0,
		Description:  "To be deleted",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "approved",
		SchoolYear:   "2024-2025",
	}

	err := repo.Create(ctx, log)
	require.NoError(t, err)

	// Delete the log
	err = repo.Delete(ctx, familyID, log.ID)
	require.NoError(t, err)

	// Verify it's deleted
	deleted, err := repo.GetByID(ctx, familyID, log.ID)
	assert.ErrorIs(t, err, ErrLogNotFound)
	assert.Nil(t, deleted)

	// Test that delete with wrong familyID doesn't affect the log
	// (create another log first)
	log2 := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        1.0,
		Description:  "Another log",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "approved",
		SchoolYear:   "2024-2025",
	}
	err = repo.Create(ctx, log2)
	require.NoError(t, err)

	// Try to delete with wrong familyID
	wrongFamilyID := testutil.NewObjectID()
	err = repo.Delete(ctx, wrongFamilyID, log2.ID)
	assert.ErrorIs(t, err, ErrLogNotFound, "should not delete log with wrong familyID")

	// Verify log2 still exists
	stillExists, err := repo.GetByID(ctx, familyID, log2.ID)
	require.NoError(t, err)
	assert.NotNil(t, stillExists)
}

func TestLogRepository_CountByFamily(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	familyID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Create 5 logs
	for i := 0; i < 5; i++ {
		log := &models.LogEntry{
			FamilyID:     familyID,
			StudentID:    studentID,
			SubjectID:    subjectID,
			Date:         time.Now().UTC().Truncate(24 * time.Hour),
			Hours:        1.0,
			LocationType: "home",
			SubmittedBy:  userID,
			Status:       "approved",
			SchoolYear:   "2024-2025",
		}
		err := repo.Create(ctx, log)
		require.NoError(t, err)
	}

	count, err := repo.Count(ctx, familyID, LogFilter{})
	require.NoError(t, err)
	assert.Equal(t, int64(5), count)

	// Count for a different family should be 0
	otherFamilyID := testutil.NewObjectID()
	otherCount, err := repo.Count(ctx, otherFamilyID, LogFilter{})
	require.NoError(t, err)
	assert.Equal(t, int64(0), otherCount)
}

func TestLogRepository_IncrementalSync(t *testing.T) {
	skipIfNoDocker(t)

	mc := testutil.SetupMongoDB(t)
	repo := NewLogRepository(mc.Database)
	ctx := testutil.TestContext(t)

	familyID := testutil.NewObjectID()
	studentID := testutil.NewObjectID()
	subjectID := testutil.NewObjectID()
	userID := testutil.NewObjectID()

	// Create initial log
	log1 := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        1.0,
		Description:  "First log",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "approved",
		SchoolYear:   "2024-2025",
	}
	err := repo.Create(ctx, log1)
	require.NoError(t, err)

	// Record the sync time
	syncTime := time.Now().UTC()
	time.Sleep(10 * time.Millisecond)

	// Create a second log after sync time
	log2 := &models.LogEntry{
		FamilyID:     familyID,
		StudentID:    studentID,
		SubjectID:    subjectID,
		Date:         time.Now().UTC().Truncate(24 * time.Hour),
		Hours:        2.0,
		Description:  "Second log",
		LocationType: "home",
		SubmittedBy:  userID,
		Status:       "approved",
		SchoolYear:   "2024-2025",
	}
	err = repo.Create(ctx, log2)
	require.NoError(t, err)

	// Query with UpdatedSince filter - should only get the second log
	logs, err := repo.GetByFamily(ctx, familyID, LogFilter{
		UpdatedSince: &syncTime,
	})
	require.NoError(t, err)
	assert.Len(t, logs, 1, "should only get logs updated after sync time")
	assert.Equal(t, "Second log", logs[0].Description)
}
