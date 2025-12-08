package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Organization represents a co-op or group of families.
// Phase 1A: Not used, but schema ready for Phase 1B.
type Organization struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name        string             `bson:"name" json:"name"`
	Description string             `bson:"description" json:"description"`
	CreatedBy   primitive.ObjectID `bson:"createdBy" json:"createdBy"`
	Active      bool               `bson:"active" json:"active"`
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time          `bson:"updatedAt" json:"updatedAt"`
}
