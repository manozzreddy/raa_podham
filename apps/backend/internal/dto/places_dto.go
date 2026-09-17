package dto

import "github.com/dynamicarraytech/raa-podham/backend/internal/repository"

type PlacePredictionResponse struct {
	PlaceID        string `json:"placeId"`
	DisplayName    string `json:"displayName"`
	SecondaryText  string `json:"secondaryText"`
	DistanceMeters *int   `json:"distanceMeters,omitempty"`
}

type AutocompleteResponse struct {
	Predictions []PlacePredictionResponse `json:"predictions"`
}

// FromPlacePredictions converts repository.PlacePrediction values into
// their API representation.
func FromPlacePredictions(predictions []repository.PlacePrediction) AutocompleteResponse {
	resp := AutocompleteResponse{
		Predictions: make([]PlacePredictionResponse, len(predictions)),
	}
	for i, p := range predictions {
		resp.Predictions[i] = PlacePredictionResponse{
			PlaceID:        p.PlaceID,
			DisplayName:    p.DisplayName,
			SecondaryText:  p.SecondaryText,
			DistanceMeters: p.DistanceMeters,
		}
	}
	return resp
}

type PlaceLocationResponse struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}
