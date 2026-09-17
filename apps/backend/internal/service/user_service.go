package service

import (
	"context"
	"log/slog"
	"time"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

type UserService struct {
	rides    repository.RideRepository
	presence repository.PresenceRepository
	profiles repository.ProfileRepository
	storage  repository.StorageRepository
	auth     repository.AuthRepository
}

func NewUserService(
	rides repository.RideRepository,
	presence repository.PresenceRepository,
	profiles repository.ProfileRepository,
	storage repository.StorageRepository,
	auth repository.AuthRepository,
) *UserService {
	return &UserService{
		rides:    rides,
		presence: presence,
		profiles: profiles,
		storage:  storage,
		auth:     auth,
	}
}

// MyRides splits a user's rides into active, upcoming (scheduled but not
// yet started), and past.
type MyRides struct {
	Active   []*model.Ride
	Upcoming []*model.Ride
	Past     []*model.Ride
}

func (s *UserService) ListMyRides(ctx context.Context, uid string) (*MyRides, error) {
	rides, err := s.rides.ListRidesForUser(ctx, uid)
	if err != nil {
		return nil, apperror.Internal(err)
	}

	result := &MyRides{}
	for _, ride := range rides {
		switch ride.Status {
		case model.RideStatusEnded:
			result.Past = append(result.Past, ride)
		case model.RideStatusScheduled:
			result.Upcoming = append(result.Upcoming, ride)
		default:
			result.Active = append(result.Active, ride)
		}
	}
	return result, nil
}

// DeleteAccount permanently removes uid and everything tied to it: every
// ride they host is force-ended (if still live) and deleted outright,
// same outcome as the host doing it themselves via EndRide+DeleteRide;
// every ride they merely ride in just loses their own membership, same
// as LeaveRide. This is deliberately reimplemented at the repository
// level rather than calling into RideService — that service's host/status
// checks exist to authorize an external caller against one ride, which
// doesn't apply here since uid is derived from each ride's own data, and
// UserService depending on RideRepository/PresenceRepository directly
// (like RideService itself does) avoids a new service-on-service
// dependency.
func (s *UserService) DeleteAccount(ctx context.Context, uid string) error {
	start := time.Now()

	rides, err := s.rides.ListRidesForUser(ctx, uid)
	if err != nil {
		return apperror.Internal(err)
	}
	slog.Info("delete account: rides listed", "uid", uid, "rideCount", len(rides), "elapsed", time.Since(start))

	ridesStart := time.Now()
	for _, ride := range rides {
		rideStart := time.Now()
		if ride.HostUID == uid {
			if ride.Status != model.RideStatusEnded {
				if err := s.rides.EndRide(ctx, ride.ID); err != nil {
					return apperror.Internal(err)
				}
				if err := s.presence.ClearRide(ctx, ride.ID); err != nil {
					return apperror.Internal(err)
				}
			}
			if err := s.rides.DeleteRide(ctx, ride.ID, ride.InviteCode); err != nil {
				return apperror.Internal(err)
			}
			// Defensive, same as RideService.DeleteRide: normally a
			// no-op by now since EndRide (or an earlier EndRide) already
			// cleared this rides/{id} RTDB subtree.
			if err := s.presence.ClearRide(ctx, ride.ID); err != nil {
				return apperror.Internal(err)
			}
		} else {
			if err := s.rides.RemoveMember(ctx, ride.ID, uid); err != nil {
				return apperror.Internal(err)
			}
			if err := s.presence.SetMember(ctx, ride.ID, uid, false); err != nil {
				return apperror.Internal(err)
			}
		}
		slog.Info("delete account: ride cleaned up",
			"uid", uid, "rideId", ride.ID, "isHost", ride.HostUID == uid,
			"elapsed", time.Since(rideStart))
	}
	slog.Info("delete account: all rides cleaned up", "uid", uid, "rideCount", len(rides), "elapsed", time.Since(ridesStart))

	storageStart := time.Now()
	if err := s.storage.DeleteAllForUser(ctx, uid); err != nil {
		return apperror.Internal(err)
	}
	slog.Info("delete account: storage cleaned up", "uid", uid, "elapsed", time.Since(storageStart))

	profileStart := time.Now()
	if err := s.profiles.DeleteProfile(ctx, uid); err != nil {
		return apperror.Internal(err)
	}
	slog.Info("delete account: profile deleted", "uid", uid, "elapsed", time.Since(profileStart))

	// Last: once this succeeds the caller's ID token no longer maps to a
	// real account, so an earlier partial failure should be retried
	// (the auth account, and so the caller's ability to retry, is still
	// intact) rather than left half-deleted.
	authStart := time.Now()
	if err := s.auth.DeleteUser(ctx, uid); err != nil {
		return apperror.Internal(err)
	}
	slog.Info("delete account: auth user deleted", "uid", uid, "elapsed", time.Since(authStart))

	slog.Info("delete account: done", "uid", uid, "totalElapsed", time.Since(start))
	return nil
}
