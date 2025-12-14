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
	ErrLogNotFound = errors.New("log entry not found")
)

// LogRepository handles log entry database operations
type LogRepository struct {
	coll *mongo.Collection
}

// NewLogRepository creates a new LogRepository
func NewLogRepository(db *mongo.Database) *LogRepository {
	return &LogRepository{
		coll: db.Collection(CollLogs),
	}
}

// EnsureIndexes creates required indexes for the log_entries collection
func (r *LogRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "familyId", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "studentId", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "date", Value: -1},
			},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "schoolYear", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "studentId", Value: 1},
				{Key: "subjectId", Value: 1},
				{Key: "schoolYear", Value: 1},
			},
		},
	}
	_, err := r.coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create creates a new log entry
func (r *LogRepository) Create(ctx context.Context, log *models.LogEntry) error {
	log.CreatedAt = time.Now().UTC()
	log.UpdatedAt = log.CreatedAt
	if log.ID.IsZero() {
		log.ID = primitive.NewObjectID()
	}

	_, err := r.coll.InsertOne(ctx, log)
	return err
}

// GetByID retrieves a log entry by ID - MUST include familyID for data isolation
func (r *LogRepository) GetByID(ctx context.Context, familyID, id primitive.ObjectID) (*models.LogEntry, error) {
	var log models.LogEntry
	// CRITICAL: Always filter by familyId to prevent cross-family access
	err := r.coll.FindOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	}).Decode(&log)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrLogNotFound
	}
	return &log, err
}

// LogFilter contains filter options for querying logs
type LogFilter struct {
	StudentID    *primitive.ObjectID
	SubjectID    *primitive.ObjectID
	StartDate    *time.Time
	EndDate      *time.Time
	UpdatedSince *time.Time // For incremental sync - only return records updated after this time
	SchoolYear   string
	Status       string
	Limit        int64
	Skip         int64
}

// GetByFamily retrieves log entries for a family with optional filters
func (r *LogRepository) GetByFamily(ctx context.Context, familyID primitive.ObjectID, filter LogFilter) ([]models.LogEntry, error) {
	query := bson.M{"familyId": familyID}

	if filter.StudentID != nil {
		query["studentId"] = *filter.StudentID
	}
	if filter.SubjectID != nil {
		query["subjectId"] = *filter.SubjectID
	}
	if filter.SchoolYear != "" {
		query["schoolYear"] = filter.SchoolYear
	}
	if filter.Status != "" {
		query["status"] = filter.Status
	}

	// Incremental sync filter - only return records updated after this time
	if filter.UpdatedSince != nil {
		query["updatedAt"] = bson.M{"$gt": *filter.UpdatedSince}
	}

	// Date range filter
	if filter.StartDate != nil || filter.EndDate != nil {
		dateFilter := bson.M{}
		if filter.StartDate != nil {
			dateFilter["$gte"] = *filter.StartDate
		}
		if filter.EndDate != nil {
			dateFilter["$lte"] = *filter.EndDate
		}
		query["date"] = dateFilter
	}

	// Build options
	opts := options.Find().SetSort(bson.D{{Key: "date", Value: -1}})
	if filter.Limit > 0 {
		opts.SetLimit(filter.Limit)
	}
	if filter.Skip > 0 {
		opts.SetSkip(filter.Skip)
	}

	cursor, err := r.coll.Find(ctx, query, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var logs []models.LogEntry
	if err := cursor.All(ctx, &logs); err != nil {
		return nil, err
	}
	return logs, nil
}

// GetByStudent retrieves log entries for a specific student
func (r *LogRepository) GetByStudent(ctx context.Context, familyID, studentID primitive.ObjectID, schoolYear string) ([]models.LogEntry, error) {
	return r.GetByFamily(ctx, familyID, LogFilter{
		StudentID:  &studentID,
		SchoolYear: schoolYear,
	})
}

// Update updates a log entry by ID - MUST include familyID for data isolation
func (r *LogRepository) Update(ctx context.Context, familyID, id primitive.ObjectID, update bson.M) error {
	update["updatedAt"] = time.Now().UTC()
	// CRITICAL: Always filter by familyId to prevent cross-family access
	result, err := r.coll.UpdateOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return ErrLogNotFound
	}
	return nil
}

// Delete permanently deletes a log entry - MUST include familyID for data isolation
func (r *LogRepository) Delete(ctx context.Context, familyID, id primitive.ObjectID) error {
	// CRITICAL: Always filter by familyId to prevent cross-family access
	result, err := r.coll.DeleteOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	})
	if err != nil {
		return err
	}
	if result.DeletedCount == 0 {
		return ErrLogNotFound
	}
	return nil
}

// GetTotalHours calculates total hours for a student in a school year
func (r *LogRepository) GetTotalHours(ctx context.Context, familyID, studentID primitive.ObjectID, schoolYear string) (float64, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"familyId":   familyID,
			"studentId":  studentID,
			"schoolYear": schoolYear,
			"status":     models.LogStatusApproved,
		}}},
		{{Key: "$group", Value: bson.M{
			"_id":        nil,
			"totalHours": bson.M{"$sum": "$hours"},
		}}},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var results []struct {
		TotalHours float64 `bson:"totalHours"`
	}
	if err := cursor.All(ctx, &results); err != nil {
		return 0, err
	}
	if len(results) == 0 {
		return 0, nil
	}
	return results[0].TotalHours, nil
}

// GetHoursBySubject calculates hours per subject for a student in a school year
func (r *LogRepository) GetHoursBySubject(ctx context.Context, familyID, studentID primitive.ObjectID, schoolYear string) (map[primitive.ObjectID]float64, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"familyId":   familyID,
			"studentId":  studentID,
			"schoolYear": schoolYear,
			"status":     models.LogStatusApproved,
		}}},
		{{Key: "$group", Value: bson.M{
			"_id":   "$subjectId",
			"hours": bson.M{"$sum": "$hours"},
		}}},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []struct {
		SubjectID primitive.ObjectID `bson:"_id"`
		Hours     float64            `bson:"hours"`
	}
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}

	hoursBySubject := make(map[primitive.ObjectID]float64)
	for _, r := range results {
		hoursBySubject[r.SubjectID] = r.Hours
	}
	return hoursBySubject, nil
}

// Count returns the number of log entries for a family
func (r *LogRepository) Count(ctx context.Context, familyID primitive.ObjectID, filter LogFilter) (int64, error) {
	query := bson.M{"familyId": familyID}

	if filter.StudentID != nil {
		query["studentId"] = *filter.StudentID
	}
	if filter.SchoolYear != "" {
		query["schoolYear"] = filter.SchoolYear
	}

	return r.coll.CountDocuments(ctx, query)
}

// CountAll returns the total number of log entries (for admin)
func (r *LogRepository) CountAll(ctx context.Context) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{})
}

// CountByFamily returns the number of log entries for a family (simple count)
func (r *LogRepository) CountByFamily(ctx context.Context, familyID primitive.ObjectID) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{"familyId": familyID})
}

// CountByStudent returns the number of log entries for a specific student
func (r *LogRepository) CountByStudent(ctx context.Context, familyID, studentID primitive.ObjectID) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{
		"familyId":  familyID,
		"studentId": studentID,
	})
}

// CountByOrg returns the number of log entries for families in an org
func (r *LogRepository) CountByOrg(ctx context.Context, orgID primitive.ObjectID) (int64, error) {
	pipeline := []bson.M{
		{
			"$lookup": bson.M{
				"from":         "families",
				"localField":   "familyId",
				"foreignField": "_id",
				"as":           "family",
			},
		},
		{
			"$match": bson.M{
				"family.organizationId": orgID,
			},
		},
		{
			"$count": "count",
		},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, err
	}
	defer cursor.Close(ctx)

	var results []bson.M
	if err := cursor.All(ctx, &results); err != nil {
		return 0, err
	}

	if len(results) == 0 {
		return 0, nil
	}

	count, ok := results[0]["count"].(int32)
	if ok {
		return int64(count), nil
	}
	count64, ok := results[0]["count"].(int64)
	if ok {
		return count64, nil
	}
	return 0, nil
}
