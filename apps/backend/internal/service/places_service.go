package service

import (
	"context"
	"strings"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

type PlacesService struct {
	places repository.PlacesRepository
}

func NewPlacesService(places repository.PlacesRepository) *PlacesService {
	return &PlacesService{places: places}
}

func (s *PlacesService) Autocomplete(ctx context.Context, input string, originLat, originLng *float64) ([]repository.PlacePrediction, error) {
	trimmed := strings.TrimSpace(input)
	if trimmed == "" {
		return nil, apperror.BadRequest("input is required")
	}

	predictions, err := s.places.Autocomplete(ctx, trimmed, originLat, originLng)
	if err != nil {
		return nil, apperror.Internal(err)
	}
	return predictions, nil
}

func (s *PlacesService) ResolveLocation(ctx context.Context, placeID string) (lat, lng float64, err error) {
	if strings.TrimSpace(placeID) == "" {
		return 0, 0, apperror.BadRequest("placeId is required")
	}

	lat, lng, err = s.places.ResolveLocation(ctx, placeID)
	if err != nil {
		return 0, 0, apperror.Internal(err)
	}
	return lat, lng, nil
}
