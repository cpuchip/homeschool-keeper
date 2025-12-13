package repository

import (
	"context"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// TelemetryRepository handles telemetry event storage
// This is completely separate from user data
type TelemetryRepository struct {
	coll *mongo.Collection
}

// NewTelemetryRepository creates a new TelemetryRepository
func NewTelemetryRepository(db *mongo.Database) *TelemetryRepository {
	return &TelemetryRepository{
		coll: db.Collection(CollTelemetry),
	}
}

// EnsureIndexes creates required indexes
func (r *TelemetryRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "installId", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "event", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "timestamp", Value: -1}},
		},
		{
			Keys: bson.D{
				{Key: "installId", Value: 1},
				{Key: "timestamp", Value: -1},
			},
		},
		{
			Keys: bson.D{{Key: "platform", Value: 1}},
		},
	}
	_, err := r.coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create stores a new telemetry event
func (r *TelemetryRepository) Create(ctx context.Context, event *models.TelemetryEvent) error {
	event.ReceivedAt = time.Now().UTC()
	if event.ID.IsZero() {
		event.ID = primitive.NewObjectID()
	}
	_, err := r.coll.InsertOne(ctx, event)
	return err
}

// CreateBatch stores multiple telemetry events
func (r *TelemetryRepository) CreateBatch(ctx context.Context, events []models.TelemetryEvent) error {
	if len(events) == 0 {
		return nil
	}
	
	docs := make([]interface{}, len(events))
	now := time.Now().UTC()
	for i := range events {
		events[i].ReceivedAt = now
		if events[i].ID.IsZero() {
			events[i].ID = primitive.NewObjectID()
		}
		docs[i] = events[i]
	}
	
	_, err := r.coll.InsertMany(ctx, docs)
	return err
}

// CountByInstallToday returns event count for an install today (for rate limiting)
func (r *TelemetryRepository) CountByInstallToday(ctx context.Context, installID string) (int64, error) {
	today := time.Now().UTC().Truncate(24 * time.Hour)
	return r.coll.CountDocuments(ctx, bson.M{
		"installId": installID,
		"receivedAt": bson.M{
			"$gte": today,
		},
	})
}

// TelemetryStats holds aggregate statistics
type TelemetryStats struct {
	TotalEvents       int64            `json:"totalEvents"`
	UniqueInstalls    int64            `json:"uniqueInstalls"`
	ActiveToday       int64            `json:"activeToday"`
	ActiveThisWeek    int64            `json:"activeThisWeek"`
	ActiveThisMonth   int64            `json:"activeThisMonth"`
	PlatformBreakdown map[string]int64 `json:"platformBreakdown"`
	EventBreakdown    map[string]int64 `json:"eventBreakdown"`
	VersionBreakdown  map[string]int64 `json:"versionBreakdown"`
}

// GetStats returns aggregate telemetry statistics
func (r *TelemetryRepository) GetStats(ctx context.Context) (*TelemetryStats, error) {
	stats := &TelemetryStats{
		PlatformBreakdown: make(map[string]int64),
		EventBreakdown:    make(map[string]int64),
		VersionBreakdown:  make(map[string]int64),
	}

	// Total events
	totalEvents, err := r.coll.CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	stats.TotalEvents = totalEvents

	// Unique installs
	uniqueInstalls, err := r.coll.Distinct(ctx, "installId", bson.M{})
	if err != nil {
		return nil, err
	}
	stats.UniqueInstalls = int64(len(uniqueInstalls))

	// Active periods
	now := time.Now().UTC()
	today := now.Truncate(24 * time.Hour)
	weekAgo := now.AddDate(0, 0, -7)
	monthAgo := now.AddDate(0, -1, 0)

	// Active today
	activeToday, err := r.countDistinctInstalls(ctx, bson.M{
		"timestamp": bson.M{"$gte": today},
	})
	if err != nil {
		return nil, err
	}
	stats.ActiveToday = activeToday

	// Active this week
	activeWeek, err := r.countDistinctInstalls(ctx, bson.M{
		"timestamp": bson.M{"$gte": weekAgo},
	})
	if err != nil {
		return nil, err
	}
	stats.ActiveThisWeek = activeWeek

	// Active this month
	activeMonth, err := r.countDistinctInstalls(ctx, bson.M{
		"timestamp": bson.M{"$gte": monthAgo},
	})
	if err != nil {
		return nil, err
	}
	stats.ActiveThisMonth = activeMonth

	// Platform breakdown
	platformPipeline := []bson.M{
		{"$group": bson.M{
			"_id":   "$platform",
			"count": bson.M{"$sum": 1},
		}},
	}
	if err := r.aggregateBreakdown(ctx, platformPipeline, stats.PlatformBreakdown); err != nil {
		return nil, err
	}

	// Event breakdown
	eventPipeline := []bson.M{
		{"$group": bson.M{
			"_id":   "$event",
			"count": bson.M{"$sum": 1},
		}},
	}
	if err := r.aggregateBreakdown(ctx, eventPipeline, stats.EventBreakdown); err != nil {
		return nil, err
	}

	// Version breakdown (last 30 days only)
	versionPipeline := []bson.M{
		{"$match": bson.M{"timestamp": bson.M{"$gte": monthAgo}}},
		{"$group": bson.M{
			"_id":   "$appVersion",
			"count": bson.M{"$sum": 1},
		}},
		{"$sort": bson.M{"count": -1}},
		{"$limit": 20},
	}
	if err := r.aggregateBreakdown(ctx, versionPipeline, stats.VersionBreakdown); err != nil {
		return nil, err
	}

	return stats, nil
}

func (r *TelemetryRepository) countDistinctInstalls(ctx context.Context, match bson.M) (int64, error) {
	pipeline := []bson.M{
		{"$match": match},
		{"$group": bson.M{"_id": "$installId"}},
		{"$count": "count"},
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

func (r *TelemetryRepository) aggregateBreakdown(ctx context.Context, pipeline []bson.M, result map[string]int64) error {
	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return err
	}
	defer cursor.Close(ctx)

	var docs []struct {
		ID    string `bson:"_id"`
		Count int64  `bson:"count"`
	}
	if err := cursor.All(ctx, &docs); err != nil {
		return err
	}

	for _, doc := range docs {
		if doc.ID != "" {
			result[doc.ID] = doc.Count
		}
	}
	return nil
}

// GetRecentEvents returns recent events (for debugging)
func (r *TelemetryRepository) GetRecentEvents(ctx context.Context, limit int64) ([]models.TelemetryEvent, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "receivedAt", Value: -1}}).
		SetLimit(limit)

	cursor, err := r.coll.Find(ctx, bson.M{}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var events []models.TelemetryEvent
	if err := cursor.All(ctx, &events); err != nil {
		return nil, err
	}
	return events, nil
}

// GetDailyActiveUsers returns DAU for the last N days
func (r *TelemetryRepository) GetDailyActiveUsers(ctx context.Context, days int) ([]DailyCount, error) {
	now := time.Now().UTC()
	startDate := now.AddDate(0, 0, -days).Truncate(24 * time.Hour)

	pipeline := []bson.M{
		{"$match": bson.M{"timestamp": bson.M{"$gte": startDate}}},
		{"$group": bson.M{
			"_id": bson.M{
				"$dateToString": bson.M{
					"format": "%Y-%m-%d",
					"date":   "$timestamp",
				},
			},
			"installs": bson.M{"$addToSet": "$installId"},
		}},
		{"$project": bson.M{
			"date":  "$_id",
			"count": bson.M{"$size": "$installs"},
		}},
		{"$sort": bson.M{"date": 1}},
	}

	cursor, err := r.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []DailyCount
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}

// DailyCount represents a count for a specific day
type DailyCount struct {
	Date  string `bson:"date" json:"date"`
	Count int64  `bson:"count" json:"count"`
}
