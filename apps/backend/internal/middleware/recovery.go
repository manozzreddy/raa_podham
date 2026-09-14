package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"
)

// Recovery recovers from a panic in a handler, logs it, and responds 500
// instead of crashing the server.
func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				slog.Error("panic recovered", "error", rec, "path", r.URL.Path, "stack", string(debug.Stack()))
				http.Error(w, "something went wrong", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
