// Package testutil provides testing utilities for the homeschool-keeper backend.
package testutil

import (
	"context"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TestContext returns a context with a timeout for tests
func TestContext(t *testing.T) context.Context {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	t.Cleanup(cancel)
	return ctx
}

// MustObjectID creates an ObjectID from a hex string, panics on error (for tests only)
func MustObjectID(hex string) primitive.ObjectID {
	id, err := primitive.ObjectIDFromHex(hex)
	if err != nil {
		panic("invalid ObjectID hex: " + hex)
	}
	return id
}

// NewObjectID generates a new ObjectID
func NewObjectID() primitive.ObjectID {
	return primitive.NewObjectID()
}

// TimePtr returns a pointer to a time.Time value
func TimePtr(t time.Time) *time.Time {
	return &t
}

// Float64Ptr returns a pointer to a float64 value
func Float64Ptr(f float64) *float64 {
	return &f
}

// StringPtr returns a pointer to a string value
func StringPtr(s string) *string {
	return &s
}
