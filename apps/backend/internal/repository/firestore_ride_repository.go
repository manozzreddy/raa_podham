package repository

import (
	"context"
	"errors"
	"fmt"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
)

const ridesCollection = "rides"
const inviteCodesCollection = "inviteCodes"
const membersSubcollection = "members"

// errInviteCodeCollision signals that a candidate invite code is already
// taken, so CreateRide should retry with a fresh one.
var errInviteCodeCollision = errors.New("invite code already exists")

// maxInviteCodeAttempts bounds how many times CreateRide will generate a
// new invite code before giving up.
const maxInviteCodeAttempts = 5

// FirestoreRideRepository is the RideRepository implementation backed by
// Firestore. Only cmd/api/main.go should construct one directly.
type FirestoreRideRepository struct {
	client *firestore.Client
}

func NewFirestoreRideRepository(client *firestore.Client) *FirestoreRideRepository {
	return &FirestoreRideRepository{client: client}
}

// CreateRide atomically writes rides/{id}, rides/{id}/members/{hostUid},
// and inviteCodes/{code}. If the invite code already assigned to ride is
// taken, it generates a new one and retries the whole transaction.
func (r *FirestoreRideRepository) CreateRide(ctx context.Context, ride *model.Ride, host *model.Member) error {
	rideRef := r.client.Collection(ridesCollection).NewDoc()
	ride.ID = rideRef.ID

	for attempt := 0; attempt < maxInviteCodeAttempts; attempt++ {
		codeRef := r.client.Collection(inviteCodesCollection).Doc(ride.InviteCode)

		err := r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			_, getErr := tx.Get(codeRef)
			switch {
			case getErr == nil:
				return errInviteCodeCollision
			case status.Code(getErr) == codes.NotFound:
				// No existing code — clear to proceed.
			default:
				return getErr
			}

			if err := tx.Set(rideRef, ride); err != nil {
				return err
			}
			memberRef := rideRef.Collection(membersSubcollection).Doc(host.UID)
			if err := tx.Set(memberRef, host); err != nil {
				return err
			}
			return tx.Set(codeRef, map[string]any{"rideId": ride.ID})
		})

		if err == nil {
			return nil
		}
		if !errors.Is(err, errInviteCodeCollision) {
			return err
		}

		newCode, genErr := model.NewInviteCode()
		if genErr != nil {
			return genErr
		}
		ride.InviteCode = newCode
	}

	return fmt.Errorf("could not allocate a unique invite code after %d attempts", maxInviteCodeAttempts)
}

func (r *FirestoreRideRepository) GetRideByID(ctx context.Context, id string) (*model.Ride, error) {
	snap, err := r.client.Collection(ridesCollection).Doc(id).Get(ctx)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return nil, ErrNotFound
		}
		return nil, err
	}

	var ride model.Ride
	if err := snap.DataTo(&ride); err != nil {
		return nil, err
	}
	ride.ID = snap.Ref.ID
	return &ride, nil
}

func (r *FirestoreRideRepository) GetRideByInviteCode(ctx context.Context, code string) (*model.Ride, error) {
	snap, err := r.client.Collection(inviteCodesCollection).Doc(code).Get(ctx)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return nil, ErrNotFound
		}
		return nil, err
	}

	var lookup struct {
		RideID string `firestore:"rideId"`
	}
	if err := snap.DataTo(&lookup); err != nil {
		return nil, err
	}

	return r.GetRideByID(ctx, lookup.RideID)
}

func (r *FirestoreRideRepository) AddMember(ctx context.Context, rideID string, member *model.Member) error {
	rideRef := r.client.Collection(ridesCollection).Doc(rideID)
	memberRef := rideRef.Collection(membersSubcollection).Doc(member.UID)

	return r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := tx.Set(memberRef, member); err != nil {
			return err
		}
		return tx.Update(rideRef, []firestore.Update{
			{Path: "memberUids", Value: firestore.ArrayUnion(member.UID)},
		})
	})
}

func (r *FirestoreRideRepository) RemoveMember(ctx context.Context, rideID, uid string) error {
	rideRef := r.client.Collection(ridesCollection).Doc(rideID)
	memberRef := rideRef.Collection(membersSubcollection).Doc(uid)

	return r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := tx.Delete(memberRef); err != nil {
			return err
		}
		return tx.Update(rideRef, []firestore.Update{
			{Path: "memberUids", Value: firestore.ArrayRemove(uid)},
		})
	})
}

func (r *FirestoreRideRepository) StartRide(ctx context.Context, rideID string) error {
	_, err := r.client.Collection(ridesCollection).Doc(rideID).Update(ctx, []firestore.Update{
		{Path: "status", Value: model.RideStatusActive},
	})
	return err
}

func (r *FirestoreRideRepository) EndRide(ctx context.Context, rideID string) error {
	_, err := r.client.Collection(ridesCollection).Doc(rideID).Update(ctx, []firestore.Update{
		{Path: "status", Value: model.RideStatusEnded},
		{Path: "endedAt", Value: firestore.ServerTimestamp},
	})
	return err
}

// DeleteRide permanently removes rides/{id}, every doc in its members
// subcollection (Firestore doesn't cascade-delete those on its own), and
// the inviteCodes/{code} lookup entry that points at it — all in one
// transaction, so a failure partway through leaves nothing half-deleted.
func (r *FirestoreRideRepository) DeleteRide(ctx context.Context, rideID, inviteCode string) error {
	rideRef := r.client.Collection(ridesCollection).Doc(rideID)

	// Reads must happen before any transaction writes below, so this
	// listing runs as a plain (non-transactional) read first.
	memberRefs, err := rideRef.Collection(membersSubcollection).DocumentRefs(ctx).GetAll()
	if err != nil {
		return err
	}

	return r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		for _, memberRef := range memberRefs {
			if err := tx.Delete(memberRef); err != nil {
				return err
			}
		}
		if err := tx.Delete(rideRef); err != nil {
			return err
		}
		return tx.Delete(r.client.Collection(inviteCodesCollection).Doc(inviteCode))
	})
}

func (r *FirestoreRideRepository) ListRidesForUser(ctx context.Context, uid string) ([]*model.Ride, error) {
	iter := r.client.Collection(ridesCollection).
		Where("memberUids", "array-contains", uid).
		OrderBy("createdAt", firestore.Desc).
		Documents(ctx)
	defer iter.Stop()

	var rides []*model.Ride
	for {
		doc, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}

		var ride model.Ride
		if err := doc.DataTo(&ride); err != nil {
			return nil, err
		}
		ride.ID = doc.Ref.ID
		rides = append(rides, &ride)
	}

	return rides, nil
}
