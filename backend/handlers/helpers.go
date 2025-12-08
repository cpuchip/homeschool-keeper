// Package handlers provides HTTP handlers for the API endpoints.
package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Response helpers

// JSON writes a JSON response with the given status code
func JSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if data != nil {
		json.NewEncoder(w).Encode(data)
	}
}

// Error writes an error response
func Error(w http.ResponseWriter, status int, message string) {
	JSON(w, status, map[string]string{"error": message})
}

// BadRequest writes a 400 error response
func BadRequest(w http.ResponseWriter, message string) {
	Error(w, http.StatusBadRequest, message)
}

// Unauthorized writes a 401 error response
func Unauthorized(w http.ResponseWriter) {
	Error(w, http.StatusUnauthorized, "Unauthorized")
}

// Forbidden writes a 403 error response
func Forbidden(w http.ResponseWriter) {
	Error(w, http.StatusForbidden, "Forbidden")
}

// NotFound writes a 404 error response
func NotFound(w http.ResponseWriter, message string) {
	Error(w, http.StatusNotFound, message)
}

// InternalError writes a 500 error response
func InternalError(w http.ResponseWriter) {
	Error(w, http.StatusInternalServerError, "Internal server error")
}

// Created writes a 201 response with the created resource
func Created(w http.ResponseWriter, data interface{}) {
	JSON(w, http.StatusCreated, data)
}

// NoContent writes a 204 response
func NoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}

// Request parsing helpers

// ParseID extracts an ObjectID from the URL path
func ParseID(r *http.Request, param string) (primitive.ObjectID, error) {
	vars := mux.Vars(r)
	return primitive.ObjectIDFromHex(vars[param])
}

// DecodeJSON decodes JSON from the request body
func DecodeJSON(r *http.Request, v interface{}) error {
	return json.NewDecoder(r.Body).Decode(v)
}

// Pagination helper
type Pagination struct {
	Limit  int64
	Offset int64
}

// GetPagination extracts pagination from query params
func GetPagination(r *http.Request) Pagination {
	limit := int64(50) // default
	offset := int64(0)

	// Parse limit
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := parseInt64(l); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	// Parse offset
	if o := r.URL.Query().Get("offset"); o != "" {
		if parsed, err := parseInt64(o); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	return Pagination{Limit: limit, Offset: offset}
}

func parseInt64(s string) (int64, error) {
	var v int64
	err := json.Unmarshal([]byte(s), &v)
	return v, err
}
