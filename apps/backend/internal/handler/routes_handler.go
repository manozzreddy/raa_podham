package handler

import (
	"net/http"
	"strconv"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/dto"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

type RoutesHandler struct {
	routes *service.RoutesService
}

func NewRoutesHandler(routes *service.RoutesService) *RoutesHandler {
	return &RoutesHandler{routes: routes}
}

func (h *RoutesHandler) ComputeRoute(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	originLat, err := parseLatLng(query.Get("originLat"))
	if err != nil {
		respondError(w, apperror.BadRequest("originLat is required and must be a number"))
		return
	}
	originLng, err := parseLatLng(query.Get("originLng"))
	if err != nil {
		respondError(w, apperror.BadRequest("originLng is required and must be a number"))
		return
	}
	destLat, err := parseLatLng(query.Get("destLat"))
	if err != nil {
		respondError(w, apperror.BadRequest("destLat is required and must be a number"))
		return
	}
	destLng, err := parseLatLng(query.Get("destLng"))
	if err != nil {
		respondError(w, apperror.BadRequest("destLng is required and must be a number"))
		return
	}

	result, err := h.routes.ComputeRoute(r.Context(), originLat, originLng, destLat, destLng)
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusOK, dto.FromRouteResult(result))
}

func parseLatLng(raw string) (float64, error) {
	return strconv.ParseFloat(raw, 64)
}
