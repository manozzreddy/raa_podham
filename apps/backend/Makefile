.PHONY: run test build lint

run:
	go run ./cmd/api

test:
	go test ./...

build:
	go build ./...

lint:
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed, skipping"; \
	fi
