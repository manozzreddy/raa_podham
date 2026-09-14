package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// GoogleRoutesBaseURL is Google's real Routes API host. Passed
// explicitly (rather than baked into GoogleRoutesRepository) so tests
// can point this same code at an httptest.Server instead.
const GoogleRoutesBaseURL = "https://routes.googleapis.com"

// GoogleRoutesRepository is the only place in the backend that holds the
// real Google API key or talks to Google's Routes API directly — same
// reasoning as GooglePlacesRepository, the key never has to ship inside
// the mobile app.
type GoogleRoutesRepository struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

func NewGoogleRoutesRepository(apiKey, baseURL string) *GoogleRoutesRepository {
	return &GoogleRoutesRepository{
		apiKey:     apiKey,
		baseURL:    baseURL,
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}
}

type computeRoutesResponse struct {
	Routes []struct {
		DistanceMeters int    `json:"distanceMeters"`
		Duration       string `json:"duration"`
		Polyline       struct {
			EncodedPolyline string `json:"encodedPolyline"`
		} `json:"polyline"`
	} `json:"routes"`
}

func (r *GoogleRoutesRepository) ComputeRoute(ctx context.Context, originLat, originLng, destLat, destLng float64) (*RouteResult, error) {
	body, err := json.Marshal(map[string]any{
		"origin": map[string]any{
			"location": map[string]any{
				"latLng": map[string]any{"latitude": originLat, "longitude": originLng},
			},
		},
		"destination": map[string]any{
			"location": map[string]any{
				"latLng": map[string]any{"latitude": destLat, "longitude": destLng},
			},
		},
		// Matches the product's motorcycle-group-ride focus. Only
		// available in a handful of countries, India among them — see
		// https://developers.google.com/maps/documentation/routes/reference/rest/v2/TopLevel/computeRoutes#TravelMode
		"travelMode": "TWO_WHEELER",
	})
	if err != nil {
		return nil, fmt.Errorf("marshal compute routes request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.baseURL+"/directions/v2:computeRoutes", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("build compute routes request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Goog-Api-Key", r.apiKey)
	// Required by Routes API — omitting it is a 400, not just wasted
	// bandwidth, same as Place Details' field mask requirement.
	req.Header.Set("X-Goog-FieldMask", "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("call compute routes: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("compute routes: unexpected status %d", resp.StatusCode)
	}

	var parsed computeRoutesResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, fmt.Errorf("decode compute routes response: %w", err)
	}
	if len(parsed.Routes) == 0 {
		return nil, fmt.Errorf("compute routes: no route found")
	}

	route := parsed.Routes[0]
	// Routes API returns duration as a protobuf Duration string (e.g.
	// "421s"), which time.ParseDuration happens to accept directly.
	duration, err := time.ParseDuration(route.Duration)
	if err != nil {
		return nil, fmt.Errorf("parse route duration %q: %w", route.Duration, err)
	}

	return &RouteResult{
		DistanceMeters:  route.DistanceMeters,
		DurationSeconds: int(duration.Seconds()),
		Polyline:        route.Polyline.EncodedPolyline,
	}, nil
}
