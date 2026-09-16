// Package service holds the app's business logic. It depends only on
// the repository interfaces (never a concrete *_repository.go type),
// which is what makes it testable with hand-written fakes instead of a
// real Firestore/RTDB.
package service

import (
	"context"
	"errors"
	"slices"
	"strings"
	"time"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

// maxNotesLength bounds how long a ride's free-text notes can be — nothing
// upstream (the mobile form) enforces this today, so the service is the one
// place it's actually guaranteed.
const maxNotesLength = 500

// maxScheduledAhead bounds how far in the future a ride can be scheduled —
// generous enough for real planning, tight enough to catch a client-side
// date-math bug (e.g. a stray year) before it reaches Firestore.
const maxScheduledAhead = 365 * 24 * time.Hour

// scheduledClockSkewTolerance forgives a small amount of client/server clock
// drift when checking whether a ScheduledAt is "in the past" — a time that's
// only a few seconds behind now almost always means "start immediately" was
// intended, not that the request is actually invalid.
const scheduledClockSkewTolerance = time.Minute

// coverPhotoURLPrefix is what every legitimate CoverPhotoURL must start
// with — this app's own Firebase Storage bucket. CoverPhotoURL is the only
// field the client hands the backend that gets rendered back out as an
// image to every ride member, so unlike free-text fields it's worth
// rejecting anything that isn't obviously one of our own uploads.
const coverPhotoURLPrefix = "https://firebasestorage.googleapis.com/"

type RideService struct {
	rides    repository.RideRepository
	presence repository.PresenceRepository
	profiles repository.ProfileRepository
}

func NewRideService(rides repository.RideRepository, presence repository.PresenceRepository, profiles repository.ProfileRepository) *RideService {
	return &RideService{rides: rides, presence: presence, profiles: profiles}
}

// CreateRideInput bundles CreateRide's ride-content fields — kept out of the
// positional parameter list because several are adjacent bare strings
// (Name, Notes, CoverPhotoURL) that positional args alone don't protect
// against transposing.
type CreateRideInput struct {
	Name          string
	Destination   *model.Destination
	ScheduledAt   *time.Time
	Notes         string
	CoverPhotoURL string
}

func (s *RideService) CreateRide(ctx context.Context, hostUID string, input CreateRideInput) (*model.Ride, error) {
	if len(input.Notes) > maxNotesLength {
		return nil, apperror.BadRequest("notes are too long")
	}
	if input.CoverPhotoURL != "" && !strings.HasPrefix(input.CoverPhotoURL, coverPhotoURLPrefix) {
		return nil, apperror.BadRequest("cover photo URL is not valid")
	}

	code, err := model.NewInviteCode()
	if err != nil {
		return nil, apperror.Internal(err)
	}

	now := time.Now().UTC()
	status := model.RideStatusActive
	if input.ScheduledAt != nil {
		if input.ScheduledAt.Before(now.Add(-scheduledClockSkewTolerance)) {
			return nil, apperror.BadRequest("scheduled time is in the past")
		}
		if input.ScheduledAt.After(now.Add(maxScheduledAhead)) {
			return nil, apperror.BadRequest("scheduled time is too far in the future")
		}
		if input.ScheduledAt.After(now) {
			status = model.RideStatusScheduled
		}
	}

	ride := &model.Ride{
		Name:          input.Name,
		HostUID:       hostUID,
		InviteCode:    code,
		Status:        status,
		MemberUIDs:    []string{hostUID},
		Destination:   input.Destination,
		ScheduledAt:   input.ScheduledAt,
		Notes:         input.Notes,
		CoverPhotoURL: input.CoverPhotoURL,
		CreatedAt:     now,
	}
	host := &model.Member{
		UID:      hostUID,
		JoinedAt: now,
		Role:     model.MemberRoleHost,
	}
	s.applyProfile(ctx, host)

	if err := s.rides.CreateRide(ctx, ride, host); err != nil {
		return nil, apperror.Internal(err)
	}
	// A scheduled ride's host isn't sharing their location yet — presence
	// (and so the mobile app's live-reporting UI) only turns on once the
	// ride actually starts, either here for an immediate ride or in
	// StartRideNow for one that was scheduled.
	if status == model.RideStatusActive {
		if err := s.presence.SetMember(ctx, ride.ID, hostUID, true); err != nil {
			return nil, apperror.Internal(err)
		}
	}

	return ride, nil
}

// StartRideNow lets the host skip the wait on a scheduled ride and go live
// immediately — the host-only mirror of EndRide, and the only other place
// (besides CreateRide) a ride's presence gets armed.
func (s *RideService) StartRideNow(ctx context.Context, hostUID, rideID string) error {
	ride, err := s.rides.GetRideByID(ctx, rideID)
	if errors.Is(err, repository.ErrNotFound) {
		return apperror.NotFound("ride")
	}
	if err != nil {
		return apperror.Internal(err)
	}

	if hostUID != ride.HostUID {
		return apperror.Forbidden("only the host can start this ride")
	}

	switch ride.Status {
	case model.RideStatusEnded:
		return apperror.Gone("this ride has ended")
	case model.RideStatusActive:
		return apperror.Conflict("this ride has already started")
	}

	if err := s.rides.StartRide(ctx, rideID); err != nil {
		return apperror.Internal(err)
	}
	// Symmetric to EndRide's presence.ClearRide below — this is the moment
	// the host's device actually starts being expected to report a position.
	if err := s.presence.SetMember(ctx, rideID, hostUID, true); err != nil {
		return apperror.Internal(err)
	}
	return nil
}

// DeleteRide permanently removes an ended ride and everything tied to it
// — Firestore (the ride doc, its members subcollection, and its invite
// code lookup), and the Realtime Database. Host-only, and only for a ride
// that's actually over: this is a one-way cleanup action, not a way to
// cancel one still in progress (EndRide is that).
func (s *RideService) DeleteRide(ctx context.Context, hostUID, rideID string) error {
	ride, err := s.rides.GetRideByID(ctx, rideID)
	if errors.Is(err, repository.ErrNotFound) {
		return apperror.NotFound("ride")
	}
	if err != nil {
		return apperror.Internal(err)
	}

	if hostUID != ride.HostUID {
		return apperror.Forbidden("only the host can delete this ride")
	}
	if ride.Status != model.RideStatusEnded {
		return apperror.Conflict("only a ride that has ended can be deleted")
	}

	if err := s.rides.DeleteRide(ctx, rideID, ride.InviteCode); err != nil {
		return apperror.Internal(err)
	}
	// EndRide already clears this rides/{id} subtree in the Realtime
	// Database when the ride ends, so this is normally a no-op by the
	// time a ride can even be deleted — kept as a defensive safety net
	// for a ride whose earlier clear failed, or one that predates that
	// cleanup existing at all.
	if err := s.presence.ClearRide(ctx, rideID); err != nil {
		return apperror.Internal(err)
	}
	return nil
}

func (s *RideService) JoinRide(ctx context.Context, uid, inviteCode string) (*model.Ride, error) {
	ride, err := s.rides.GetRideByInviteCode(ctx, inviteCode)
	if errors.Is(err, repository.ErrNotFound) {
		return nil, apperror.NotFound("ride")
	}
	if err != nil {
		return nil, apperror.Internal(err)
	}

	if ride.Status == model.RideStatusEnded {
		return nil, apperror.Gone("this ride has ended")
	}

	if slices.Contains(ride.MemberUIDs, uid) {
		return nil, apperror.Conflict("already a member of this ride")
	}

	member := &model.Member{
		UID:      uid,
		JoinedAt: time.Now().UTC(),
		Role:     model.MemberRoleRider,
	}
	s.applyProfile(ctx, member)

	if err := s.rides.AddMember(ctx, ride.ID, member); err != nil {
		return nil, apperror.Internal(err)
	}
	if err := s.presence.SetMember(ctx, ride.ID, uid, true); err != nil {
		return nil, apperror.Internal(err)
	}

	ride.MemberUIDs = append(ride.MemberUIDs, uid)
	return ride, nil
}

func (s *RideService) LeaveRide(ctx context.Context, uid, rideID string) error {
	ride, err := s.rides.GetRideByID(ctx, rideID)
	if errors.Is(err, repository.ErrNotFound) {
		return apperror.NotFound("ride")
	}
	if err != nil {
		return apperror.Internal(err)
	}

	if uid == ride.HostUID {
		return s.EndRide(ctx, uid, rideID)
	}

	if err := s.rides.RemoveMember(ctx, rideID, uid); err != nil {
		return apperror.Internal(err)
	}
	if err := s.presence.SetMember(ctx, rideID, uid, false); err != nil {
		return apperror.Internal(err)
	}
	return nil
}

func (s *RideService) EndRide(ctx context.Context, uid, rideID string) error {
	ride, err := s.rides.GetRideByID(ctx, rideID)
	if errors.Is(err, repository.ErrNotFound) {
		return apperror.NotFound("ride")
	}
	if err != nil {
		return apperror.Internal(err)
	}

	if uid != ride.HostUID {
		return apperror.Forbidden("only the host can end this ride")
	}

	if err := s.rides.EndRide(ctx, rideID); err != nil {
		return apperror.Internal(err)
	}
	if err := s.presence.ClearRide(ctx, rideID); err != nil {
		return apperror.Internal(err)
	}
	return nil
}

// RemoveMember lets the host evict a rider mid-ride — anyone else calling
// this gets Forbidden, and the host can't target themself (EndRide is the
// host's own way off the ride) or someone who isn't currently a member.
func (s *RideService) RemoveMember(ctx context.Context, hostUID, rideID, targetUID string) error {
	ride, err := s.rides.GetRideByID(ctx, rideID)
	if errors.Is(err, repository.ErrNotFound) {
		return apperror.NotFound("ride")
	}
	if err != nil {
		return apperror.Internal(err)
	}

	if hostUID != ride.HostUID {
		return apperror.Forbidden("only the host can remove a rider")
	}
	if targetUID == ride.HostUID {
		return apperror.BadRequest("the host can't remove themself — end the ride instead")
	}

	if !slices.Contains(ride.MemberUIDs, targetUID) {
		return apperror.NotFound("member")
	}

	if err := s.rides.RemoveMember(ctx, rideID, targetUID); err != nil {
		return apperror.Internal(err)
	}
	// Sets present:false in the RTDB presence mirror, which
	// database.rules.json's positions write rule now also checks — this
	// is what actually stops the removed rider's device from continuing
	// to write its position after this call, not just a display flag.
	if err := s.presence.SetMember(ctx, rideID, targetUID, false); err != nil {
		return apperror.Internal(err)
	}
	return nil
}

// applyProfile fills in a member's displayName/photoUrl from their user
// profile, if one has been written yet. Best-effort: a missing or
// not-yet-written profile just leaves the member with an empty name
// (the mobile app falls back to "Rider") rather than failing the whole
// create/join request over it.
func (s *RideService) applyProfile(ctx context.Context, member *model.Member) {
	profile, err := s.profiles.GetProfile(ctx, member.UID)
	if err != nil {
		return
	}
	member.DisplayName = profile.DisplayName
	member.PhotoURL = profile.PhotoURL
}
