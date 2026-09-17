package repository

import "context"

// AuthRepository manages Firebase Auth user records.
type AuthRepository interface {
	DeleteUser(ctx context.Context, uid string) error
}
