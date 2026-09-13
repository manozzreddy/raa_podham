// Package dto holds the JSON request/response shapes the handler layer
// decodes/encodes — kept separate from model so the wire format can
// evolve independently of the Firestore document shape.
package dto

import "github.com/dynamicarraytech/raa-podham/backend/internal/model"

type CreateRideRequest struct {
	Name string `json:"name"`
}

type JoinRideRequest struct {
	InviteCode string `json:"inviteCode"`
}

type RideResponse struct {
	ID         string   `json:"id"`
	Name       string   `json:"name"`
	HostUID    string   `json:"hostUid"`
	InviteCode string   `json:"inviteCode"`
	Status     string   `json:"status"`
	MemberUIDs []string `json:"memberUids"`
}

// FromRide converts a model.Ride into its API representation.
func FromRide(ride *model.Ride) RideResponse {
	return RideResponse{
		ID:         ride.ID,
		Name:       ride.Name,
		HostUID:    ride.HostUID,
		InviteCode: ride.InviteCode,
		Status:     string(ride.Status),
		MemberUIDs: ride.MemberUIDs,
	}
}

type MyRidesResponse struct {
	Active []RideResponse `json:"active"`
	Past   []RideResponse `json:"past"`
}
