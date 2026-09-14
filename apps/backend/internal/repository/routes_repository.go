package repository

import "context"

// RouteResult is one computed route between two points.
type RouteResult struct {
	DistanceMeters  int
	DurationSeconds int
	// Polyline is the route's path in Google's standard encoded-polyline
	// format — the client decodes it, this layer never does.
	Polyline string
}

// RoutesRepository computes a route between two points. The only
// implementation is Google's Routes API (google_routes_repository.go),
// but this stays an interface for the same reason PlacesRepository does:
// the service layer is testable against a hand-written fake instead of a
// real network call.
type RoutesRepository interface {
	ComputeRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*RouteResult, error)
}
