package model

import (
	"crypto/rand"
	"math/big"
	"time"
)

// RideStatus is a ride's lifecycle state.
type RideStatus string

const (
	RideStatusActive RideStatus = "active"
	RideStatusEnded  RideStatus = "ended"
)

// Destination is the pin shown on the map for everyone in the ride — not
// a route, just a marker (see internal/dto's DestinationDTO, its wire
// representation).
type Destination struct {
	Name string  `firestore:"name"`
	Lat  float64 `firestore:"lat"`
	Lng  float64 `firestore:"lng"`
}

// Ride mirrors the rides/{id} Firestore document.
type Ride struct {
	ID          string       `firestore:"-"`
	Name        string       `firestore:"name"`
	HostUID     string       `firestore:"hostUid"`
	InviteCode  string       `firestore:"inviteCode"`
	Status      RideStatus   `firestore:"status"`
	MemberUIDs  []string     `firestore:"memberUids"`
	Destination *Destination `firestore:"destination,omitempty"`
	CreatedAt   time.Time    `firestore:"createdAt"`
	EndedAt     *time.Time   `firestore:"endedAt,omitempty"`
}

const (
	// inviteCodeAlphabet excludes visually ambiguous characters (O/0, I/1).
	inviteCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	inviteCodeLength   = 6
)

// NewInviteCode generates a random 6-character invite code.
func NewInviteCode() (string, error) {
	code := make([]byte, inviteCodeLength)
	alphabetSize := big.NewInt(int64(len(inviteCodeAlphabet)))

	for i := range code {
		n, err := rand.Int(rand.Reader, alphabetSize)
		if err != nil {
			return "", err
		}
		code[i] = inviteCodeAlphabet[n.Int64()]
	}

	return string(code), nil
}
