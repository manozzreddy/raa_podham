package repository_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

func TestGoogleRoutesRepository_ComputeRoute(t *testing.T) {
	var gotPath, gotAPIKey, gotFieldMask string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		gotAPIKey = r.Header.Get("X-Goog-Api-Key")
		gotFieldMask = r.Header.Get("X-Goog-FieldMask")

		_, _ = w.Write([]byte(`{
			"routes": [
				{
					"distanceMeters": 1967,
					"duration": "421s",
					"polyline": {"encodedPolyline": "_p~iF~ps|Uez"}
				}
			]
		}`))
	}))
	defer server.Close()

	repo := repository.NewGoogleRoutesRepository("test-key", server.URL)

	result, err := repo.ComputeRoute(context.Background(), 12.9716, 77.5946, 12.9634, 77.5855)
	if err != nil {
		t.Fatalf("ComputeRoute returned error: %v", err)
	}
	if gotPath != "/directions/v2:computeRoutes" {
		t.Errorf("request path = %q, want %q", gotPath, "/directions/v2:computeRoutes")
	}
	if gotAPIKey != "test-key" {
		t.Errorf("X-Goog-Api-Key = %q, want %q", gotAPIKey, "test-key")
	}
	if gotFieldMask == "" {
		t.Errorf("X-Goog-FieldMask was empty, want a field mask")
	}
	if result.DistanceMeters != 1967 {
		t.Errorf("DistanceMeters = %d, want 1967", result.DistanceMeters)
	}
	if result.DurationSeconds != 421 {
		t.Errorf("DurationSeconds = %d, want 421", result.DurationSeconds)
	}
	if result.Polyline != "_p~iF~ps|Uez" {
		t.Errorf("Polyline = %q, want the encoded polyline from the response", result.Polyline)
	}
}

func TestGoogleRoutesRepository_ComputeRoute_NoRouteFound(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"routes": []}`))
	}))
	defer server.Close()

	repo := repository.NewGoogleRoutesRepository("test-key", server.URL)

	if _, err := repo.ComputeRoute(context.Background(), 12.9716, 77.5946, 12.9634, 77.5855); err == nil {
		t.Fatal("expected an error when no route is returned, got nil")
	}
}

func TestGoogleRoutesRepository_ComputeRoute_UnexpectedStatus(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusForbidden)
	}))
	defer server.Close()

	repo := repository.NewGoogleRoutesRepository("test-key", server.URL)

	if _, err := repo.ComputeRoute(context.Background(), 12.9716, 77.5946, 12.9634, 77.5855); err == nil {
		t.Fatal("expected an error for a non-200 response, got nil")
	}
}
