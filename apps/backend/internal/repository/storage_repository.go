package repository

import "context"

// StorageRepository manages the app's Firebase Storage objects.
type StorageRepository interface {
	// DeleteAllForUser removes every Storage object that belongs to uid
	// (currently just their rideCoverPhotos/{uid}/ uploads — see
	// storage.rules).
	DeleteAllForUser(ctx context.Context, uid string) error
}
