package testutil_test

import (
	"context"
	"testing"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TestMongoDBContainer verifies the testcontainer setup works
func TestMongoDBContainer(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Setup MongoDB container
	mongo := testutil.SetupMongoDB(t)

	// Verify we have a connection
	assert.NotNil(t, mongo.Client)
	assert.NotNil(t, mongo.Database)
	assert.NotEmpty(t, mongo.URI)

	// Test basic CRUD operations
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Create a test document
	type TestDoc struct {
		ID   primitive.ObjectID `bson:"_id,omitempty"`
		Name string             `bson:"name"`
	}

	coll := mongo.Collection("test_collection")

	// Insert
	doc := TestDoc{Name: "test"}
	result, err := coll.InsertOne(ctx, doc)
	require.NoError(t, err)
	assert.NotNil(t, result.InsertedID)

	// Read
	var found TestDoc
	err = coll.FindOne(ctx, bson.M{"name": "test"}).Decode(&found)
	require.NoError(t, err)
	assert.Equal(t, "test", found.Name)

	// Update
	_, err = coll.UpdateOne(ctx, bson.M{"name": "test"}, bson.M{"$set": bson.M{"name": "updated"}})
	require.NoError(t, err)

	// Verify update
	err = coll.FindOne(ctx, bson.M{"name": "updated"}).Decode(&found)
	require.NoError(t, err)
	assert.Equal(t, "updated", found.Name)

	// Delete
	_, err = coll.DeleteOne(ctx, bson.M{"name": "updated"})
	require.NoError(t, err)

	// Verify delete
	count, err := coll.CountDocuments(ctx, bson.M{})
	require.NoError(t, err)
	assert.Equal(t, int64(0), count)
}

// TestClearCollections verifies the cleanup helper
func TestClearCollections(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	mongo := testutil.SetupMongoDB(t)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Insert some data
	_, err := mongo.Collection("coll1").InsertOne(ctx, bson.M{"data": "test1"})
	require.NoError(t, err)
	_, err = mongo.Collection("coll2").InsertOne(ctx, bson.M{"data": "test2"})
	require.NoError(t, err)

	// Clear all collections
	mongo.ClearCollections(t)

	// Verify collections are empty
	count1, _ := mongo.Collection("coll1").CountDocuments(ctx, bson.M{})
	count2, _ := mongo.Collection("coll2").CountDocuments(ctx, bson.M{})
	assert.Equal(t, int64(0), count1)
	assert.Equal(t, int64(0), count2)
}
