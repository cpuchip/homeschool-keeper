package testutil

import (
	"context"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/mongodb"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// MongoContainer holds a running MongoDB testcontainer
type MongoContainer struct {
	Container testcontainers.Container
	URI       string
	Client    *mongo.Client
	Database  *mongo.Database
}

// SetupMongoDB creates a new MongoDB container for testing.
// The container is automatically cleaned up when the test completes.
// This works in both local development and GitHub Actions CI.
func SetupMongoDB(t *testing.T) *MongoContainer {
	t.Helper()

	ctx := context.Background()

	// Start MongoDB container
	mongoContainer, err := mongodb.Run(ctx, "mongo:8")
	if err != nil {
		t.Fatalf("Failed to start MongoDB container: %v", err)
	}

	// Get connection string
	uri, err := mongoContainer.ConnectionString(ctx)
	if err != nil {
		t.Fatalf("Failed to get MongoDB connection string: %v", err)
	}

	// Connect to MongoDB
	clientOpts := options.Client().ApplyURI(uri)
	client, err := mongo.Connect(ctx, clientOpts)
	if err != nil {
		t.Fatalf("Failed to connect to MongoDB: %v", err)
	}

	// Ping to verify connection
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := client.Ping(pingCtx, nil); err != nil {
		t.Fatalf("Failed to ping MongoDB: %v", err)
	}

	// Create test database
	dbName := "hmslogs_test"
	database := client.Database(dbName)

	mc := &MongoContainer{
		Container: mongoContainer,
		URI:       uri,
		Client:    client,
		Database:  database,
	}

	// Register cleanup
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cleanupCancel()

		if err := client.Disconnect(cleanupCtx); err != nil {
			t.Logf("Warning: Failed to disconnect MongoDB client: %v", err)
		}

		if err := mongoContainer.Terminate(cleanupCtx); err != nil {
			t.Logf("Warning: Failed to terminate MongoDB container: %v", err)
		}
	})

	return mc
}

// ClearCollections drops all collections in the test database.
// Useful for resetting state between tests.
func (mc *MongoContainer) ClearCollections(t *testing.T) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	collections, err := mc.Database.ListCollectionNames(ctx, map[string]any{})
	if err != nil {
		t.Fatalf("Failed to list collections: %v", err)
	}

	for _, coll := range collections {
		if err := mc.Database.Collection(coll).Drop(ctx); err != nil {
			t.Fatalf("Failed to drop collection %s: %v", coll, err)
		}
	}
}

// Collection returns a collection from the test database
func (mc *MongoContainer) Collection(name string) *mongo.Collection {
	return mc.Database.Collection(name)
}
