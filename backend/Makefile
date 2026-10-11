VERSION ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)
IMAGE   ?= ghcr.io/krisna-achmad31/riung-api

.PHONY: build test test-integration vet lint vuln run migrate docker dev-up dev-down

build:
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X main.version=$(VERSION)" -o bin/riung ./cmd/riung

test:
	go test -race ./...

# Needs a Postgres superuser URL. Against the dev compose stack (make dev-up):
#   make test-integration
RIUNG_TEST_DATABASE_URL      ?= postgres://postgres:postgres_dev@127.0.0.1:55432/postgres?sslmode=disable
RIUNG_TEST_MIGRATOR_PASSWORD ?= riung_migrator_dev_pw
RIUNG_TEST_APP_PASSWORD      ?= riung_app_dev_pw_local
test-integration:
	@RIUNG_TEST_DATABASE_URL="$(RIUNG_TEST_DATABASE_URL)" \
	RIUNG_TEST_MIGRATOR_PASSWORD="$(RIUNG_TEST_MIGRATOR_PASSWORD)" \
	RIUNG_TEST_APP_PASSWORD="$(RIUNG_TEST_APP_PASSWORD)" \
	go test -race -count=1 ./...

vet:
	go vet ./...
	test -z "$$(gofmt -l .)"

lint:
	golangci-lint run ./...

vuln:
	govulncheck ./...

run: build
	./bin/riung api

migrate: build
	./bin/riung migrate up

docker:
	docker build --build-arg VERSION=$(VERSION) -t $(IMAGE):$(VERSION) .

dev-up:
	docker compose -f deploy/docker-compose.yml up --build

dev-down:
	docker compose -f deploy/docker-compose.yml down
