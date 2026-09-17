// Package firebaseapp initializes the Firebase Admin SDK and exposes its
// clients (Auth, Firestore, Realtime Database) via small constructors.
package firebaseapp

import (
	"context"
	"fmt"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/db"
	fbstorage "firebase.google.com/go/v4/storage"

	"github.com/dynamicarraytech/raa-podham/backend/internal/config"
)

// New initializes the Firebase Admin SDK app. No explicit credentials are
// passed — it relies on Application Default Credentials, so the same
// code runs unchanged on Cloud Run and locally after `gcloud auth
// application-default login`.
func New(ctx context.Context, cfg *config.Config) (*firebase.App, error) {
	app, err := firebase.NewApp(ctx, &firebase.Config{
		ProjectID:     cfg.FirebaseProjectID,
		DatabaseURL:   cfg.RTDBURL,
		StorageBucket: cfg.StorageBucket,
	})
	if err != nil {
		return nil, fmt.Errorf("initializing firebase app: %w", err)
	}
	return app, nil
}

// NewAuthClient returns a Firebase Auth client for verifying ID tokens.
func NewAuthClient(ctx context.Context, app *firebase.App) (*auth.Client, error) {
	client, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("initializing auth client: %w", err)
	}
	return client, nil
}

// NewFirestoreClient returns a Firestore client.
func NewFirestoreClient(ctx context.Context, app *firebase.App) (*firestore.Client, error) {
	client, err := app.Firestore(ctx)
	if err != nil {
		return nil, fmt.Errorf("initializing firestore client: %w", err)
	}
	return client, nil
}

// NewRTDBClient returns a Realtime Database client, rooted at the
// project's default database URL.
func NewRTDBClient(ctx context.Context, app *firebase.App) (*db.Client, error) {
	client, err := app.Database(ctx)
	if err != nil {
		return nil, fmt.Errorf("initializing rtdb client: %w", err)
	}
	return client, nil
}

// NewStorageClient returns a Firebase Storage client, scoped to the
// project's default bucket.
func NewStorageClient(ctx context.Context, app *firebase.App) (*fbstorage.Client, error) {
	client, err := app.Storage(ctx)
	if err != nil {
		return nil, fmt.Errorf("initializing storage client: %w", err)
	}
	return client, nil
}
