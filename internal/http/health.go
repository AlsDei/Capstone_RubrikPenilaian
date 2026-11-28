// Package http berisi router, handler, dan middleware (E1).
// Handler hanya decode -> panggil service -> encode, tanpa aturan bisnis.
package http

import (
	"context"
	"encoding/json"
	"net/http"
	"time"
)

// Pinger dipenuhi oleh *sql.DB; dipisah sebagai interface agar mudah dites.
type Pinger interface {
	PingContext(ctx context.Context) error
}

// healthTimeout: batas pemeriksaan database (E10: SELECT 1, batas 2 detik).
const healthTimeout = 2 * time.Second

// HealthHandler melayani GET /healthz (BASE-09):
// 200 bila proses hidup dan database terjangkau, 503 bila database tidak terjangkau.
func HealthHandler(db Pinger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), healthTimeout)
		defer cancel()

		status, body := http.StatusOK, map[string]string{"status": "ok"}
		if err := db.PingContext(ctx); err != nil {
			status, body = http.StatusServiceUnavailable, map[string]string{"status": "database tidak terjangkau"}
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_ = json.NewEncoder(w).Encode(body)
	}
}
