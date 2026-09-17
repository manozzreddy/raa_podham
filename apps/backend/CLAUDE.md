# Raa Podham Backend

Go HTTP API (Cloud Run) backing the mobile app — Firebase Auth for
identity, Firestore for durable ride/profile data, Realtime Database for
live position/presence, Cloud Storage for ride cover photos. Fronted by
`chi`.

## Layers

Three layers, one direction of dependency:

```
handler  →  service  →  repository (interface)
                              ↑
                    concrete impl (Firestore*/RTDB*/Firebase*)
```

- **`internal/handler`** — the thin HTTP layer. Decode the request, pull
  the caller's uid from context, call the matching service method,
  encode the response. No business logic here — see
  `handler/ride_handler.go`'s own package doc comment. Every handler
  method follows the same shape:

  ```go
  func (h *RideHandler) EndRide(w http.ResponseWriter, r *http.Request) {
      uid, ok := middleware.UIDFromContext(r.Context())
      if !ok {
          respondError(w, apperror.Forbidden("missing authenticated user"))
          return
      }

      rideID := chi.URLParam(r, "id")
      if err := h.rides.EndRide(r.Context(), uid, rideID); err != nil {
          respondError(w, err)
          return
      }

      w.WriteHeader(http.StatusNoContent)
  }
  ```

  `respondJSON`/`respondError` (defined once in `ride_handler.go`, shared
  across the package) are the only way a handler writes a response.

- **`internal/service`** — business logic and authorization checks
  (host-only, status transitions, validation). Depends only on
  `repository` **interfaces**, never a concrete `Firestore*`/`RTDB*`/
  `Firebase*` type — see `service/ride_service.go`'s package doc comment.
  This is what makes services testable against hand-written fakes
  instead of real Firestore/RTDB (see Testing below), and is the seam a
  different backing store could drop into later without touching this
  layer. A service method returns `*apperror.AppError` (via
  `apperror.BadRequest`/`NotFound`/`Forbidden`/`Conflict`/`Gone`/`Internal`),
  never a bare `error` — `apperror.Internal(err)` logs the real error
  server-side and hands the handler a generic message to show the
  client.

- **`internal/repository`** — one file per concern declares the
  interface (`ride_repository.go`, `profile_repository.go`,
  `auth_repository.go`, `storage_repository.go`, `presence_repository.go`),
  and a same-package `Firestore*`/`RTDB*`/`Firebase*` file implements it
  against the real SDK. These are **the only files allowed to import**
  `cloud.google.com/go/firestore`, `firebase.google.com/go/v4/*`, or
  `cloud.google.com/go/storage` directly.

**`cmd/api/main.go` is the only place in the codebase allowed to
reference a concrete repository/client type** — it's where every
`New*Client`/`NewFirestore*Repository`/`New*Service`/`New*Handler` call
happens, wired together and handed to `server.NewRouter`. Nothing above
main.go should import `firebaseapp` or a concrete repository type.

## Errors

`internal/apperror` is the only way a service signals a failure that
should reach the client as something other than a generic 500 —
`BadRequest`, `NotFound(resource)`, `Forbidden(msg)`, `Conflict(msg)`,
`Gone(msg)`, or `Internal(err)` for anything unexpected. `respondError`
(in `handler/ride_handler.go`) type-switches on `*apperror.AppError` to
pick the right HTTP status; anything else falls back to a bare 500 with
no detail leaked to the client.

## Routing

All routes are declared in one place, `internal/server/router.go`.
`/healthz` and `/health` (both registered — something on the network
path drops the trailing "z" in transit) are the only unauthenticated
routes; everything else sits behind `appmiddleware.Auth(authClient)`,
which verifies the Firebase ID token and stores the caller's uid in
context (`middleware.UIDFromContext`). `Recovery`, `Logging`, and `CORS`
apply globally, in that order, ahead of the auth-gated group.

## Testing

Service-layer tests (`service/*_test.go`, package `service_test`) use
hand-written in-memory fakes for each repository interface
(`fakeRideRepository`, `fakePresenceRepository`, `fakeProfileRepository`,
`fakeStorageRepository`, `fakeAuthRepository`) rather than a real
Firestore/RTDB — that's the whole point of the service layer depending
only on interfaces. Fakes for the same interface are shared across test
files in the package (e.g. `user_service_test.go` reuses
`fakeRideRepository` from `ride_service_test.go`) — check for an
existing fake before writing a new one. `appErrorCode(t, err)` asserts
which `apperror` code a returned error carries.

## `model` vs `dto`

`internal/model` mirrors what's actually stored (a Firestore document
shape, e.g. `model.Ride` ↔ `rides/{id}`). `internal/dto` is the JSON
wire shape a handler decodes/encodes, kept as a separate type
specifically so the wire format can evolve independently of the storage
shape — a handler converts between them (see `dto.FromRide`), a service
never imports `dto`.
