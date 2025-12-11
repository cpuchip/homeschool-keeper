// Package repository provides database operations for the homeschool-keeper application.
// All queries are scoped by familyId to ensure data isolation.
package repository

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
)

// Collections names
const (
	CollUsers     = "users"
	CollFamilies  = "families"
	CollOrgs      = "organizations"
	CollStudents  = "students"
	CollSubjects  = "subjects"
	CollLogs      = "log_entries"
	CollLocations = "locations"
)

// Repository provides access to all data repositories
type Repository struct {
	db        *mongo.Database
	Users     *UserRepository
	Families  *FamilyRepository
	Students  *StudentRepository
	Subjects  *SubjectRepository
	Logs      *LogRepository
	Locations *LocationRepository
}

// New creates a new Repository with all sub-repositories
func New(db *mongo.Database) *Repository {
	return &Repository{
		db:        db,
		Users:     NewUserRepository(db),
		Families:  NewFamilyRepository(db),
		Students:  NewStudentRepository(db),
		Subjects:  NewSubjectRepository(db),
		Logs:      NewLogRepository(db),
		Locations: NewLocationRepository(db),
	}
}

// DefaultTimeout returns a context with a default timeout for database operations
func DefaultTimeout(ctx context.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(ctx, 10*time.Second)
}

// EnsureIndexes creates all required indexes for the collections
func (r *Repository) EnsureIndexes(ctx context.Context) error {
	if err := r.Users.EnsureIndexes(ctx); err != nil {
		return err
	}
	if err := r.Families.EnsureIndexes(ctx); err != nil {
		return err
	}
	if err := r.Students.EnsureIndexes(ctx); err != nil {
		return err
	}
	if err := r.Subjects.EnsureIndexes(ctx); err != nil {
		return err
	}
	if err := r.Logs.EnsureIndexes(ctx); err != nil {
		return err
	}
	if err := r.Locations.EnsureIndexes(ctx); err != nil {
		return err
	}
	return nil
}
