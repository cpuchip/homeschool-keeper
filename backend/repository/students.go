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
	ErrStudentNotFound = errors.New("student not found")
)

// StudentRepository handles student database operations
type StudentRepository struct {
	coll *mongo.Collection
}

// NewStudentRepository creates a new StudentRepository
func NewStudentRepository(db *mongo.Database) *StudentRepository {
	return &StudentRepository{
		coll: db.Collection(CollStudents),
	}
}

// EnsureIndexes creates required indexes for the students collection
func (r *StudentRepository) EnsureIndexes(ctx context.Context) error {
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

// Create creates a new student
func (r *StudentRepository) Create(ctx context.Context, student *models.Student) error {
	student.CreatedAt = time.Now().UTC()
	student.UpdatedAt = student.CreatedAt
	if student.ID.IsZero() {
		student.ID = primitive.NewObjectID()
	}
	student.Active = true

	_, err := r.coll.InsertOne(ctx, student)
	return err
}

// GetByID retrieves a student by ID - MUST include familyID for data isolation
func (r *StudentRepository) GetByID(ctx context.Context, familyID, id primitive.ObjectID) (*models.Student, error) {
	var student models.Student
	// CRITICAL: Always filter by familyId to prevent cross-family access
	err := r.coll.FindOne(ctx, bson.M{
		"_id":      id,
		"familyId": familyID,
		"active":   true,
	}).Decode(&student)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrStudentNotFound
	}
	return &student, err
}

// GetByFamily retrieves all active students for a family
func (r *StudentRepository) GetByFamily(ctx context.Context, familyID primitive.ObjectID) ([]models.Student, error) {
	opts := options.Find().SetSort(bson.D{{Key: "name", Value: 1}})
	cursor, err := r.coll.Find(ctx, bson.M{
		"familyId": familyID,
		"active":   true,
	}, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var students []models.Student
	if err := cursor.All(ctx, &students); err != nil {
		return nil, err
	}
	return students, nil
}

// Update updates a student by ID - MUST include familyID for data isolation
func (r *StudentRepository) Update(ctx context.Context, familyID, id primitive.ObjectID, update bson.M) error {
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
		return ErrStudentNotFound
	}
	return nil
}

// SoftDelete deactivates a student (soft delete) - MUST include familyID
func (r *StudentRepository) SoftDelete(ctx context.Context, familyID, id primitive.ObjectID) error {
	return r.Update(ctx, familyID, id, bson.M{"active": false})
}

// Count returns the number of active students in a family
func (r *StudentRepository) Count(ctx context.Context, familyID primitive.ObjectID) (int64, error) {
	return r.coll.CountDocuments(ctx, bson.M{"familyId": familyID, "active": true})
}
