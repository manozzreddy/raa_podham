package repository

import "context"

// PlacePrediction is one Autocomplete (New) candidate — not yet resolved
// to coordinates, since that endpoint doesn't return them.
type PlacePrediction struct {
	PlaceID       string
	DisplayName   string
	SecondaryText string
	// DistanceMeters is nil unless Autocomplete was given an origin —
	// Google only computes this when one's supplied.
	DistanceMeters *int
}

// PlacesRepository looks up destination candidates and resolves one to
// coordinates. The only implementation is Google's Places API (New)
// (google_places_repository.go), but this stays an interface for the
// same reason RideRepository does: the service layer is testable
// against a hand-written fake instead of a real network call.
type PlacesRepository interface {
	// originLat/originLng are both nil for a plain, distance-free search.
	Autocomplete(ctx context.Context, input string, originLat, originLng *float64) ([]PlacePrediction, error)
	ResolveLocation(ctx context.Context, placeID string) (lat, lng float64, err error)
}
