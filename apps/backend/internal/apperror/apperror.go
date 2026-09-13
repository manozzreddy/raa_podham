// Package apperror defines the typed errors that flow up from the
// service layer to the handler layer, carrying enough information for a
// handler to produce the right HTTP response without knowing which
// layer raised the error.
package apperror

import (
	"fmt"
	"log/slog"
	"net/http"
)

type AppError struct {
	Code       string
	Message    string
	HTTPStatus int
}

func (e *AppError) Error() string { return e.Message }

func BadRequest(msg string) *AppError {
	return &AppError{
		Code:       "bad_request",
		Message:    msg,
		HTTPStatus: http.StatusBadRequest,
	}
}

func NotFound(resource string) *AppError {
	return &AppError{
		Code:       "not_found",
		Message:    fmt.Sprintf("%s not found", resource),
		HTTPStatus: http.StatusNotFound,
	}
}

func Forbidden(msg string) *AppError {
	return &AppError{
		Code:       "forbidden",
		Message:    msg,
		HTTPStatus: http.StatusForbidden,
	}
}

func Conflict(msg string) *AppError {
	return &AppError{
		Code:       "conflict",
		Message:    msg,
		HTTPStatus: http.StatusConflict,
	}
}

func Gone(msg string) *AppError {
	return &AppError{
		Code:       "gone",
		Message:    msg,
		HTTPStatus: http.StatusGone,
	}
}

// Internal wraps an unexpected error. The real error is logged
// server-side; the client only ever sees a generic message.
func Internal(err error) *AppError {
	slog.Error("internal error", "error", err)
	return &AppError{
		Code:       "internal",
		Message:    "something went wrong",
		HTTPStatus: http.StatusInternalServerError,
	}
}
