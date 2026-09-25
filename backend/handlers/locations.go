package handlers

import (
	"net/http"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/models"
	"github.com/cpuchip/homeschool-keeper/backend/repository"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// LocationHandler handles HTTP requests for locations
type LocationHandler struct {
	repo *repository.LocationRepository
}

// NewLocationHandler creates a new location handler
func NewLocationHandler(repo *repository.LocationRepository) *LocationHandler {
	return &LocationHandler{repo: repo}
}

// List returns all locations for the user's family
func (h *LocationHandler) List(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	// Check for "since" query param for incremental sync
	sinceStr := r.URL.Query().Get("since")
	var locations []models.Location

	if sinceStr != "" {
		since, parseErr := time.Parse(time.RFC3339, sinceStr)
		if parseErr != nil {
			BadRequest(w, "Invalid 'since' timestamp format")
			return
		}
		locations, err = h.repo.GetByFamilySince(r.Context(), familyID, since)
	} else {
		locations, err = h.repo.GetByFamily(r.Context(), familyID)
	}

	if err != nil {
		InternalError(w)
		return
	}

	// Return empty array instead of null
	if locations == nil {
		locations = []models.Location{}
	}

	JSON(w, http.StatusOK, map[string]interface{}{
		"locations": locations,
	})
}

// Get returns a single location by ID
func (h *LocationHandler) Get(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	id, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid location ID")
		return
	}

	location, err := h.repo.GetByID(r.Context(), familyID, id)
	if err != nil {
		NotFound(w, "Location not found")
		return
	}

	JSON(w, http.StatusOK, location)
}

// CreateLocationRequest represents the request body for creating a location
type CreateLocationRequest struct {
	Type    string `json:"type"`
	Name    string `json:"name"`
	Address string `json:"address,omitempty"`
}

// Create creates a new location
func (h *LocationHandler) Create(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	var req CreateLocationRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Validate required fields
	if req.Name == "" {
		BadRequest(w, "Name is required")
		return
	}
	if req.Type == "" {
		BadRequest(w, "Type is required")
		return
	}

	// Validate type
	validTypes := map[string]bool{
		"field_trip": true,
		"co_op":      true,
		"other":      true,
	}
	if !validTypes[req.Type] {
		BadRequest(w, "Invalid location type. Must be: field_trip, co_op, or other")
		return
	}

	location := models.NewLocation(familyID, req.Type, req.Name)
	location.Address = req.Address

	if err := h.repo.Create(r.Context(), location); err != nil {
		InternalError(w)
		return
	}

	Created(w, location)
}

// UpdateLocationRequest represents the request body for updating a location
type UpdateLocationRequest struct {
	Type    *string `json:"type,omitempty"`
	Name    *string `json:"name,omitempty"`
	Address *string `json:"address,omitempty"`
}

// Update updates an existing location
func (h *LocationHandler) Update(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	id, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid location ID")
		return
	}

	var req UpdateLocationRequest
	if err := DecodeJSON(r, &req); err != nil {
		BadRequest(w, "Invalid request body")
		return
	}

	// Build update document
	update := primitive.M{}
	if req.Name != nil {
		if *req.Name == "" {
			BadRequest(w, "Name cannot be empty")
			return
		}
		update["name"] = *req.Name
	}
	if req.Type != nil {
		validTypes := map[string]bool{
			"field_trip": true,
			"co_op":      true,
			"other":      true,
		}
		if !validTypes[*req.Type] {
			BadRequest(w, "Invalid location type")
			return
		}
		update["type"] = *req.Type
	}
	if req.Address != nil {
		update["address"] = *req.Address
	}

	if len(update) == 0 {
		BadRequest(w, "No fields to update")
		return
	}

	if err := h.repo.Update(r.Context(), familyID, id, update); err != nil {
		InternalError(w)
		return
	}

	// Get updated location
	location, err := h.repo.GetByID(r.Context(), familyID, id)
	if err != nil {
		InternalError(w)
		return
	}

	JSON(w, http.StatusOK, location)
}

// Delete soft-deletes a location
func (h *LocationHandler) Delete(w http.ResponseWriter, r *http.Request) {
	session := auth.GetUserFromContext(r.Context())
	if session == nil {
		Unauthorized(w)
		return
	}

	familyID, err := auth.FamilyIDToObjectID(session)
	if err != nil {
		Unauthorized(w)
		return
	}

	id, err := ParseID(r, "id")
	if err != nil {
		BadRequest(w, "Invalid location ID")
		return
	}

	if err := h.repo.Delete(r.Context(), familyID, id); err != nil {
		InternalError(w)
		return
	}

	NoContent(w)
}
