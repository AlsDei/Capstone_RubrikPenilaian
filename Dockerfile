# Citra dua tahap, pengguna nonroot (E10).
# Tahap 1: kompilasi. Tahap 2: citra kecil hanya berisi biner server, biner seed, dan data seed.
ARG GO_VERSION=1.24

FROM golang:${GO_VERSION}-alpine AS build
ARG MAIN_PKG=./cmd/server
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ${MAIN_PKG} \
 && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/seed ./cmd/seed

FROM alpine:3.20
# tzdata: zona waktu bisnis WIB (Kamus Data bagian 7); ca-certificates untuk koneksi keluar bila ada
RUN apk add --no-cache ca-certificates tzdata \
 && adduser -D -H -u 10001 app
WORKDIR /app
COPY --from=build /out/server /out/seed ./
COPY db/seed ./db/seed
# "docker compose run --rm app seed" menjalankan impor CSV; tanpa argumen menjalankan server
RUN printf '#!/bin/sh\nset -e\nif [ "$1" = "seed" ]; then shift; exec /app/seed "$@"; fi\nexec /app/server "$@"\n' > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh
ENV TZ=Asia/Jakarta
USER app
EXPOSE 8080
ENTRYPOINT ["/app/entrypoint.sh"]