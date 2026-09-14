package repository

import (
	"context"

	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
)

// ProfileRepository reads the user profile data the mobile app writes to
// Firestore right after sign-in — separate from RideRepository since it's
// keyed by uid rather than ride ID and has nothing to do with ride
// membership itself.
type ProfileRepository interface {
	GetProfile(ctx context.Context, uid string) (*model.UserProfile, error)
}
