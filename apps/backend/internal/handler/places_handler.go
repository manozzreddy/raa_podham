package handler

import (
	"net/http"

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
	predictions, err := h.places.Autocomplete(r.Context(), r.URL.Query().Get("input"))
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusOK, dto.FromPlacePredictions(predictions))
}

func (h *PlacesHandler) ResolveLocation(w http.ResponseWriter, r *http.Request) {
	lat, lng, err := h.places.ResolveLocation(r.Context(), r.URL.Query().Get("placeId"))
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusOK, dto.PlaceLocationResponse{Lat: lat, Lng: lng})
}
