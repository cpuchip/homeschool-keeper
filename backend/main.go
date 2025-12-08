package main

import (
	"context"
	"embed"
	"encoding/json"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/cpuchip/homeschool-keeper/backend/auth"
	"github.com/cpuchip/homeschool-keeper/backend/config"
	"github.com/cpuchip/homeschool-keeper/backend/db"
	"github.com/cpuchip/homeschool-keeper/backend/handlers"
	"github.com/cpuchip/homeschool-keeper/backend/repository"
	gorillaHandlers "github.com/gorilla/handlers"
	"github.com/gorilla/mux"
)

//go:embed frontend/dist
var embeddedFrontend embed.FS

//go:embed embedded
var embeddedFallback embed.FS

func main() {
	// Load configuration
	cfg := config.Load()

	// Validate required configuration
	if cfg.SessionSecret == "" {
		log.Fatal("SESSION_SECRET environment variable is required")
	}

	// Initialize session handling
	auth.InitSession(cfg.SessionSecret)

	// Connect to MongoDB
	mongoClient, err := db.Connect(cfg.MongoURI)
	if err != nil {
		log.Printf("Warning: MongoDB connection failed: %v", err)
		log.Printf("Running without database - some features will be unavailable")
	} else {
		defer func() {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			if err := mongoClient.Disconnect(ctx); err != nil {
				log.Printf("Error disconnecting from MongoDB: %v", err)
			}
		}()
		log.Printf("Connected to MongoDB")
	}

	// Get database
	database := db.GetDatabase(mongoClient, cfg.DBName)

	// Initialize repositories
	var repo *repository.Repository
	if database != nil {
		repo = repository.New(database)

		// Ensure indexes
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		if err := repo.EnsureIndexes(ctx); err != nil {
			log.Printf("Warning: Failed to create indexes: %v", err)
		}
		cancel()
	}

	// Create router
	r := mux.NewRouter()

	// API routes
	api := r.PathPrefix("/api").Subrouter()

	// Health check
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		status := map[string]any{
			"status":  "ok",
			"time":    time.Now().UTC().Format(time.RFC3339),
			"version": "1.0.0",
		}
		if mongoClient != nil {
			ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
			defer cancel()
			if err := mongoClient.Ping(ctx, nil); err != nil {
				status["database"] = "disconnected"
			} else {
				status["database"] = "connected"
			}
		} else {
			status["database"] = "not configured"
		}
		writeJSON(w, status)
	}).Methods("GET")

	// Only register API routes if database is available
	if repo != nil {
		// Initialize handlers
		authHandler := handlers.NewAuthHandler(repo.Users, repo.Families, repo.Subjects)
		studentHandler := handlers.NewStudentHandler(repo.Students, repo.Logs)
		subjectHandler := handlers.NewSubjectHandler(repo.Subjects)
		logHandler := handlers.NewLogHandler(repo.Logs, repo.Students, repo.Subjects, repo.Families)
		statsHandler := handlers.NewStatsHandler(repo.Logs, repo.Students, repo.Subjects, repo.Families)
		onboardingHandler := handlers.NewOnboardingHandler(repo.Families, repo.Subjects, repo.Students)

		// Auth routes (no authentication required)
		api.HandleFunc("/v1/auth/register", authHandler.Register).Methods("POST")
		api.HandleFunc("/v1/auth/login", authHandler.Login).Methods("POST")
		api.HandleFunc("/v1/auth/logout", authHandler.Logout).Methods("POST")
		api.HandleFunc("/v1/auth/me", auth.RequireAuthFunc(authHandler.Me)).Methods("GET")

		// Onboarding routes (authentication required)
		api.HandleFunc("/v1/onboarding/subjects", onboardingHandler.GetDefaultSubjects).Methods("GET")
		api.HandleFunc("/v1/onboarding/status", auth.RequireAuthFunc(onboardingHandler.GetStatus)).Methods("GET")
		api.HandleFunc("/v1/onboarding/complete", auth.RequireAuthFunc(onboardingHandler.Complete)).Methods("POST")

		// Student routes (authentication required)
		api.HandleFunc("/v1/students", auth.RequireAuthFunc(studentHandler.List)).Methods("GET")
		api.HandleFunc("/v1/students", auth.RequireAuthFunc(studentHandler.Create)).Methods("POST")
		api.HandleFunc("/v1/students/{id}", auth.RequireAuthFunc(studentHandler.Get)).Methods("GET")
		api.HandleFunc("/v1/students/{id}", auth.RequireAuthFunc(studentHandler.Update)).Methods("PATCH")
		api.HandleFunc("/v1/students/{id}", auth.RequireAuthFunc(studentHandler.Delete)).Methods("DELETE")

		// Subject routes (authentication required)
		api.HandleFunc("/v1/subjects", auth.RequireAuthFunc(subjectHandler.List)).Methods("GET")
		api.HandleFunc("/v1/subjects", auth.RequireAuthFunc(subjectHandler.Create)).Methods("POST")
		api.HandleFunc("/v1/subjects/{id}", auth.RequireAuthFunc(subjectHandler.Get)).Methods("GET")
		api.HandleFunc("/v1/subjects/{id}", auth.RequireAuthFunc(subjectHandler.Update)).Methods("PATCH")
		api.HandleFunc("/v1/subjects/{id}", auth.RequireAuthFunc(subjectHandler.Delete)).Methods("DELETE")

		// Log routes (authentication required)
		api.HandleFunc("/v1/logs", auth.RequireAuthFunc(logHandler.List)).Methods("GET")
		api.HandleFunc("/v1/logs", auth.RequireAuthFunc(logHandler.Create)).Methods("POST")
		api.HandleFunc("/v1/logs/{id}", auth.RequireAuthFunc(logHandler.Get)).Methods("GET")
		api.HandleFunc("/v1/logs/{id}", auth.RequireAuthFunc(logHandler.Update)).Methods("PATCH")
		api.HandleFunc("/v1/logs/{id}", auth.RequireAuthFunc(logHandler.Delete)).Methods("DELETE")

		// Stats routes (authentication required)
		api.HandleFunc("/v1/stats/student/{id}", auth.RequireAuthFunc(statsHandler.StudentStats)).Methods("GET")
		api.HandleFunc("/v1/stats/family", auth.RequireAuthFunc(statsHandler.FamilyStats)).Methods("GET")
	}

	// Serve SPA frontend
	r.PathPrefix("/").Handler(spaFileServer())

	// CORS middleware
	corsHandler := gorillaHandlers.CORS(
		gorillaHandlers.AllowedOrigins([]string{"*"}),
		gorillaHandlers.AllowedMethods([]string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}),
		gorillaHandlers.AllowedHeaders([]string{"Content-Type", "Authorization"}),
		gorillaHandlers.AllowCredentials(),
	)

	// Logging middleware
	loggedRouter := gorillaHandlers.LoggingHandler(os.Stdout, corsHandler(r))

	// Create server
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      loggedRouter,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Server listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

func spaFileServer() http.Handler {
	// Try on-disk frontend/dist first (for local dev)
	candidates := []string{
		"frontend/dist",
		"backend/frontend/dist",
	}
	for _, dir := range candidates {
		if stat, err := os.Stat(dir); err == nil && stat.IsDir() {
			log.Printf("Serving frontend from disk: %s", dir)
			return spaFromFS(os.DirFS(dir))
		}
	}

	// Try embedded frontend/dist
	if sub, err := fs.Sub(embeddedFrontend, "frontend/dist"); err == nil {
		if _, err := fs.Stat(sub, "index.html"); err == nil {
			log.Printf("Serving frontend from embedded assets")
			return spaFromFS(sub)
		}
	}

	// Fallback to minimal embedded page
	log.Printf("Serving fallback embedded page")
	sub, _ := fs.Sub(embeddedFallback, "embedded")
	return spaFromFS(sub)
}

func spaFromFS(fsys fs.FS) http.Handler {
	fileServer := http.FileServer(http.FS(fsys))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path
		if path == "/" {
			serveIndex(w, fsys)
			return
		}

		// Try to serve the file
		cleanPath := strings.TrimPrefix(path, "/")
		if f, err := fsys.Open(cleanPath); err == nil {
			f.Close()
			fileServer.ServeHTTP(w, r)
			return
		}

		// Fallback to index.html for SPA routes
		serveIndex(w, fsys)
	})
}

func serveIndex(w http.ResponseWriter, fsys fs.FS) {
	if b, err := fs.ReadFile(fsys, "index.html"); err == nil {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		w.Write(b)
		return
	}
	http.Error(w, "Not Found", http.StatusNotFound)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	enc.Encode(v)
}

func writeError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]any{
			"message": message,
		},
	})
}
