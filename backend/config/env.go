package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// Config holds all configuration for the application
type Config struct {
	Port     string
	MongoURI string
	DBName   string
	DevMode  bool

	// Session settings (web auth)
	SessionSecret string

	// Encryption settings
	EncryptionMasterKey string

	// JWT settings (mobile auth)
	JWTSecret        string
	JWTAccessExpiry  string
	JWTRefreshExpiry string
}

// Load reads configuration from environment variables
func Load() *Config {
	// Load .env file if it exists (ignore error if not found)
	_ = godotenv.Load()
	_ = godotenv.Load("../.env") // Also try parent directory

	cfg := &Config{
		Port:                getEnv("PORT", "8080"),
		MongoURI:            getEnv("MONGODB_URI", ""),
		DBName:              getEnv("MONGO_DB", "hmslogs"),
		DevMode:             getEnv("DEV_MODE", "false") == "true",
		SessionSecret:       getEnv("SESSION_SECRET", ""),
		EncryptionMasterKey: getEnv("ENCRYPTION_MASTER_KEY", ""),
		JWTSecret:           getEnv("JWT_SECRET", ""),
		JWTAccessExpiry:     getEnv("JWT_ACCESS_EXPIRY", "15m"),
		JWTRefreshExpiry:    getEnv("JWT_REFRESH_EXPIRY", "168h"),
	}

	// Build MongoDB URI from parts if not provided directly
	if cfg.MongoURI == "" {
		cfg.MongoURI = buildMongoURI()
	}

	// Log loaded configuration (non-sensitive fields)
	fmt.Println("📋 Configuration loaded:")
	fmt.Printf("  PORT: %s\n", cfg.Port)
	fmt.Printf("  MONGO_DB: %s\n", cfg.DBName)
	fmt.Printf("  MONGODB_URI: %s\n", RedactMongoURI(cfg.MongoURI))
	fmt.Printf("  DEV_MODE: %t\n", cfg.DevMode)
	fmt.Printf("  JWT_ACCESS_EXPIRY: %s\n", cfg.JWTAccessExpiry)
	fmt.Printf("  JWT_REFRESH_EXPIRY: %s\n", cfg.JWTRefreshExpiry)
	fmt.Printf("  SESSION_SECRET: %s\n", maskSecret(cfg.SessionSecret))
	fmt.Printf("  ENCRYPTION_MASTER_KEY: %s\n", maskSecret(cfg.EncryptionMasterKey))
	fmt.Printf("  JWT_SECRET: %s\n", maskSecret(cfg.JWTSecret))

	return cfg
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func buildMongoURI() string {
	host := getEnv("MONGO_HOST", "localhost:27017")
	db := getEnv("MONGO_DB", "homeschool-keeper")
	user := getEnv("MONGO_USER", "")
	pass := getEnv("MONGO_PASSWORD", "")
	opts := getEnv("MONGO_OPTIONS", "")

	if user != "" && pass != "" {
		uri := "mongodb://" + user + ":" + pass + "@" + host + "/" + db
		if opts != "" {
			uri += "?" + opts
		}
		return uri
	}

	uri := "mongodb://" + host + "/" + db
	if opts != "" {
		uri += "?" + opts
	}
	return uri
}

// RedactMongoURI returns URI with password redacted for logging
func RedactMongoURI(uri string) string {
	// Simple redaction - find :// and @ and redact between
	start := -1
	for i := 0; i < len(uri)-2; i++ {
		if uri[i:i+3] == "://" {
			start = i + 3
			break
		}
	}
	if start == -1 {
		return uri
	}

	atPos := -1
	for i := start; i < len(uri); i++ {
		if uri[i] == '@' {
			atPos = i
			break
		}
	}
	if atPos == -1 {
		return uri
	}

	colonPos := -1
	for i := start; i < atPos; i++ {
		if uri[i] == ':' {
			colonPos = i
			break
		}
	}
	if colonPos == -1 {
		return uri
	}

	return uri[:colonPos+1] + "****" + uri[atPos:]
}

// maskSecret returns a masked version of a secret for logging
func maskSecret(secret string) string {
	if secret == "" {
		return "(not set)"
	}
	return "****"
}
