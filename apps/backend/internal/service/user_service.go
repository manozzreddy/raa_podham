package service

import (
	"context"

	"github.com/dynamicarraytech/raa-podham/backend/internal/apperror"
	"github.com/dynamicarraytech/raa-podham/backend/internal/model"
	"github.com/dynamicarraytech/raa-podham/backend/internal/repository"
)

type UserService struct {
	rides repository.RideRepository
}

func NewUserService(rides repository.RideRepository) *UserService {
	return &UserService{rides: rides}
}

// MyRides splits a user's rides into active and past.
type MyRides struct {
	Active []*model.Ride
	Past   []*model.Ride
}

func (s *UserService) ListMyRides(ctx context.Context, uid string) (*MyRides, error) {
	rides, err := s.rides.ListRidesForUser(ctx, uid)
	if err != nil {
		return nil, apperror.Internal(err)
	}

	result := &MyRides{}
	for _, ride := range rides {
		if ride.Status == model.RideStatusEnded {
			result.Past = append(result.Past, ride)
		} else {
			result.Active = append(result.Active, ride)
		}
	}
	return result, nil
}
