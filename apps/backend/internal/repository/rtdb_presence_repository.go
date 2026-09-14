package repository

import (
	"context"

	"firebase.google.com/go/v4/db"
)

// RTDBPresenceRepository is the PresenceRepository implementation backed
// by the Realtime Database. Only cmd/api/main.go should construct one
// directly.
type RTDBPresenceRepository struct {
	client *db.Client
}

func NewRTDBPresenceRepository(client *db.Client) *RTDBPresenceRepository {
	return &RTDBPresenceRepository{client: client}
}

func (r *RTDBPresenceRepository) SetMember(ctx context.Context, rideID, uid string, present bool) error {
	ref := r.client.NewRef("rides/" + rideID + "/members/" + uid)
	return ref.Set(ctx, map[string]any{"present": present})
}

// ClearRide deletes the whole rides/{rideId} subtree — both positions
// and members — in one call.
func (r *RTDBPresenceRepository) ClearRide(ctx context.Context, rideID string) error {
	ref := r.client.NewRef("rides/" + rideID)
	return ref.Delete(ctx)
}
