package service_test

import (
	"context"
	"testing"
	"time"

	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

// fakeStorageRepository is a minimal in-memory repository.StorageRepository.
type fakeStorageRepository struct {
	deletedForUID map[string]bool
}

func newFakeStorageRepository() *fakeStorageRepository {
	return &fakeStorageRepository{deletedForUID: make(map[string]bool)}
}

func (f *fakeStorageRepository) DeleteAllForUser(ctx context.Context, uid string) error {
	f.deletedForUID[uid] = true
	return nil
}

// fakeAuthRepository is a minimal in-memory repository.AuthRepository.
type fakeAuthRepository struct {
	deletedUID string
}

func (f *fakeAuthRepository) DeleteUser(ctx context.Context, uid string) error {
	f.deletedUID = uid
	return nil
}

func newUserServiceForTest(rides *fakeRideRepository, presence *fakePresenceRepository, profiles *fakeProfileRepository, storage *fakeStorageRepository, auth *fakeAuthRepository) *service.UserService {
	return service.NewUserService(rides, presence, profiles, storage, auth)
}

func TestDeleteAccount_HostedRideIsEndedAndDeleted(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	profiles := newFakeProfileRepository()
	storage := newFakeStorageRepository()
	auth := &fakeAuthRepository{}

	rides.seedRide(&model.Ride{
		ID:         "ride-1",
		HostUID:    "host-uid",
		InviteCode: "CODE01",
		Status:     model.RideStatusActive,
		MemberUIDs: []string{"host-uid"},
		CreatedAt:  time.Now().UTC(),
	})

	users := newUserServiceForTest(rides, presence, profiles, storage, auth)
	if err := users.DeleteAccount(context.Background(), "host-uid"); err != nil {
		t.Fatalf("DeleteAccount returned an error: %v", err)
	}

	if _, err := rides.GetRideByID(context.Background(), "ride-1"); err == nil {
		t.Fatal("expected the hosted ride to be deleted")
	}
	if !presence.cleared["ride-1"] {
		t.Fatal("expected the hosted ride's RTDB presence to be cleared")
	}
	if !storage.deletedForUID["host-uid"] {
		t.Fatal("expected the host's storage objects to be deleted")
	}
	if auth.deletedUID != "host-uid" {
		t.Fatalf("expected the Firebase Auth user to be deleted, got %q", auth.deletedUID)
	}
}

func TestDeleteAccount_RiddenRideIsUntouchedExceptMembership(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	profiles := newFakeProfileRepository()
	storage := newFakeStorageRepository()
	auth := &fakeAuthRepository{}

	rides.seedRide(&model.Ride{
		ID:         "ride-2",
		HostUID:    "other-host",
		InviteCode: "CODE02",
		Status:     model.RideStatusActive,
		MemberUIDs: []string{"other-host", "rider-uid"},
		CreatedAt:  time.Now().UTC(),
	})

	users := newUserServiceForTest(rides, presence, profiles, storage, auth)
	if err := users.DeleteAccount(context.Background(), "rider-uid"); err != nil {
		t.Fatalf("DeleteAccount returned an error: %v", err)
	}

	ride, err := rides.GetRideByID(context.Background(), "ride-2")
	if err != nil {
		t.Fatalf("expected the ride to still exist, got error: %v", err)
	}
	for _, uid := range ride.MemberUIDs {
		if uid == "rider-uid" {
			t.Fatal("expected rider-uid to be removed from the ride's members")
		}
	}
	if ride.Status != model.RideStatusActive {
		t.Fatalf("expected the ride to remain active, got %q", ride.Status)
	}
	if present, ok := presence.present["ride-2"]["rider-uid"]; !ok || present {
		t.Fatal("expected rider-uid's presence to be set to false")
	}
}

func TestDeleteAccount_HostedAndRiddenRidesTogether(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	profiles := newFakeProfileRepository()
	storage := newFakeStorageRepository()
	auth := &fakeAuthRepository{}

	rides.seedRide(&model.Ride{
		ID:         "hosted",
		HostUID:    "uid",
		InviteCode: "CODE03",
		Status:     model.RideStatusEnded,
		MemberUIDs: []string{"uid"},
		CreatedAt:  time.Now().UTC(),
	})
	rides.seedRide(&model.Ride{
		ID:         "ridden",
		HostUID:    "other-host",
		InviteCode: "CODE04",
		Status:     model.RideStatusScheduled,
		MemberUIDs: []string{"other-host", "uid"},
		CreatedAt:  time.Now().UTC(),
	})

	users := newUserServiceForTest(rides, presence, profiles, storage, auth)
	if err := users.DeleteAccount(context.Background(), "uid"); err != nil {
		t.Fatalf("DeleteAccount returned an error: %v", err)
	}

	if _, err := rides.GetRideByID(context.Background(), "hosted"); err == nil {
		t.Fatal("expected the already-ended hosted ride to be deleted too")
	}
	riddenRide, err := rides.GetRideByID(context.Background(), "ridden")
	if err != nil {
		t.Fatalf("expected the ridden ride to still exist, got error: %v", err)
	}
	if riddenRide.Status != model.RideStatusScheduled {
		t.Fatalf("expected the ridden ride's status to be untouched, got %q", riddenRide.Status)
	}
}
