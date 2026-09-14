// Package service holds the app's business logic. It depends only on
// the repository interfaces (never a concrete *_repository.go type),
// which is what makes it testable with hand-written fakes instead of a
// real Firestore/RTDB.
package service

import (
	"context"
	"errors"
	"slices"
	"time"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

type RideService struct {
	rides    repository.RideRepository
	presence repository.PresenceRepository
	profiles repository.ProfileRepository
}

func NewRideService(rides repository.RideRepository, presence repository.PresenceRepository, profiles repository.ProfileRepository) *RideService {
	return &RideService{rides: rides, presence: presence, profiles: profiles}
}

func (s *RideService) CreateRide(ctx context.Context, hostUID, name string, destination *model.Destination) (*model.Ride, error) {
	code, err := model.NewInviteCode()
	if err != nil {
		return nil, apperror.Internal(err)
	}

	now := time.Now().UTC()
	ride := &model.Ride{
		Name:        name,
		HostUID:     hostUID,
		InviteCode:  code,
		Status:      model.RideStatusActive,
		MemberUIDs:  []string{hostUID},
		Destination: destination,
		CreatedAt:   now,
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
	if err := s.presence.SetMember(ctx, ride.ID, hostUID, true); err != nil {
		return nil, apperror.Internal(err)
	}

	return ride, nil
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
