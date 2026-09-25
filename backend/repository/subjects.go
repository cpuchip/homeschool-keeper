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
	ErrSubjectNotFound = errors.New("subject not found")
)

// SubjectRepository handles subject database operations
type SubjectRepository struct {
	coll *mongo.Collection
}

// NewSubjectRepository creates a new SubjectRepository
func NewSubjectRepository(db *mongo.Database) *SubjectRepository {
	return &SubjectRepository{
		coll: db.Collection(CollSubjects),
	}
}

// EnsureIndexes creates required indexes for the subjects collection
func (r *SubjectRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "familyId", Value: 1}},
		},
		{
			Keys: bson.D{
				{Key: "familyId", Value: 1},
				{Key: "active", Value: 1},
			},
		},
	}
	_, err := r.coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create creates a new subject
func (r *SubjectRepository) Create(ctx context.Context, subject *models.Subject) error {
	subject.CreatedAt = time.Now().UTC()
	subject.UpdatedAt = subject.CreatedAt
	if subject.ID.IsZero() {
		subject.ID = primitive.NewObjectID()
	}
	subject.Active = true

	_, err := r.coll.InsertOne(ctx, subject)
	return err
}

// GetByID retrieves a subject by ID - MUST include familyID for data isolation
func (r *SubjectRepository) GetByID(ctx context.Context, familyID, id primitive.ObjectID) (*models.Subject, error) {
	var subject models.Subject
	// CRITICAL: Always filter by familyId to prevent cross-family access
	err := r.coll.FindOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
		"active":   true,
	}).Decode(&subject)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrSubjectNotFound
	}
	return &subject, err
}

// GetByFamily retrieves all active subjects for a family
func (r *SubjectRepository) GetByFamily(ctx context.Context, familyID primitive.ObjectID) ([]models.Subject, error) {
	return r.GetByFamilyUpdatedSince(ctx, familyID, nil)
}

// GetByFamilyUpdatedSince retrieves subjects updated after the given time (for incremental sync)
func (r *SubjectRepository) GetByFamilyUpdatedSince(ctx context.Context, familyID primitive.ObjectID, since *time.Time) ([]models.Subject, error) {
	opts := options.Find().SetSort(bson.D{
		{Key: "sortOrder", Value: 1},
		{Key: "name", Value: 1},
	})
	query := bson.M{
		"familyId": familyID,
		"active":   true,
	}
	if since != nil {
		query["updatedAt"] = bson.M{"$gt": *since}
	}
	cursor, err := r.coll.Find(ctx, query, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var subjects []models.Subject
	if err := cursor.All(ctx, &subjects); err != nil {
		return nil, err
	}
	return subjects, nil
}

// GetByType retrieves subjects of a specific type (core/elective) for a family
func (r *SubjectRepository) GetByType(ctx context.Context, familyID primitive.ObjectID, subjectType string) ([]models.Subject, error) {
	opts := options.Find().SetSort(bson.D{{Key: "name", Value: 1}})
	cursor, err := r.coll.Find(ctx, bson.M{
		"familyId": familyID,
		"type":     subjectType,
		"active":   true,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var subjects []models.Subject
	if err := cursor.All(ctx, &subjects); err != nil {
		return nil, err
	}
	return subjects, nil
}

// Update updates a subject by ID - MUST include familyID for data isolation
func (r *SubjectRepository) Update(ctx context.Context, familyID, id primitive.ObjectID, update bson.M) error {
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
		return ErrSubjectNotFound
	}
	return nil
}

// SoftDelete deactivates a subject (soft delete) - MUST include familyID
func (r *SubjectRepository) SoftDelete(ctx context.Context, familyID, id primitive.ObjectID) error {
	return r.Update(ctx, familyID, id, bson.M{"active": false})
}

// Restore reactivates a soft-deleted subject - MUST include familyID
func (r *SubjectRepository) Restore(ctx context.Context, familyID, id primitive.ObjectID) error {
	update := bson.M{
		"active":    true,
		"updatedAt": time.Now().UTC(),
	}
	result, err := r.coll.UpdateOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
		"active":   false,
	}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return ErrSubjectNotFound
	}
	return nil
}

// GetDeleted retrieves all soft-deleted subjects for a family
func (r *SubjectRepository) GetDeleted(ctx context.Context, familyID primitive.ObjectID) ([]models.Subject, error) {
	opts := options.Find().SetSort(bson.D{{Key: "name", Value: 1}})
	cursor, err := r.coll.Find(ctx, bson.M{
		"familyId": familyID,
		"active":   false,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var subjects []models.Subject
	if err := cursor.All(ctx, &subjects); err != nil {
		return nil, err
	}
	return subjects, nil
}

// HardDelete permanently removes a subject - MUST include familyID
func (r *SubjectRepository) HardDelete(ctx context.Context, familyID, id primitive.ObjectID) error {
	result, err := r.coll.DeleteOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
	})
	if err != nil {
		return err
	}
	if result.DeletedCount == 0 {
		return ErrSubjectNotFound
	}
	return nil
}

// SeedDefaults creates default subjects for a new family based on state
func (r *SubjectRepository) SeedDefaults(ctx context.Context, familyID primitive.ObjectID, subjectNames []string) error {
	// Build a map of requested subject names for quick lookup
	requested := make(map[string]bool)
	for _, name := range subjectNames {
		requested[name] = true
	}

	// Create subjects from Missouri defaults that were selected
	for i, def := range models.MissouriDefaultSubjects {
		if !requested[def.Name] {
			continue
		}

		subject := &models.Subject{
			ID:        primitive.NewObjectID(),
			FamilyID:  familyID,
			Name:      def.Name,
			Type:      def.Type,
			Color:     def.Color,
			IsDefault: true,
			SortOrder: i,
			Active:    true,
			CreatedAt: time.Now().UTC(),
			UpdatedAt: time.Now().UTC(),
		}
		if _, err := r.coll.InsertOne(ctx, subject); err != nil {
			return err
		}
	}

	return nil
}

// Count returns the number of active subjects in a family
func (r *SubjectRepository) Count(ctx context.Context, familyID primitive.ObjectID) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{"familyId": familyID, "active": true})
}
