package repository

import (
	"context"

	"firebase.google.com/go/v4/auth"
)

// FirebaseAuthRepository is the AuthRepository implementation backed by
// Firebase Auth. Only cmd/api/main.go should construct one directly.
type FirebaseAuthRepository struct {
	client *auth.Client
}

func NewFirebaseAuthRepository(client *auth.Client) *FirebaseAuthRepository {
	return &FirebaseAuthRepository{client: client}
}

func (r *FirebaseAuthRepository) DeleteUser(ctx context.Context, uid string) error {
	return r.client.DeleteUser(ctx, uid)
}
