// Package dto holds the JSON request/response shapes the handler layer
// decodes/encodes — kept separate from model so the wire format can
// evolve independently of the Firestore document shape.
package dto

import (
	"time"

	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
)

// DestinationDTO is the wire shape of model.Destination — a name plus
// coordinates, matching what the mobile app's destination-search screen
// (backed by the Places API proxy) already hands back.
type DestinationDTO struct {
	Name string  `json:"name"`
	Lat  float64 `json:"lat"`
	Lng  float64 `json:"lng"`
}

type CreateRideRequest struct {
	Name          string          `json:"name"`
	Destination   *DestinationDTO `json:"destination,omitempty"`
	ScheduledAt   *time.Time      `json:"scheduledAt,omitempty"`
	Notes         string          `json:"notes,omitempty"`
	CoverPhotoURL string          `json:"coverPhotoUrl,omitempty"`
}

type JoinRideRequest struct {
	InviteCode string `json:"inviteCode"`
}

type RideResponse struct {
	ID            string          `json:"id"`
	Name          string          `json:"name"`
	HostUID       string          `json:"hostUid"`
	InviteCode    string          `json:"inviteCode"`
	Status        string          `json:"status"`
	MemberUIDs    []string        `json:"memberUids"`
	Destination   *DestinationDTO `json:"destination,omitempty"`
	ScheduledAt   *time.Time      `json:"scheduledAt,omitempty"`
	Notes         string          `json:"notes,omitempty"`
	CoverPhotoURL string          `json:"coverPhotoUrl,omitempty"`
	CreatedAt     time.Time       `json:"createdAt"`
	EndedAt       *time.Time      `json:"endedAt,omitempty"`
}

// FromRide converts a model.Ride into its API representation.
func FromRide(ride *model.Ride) RideResponse {
	resp := RideResponse{
		ID:            ride.ID,
		Name:          ride.Name,
		HostUID:       ride.HostUID,
		InviteCode:    ride.InviteCode,
		Status:        string(ride.Status),
		MemberUIDs:    ride.MemberUIDs,
		ScheduledAt:   ride.ScheduledAt,
		Notes:         ride.Notes,
		CoverPhotoURL: ride.CoverPhotoURL,
		CreatedAt:     ride.CreatedAt,
		EndedAt:       ride.EndedAt,
	}
	if ride.Destination != nil {
		resp.Destination = &DestinationDTO{
			Name: ride.Destination.Name,
			Lat:  ride.Destination.Lat,
			Lng:  ride.Destination.Lng,
		}
	}
	return resp
}

type MyRidesResponse struct {
	Active   []RideResponse `json:"active"`
	Upcoming []RideResponse `json:"upcoming"`
	Past     []RideResponse `json:"past"`
}
