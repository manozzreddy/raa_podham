package middleware

import (
	"context"
	"log/slog"
	"net/http"
	"strings"

	"firebase.google.com/go/v4/auth"
)

// ctxKey is unexported so context keys from this package can never
// collide with a key from any other package.
type ctxKey int

const uidKey ctxKey = iota

// Auth verifies the Firebase ID token in the Authorization header and
// stores the caller's UID in the request context for downstream
// handlers to read via UIDFromContext.
func Auth(authClient *auth.Client) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			token := strings.TrimPrefix(header, "Bearer ")
			if token == "" || token == header {
				slog.Warn("auth rejected: no bearer token on request", "path", r.URL.Path, "hasAuthHeader", header != "")
				http.Error(w, "missing bearer token", http.StatusUnauthorized)
				return
			}

			decoded, err := authClient.VerifyIDToken(r.Context(), token)
			if err != nil {
				slog.Warn("auth rejected: token verification failed", "path", r.URL.Path, "error", err)
				http.Error(w, "invalid or expired token", http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), uidKey, decoded.UID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// UIDFromContext returns the authenticated caller's UID, as set by Auth.
func UIDFromContext(ctx context.Context) (string, bool) {
	uid, ok := ctx.Value(uidKey).(string)
	return uid, ok
}
