package model

// UserProfile mirrors the users/{uid} Firestore document, written by the
// mobile app right after sign-in (features/auth/data/user_profile_repository.dart).
type UserProfile struct {
	UID         string `firestore:"-"`
	DisplayName string `firestore:"displayName"`
	PhotoURL    string `firestore:"photoUrl"`
}
