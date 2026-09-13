package handler

import (
	"net/http"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/dto"
	"github.com/dynamicarraytech/raa-podham/backend/internal/middleware"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

type UserHandler struct {
	users *service.UserService
}

func NewUserHandler(users *service.UserService) *UserHandler {
	return &UserHandler{users: users}
}

func (h *UserHandler) ListMyRides(w http.ResponseWriter, r *http.Request) {
	uid, ok := middleware.UIDFromContext(r.Context())
	if !ok {
		respondError(w, apperror.Forbidden("missing authenticated user"))
		return
	}

	myRides, err := h.users.ListMyRides(r.Context(), uid)
	if err != nil {
		respondError(w, err)
		return
	}

	response := dto.MyRidesResponse{
		Active: make([]dto.RideResponse, 0, len(myRides.Active)),
		Past:   make([]dto.RideResponse, 0, len(myRides.Past)),
	}
	for _, ride := range myRides.Active {
		response.Active = append(response.Active, dto.FromRide(ride))
	}
	for _, ride := range myRides.Past {
		response.Past = append(response.Past, dto.FromRide(ride))
	}

	respondJSON(w, http.StatusOK, response)
}
