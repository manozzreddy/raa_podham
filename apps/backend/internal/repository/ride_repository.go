// Package repository declares the persistence interfaces the service
// layer depends on, plus their concrete Firestore/Realtime Database
// implementations. The service layer only ever imports the interfaces
// declared here — never the concrete *_repository.go files directly.
package repository

import (
	"context"
	"errors"

	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
)

// ErrNotFound is returned by lookup methods when nothing matches —
// callers distinguish it from other errors with errors.Is.
var ErrNotFound = errors.New("not found")

// RideRepository persists rides and their membership.
type RideRepository interface {
	CreateRide(ctx context.Context, ride *model.Ride, host *model.Member) error
	GetRideByID(ctx context.Context, id string) (*model.Ride, error)
	GetRideByInviteCode(ctx context.Context, code string) (*model.Ride, error)
	AddMember(ctx context.Context, rideID string, member *model.Member) error
	RemoveMember(ctx context.Context, rideID, uid string) error
	EndRide(ctx context.Context, rideID string) error
	ListRidesForUser(ctx context.Context, uid string) ([]*model.Ride, error)
}
