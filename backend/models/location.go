package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Location represents a saved location for quick selection during log entry
type Location struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	FamilyID  primitive.ObjectID `bson:"familyId" json:"familyId"`
	Type      string             `bson:"type" json:"type"` // field_trip, co_op, other (not home or online)
	Name      string             `bson:"name" json:"name"` // "Science Museum"
	Address   string             `bson:"address,omitempty" json:"address,omitempty"`
	Active    bool               `bson:"active" json:"active"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// NewLocation creates a new Location with default values
func NewLocation(familyID primitive.ObjectID, locationType string, name string) *Location {
	now := time.Now().UTC()
	return &Location{
		ID:        primitive.NewObjectID(),
		FamilyID:  familyID,
		Type:      locationType,
		Name:      name,
		Active:    true,
		CreatedAt: now,
		UpdatedAt: now,
	}
}
