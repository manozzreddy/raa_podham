package dto

import "github.com/dynamicarraytech/raa-podham/backend/internal/repository"

type RouteResponse struct {
	DistanceMeters  int    `json:"distanceMeters"`
	DurationSeconds int    `json:"durationSeconds"`
	Polyline        string `json:"polyline"`
}

// FromRouteResult converts a repository.RouteResult into its API
// representation.
func FromRouteResult(result *repository.RouteResult) RouteResponse {
	return RouteResponse{
		DistanceMeters:  result.DistanceMeters,
		DurationSeconds: result.DurationSeconds,
		Polyline:        result.Polyline,
	}
}
