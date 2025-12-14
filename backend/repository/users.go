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
	ErrUserNotFound       = errors.New("user not found")
	ErrUserExists         = errors.New("user with this email already exists")
	ErrInvalidCredentials = errors.New("invalid credentials")
)

// UserRepository handles user database operations
type UserRepository struct {
	coll *mongo.Collection
}

// NewUserRepository creates a new UserRepository
func NewUserRepository(db *mongo.Database) *UserRepository {
	return &UserRepository{
		coll: db.Collection(CollUsers),
	}
}

// EnsureIndexes creates required indexes for the users collection
func (r *UserRepository) EnsureIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "email", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "familyId", Value: 1}},
		},
	}
	_, err := r.coll.Indexes().CreateMany(ctx, indexes)
	return err
}

// Create creates a new user
func (r *UserRepository) Create(ctx context.Context, user *models.User) error {
	user.CreatedAt = time.Now().UTC()
	user.UpdatedAt = user.CreatedAt
	if user.ID.IsZero() {
		user.ID = primitive.NewObjectID()
	}
	user.Active = true

	_, err := r.coll.InsertOne(ctx, user)
	if mongo.IsDuplicateKeyError(err) {
		return ErrUserExists
	}
	return err
}

// GetByID retrieves a user by ID
func (r *UserRepository) GetByID(ctx context.Context, id primitive.ObjectID) (*models.User, error) {
	var user models.User
	err := r.coll.FindOne(ctx, bson.M{"_id": id, "active": true}).Decode(&user)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrUserNotFound
	}
	return &user, err
}

// GetByEmail retrieves a user by email (for login)
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	err := r.coll.FindOne(ctx, bson.M{"email": email, "active": true}).Decode(&user)
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, ErrUserNotFound
	}
	return &user, err
}

// GetByFamily retrieves all users belonging to a family
func (r *UserRepository) GetByFamily(ctx context.Context, familyID primitive.ObjectID) ([]models.User, error) {
	cursor, err := r.coll.Find(ctx, bson.M{"familyId": familyID, "active": true})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var users []models.User
	if err := cursor.All(ctx, &users); err != nil {
		return nil, err
	}
	return users, nil
}

// Update updates a user by ID
func (r *UserRepository) Update(ctx context.Context, id primitive.ObjectID, update bson.M) error {
	update["updatedAt"] = time.Now().UTC()
	result, err := r.coll.UpdateOne(ctx, bson.M{"_id": id}, bson.M{"$set": update})
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return ErrUserNotFound
	}
	return nil
}

// UpdateLastLogin updates the last login time for a user
func (r *UserRepository) UpdateLastLogin(ctx context.Context, id primitive.ObjectID) error {
	now := time.Now().UTC()
	return r.Update(ctx, id, bson.M{"lastLoginAt": now})
}

// UpdateGoogleID updates the Google ID for a user (for linking Google OAuth)
func (r *UserRepository) UpdateGoogleID(ctx context.Context, id primitive.ObjectID, googleID string) error {
	return r.Update(ctx, id, bson.M{"googleId": googleID})
}

// SoftDelete deactivates a user (soft delete)
func (r *UserRepository) SoftDelete(ctx context.Context, id primitive.ObjectID) error {
	return r.Update(ctx, id, bson.M{"active": false})
}
