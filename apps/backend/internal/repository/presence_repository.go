package repository

import "context"

// PresenceRepository tracks who's currently live on a ride, in the
// Realtime Database.
type PresenceRepository interface {
	SetMember(ctx context.Context, rideID, uid string, present bool) error
	ClearRide(ctx context.Context, rideID string) error
}
