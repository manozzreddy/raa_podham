package service_test

import (
	"context"
	"errors"
	"testing"

	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

// fakePlacesRepository is a minimal in-memory repository.PlacesRepository,
// standing in for a real call to Google.
type fakePlacesRepository struct {
	predictions []repository.PlacePrediction
	lat, lng    float64
	err         error
}

func (f *fakePlacesRepository) Autocomplete(ctx context.Context, input string) ([]repository.PlacePrediction, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.predictions, nil
}

func (f *fakePlacesRepository) ResolveLocation(ctx context.Context, placeID string) (float64, float64, error) {
	if f.err != nil {
		return 0, 0, f.err
	}
	return f.lat, f.lng, nil
}

func TestPlacesService_Autocomplete(t *testing.T) {
	fake := &fakePlacesRepository{
		predictions: []repository.PlacePrediction{
			{PlaceID: "place-1", DisplayName: "Cubbon Park", SecondaryText: "Bengaluru, India"},
		},
	}
	svc := service.NewPlacesService(fake)

	predictions, err := svc.Autocomplete(context.Background(), "cubbon park")
	if err != nil {
		t.Fatalf("Autocomplete returned error: %v", err)
	}
	if len(predictions) != 1 || predictions[0].PlaceID != "place-1" {
		t.Errorf("predictions = %+v, want a single place-1 prediction", predictions)
	}
}

func TestPlacesService_Autocomplete_EmptyInput(t *testing.T) {
	svc := service.NewPlacesService(&fakePlacesRepository{})

	_, err := svc.Autocomplete(context.Background(), "   ")
	if got := appErrorCode(t, err); got != "bad_request" {
		t.Errorf("error code = %q, want %q", got, "bad_request")
	}
}

func TestPlacesService_Autocomplete_RepositoryError(t *testing.T) {
	svc := service.NewPlacesService(&fakePlacesRepository{err: errors.New("boom")})

	_, err := svc.Autocomplete(context.Background(), "cubbon park")
	if got := appErrorCode(t, err); got != "internal" {
		t.Errorf("error code = %q, want %q", got, "internal")
	}
}

func TestPlacesService_ResolveLocation(t *testing.T) {
	svc := service.NewPlacesService(&fakePlacesRepository{lat: 12.9716, lng: 77.5946})

	lat, lng, err := svc.ResolveLocation(context.Background(), "place-1")
	if err != nil {
		t.Fatalf("ResolveLocation returned error: %v", err)
	}
	if lat != 12.9716 || lng != 77.5946 {
		t.Errorf("lat,lng = %v,%v, want 12.9716,77.5946", lat, lng)
	}
}

func TestPlacesService_ResolveLocation_EmptyPlaceID(t *testing.T) {
	svc := service.NewPlacesService(&fakePlacesRepository{})

	_, _, err := svc.ResolveLocation(context.Background(), "")
	if got := appErrorCode(t, err); got != "bad_request" {
		t.Errorf("error code = %q, want %q", got, "bad_request")
	}
}
