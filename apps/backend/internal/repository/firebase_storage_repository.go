package repository

import (
	"context"
	"errors"
	"fmt"

	"cloud.google.com/go/storage"
	"google.golang.org/api/iterator"
)

// rideCoverPhotosPrefix mirrors storage.rules' rideCoverPhotos/{uid}/{fileName}
// path — the only per-user data this app keeps in Firebase Storage.
const rideCoverPhotosPrefix = "rideCoverPhotos/"

// FirebaseStorageRepository is the StorageRepository implementation backed
// by the Firebase Storage default bucket. Only cmd/api/main.go should
// construct one directly.
type FirebaseStorageRepository struct {
	bucket *storage.BucketHandle
}

func NewFirebaseStorageRepository(bucket *storage.BucketHandle) *FirebaseStorageRepository {
	return &FirebaseStorageRepository{bucket: bucket}
}

func (r *FirebaseStorageRepository) DeleteAllForUser(ctx context.Context, uid string) error {
	prefix := rideCoverPhotosPrefix + uid + "/"
	it := r.bucket.Objects(ctx, &storage.Query{Prefix: prefix})

	for {
		attrs, err := it.Next()
		if errors.Is(err, iterator.Done) {
			return nil
		}
		if err != nil {
			return fmt.Errorf("listing storage objects under %q: %w", prefix, err)
		}

		if err := r.bucket.Object(attrs.Name).Delete(ctx); err != nil && !errors.Is(err, storage.ErrObjectNotExist) {
			return fmt.Errorf("deleting storage object %q: %w", attrs.Name, err)
		}
	}
}
