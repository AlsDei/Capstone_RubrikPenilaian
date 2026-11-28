// Package config membaca konfigurasi dari variabel lingkungan (E1, E5).
package config

import (
	"fmt"
	"os"
)

// Config berisi seluruh pengaturan runtime aplikasi.
type Config struct {
	HTTPAddr           string // alamat dengar di dalam container (selalu :8080)
	DatabaseURL        string
	JWTSecret          string
	CORSAllowedOrigins string
}

// Load membaca env dan gagal bila ada nilai wajib yang kosong.
// Rahasia hanya boleh datang dari env, tidak pernah dari berkas di repo.
func Load() (Config, error) {
	c := Config{
		HTTPAddr:           getenv("HTTP_ADDR", ":8080"),
		DatabaseURL:        os.Getenv("DATABASE_URL"),
		JWTSecret:          os.Getenv("JWT_SECRET"),
		CORSAllowedOrigins: getenv("CORS_ALLOWED_ORIGINS", "http://localhost:3110"),
	}
	if c.DatabaseURL == "" {
		return Config{}, fmt.Errorf("DATABASE_URL wajib diisi")
	}
	if c.JWTSecret == "" {
		return Config{}, fmt.Errorf("JWT_SECRET wajib diisi")
	}
	return c, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
