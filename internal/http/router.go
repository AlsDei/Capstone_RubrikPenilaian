package http

import "net/http"

// NewRouter merangkai semua rute. Rute lain (auth, rubrik, penugasan, hasil, ...)
// ditambahkan di sini seiring pengerjaan; jangan lupa perbarui openapi.yaml (BASE-07).
func NewRouter(db Pinger) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", HealthHandler(db))
	return mux
}
