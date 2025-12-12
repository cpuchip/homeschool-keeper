package repository

import (
	"context"
	"errors"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

var (
	ErrFamilyNotFound = errors.New("family not found")
)

// FamilyRepository handles family database operations
type FamilyRepository struct {
	coll *mongo.Collection
}

// NewFamilyRepository creates a new FamilyRepository
func NewFamilyRepository(db *mongo.Database) *FamilyRepository {
	return &FamilyRepository{
		coll: db.Collection(CollFamilies),
	}
}

// EnsureIndexes creates required indexes for the families collection
func (r *FamilyRepository) EnsureIndexes(ctx context.Context) error {
	// No special indexes needed for families yet
	return nil
}

// Create creates a new family
func (r *FamilyRepository) Create(ctx context.Context, family *models.Family) error {
	family.CreatedAt = time.Now().UTC()
	family.UpdatedAt = family.CreatedAt
	if family.ID.IsZero() {
		family.ID = primitive.NewObjectID()
	}

	_, err := r.coll.InsertOne(ctx, family)
	return err
}

// GetByID retrieves a family by ID
func (r *FamilyRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Family, error) {
	var family models.Family
	err := r.coll.FindOne(ctx, bson.M{"_id": id}).Decode(&family)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrFamilyNotFound
	}
	return &family, err
}

// Update updates a family by ID
func (r *FamilyRepository) Update(ctx context.Context, id primitive.ObjectID, update bson.M) error {
	update["updatedAt"] = time.Now().UTC()
	result, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return ErrFamilyNotFound
	}
	return nil
}

// UpdateSettings updates family settings
func (r *FamilyRepository) UpdateSettings(ctx context.Context, id primitive.ObjectID, settings models.FamilySettings) error {
	return r.Update(ctx, id, bson.M{"settings": settings})
}

// UpdateSchoolYear updates the school year configuration
func (r *FamilyRepository) UpdateSchoolYear(ctx context.Context, id primitive.ObjectID, start, end time.Time, yearStr string) error {
	return r.Update(ctx, id, bson.M{
		"schoolYearStart": start,
		"schoolYearEnd":   end,
		"currentYear":     yearStr,
	})
}

// CompleteOnboarding marks onboarding as complete
func (r *FamilyRepository) CompleteOnboarding(ctx context.Context, id primitive.ObjectID) error {
	return r.Update(ctx, id, bson.M{"onboardingDone": true})
}

// UpdateStorageUsage updates the storage used bytes for a family (can be positive or negative)
func (r *FamilyRepository) UpdateStorageUsage(ctx context.Context, id primitive.ObjectID, deltaBytes int64) error {
	_, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{
		"$inc": bson.M{"premium.storageUsedBytes": deltaBytes},
		"$set": bson.M{"updatedAt": time.Now().UTC()},
	})
	return err
}

// SetPremiumFeatures updates the premium feature flags for a family
func (r *FamilyRepository) SetPremiumFeatures(ctx context.Context, id primitive.ObjectID, syncEnabled, uploadsEnabled bool, storageLimitBytes int64) error {
	return r.Update(ctx, id, bson.M{
		"premium.syncEnabled":       syncEnabled,
		"premium.uploadsEnabled":    uploadsEnabled,
		"premium.storageLimitBytes": storageLimitBytes,
	})
}
