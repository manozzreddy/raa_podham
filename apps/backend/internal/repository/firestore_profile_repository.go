package repository

import (
	"context"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
)

const usersCollection = "users"

// FirestoreProfileRepository is the ProfileRepository implementation
// backed by Firestore. Only cmd/api/main.go should construct one
// directly.
type FirestoreProfileRepository struct {
	client *firestore.Client
}

func NewFirestoreProfileRepository(client *firestore.Client) *FirestoreProfileRepository {
	return &FirestoreProfileRepository{client: client}
}

// GetProfile returns the user's profile, or ErrNotFound if they haven't
// signed in yet — the mobile app writes this doc right after sign-in, so
// callers should treat that as "no profile yet" rather than a hard
// failure.
func (r *FirestoreProfileRepository) GetProfile(ctx context.Context, uid string) (*model.UserProfile, error) {
	snap, err := r.client.Collection(usersCollection).Doc(uid).Get(ctx)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return nil, ErrNotFound
		}
		return nil, err
	}

	var profile model.UserProfile
	if err := snap.DataTo(&profile); err != nil {
		return nil, err
	}
	profile.UID = snap.Ref.ID
	return &profile, nil
}
