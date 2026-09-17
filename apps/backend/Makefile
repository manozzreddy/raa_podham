.PHONY: run watch test build lint

run:
	go run ./cmd/api

# Rebuilds and restarts the API on every saved .go file change, per
# .air.toml. Requires air: go install github.com/air-verse/air@latest
watch:
	air

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
