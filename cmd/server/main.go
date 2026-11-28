// Titik masuk server: membaca konfigurasi, membuka koneksi database,
// merangkai router, lalu menjalankan HTTP server dengan shutdown yang rapi.
package main

import (
	"context"
	"database/sql"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib" // driver "pgx" untuk database/sql

	"github.com/AlsDei/Capstone_RubrikPenilaian/internal/config"
	apphttp "github.com/AlsDei/Capstone_RubrikPenilaian/internal/http"
)

func main() {
	if err := run(); err != nil {
		log.Fatalf("server berhenti: %v", err)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	// sql.Open tidak langsung terhubung; /healthz yang melaporkan 503 bila database mati.
	db, err := sql.Open("pgx", cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer db.Close()
	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(30 * time.Minute)

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           apphttp.NewRouter(db),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	errCh := make(chan error, 1)
	go func() {
		log.Printf("server mendengar di %s", cfg.HTTPAddr)
		errCh <- srv.ListenAndServe()
	}()

	select {
	case err := <-errCh:
		if !errors.Is(err, http.ErrServerClosed) {
			return err
		}
		return nil
	case <-ctx.Done():
		log.Println("menerima sinyal berhenti, mematikan server...")
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		return srv.Shutdown(shutdownCtx)
	}
}
