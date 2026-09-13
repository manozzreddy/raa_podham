package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// GooglePlacesBaseURL is Google's real Places API (New) host. Passed
// explicitly (rather than baked into GooglePlacesRepository) so tests can
// point this same code at an httptest.Server instead.
const GooglePlacesBaseURL = "https://places.googleapis.com"

// GooglePlacesRepository is the only place in the backend that holds the
// real Google API key or talks to Google directly — the whole point of
// this repository existing server-side is that the key never has to
// ship inside the mobile app.
type GooglePlacesRepository struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

func NewGooglePlacesRepository(apiKey, baseURL string) *GooglePlacesRepository {
	return &GooglePlacesRepository{
		apiKey:     apiKey,
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}
}

type autocompleteResponse struct {
	Suggestions []struct {
		PlacePrediction struct {
			PlaceID string `json:"placeId"`
			Text    struct {
				Text string `json:"text"`
			} `json:"text"`
			StructuredFormat struct {
				MainText struct {
					Text string `json:"text"`
				} `json:"mainText"`
				SecondaryText struct {
					Text string `json:"text"`
				} `json:"secondaryText"`
			} `json:"structuredFormat"`
		} `json:"placePrediction"`
	} `json:"suggestions"`
}

func (r *GooglePlacesRepository) Autocomplete(ctx context.Context, input string) ([]PlacePrediction, error) {
	body, err := json.Marshal(map[string]any{
		"input": input,
		// Matches the product's India-only scope for now, the same
		// restriction the client-side Nominatim call this replaced used.
		"includedRegionCodes": []string{"in"},
	})
	if err != nil {
		return nil, fmt.Errorf("marshal autocomplete request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.baseURL+"/v1/places:autocomplete", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("build autocomplete request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Goog-Api-Key", r.apiKey)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("call autocomplete: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("autocomplete: unexpected status %d", resp.StatusCode)
	}

	var parsed autocompleteResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, fmt.Errorf("decode autocomplete response: %w", err)
	}

	predictions := make([]PlacePrediction, 0, len(parsed.Suggestions))
	for _, s := range parsed.Suggestions {
		p := s.PlacePrediction
		displayName := p.StructuredFormat.MainText.Text
		secondaryText := p.StructuredFormat.SecondaryText.Text
		// structuredFormat is normally present; fall back to the plain
		// formatted text rather than a blank row if it's ever missing.
		if displayName == "" {
			displayName = p.Text.Text
		}
		predictions = append(predictions, PlacePrediction{
			PlaceID:       p.PlaceID,
			DisplayName:   displayName,
			SecondaryText: secondaryText,
		})
	}
	return predictions, nil
}

func (r *GooglePlacesRepository) ResolveLocation(ctx context.Context, placeID string) (float64, float64, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, r.baseURL+"/v1/places/"+placeID, nil)
	if err != nil {
		return 0, 0, fmt.Errorf("build place details request: %w", err)
	}
	req.Header.Set("X-Goog-Api-Key", r.apiKey)
	// Required by Place Details (New) — omitting it is a 400, not just
	// wasted bandwidth.
	req.Header.Set("X-Goog-FieldMask", "location")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return 0, 0, fmt.Errorf("call place details: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, 0, fmt.Errorf("place details: unexpected status %d", resp.StatusCode)
	}

	var parsed struct {
		Location struct {
			Latitude  float64 `json:"latitude"`
			Longitude float64 `json:"longitude"`
		} `json:"location"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return 0, 0, fmt.Errorf("decode place details response: %w", err)
	}
	return parsed.Location.Latitude, parsed.Location.Longitude, nil
}
