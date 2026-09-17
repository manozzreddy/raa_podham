package service_test

import (
	"context"
	"errors"
	"slices"
	"strconv"
	"strings"
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

func (f *fakeRideRepository) UpdateRide(ctx context.Context, ride *model.Ride) error {
	if _, ok := f.rides[ride.ID]; !ok {
		return repository.ErrNotFound
	}
	f.rides[ride.ID] = ride
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

func (f *fakeRideRepository) StartRide(ctx context.Context, rideID string) error {
	ride, ok := f.rides[rideID]
	if !ok {
		return repository.ErrNotFound
	}
	ride.Status = model.RideStatusActive
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

func (f *fakeRideRepository) DeleteRide(ctx context.Context, rideID, inviteCode string) error {
	if _, ok := f.rides[rideID]; !ok {
		return repository.ErrNotFound
	}
	delete(f.rides, rideID)
	delete(f.inviteCodes, inviteCode)
	return nil
}

func (f *fakeRideRepository) ListRidesForUser(ctx context.Context, uid string) ([]*model.Ride, error) {
	var result []*model.Ride
	for _, ride := range f.rides {
		if slices.Contains(ride.MemberUIDs, uid) {
			result = append(result, ride)
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

func (f *fakeProfileRepository) DeleteProfile(ctx context.Context, uid string) error {
	delete(f.profiles, uid)
	return nil
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

	ride, err := svc.CreateRide(context.Background(), "host-1", service.CreateRideInput{Name: "Sunday Sunrise Ride"})
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

func TestRideService_CreateRide_WithDestination(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())

	destination := &model.Destination{Name: "Cubbon Park", Lat: 12.9716, Lng: 77.5946}
	ride, err := svc.CreateRide(context.Background(), "host-1", service.CreateRideInput{
		Name:        "Sunday Sunrise Ride",
		Destination: destination,
	})
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}
	if ride.Destination == nil {
		t.Fatalf("Destination = nil, want %+v", destination)
	}
	if *ride.Destination != *destination {
		t.Errorf("Destination = %+v, want %+v", ride.Destination, destination)
	}
}

func TestRideService_CreateRide_Scheduled(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())

	scheduledAt := time.Now().UTC().Add(24 * time.Hour)
	ride, err := svc.CreateRide(context.Background(), "host-1", service.CreateRideInput{
		Name:        "Next Sunday Ride",
		ScheduledAt: &scheduledAt,
	})
	if err != nil {
		t.Fatalf("CreateRide returned error: %v", err)
	}
	if ride.Status != model.RideStatusScheduled {
		t.Errorf("Status = %q, want %q", ride.Status, model.RideStatusScheduled)
	}
	if presence.present[ride.ID]["host-1"] {
		t.Errorf("expected host NOT to be marked present for a scheduled (not yet started) ride")
	}
}

func TestRideService_CreateRide_Validation(t *testing.T) {
	past := time.Now().UTC().Add(-time.Hour)
	tooFarAhead := time.Now().UTC().Add(2 * 365 * 24 * time.Hour)
	tooLongNotes := strings.Repeat("a", 501)

	tests := []struct {
		name  string
		input service.CreateRideInput
	}{
		{
			name:  "scheduled time in the past",
			input: service.CreateRideInput{Name: "Ride", ScheduledAt: &past},
		},
		{
			name:  "scheduled time too far ahead",
			input: service.CreateRideInput{Name: "Ride", ScheduledAt: &tooFarAhead},
		},
		{
			name:  "notes too long",
			input: service.CreateRideInput{Name: "Ride", Notes: tooLongNotes},
		},
		{
			name:  "cover photo URL not from our Storage bucket",
			input: service.CreateRideInput{Name: "Ride", CoverPhotoURL: "https://evil.example.com/x.jpg"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())

			_, err := svc.CreateRide(context.Background(), "host-1", tt.input)
			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != "bad_request" {
				t.Errorf("error code = %q, want %q", got, "bad_request")
			}
		})
	}
}

func TestRideService_StartRideNow(t *testing.T) {
	tests := []struct {
		name      string
		callerUID string
		seed      *model.Ride
		wantCode  string // "" means no error expected
	}{
		{
			name:      "host starts a scheduled ride",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			wantCode: "",
		},
		{
			name:      "non-host forbidden",
			callerUID: "rider-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
				HostUID: "host-1", MemberUIDs: []string{"host-1", "rider-1"},
			},
			wantCode: "forbidden",
		},
		{
			name:      "already active",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusActive,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			wantCode: "conflict",
		},
		{
			name:      "already ended",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusEnded,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			wantCode: "gone",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())
			rides.seedRide(tt.seed)

			err := svc.StartRideNow(context.Background(), tt.callerUID, "ride-1")
			if tt.wantCode == "" {
				if err != nil {
					t.Fatalf("StartRideNow returned error: %v", err)
				}
				got, getErr := rides.GetRideByID(context.Background(), "ride-1")
				if getErr != nil {
					t.Fatalf("GetRideByID returned error: %v", getErr)
				}
				if got.Status != model.RideStatusActive {
					t.Errorf("Status = %q, want %q", got.Status, model.RideStatusActive)
				}
				if !presence.present["ride-1"]["host-1"] {
					t.Errorf("expected host to be marked present after starting the ride")
				}
				return
			}

			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != tt.wantCode {
				t.Errorf("error code = %q, want %q", got, tt.wantCode)
			}
		})
	}
}

func TestRideService_UpdateRide(t *testing.T) {
	destination := &model.Destination{Name: "Cubbon Park", Lat: 12.9716, Lng: 77.5946}
	scheduledAt := time.Now().UTC().Add(24 * time.Hour)

	tests := []struct {
		name      string
		callerUID string
		seed      *model.Ride
		input     service.UpdateRideInput
		wantCode  string // "" means no error expected
	}{
		{
			name:      "host edits a scheduled ride",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
				HostUID: "host-1", MemberUIDs: []string{"host-1"}, Name: "Old name",
			},
			input: service.UpdateRideInput{
				Name: "New name", Destination: destination, ScheduledAt: &scheduledAt, Notes: "Bring water",
			},
			wantCode: "",
		},
		{
			name:      "non-host forbidden",
			callerUID: "rider-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
				HostUID: "host-1", MemberUIDs: []string{"host-1", "rider-1"},
			},
			input:    service.UpdateRideInput{Name: "New name"},
			wantCode: "forbidden",
		},
		{
			name:      "active ride can't be edited",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusActive,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			input:    service.UpdateRideInput{Name: "New name"},
			wantCode: "conflict",
		},
		{
			name:      "ended ride can't be edited",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusEnded,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			input:    service.UpdateRideInput{Name: "New name"},
			wantCode: "gone",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())
			rides.seedRide(tt.seed)

			got, err := svc.UpdateRide(context.Background(), tt.callerUID, "ride-1", tt.input)
			if tt.wantCode == "" {
				if err != nil {
					t.Fatalf("UpdateRide returned error: %v", err)
				}
				if got.Name != tt.input.Name {
					t.Errorf("Name = %q, want %q", got.Name, tt.input.Name)
				}
				if got.Destination == nil || *got.Destination != *destination {
					t.Errorf("Destination = %+v, want %+v", got.Destination, destination)
				}
				return
			}

			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != tt.wantCode {
				t.Errorf("error code = %q, want %q", got, tt.wantCode)
			}
		})
	}
}

// TestRideService_UpdateRide_ClearingScheduledTimeStartsRide covers the
// same status-derivation UpdateRide shares with CreateRide via
// validateRideInput: submitting the edit form with no scheduled time set
// (the host cleared it) flips the ride active immediately, same as
// skipping "Starts" at creation.
func TestRideService_UpdateRide_ClearingScheduledTimeStartsRide(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())
	rides.seedRide(&model.Ride{
		ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
		HostUID: "host-1", MemberUIDs: []string{"host-1"}, Name: "Ride",
	})

	got, err := svc.UpdateRide(context.Background(), "host-1", "ride-1", service.UpdateRideInput{Name: "Ride"})
	if err != nil {
		t.Fatalf("UpdateRide returned error: %v", err)
	}
	if got.Status != model.RideStatusActive {
		t.Errorf("Status = %q, want %q", got.Status, model.RideStatusActive)
	}
	if !presence.present["ride-1"]["host-1"] {
		t.Errorf("expected host to be marked present once the edit starts the ride")
	}
}

func TestRideService_UpdateRide_Validation(t *testing.T) {
	past := time.Now().UTC().Add(-time.Hour)
	tooFarAhead := time.Now().UTC().Add(2 * 365 * 24 * time.Hour)
	tooLongNotes := strings.Repeat("a", 501)

	tests := []struct {
		name  string
		input service.UpdateRideInput
	}{
		{
			name:  "scheduled time in the past",
			input: service.UpdateRideInput{Name: "Ride", ScheduledAt: &past},
		},
		{
			name:  "scheduled time too far ahead",
			input: service.UpdateRideInput{Name: "Ride", ScheduledAt: &tooFarAhead},
		},
		{
			name:  "notes too long",
			input: service.UpdateRideInput{Name: "Ride", Notes: tooLongNotes},
		},
		{
			name:  "cover photo URL not from our Storage bucket",
			input: service.UpdateRideInput{Name: "Ride", CoverPhotoURL: "https://evil.example.com/x.jpg"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())
			rides.seedRide(&model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			})

			_, err := svc.UpdateRide(context.Background(), "host-1", "ride-1", tt.input)
			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != "bad_request" {
				t.Errorf("error code = %q, want %q", got, "bad_request")
			}
		})
	}
}

func TestRideService_DeleteRide(t *testing.T) {
	tests := []struct {
		name      string
		callerUID string
		seed      *model.Ride
		wantCode  string // "" means no error expected
	}{
		{
			name:      "host deletes an ended ride",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusEnded,
				HostUID: "host-1", MemberUIDs: []string{"host-1", "rider-1"},
			},
			wantCode: "",
		},
		{
			name:      "non-host forbidden",
			callerUID: "rider-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusEnded,
				HostUID: "host-1", MemberUIDs: []string{"host-1", "rider-1"},
			},
			wantCode: "forbidden",
		},
		{
			name:      "still active",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusActive,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			wantCode: "conflict",
		},
		{
			name:      "host deletes a still-scheduled ride",
			callerUID: "host-1",
			seed: &model.Ride{
				ID: "ride-1", InviteCode: "CODE01", Status: model.RideStatusScheduled,
				HostUID: "host-1", MemberUIDs: []string{"host-1"},
			},
			wantCode: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())
			rides.seedRide(tt.seed)

			err := svc.DeleteRide(context.Background(), tt.callerUID, "ride-1")
			if tt.wantCode == "" {
				if err != nil {
					t.Fatalf("DeleteRide returned error: %v", err)
				}
				if _, getErr := rides.GetRideByID(context.Background(), "ride-1"); !errors.Is(getErr, repository.ErrNotFound) {
					t.Errorf("expected ride-1 to be gone, GetRideByID returned: %v", getErr)
				}
				if _, getErr := rides.GetRideByInviteCode(context.Background(), "CODE01"); !errors.Is(getErr, repository.ErrNotFound) {
					t.Errorf("expected invite code CODE01 to be gone, GetRideByInviteCode returned: %v", getErr)
				}
				return
			}

			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != tt.wantCode {
				t.Errorf("error code = %q, want %q", got, tt.wantCode)
			}
			// A rejected delete must leave the ride untouched.
			if _, getErr := rides.GetRideByID(context.Background(), "ride-1"); getErr != nil {
				t.Errorf("expected ride-1 to still exist after a rejected delete, GetRideByID returned: %v", getErr)
			}
		})
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

	ride, err := svc.CreateRide(context.Background(), "host-1", service.CreateRideInput{Name: "Test Ride"})
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

func TestRideService_RemoveMember(t *testing.T) {
	tests := []struct {
		name       string
		callerUID  string
		targetUID  string
		wantCode   string // "" means no error expected
	}{
		{
			name:      "host removes a rider",
			callerUID: "host-1",
			targetUID: "rider-1",
			wantCode:  "",
		},
		{
			name:      "non-host forbidden",
			callerUID: "rider-1",
			targetUID: "rider-2",
			wantCode:  "forbidden",
		},
		{
			name:      "host can't remove themself",
			callerUID: "host-1",
			targetUID: "host-1",
			wantCode:  "bad_request",
		},
		{
			name:      "target isn't a member",
			callerUID: "host-1",
			targetUID: "someone-else",
			wantCode:  "not_found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rides := newFakeRideRepository()
			presence := newFakePresenceRepository()
			svc := service.NewRideService(rides, presence, newFakeProfileRepository())

			rides.seedRide(&model.Ride{
				ID:         "ride-1",
				InviteCode: "CODE01",
				Status:     model.RideStatusActive,
				HostUID:    "host-1",
				MemberUIDs: []string{"host-1", "rider-1", "rider-2"},
			})

			err := svc.RemoveMember(context.Background(), tt.callerUID, "ride-1", tt.targetUID)
			if tt.wantCode == "" {
				if err != nil {
					t.Fatalf("RemoveMember returned error: %v", err)
				}
				got, getErr := rides.GetRideByID(context.Background(), "ride-1")
				if getErr != nil {
					t.Fatalf("GetRideByID returned error: %v", getErr)
				}
				if slices.Contains(got.MemberUIDs, tt.targetUID) {
					t.Errorf("expected %q to be removed from MemberUIDs, got %v", tt.targetUID, got.MemberUIDs)
				}
				if presence.present["ride-1"][tt.targetUID] {
					t.Errorf("expected %q to be marked absent in presence repo", tt.targetUID)
				}
				return
			}

			if err == nil {
				t.Fatalf("expected an error, got nil")
			}
			if got := appErrorCode(t, err); got != tt.wantCode {
				t.Errorf("error code = %q, want %q", got, tt.wantCode)
			}
		})
	}
}

func TestRideService_EndRide_NonHostForbidden(t *testing.T) {
	rides := newFakeRideRepository()
	presence := newFakePresenceRepository()
	svc := service.NewRideService(rides, presence, newFakeProfileRepository())

	ride, err := svc.CreateRide(context.Background(), "host-1", service.CreateRideInput{Name: "Test Ride"})
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
