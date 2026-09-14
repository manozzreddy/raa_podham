// Command api runs the Raa Podham backend's HTTP API.
//
// This file is the only place in the codebase allowed to reference
// concrete repository types (FirestoreRideRepository,
// RTDBPresenceRepository, FirestoreProfileRepository,
// GooglePlacesRepository) — everywhere else depends only on the
// repository package's interfaces.
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/db"

	"github.com/dynamicarraytech/raa-podham/backend/internal/config"
	"github.com/dynamicarraytech/raa-podham/backend/internal/firebaseapp"
	"github.com/dynamicarraytech/raa-podham/backend/internal/handler"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
	"github.com/dynamicarraytech/raa-podham/backend/internal/server"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

// step logs how long a startup step took — so a hang (e.g. a blocked
// network call to Google's metadata/token endpoints) shows up as "starting
// X" with no matching "X ready" line, instead of the process just going
// silent.
func step(name string, fn func() error) error {
	slog.Info("starting: " + name)
	start := time.Now()
	if err := fn(); err != nil {
		slog.Error("failed: "+name, "error", err, "elapsed", time.Since(start))
		return err
	}
	slog.Info(name+" ready", "elapsed", time.Since(start))
	return nil
}

func main() {
	if err := run(); err != nil {
		slog.Error("fatal error", "error", err)
		os.Exit(1)
	}
}

func run() error {
	ctx := context.Background()

	cfg, err := config.Load()
	if err != nil {
		return err
	}
	slog.Info("config loaded", "env", cfg.Env, "host", cfg.Host, "port", cfg.Port, "firebaseProjectId", cfg.FirebaseProjectID, "rtdbUrl", cfg.RTDBURL)

	var app *firebase.App
	if err := step("firebase app", func() error {
		var err error
		app, err = firebaseapp.New(ctx, cfg)
		return err
	}); err != nil {
		return err
	}

	var authClient *auth.Client
	if err := step("auth client", func() error {
		var err error
		authClient, err = firebaseapp.NewAuthClient(ctx, app)
		return err
	}); err != nil {
		return err
	}

	var firestoreClient *firestore.Client
	if err := step("firestore client", func() error {
		var err error
		firestoreClient, err = firebaseapp.NewFirestoreClient(ctx, app)
		return err
	}); err != nil {
		return err
	}
	defer firestoreClient.Close()

	var rtdbClient *db.Client
	if err := step("rtdb client", func() error {
		var err error
		rtdbClient, err = firebaseapp.NewRTDBClient(ctx, app)
		return err
	}); err != nil {
		return err
	}

	rideRepo := repository.NewFirestoreRideRepository(firestoreClient)
	presenceRepo := repository.NewRTDBPresenceRepository(rtdbClient)
	profileRepo := repository.NewFirestoreProfileRepository(firestoreClient)
	placesRepo := repository.NewGooglePlacesRepository(cfg.GooglePlacesAPIKey, repository.GooglePlacesBaseURL)
	// Same key as Places — both were enabled on it together (see
	// .env.example); it's just named for the first of the two.
	routesRepo := repository.NewGoogleRoutesRepository(cfg.GooglePlacesAPIKey, repository.GoogleRoutesBaseURL)

	rideService := service.NewRideService(rideRepo, presenceRepo, profileRepo)
	userService := service.NewUserService(rideRepo)
	placesService := service.NewPlacesService(placesRepo)
	routesService := service.NewRoutesService(routesRepo)

	handlers := server.Handlers{
		Ride:   handler.NewRideHandler(rideService),
		User:   handler.NewUserHandler(userService),
		Places: handler.NewPlacesHandler(placesService),
		Routes: handler.NewRoutesHandler(routesService),
	}

	router := server.NewRouter(handlers, authClient)

	// The mobile app's home screen (RidesViewModel -> RideRepository.myRides)
	// gates the entire landing screen on this endpoint, so it's the first
	// thing worth seeing in the log when the API comes up locally.
	slog.Info("home page API", "url", fmt.Sprintf("http://localhost:%s/users/me/rides", cfg.Port))

	srv := server.New(cfg.Host+":"+cfg.Port, router)

	return srv.Run()
}
