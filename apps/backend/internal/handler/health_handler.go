package handler

import "net/http"

// Health responds 200 OK — used for Cloud Run's health checks. Not
// behind auth.
func Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok"))
}
