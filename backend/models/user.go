// Package models defines the data structures for the homeschool-keeper application.
package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// User represents a user account in the system
type User struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Email        string             `bson:"email" json:"email"`
	PasswordHash string             `bson:"passwordHash" json:"-"` // Never sent to client
	Name         string             `bson:"name" json:"name"`
	FamilyID     primitive.ObjectID `bson:"familyId" json:"familyId"`
	Role         string             `bson:"role" json:"role"` // admin, parent, student
	IsSuperAdmin bool               `bson:"isSuperAdmin" json:"isSuperAdmin"`
	Active       bool               `bson:"active" json:"active"`
	GoogleID     string             `bson:"googleId,omitempty" json:"-"` // Google user ID for OAuth
	LastLoginAt  *time.Time         `bson:"lastLoginAt,omitempty" json:"lastLoginAt,omitempty"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// User roles
const (
	RoleAdmin   = "admin"
	RoleParent  = "parent"
	RoleStudent = "student"
)

// UserResponse is the user data returned to clients (excludes sensitive fields)
type UserResponse struct {
	ID           primitive.ObjectID `json:"id"`
	Email        string             `json:"email"`
	Name         string             `json:"name"`
	FamilyID     primitive.ObjectID `json:"familyId"`
	Role         string             `json:"role"`
	IsSuperAdmin bool               `json:"isSuperAdmin"`
	LastLoginAt  *time.Time         `json:"lastLoginAt,omitempty"`
	CreatedAt    time.Time          `json:"createdAt"`
}

// ToResponse converts a User to a UserResponse (for API output)
func (u *User) ToResponse() UserResponse {
	return UserResponse{
		ID:           u.ID,
		Email:        u.Email,
		Name:         u.Name,
		FamilyID:     u.FamilyID,
		Role:         u.Role,
		IsSuperAdmin: u.IsSuperAdmin,
		LastLoginAt:  u.LastLoginAt,
		CreatedAt:    u.CreatedAt,
	}
}
