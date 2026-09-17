package service_test

import (
	"context"
	"errors"
	"testing"

	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

// fakeRoutesRepository is a minimal in-memory repository.RoutesRepository,
// standing in for a real call to Google.
type fakeRoutesRepository struct {
	result *repository.RouteResult
	err    error
}

func (f *fakeRoutesRepository) ComputeRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*repository.RouteResult, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.result, nil
}

func TestRoutesService_ComputeRoute(t *testing.T) {
	fake := &fakeRoutesRepository{
		result: &repository.RouteResult{DistanceMeters: 1967, DurationSeconds: 421, Polyline: "abc"},
	}
	svc := service.NewRoutesService(fake)

	result, err := svc.ComputeRoute(context.Background(), 12.9716, 77.5946, 12.9634, 77.5855)
	if err != nil {
		t.Fatalf("ComputeRoute returned error: %v", err)
	}
	if result.DistanceMeters != 1967 || result.DurationSeconds != 421 {
		t.Errorf("result = %+v, want distance 1967 and duration 421", result)
	}
}

func TestRoutesService_ComputeRoute_RepositoryError(t *testing.T) {
	svc := service.NewRoutesService(&fakeRoutesRepository{err: errors.New("boom")})

	_, err := svc.ComputeRoute(context.Background(), 12.9716, 77.5946, 12.9634, 77.5855)
	if got := appErrorCode(t, err); got != "internal" {
		t.Errorf("error code = %q, want %q", got, "internal")
	}
}
