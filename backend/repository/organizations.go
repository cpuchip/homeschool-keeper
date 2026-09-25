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
	ErrOrgNotFound = errors.New("organization not found")
)

// OrganizationRepository handles organization database operations
type OrganizationRepository struct {
	coll *mongo.Collection
}

// NewOrganizationRepository creates a new OrganizationRepository
func NewOrganizationRepository(db *mongo.Database) *OrganizationRepository {
	return &OrganizationRepository{
		coll: db.Collection(CollOrgs),
	}
}

// EnsureIndexes creates required indexes for the organizations collection
func (r *OrganizationRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "name", Value: 1}},
		},
	}
	_, err := r.coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create creates a new organization
func (r *OrganizationRepository) Create(ctx context.Context, org *models.Organization) error {
	org.CreatedAt = time.Now().UTC()
	org.UpdatedAt = org.CreatedAt
	if org.ID.IsZero() {
		org.ID = primitive.NewObjectID()
	}

	_, err := r.coll.InsertOne(ctx, org)
	return err
}

// GetByID retrieves an organization by ID
func (r *OrganizationRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.Organization, error) {
	var org models.Organization
	err := r.coll.FindOne(ctx, bson.M{"_id": id}).Decode(&org)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrOrgNotFound
	}
	return &org, err
}

// GetAll returns all organizations (for admin)
func (r *OrganizationRepository) GetAll(ctx context.Context) ([]models.Organization, error) {
	cursor, err := r.coll.Find(ctx, bson.M{})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var orgs []models.Organization
	if err := cursor.All(ctx, &orgs); err != nil {
		return nil, err
	}
	return orgs, nil
}

// Count returns the total number of organizations
func (r *OrganizationRepository) Count(ctx context.Context) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{})
}

// Update updates an organization
func (r *OrganizationRepository) Update(ctx context.Context, id primitive.ObjectID, update bson.M) error {
	update["updatedAt"] = time.Now().UTC()
	result, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return ErrOrgNotFound
	}
	return nil
}

// Delete deletes an organization
func (r *OrganizationRepository) Delete(ctx context.Context, id primitive.ObjectID) error {
	result, err := r.coll.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return err
	}
	if result.DeletedCount == 0 {
		return ErrOrgNotFound
	}
	return nil
}
