// Program seed: impor CSV akun, kelompok, dan anggota (BASE-01, BASE-04).
//
//	docker compose run --rm app seed
//
// Env: DATABASE_URL (wajib), SEED_PASSWORD (wajib, 8-72 byte; kata sandi semua akun seed),
// SEED_DIR (opsional, default db/seed). Kode keluar 0 bila semua baris masuk atau dilewati,
// 1 bila ada kegagalan fatal, 2 bila ada baris rusak (sisanya tetap masuk).
package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib" // driver "pgx" untuk database/sql
	"golang.org/x/crypto/bcrypt"

	"github.com/AlsDei/Capstone_RubrikPenilaian/internal/seed"
)

func main() { os.Exit(run()) }

func run() int {
	dsn := os.Getenv("DATABASE_URL")
	pw := os.Getenv("SEED_PASSWORD")
	dir := os.Getenv("SEED_DIR")
	if dir == "" {
		dir = "db/seed"
	}
	if dsn == "" {
		return gagal("DATABASE_URL wajib diisi")
	}
	if len(pw) < 8 || len(pw) > 72 {
		return gagal("SEED_PASSWORD wajib diisi (8-72 byte; batas 72 dari bcrypt)")
	}

	// Satu hash dipakai semua akun seed: cukup untuk data fiktif dan jauh lebih cepat.
	hash, err := bcrypt.GenerateFromPassword([]byte(pw), 10)
	if err != nil {
		return gagal("hash gagal: %v", err)
	}

	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return gagal("buka database: %v", err)
	}
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		return gagal("database tidak terjangkau: %v", err)
	}

	hasil, err := seed.Run(ctx, seed.NewDB(db), os.DirFS(dir), string(hash))
	rusak := 0
	for _, h := range hasil {
		// Laporan per berkas mengikuti Kamus Data bagian 5: diproses, berhasil, gagal[{baris, alasan}].
		// berhasil = baru + sudah ada (idempoten); baru dicatat terpisah.
		gagalBaris := h.Galat
		if gagalBaris == nil {
			gagalBaris = []seed.Galat{}
		}
		laporan := struct {
			Berkas   string       `json:"berkas"`
			Diproses int          `json:"diproses"`
			Berhasil int          `json:"berhasil"`
			Baru     int          `json:"baru"`
			Gagal    []seed.Galat `json:"gagal"`
		}{h.Berkas, h.Baru + h.Dilewati + len(h.Galat), h.Baru + h.Dilewati, h.Baru, gagalBaris}
		_ = json.NewEncoder(os.Stdout).Encode(laporan)
		rusak += len(h.Galat)
	}
	if err != nil {
		return gagal("%v", err)
	}
	if rusak > 0 {
		return 2
	}
	return 0
}

func gagal(format string, a ...any) int {
	fmt.Fprintf(os.Stderr, "seed gagal: "+format+"\n", a...)
	return 1
}
