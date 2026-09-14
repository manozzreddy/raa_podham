package service

import (
	"context"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

type RoutesService struct {
	routes repository.RoutesRepository
}

func NewRoutesService(routes repository.RoutesRepository) *RoutesService {
	return &RoutesService{routes: routes}
}

func (s *RoutesService) ComputeRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*repository.RouteResult, error) {
	result, err := s.routes.ComputeRoute(ctx, originLat, originLng, destLat, destLng)
	if err != nil {
		return nil, apperror.Internal(err)
	}
	return result, nil
}
