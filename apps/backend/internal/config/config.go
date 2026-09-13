// Package config loads the app's runtime configuration from environment
// variables.
package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port               string
	FirebaseProjectID  string
	RTDBURL            string
	GooglePlacesAPIKey string
	Env                string
}

// Load reads Config from the environment, failing fast if a required
// value is missing in production.
func Load() (*Config, error) {
	// Populates os.Getenv for any key not already set in the real
	// environment — real env vars (as Cloud Run provides) always win.
	// There's deliberately no .env in production, so a missing file
	// here is expected, not an error.
	_ = godotenv.Load()

	cfg := &Config{
		Port:               getEnv("PORT", "8080"),
		FirebaseProjectID:  os.Getenv("FIREBASE_PROJECT_ID"),
		RTDBURL:            os.Getenv("RTDB_URL"),
		GooglePlacesAPIKey: os.Getenv("GOOGLE_PLACES_API_KEY"),
		Env:                getEnv("ENV", "development"),
	}

	if cfg.Env == "production" && cfg.FirebaseProjectID == "" {
		return nil, fmt.Errorf("FIREBASE_PROJECT_ID must be set in production")
	}
	if cfg.Env == "production" && cfg.GooglePlacesAPIKey == "" {
		return nil, fmt.Errorf("GOOGLE_PLACES_API_KEY must be set in production")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
