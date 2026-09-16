// Package handler is the thin HTTP layer: decode a request, call the
// matching service method, encode the response. No business logic
// lives here.
package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/dto"
	"github.com/dynamicarraytech/raa-podham/backend/internal/middleware"
	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

type RideHandler struct {
	rides *service.RideService
}

func NewRideHandler(rides *service.RideService) *RideHandler {
	return &RideHandler{rides: rides}
}

func (h *RideHandler) CreateRide(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	var req dto.CreateRideRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, apperror.Internal(err))
		return
	}

	var destination *model.Destination
	if req.Destination != nil {
		destination = &model.Destination{
			Name: req.Destination.Name,
			Lat:  req.Destination.Lat,
			Lng:  req.Destination.Lng,
		}
	}

	ride, err := h.rides.CreateRide(r.Context(), uid, service.CreateRideInput{
		Name:          req.Name,
		Destination:   destination,
		ScheduledAt:   req.ScheduledAt,
		Notes:         req.Notes,
		CoverPhotoURL: req.CoverPhotoURL,
	})
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusCreated, dto.FromRide(ride))
}

func (h *RideHandler) StartRide(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	rideID := chi.URLParam(r, "id")
	if err := h.rides.StartRideNow(r.Context(), uid, rideID); err != nil {
		respondError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *RideHandler) JoinRide(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	var req dto.JoinRideRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, apperror.Internal(err))
		return
	}

	ride, err := h.rides.JoinRide(r.Context(), uid, req.InviteCode)
	if err != nil {
		respondError(w, err)
		return
	}

	respondJSON(w, http.StatusOK, dto.FromRide(ride))
}

func (h *RideHandler) LeaveRide(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	rideID := chi.URLParam(r, "id")
	if err := h.rides.LeaveRide(r.Context(), uid, rideID); err != nil {
		respondError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *RideHandler) EndRide(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	rideID := chi.URLParam(r, "id")
	if err := h.rides.EndRide(r.Context(), uid, rideID); err != nil {
		respondError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *RideHandler) DeleteRide(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	rideID := chi.URLParam(r, "id")
	if err := h.rides.DeleteRide(r.Context(), uid, rideID); err != nil {
		respondError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *RideHandler) RemoveMember(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	rideID := chi.URLParam(r, "id")
	memberUID := chi.URLParam(r, "uid")
	if err := h.rides.RemoveMember(r.Context(), uid, rideID, memberUID); err != nil {
		respondError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func respondJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

// respondError type-switches on *apperror.AppError to produce the right
// status/body; anything else is treated as an unexpected internal error.
func respondError(w http.ResponseWriter, err error) {
	switch e := err.(type) {
	case *apperror.AppError:
		respondJSON(w, e.HTTPStatus, map[string]string{"code": e.Code, "message": e.Message})
	default:
		respondJSON(w, http.StatusInternalServerError, map[string]string{
			"code":    "internal",
			"message": "something went wrong",
		})
	}
}
