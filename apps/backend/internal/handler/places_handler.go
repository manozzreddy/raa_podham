package handler

import (
	"net/http"
	"net/url"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/dto"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

type PlacesHandler struct {
	places *service.PlacesService
}

func NewPlacesHandler(places *service.PlacesService) *PlacesHandler {
	return &PlacesHandler{places: places}
}

func (h *PlacesHandler) Autocomplete(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	originLat, originLng, err := parseOptionalOrigin(query)
	if err != nil {
		respondError(w, apperror.BadRequest("originLat/originLng must be numbers"))
		return
	}

	predictions, err := h.places.Autocomplete(r.Context(), query.Get("input"), originLat, originLng)
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusOK, dto.FromPlacePredictions(predictions))
}

// parseOptionalOrigin parses originLat/originLng for a distance-aware
// search — unlike /routes' required coordinates, missing either one here
// just means a plain, distance-free search rather than a bad request.
func parseOptionalOrigin(query url.Values) (lat, lng *float64, err error) {
	latStr := query.Get("originLat")
	lngStr := query.Get("originLng")
	if latStr == "" || lngStr == "" {
		return nil, nil, nil
	}

	latVal, err := parseLatLng(latStr)
	if err != nil {
		return nil, nil, err
	}
	lngVal, err := parseLatLng(lngStr)
	if err != nil {
		return nil, nil, err
	}
	return &latVal, &lngVal, nil
}

func (h *PlacesHandler) ResolveLocation(w http.ResponseWriter, r *http.Request) {
	lat, lng, err := h.places.ResolveLocation(r.Context(), r.URL.Query().Get("placeId"))
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusOK, dto.PlaceLocationResponse{Lat: lat, Lng: lng})
}
