package repository

import (
	"context"
	"errors"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	ErrWorkSampleNotFound = errors.New("work sample not found")
)

// WorkSampleRepository handles work sample database operations
type WorkSampleRepository struct {
	coll *mongo.Collection
}

// NewWorkSampleRepository creates a new WorkSampleRepository
func NewWorkSampleRepository(db *mongo.Database) *WorkSampleRepository {
	return &WorkSampleRepository{
		coll: db.Collection(CollWorkSamples),
	}
}

// EnsureIndexes creates required indexes for the work_samples collection
func (r *WorkSampleRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "familyId", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "logEntryId", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "studentId", Value: 1},
			},
		},
	}
	_, err := r.coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create creates a new work sample record
func (r *WorkSampleRepository) Create(ctx context.Context, sample *models.WorkSample) error {
	sample.CreatedAt = time.Now().UTC()
	if sample.ID.IsZero() {
		sample.ID = primitive.NewObjectID()
	}

	_, err := r.coll.InsertOne(ctx, sample)
	return err
}

// GetByID retrieves a work sample by ID - MUST include familyID for data isolation
func (r *WorkSampleRepository) GetByID(ctx context.Context, familyID, id primitive.ObjectID) (*models.WorkSample, error) {
	var sample models.WorkSample
	err := r.coll.FindOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	}).Decode(&sample)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrWorkSampleNotFound
	}
	return &sample, err
}

// GetByLogEntry retrieves all work samples for a specific log entry
func (r *WorkSampleRepository) GetByLogEntry(ctx context.Context, familyID, logEntryID primitive.ObjectID) ([]models.WorkSample, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: 1}})
	cursor, err := r.coll.Find(ctx, bson.M{
		"familyId":   familyID,
		"logEntryId": logEntryID,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var samples []models.WorkSample
	if err := cursor.All(ctx, &samples); err != nil {
		return nil, err
	}
	return samples, nil
}

// GetByStudent retrieves all work samples for a student
func (r *WorkSampleRepository) GetByStudent(ctx context.Context, familyID, studentID primitive.ObjectID) ([]models.WorkSample, error) {
	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.coll.Find(ctx, bson.M{
		"familyId":  familyID,
		"studentId": studentID,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var samples []models.WorkSample
	if err := cursor.All(ctx, &samples); err != nil {
		return nil, err
	}
	return samples, nil
}

// GetByFamily retrieves all work samples for a family (with pagination)
func (r *WorkSampleRepository) GetByFamily(ctx context.Context, familyID primitive.ObjectID, limit, skip int64) ([]models.WorkSample, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(limit).
		SetSkip(skip)

	cursor, err := r.coll.Find(ctx, bson.M{
		"familyId": familyID,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var samples []models.WorkSample
	if err := cursor.All(ctx, &samples); err != nil {
		return nil, err
	}
	return samples, nil
}

// Delete removes a work sample record - MUST include familyID for data isolation
func (r *WorkSampleRepository) Delete(ctx context.Context, familyID, id primitive.ObjectID) error {
	result, err := r.coll.DeleteOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	})
	if err != nil {
		return err
	}
	if result.DeletedCount == 0 {
		return ErrWorkSampleNotFound
	}
	return nil
}

// DeleteByLogEntry removes all work samples for a log entry
func (r *WorkSampleRepository) DeleteByLogEntry(ctx context.Context, familyID, logEntryID primitive.ObjectID) (int64, error) {
	result, err := r.coll.DeleteMany(ctx, bson.M{
		"familyId":   familyID,
		"logEntryId": logEntryID,
	})
	if err != nil {
		return 0, err
	}
	return result.DeletedCount, nil
}

// CountByFamily returns the total count of work samples for a family
func (r *WorkSampleRepository) CountByFamily(ctx context.Context, familyID primitive.ObjectID) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{"familyId": familyID})
}

// GetTotalSizeByFamily returns the total size of work samples for a family
func (r *WorkSampleRepository) GetTotalSizeByFamily(ctx context.Context, familyID primitive.ObjectID) (int64, error) {
	pipeline := []bson.M{
		{"$match": bson.M{"familyId": familyID}},
		{"$group": bson.M{
			"_id":       nil,
			"totalSize": bson.M{"$sum": "$sizeBytes"},
		}},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var results []struct {
		TotalSize int64 `bson:"totalSize"`
	}
	if err := cursor.All(ctx, &results); err != nil {
		return 0, err
	}

	if len(results) == 0 {
		return 0, nil
	}
	return results[0].TotalSize, nil
}
