package db

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Connect establishes a connection to MongoDB
func Connect(uri string) (*mongo.Client, error) {
	if uri == "" {
		return nil, nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	clientOptions := options.Client().ApplyURI(uri)
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, err
	}

	// Ping to verify connection
	if err := client.Ping(ctx, nil); err != nil {
		return nil, err
	}

	return client, nil
}

// GetDatabase returns the database instance
func GetDatabase(client *mongo.Client, name string) *mongo.Database {
	if client == nil {
		return nil
	}
	return client.Database(name)
}

// Collections
const (
	CollectionUsers         = "users"
	CollectionOrganizations = "organizations"
	CollectionStudents      = "students"
	CollectionSubjects      = "subjects"
	CollectionLogEntries    = "log_entries"
	CollectionAttachments   = "attachments"
	CollectionRefreshTokens = "refresh_tokens"
)
