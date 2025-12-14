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

// LocationRepository handles location database operations
type LocationRepository struct {
	collection *mongo.Collection
}

// NewLocationRepository creates a new location repository
func NewLocationRepository(db *mongo.Database) *LocationRepository {
	return &LocationRepository{
		collection: db.Collection("locations"),
	}
}

// Create creates a new location
func (r *LocationRepository) Create(ctx context.Context, location *models.Location) error {
	_, err := r.collection.InsertOne(ctx, location)
	return err
}

// GetByID retrieves a location by ID (scoped to family)
func (r *LocationRepository) GetByID(ctx context.Context, familyID, id primitive.ObjectID) (*models.Location, error) {
	var location models.Location
	err := r.collection.FindOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	}).Decode(&location)
	if err != nil {
		return nil, err
	}
	return &location, nil
}

// GetByFamily retrieves all locations for a family
func (r *LocationRepository) GetByFamily(ctx context.Context, familyID primitive.ObjectID) ([]models.Location, error) {
	opts := options.Find().SetSort(bson.D{{Key: "name", Value: 1}})
	cursor, err := r.collection.Find(ctx, bson.M{
		"familyId": familyID,
		"active":   true,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var locations []models.Location
	if err := cursor.All(ctx, &locations); err != nil {
		return nil, err
	}
	return locations, nil
}

// GetByFamilySince retrieves locations updated since a timestamp (for sync)
func (r *LocationRepository) GetByFamilySince(ctx context.Context, familyID primitive.ObjectID, since time.Time) ([]models.Location, error) {
	opts := options.Find().SetSort(bson.D{{Key: "updatedAt", Value: 1}})
	cursor, err := r.collection.Find(ctx, bson.M{
		"familyId":  familyID,
		"updatedAt": bson.M{"$gt": since},
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var locations []models.Location
	if err := cursor.All(ctx, &locations); err != nil {
		return nil, err
	}
	return locations, nil
}

// Update updates a location (scoped to family)
func (r *LocationRepository) Update(ctx context.Context, familyID, id primitive.ObjectID, update bson.M) error {
	update["updatedAt"] = time.Now().UTC()
	_, err := r.collection.UpdateOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	}, bson.M{"$set": update})
	return err
}

// Delete soft-deletes a location (scoped to family)
func (r *LocationRepository) Delete(ctx context.Context, familyID, id primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	}, bson.M{"$set": bson.M{
		"active":    false,
		"updatedAt": time.Now().UTC(),
	}})
	return err
}

// EnsureIndexes creates the required indexes for the locations collection
func (r *LocationRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "active", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "type", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "updatedAt", Value: 1},
			},
		},
	}
	_, err := r.collection.Indexes().CreateMany(ctx, indexes)
	return err
}
