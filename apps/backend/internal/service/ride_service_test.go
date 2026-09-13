package service_test

import (
	"context"
	"errors"
	"strconv"
	"testing"
	"time"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
	"github.com/dynamicarraytech/raa-podham/backend/internal/service"
)

// fakeRideRepository is a minimal in-memory repository.RideRepository,
// standing in for Firestore so RideService can be tested without one.
type fakeRideRepository struct {
	rides       map[string]*model.Ride
	inviteCodes map[string]string // invite code -> ride ID
	nextID      int
}

func newFakeRideRepository() *fakeRideRepository {
	return &fakeRideRepository{
		rides:       make(map[string]*model.Ride),
		inviteCodes: make(map[string]string),
	}
}

func (f *fakeRideRepository) CreateRide(ctx context.Context, ride *model.Ride, host *model.Member) error {
	f.nextID++
	ride.ID = "ride-" + strconv.Itoa(f.nextID)
	f.rides[ride.ID] = ride
	f.inviteCodes[ride.InviteCode] = ride.ID
	return nil
}

func (f *fakeRideRepository) GetRideByID(ctx context.Context, id string) (*model.Ride, error) {
	ride, ok := f.rides[id]
	if !ok {
		return nil, repository.ErrNotFound
	}
	return ride, nil
}

func (f *fakeRideRepository) GetRideByInviteCode(ctx context.Context, code string) (*model.Ride, error) {
	id, ok := f.inviteCodes[code]
	if !ok {
		return nil, repository.ErrNotFound
	}
	return f.GetRideByID(ctx, id)
}

func (f *fakeRideRepository) AddMember(ctx context.Context, rideID string, member *model.Member) error {
	ride, ok := f.rides[rideID]
	if !ok {
		return repository.ErrNotFound
	}
	ride.MemberUIDs = append(ride.MemberUIDs, member.UID)
	return nil
}

func (f *fakeRideRepository) RemoveMember(ctx context.Context, rideID, uid string) error {
	ride, ok := f.rides[rideID]
	if !ok {
		return repository.ErrNotFound
	}
	filtered := ride.MemberUIDs[:0]
	for _, existing := range ride.MemberUIDs {
		if existing != uid {
			filtered = append(filtered, existing)
		}
	}
	ride.MemberUIDs = filtered
	return nil
}

func (f *fakeRideRepository) EndRide(ctx context.Context, rideID string) error {
	ride, ok := f.rides[rideID]
	if !ok {
		return repository.ErrNotFound
	}
	ride.Status = model.RideStatusEnded
	now := time.Now().UTC()
	ride.EndedAt = &now
	return nil
}

func (f *fakeRideRepository) ListRidesForUser(ctx context.Context, uid string) ([]*model.Ride, error) {
	var result []*model.Ride
	for _, ride := range f.rides {
		for _, memberUID := range ride.MemberUIDs {
			if memberUID == uid {
				result = append(result, ride)
				break
			}
		}
	}
	return result, nil
}

// seedRide inserts a ride directly, bypassing CreateRide, for tests that
// need specific starting state (e.g. an already-ended ride).
func (f *fakeRideRepository) seedRide(ride *model.Ride) {
	f.rides[ride.ID] = ride
	f.inviteCodes[ride.InviteCode] = ride.ID
}

// fakePresenceRepository is a minimal in-memory repository.PresenceRepository.
type fakePresenceRepository struct {
	present map[string]map[string]bool // rideID -> uid -> present
	cleared map[string]bool
}

func newFakePresenceRepository() *fakePresenceRepository {
	return &fakePresenceRepository{
		present: make(map[string]map[string]bool),
		cleared: make(map[string]bool),
	}
}

func (f *fakePresenceRepository) SetMember(ctx context.Context, rideID, uid string, present bool) error {
	if f.present[rideID] == nil {
		f.present[rideID] = make(map[string]bool)
	}
	f.present[rideID][uid] = present
	return nil
}

func (f *fakePresenceRepository) ClearRide(ctx context.Context, rideID string) error {
	f.cleared[rideID] = true
	delete(f.present, rideID)
	return nil
}

// fakeProfileRepository is a minimal in-memory repository.ProfileRepository.
// Empty (no seeded profiles) by default, matching how a brand-new user
// looks in Firestore before RideService falls back to an empty name.
type fakeProfileRepository struct {
	profiles map[string]*model.UserProfile
}

func newFakeProfileRepository() *fakeProfileRepository {
	return &fakeProfileRepository{profiles: make(map[string]*model.UserProfile)}
}

func (f *fakeProfileRepository) GetProfile(ctx context.Context, uid string) (*model.UserProfile, error) {
	profile, ok := f.profiles[uid]
	if !ok {
		return nil, repository.ErrNotFound
	}
	return profile, nil
}

func appErrorCode(t *testing.T, err error) string {
	t.Helper()
	var appErr *apperror.AppError
	if !errors.As(err, &appErr) {
		t.Fatalf("expected an *apperror.AppError, got %T: %v", err, err)
	}
	return appErr.Code
}

func TestRideService_CreateRide(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())

	ride, err := svc.CreateRide(context.Background(), "host-1", "Sunday Sunrise Ride")
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}
	if ride.HostUID != "host-1" {
		t.Errorf("HostUID = %q, want %q", ride.HostUID, "host-1")
	}
	if len(ride.InviteCode) != 6 {
		t.Errorf("InviteCode length = %d, want 6", len(ride.InviteCode))
	}
	if ride.Status != model.RideStatusActive {
		t.Errorf("Status = %q, want %q", ride.Status, model.RideStatusActive)
	}
	if !presence.present[ride.ID]["host-1"] {
		t.Errorf("expected host to be marked present in presence repo")
	}
}

func TestRideService_JoinRide(t *testing.T) {
	tests := []struct {
		name     string
		seed     func(rides *fakeRideRepository) string // returns the invite code to join with
		joinUID  string
		wantCode string
	}{
		{
			name: "invalid code",
			seed: func(rides *fakeRideRepository) string {
				return "BADCOD"
			},
			joinUID:  "rider-1",
			wantCode: "not_found",
		},
		{
			name: "ended ride",
			seed: func(rides *fakeRideRepository) string {
				rides.seedRide(&model.Ride{
					ID:         "ride-ended",
					InviteCode: "ENDED1",
					Status:     model.RideStatusEnded,
					HostUID:    "host-1",
					MemberUIDs: []string{"host-1"},
				})
				return "ENDED1"
			},
			joinUID:  "rider-1",
			wantCode: "gone",
		},
		{
			name: "already a member",
			seed: func(rides *fakeRideRepository) string {
				rides.seedRide(&model.Ride{
					ID:         "ride-active",
					InviteCode: "MEMBR1",
					Status:     model.RideStatusActive,
					HostUID:    "host-1",
					MemberUIDs: []string{"host-1", "rider-1"},
				})
				return "MEMBR1"
			},
			joinUID:  "rider-1",
			wantCode: "conflict",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())

			code := tt.seed(rides)

			_, err := svc.JoinRide(context.Background(), tt.joinUID, code)
			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != tt.wantCode {
				t.Errorf("error code = %q, want %q", got, tt.wantCode)
			}
		})
	}
}

func TestRideService_LeaveRide_HostEndsRide(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())

	ride, err := svc.CreateRide(context.Background(), "host-1", "Test Ride")
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}

	if err := svc.LeaveRide(context.Background(), "host-1", ride.ID); err != nil {
		t.Fatalf("LeaveRide returned error: %v", err)
	}

	got, err := rides.GetRideByID(context.Background(), ride.ID)
	if err != nil {
		t.Fatalf("GetRideByID returned error: %v", err)
	}
	if got.Status != model.RideStatusEnded {
		t.Errorf("Status = %q, want %q after host leaves", got.Status, model.RideStatusEnded)
	}
	if !presence.cleared[ride.ID] {
		t.Errorf("expected presence to be cleared when the host leaves")
	}
}

func TestRideService_EndRide_NonHostForbidden(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())

	ride, err := svc.CreateRide(context.Background(), "host-1", "Test Ride")
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}

	err = svc.EndRide(context.Background(), "someone-else", ride.ID)
	if err == nil {
		t.Fatalf("expected an error, got nil")
	}
	if got := appErrorCode(t, err); got != "forbidden" {
		t.Errorf("error code = %q, want %q", got, "forbidden")
	}
}
