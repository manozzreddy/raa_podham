package repository_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

func TestGooglePlacesRepository_Autocomplete(t *testing.T) {
	var gotPath, gotAPIKey string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		gotAPIKey = r.Header.Get("X-Goog-Api-Key")

		_, _ = w.Write([]byte(`{
			"suggestions": [
				{
					"placePrediction": {
						"placeId": "place-1",
						"text": {"text": "Cubbon Park, Kasturba Road, Bengaluru, Karnataka, India"},
						"structuredFormat": {
							"mainText": {"text": "Cubbon Park"},
							"secondaryText": {"text": "Kasturba Road, Bengaluru, Karnataka, India"}
						}
					}
				}
			]
		}`))
	}))
	defer server.Close()

	repo := repository.NewGooglePlacesRepository("test-key", server.URL)

	predictions, err := repo.Autocomplete(context.Background(), "cubbon park", nil, nil)
	if err != nil {
		t.Fatalf("Autocomplete returned error: %v", err)
	}
	if gotPath != "/v1/places:autocomplete" {
		t.Errorf("request path = %q, want %q", gotPath, "/v1/places:autocomplete")
	}
	if gotAPIKey != "test-key" {
		t.Errorf("X-Goog-Api-Key = %q, want %q", gotAPIKey, "test-key")
	}
	if len(predictions) != 1 {
		t.Fatalf("len(predictions) = %d, want 1", len(predictions))
	}
	if predictions[0].PlaceID != "place-1" {
		t.Errorf("PlaceID = %q, want %q", predictions[0].PlaceID, "place-1")
	}
	if predictions[0].DisplayName != "Cubbon Park" {
		t.Errorf("DisplayName = %q, want %q", predictions[0].DisplayName, "Cubbon Park")
	}
	if predictions[0].SecondaryText != "Kasturba Road, Bengaluru, Karnataka, India" {
		t.Errorf("SecondaryText = %q, want %q", predictions[0].SecondaryText, "Kasturba Road, Bengaluru, Karnataka, India")
	}
}

func TestGooglePlacesRepository_Autocomplete_WithOrigin(t *testing.T) {
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewDecoder(r.Body).Decode(&gotBody)
		_, _ = w.Write([]byte(`{
			"suggestions": [
				{
					"placePrediction": {
						"placeId": "place-1",
						"text": {"text": "Cubbon Park, Kasturba Road, Bengaluru, Karnataka, India"},
						"structuredFormat": {
							"mainText": {"text": "Cubbon Park"},
							"secondaryText": {"text": "Kasturba Road, Bengaluru, Karnataka, India"}
						},
						"distanceMeters": 2345
					}
				}
			]
		}`))
	}))
	defer server.Close()

	repo := repository.NewGooglePlacesRepository("test-key", server.URL)
	originLat, originLng := 12.97, 77.59

	predictions, err := repo.Autocomplete(context.Background(), "cubbon park", &originLat, &originLng)
	if err != nil {
		t.Fatalf("Autocomplete returned error: %v", err)
	}

	origin, ok := gotBody["origin"].(map[string]any)
	if !ok {
		t.Fatalf("request body had no origin field: %+v", gotBody)
	}
	if origin["latitude"] != originLat || origin["longitude"] != originLng {
		t.Errorf("origin = %+v, want {latitude:%v longitude:%v}", origin, originLat, originLng)
	}

	if predictions[0].DistanceMeters == nil || *predictions[0].DistanceMeters != 2345 {
		t.Errorf("DistanceMeters = %v, want 2345", predictions[0].DistanceMeters)
	}
}

func TestGooglePlacesRepository_Autocomplete_FallsBackWithoutStructuredFormat(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{
			"suggestions": [
				{"placePrediction": {"placeId": "place-2", "text": {"text": "Bengaluru"}}}
			]
		}`))
	}))
	defer server.Close()

	repo := repository.NewGooglePlacesRepository("test-key", server.URL)

	predictions, err := repo.Autocomplete(context.Background(), "bengaluru", nil, nil)
	if err != nil {
		t.Fatalf("Autocomplete returned error: %v", err)
	}
	if predictions[0].DisplayName != "Bengaluru" {
		t.Errorf("DisplayName = %q, want %q", predictions[0].DisplayName, "Bengaluru")
	}
	if predictions[0].SecondaryText != "" {
		t.Errorf("SecondaryText = %q, want empty", predictions[0].SecondaryText)
	}
}

func TestGooglePlacesRepository_Autocomplete_UnexpectedStatus(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusForbidden)
	}))
	defer server.Close()

	repo := repository.NewGooglePlacesRepository("test-key", server.URL)

	if _, err := repo.Autocomplete(context.Background(), "cubbon park", nil, nil); err == nil {
		t.Fatal("expected an error for a non-200 response, got nil")
	}
}

func TestGooglePlacesRepository_ResolveLocation(t *testing.T) {
	var gotPath, gotFieldMask string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		gotFieldMask = r.Header.Get("X-Goog-FieldMask")

		_ = json.NewEncoder(w).Encode(map[string]any{
			"location": map[string]float64{"latitude": 12.9716, "longitude": 77.5946},
		})
	}))
	defer server.Close()

	repo := repository.NewGooglePlacesRepository("test-key", server.URL)

	lat, lng, err := repo.ResolveLocation(context.Background(), "place-1")
	if err != nil {
		t.Fatalf("ResolveLocation returned error: %v", err)
	}
	if gotPath != "/v1/places/place-1" {
		t.Errorf("request path = %q, want %q", gotPath, "/v1/places/place-1")
	}
	if gotFieldMask != "location" {
		t.Errorf("X-Goog-FieldMask = %q, want %q", gotFieldMask, "location")
	}
	if lat != 12.9716 || lng != 77.5946 {
		t.Errorf("lat,lng = %v,%v, want 12.9716,77.5946", lat, lng)
	}
}
