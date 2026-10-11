# syntax=docker/dockerfile:1
# Riung backend: one static binary on distroless (no shell, runs as nonroot).
# Base images are pinned by digest; Dependabot proposes updates.

FROM golang:1.27.2-alpine@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /out/riung ./cmd/riung

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/riung /riung
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/riung"]
CMD ["api"]
