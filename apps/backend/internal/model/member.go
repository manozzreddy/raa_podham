package model

import "time"

// MemberRole distinguishes a ride's host from its regular riders.
type MemberRole string

const (
	MemberRoleHost  MemberRole = "host"
	MemberRoleRider MemberRole = "rider"
)

// Member mirrors a rides/{id}/members/{uid} Firestore document.
type Member struct {
	UID         string     `firestore:"-"`
	DisplayName string     `firestore:"displayName"`
	PhotoURL    string     `firestore:"photoUrl"`
	JoinedAt    time.Time  `firestore:"joinedAt"`
	Role        MemberRole `firestore:"role"`
}
