package server

import (
	"net/http"

	"firebase.google.com/go/v4/auth"
	"github.com/go-chi/chi/v5"

	"github.com/dynamicarraytech/raa-podham/backend/internal/handler"
	appmiddleware "github.com/dynamicarraytech/raa-podham/backend/internal/middleware"
)

// Handlers bundles the handlers NewRouter wires up. Built in
// cmd/api/main.go.
type Handlers struct {
	Ride   *handler.RideHandler
	User   *handler.UserHandler
	Places *handler.PlacesHandler
	Routes *handler.RoutesHandler
}

// NewRouter builds the app's full route tree: Recovery, Logging, and
// CORS apply globally; /healthz is unauthenticated; everything else
// sits behind Auth.
func NewRouter(h Handlers, authClient *auth.Client) http.Handler {
	r := chi.NewRouter()

	r.Use(appmiddleware.Recovery)
	r.Use(appmiddleware.Logging)
	r.Use(appmiddleware.CORS())

	// Registered under both names: something on at least one network path
	// between clients and this service consistently drops the trailing
	// "z" from "/healthz" in transit, so "/health" is served too rather
	// than chasing that further.
	r.Get("/healthz", handler.Health)
	r.Get("/health", handler.Health)

	r.Group(func(r chi.Router) {
		r.Use(appmiddleware.Auth(authClient))

		r.Post("/rides", h.Ride.CreateRide)
		r.Patch("/rides/{id}", h.Ride.UpdateRide)
		r.Post("/rides/join", h.Ride.JoinRide)
		r.Post("/rides/{id}/start", h.Ride.StartRide)
		r.Post("/rides/{id}/leave", h.Ride.LeaveRide)
		r.Post("/rides/{id}/end", h.Ride.EndRide)
		r.Post("/rides/{id}/members/{uid}/remove", h.Ride.RemoveMember)
		r.Delete("/rides/{id}", h.Ride.DeleteRide)
		r.Get("/users/me/rides", h.User.ListMyRides)
		r.Delete("/users/me", h.User.DeleteAccount)

		// Behind auth like everything else here, deliberately: these
		// proxy Google's billed Places/Routes APIs, so an unauthenticated
		// caller must never be able to reach them and run up our bill.
		r.Get("/places/autocomplete", h.Places.Autocomplete)
		r.Get("/places/details", h.Places.ResolveLocation)
		r.Get("/routes", h.Routes.ComputeRoute)
	})

	return r
}
