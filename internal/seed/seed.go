// Package seed mengimpor CSV akun, kelompok, dan anggota (BASE-01, BASE-04, E10).
//
// Sifat impor:
//   - idempoten: baris yang sudah ada dilewati (ON CONFLICT DO NOTHING), jadi aman dijalankan berulang;
//   - parsial: baris rusak dilaporkan dan dilewati, baris lain tetap masuk.
//
// Kata sandi tidak ada di CSV. Semua akun seed memakai satu kata sandi dari env SEED_PASSWORD
// (di-hash bcrypt sekali oleh pemanggil), supaya tidak ada rahasia di repositori.
package seed

import (
	"context"
	"database/sql"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"strings"
	"unicode/utf8"
)

// DB adalah akses database yang dibutuhkan impor; dipisah agar mudah dites.
type DB interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	// Cari menjalankan kueri satu kolom teks dengan satu argumen; found=false bila tidak ada baris.
	Cari(ctx context.Context, query, arg string) (nilai string, found bool, err error)
}

// Querier dipenuhi oleh *sql.DB dan *sql.Tx.
type Querier interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// NewDB membungkus *sql.DB (atau *sql.Tx) menjadi DB.
func NewDB(q Querier) DB { return sqlDB{q} }

type sqlDB struct{ Querier }

func (d sqlDB) Cari(ctx context.Context, query, arg string) (string, bool, error) {
	var v string
	err := d.QueryRowContext(ctx, query, arg).Scan(&v)
	if errors.Is(err, sql.ErrNoRows) {
		return "", false, nil
	}
	return v, err == nil, err
}

// Galat satu baris CSV yang gagal diimpor.
type Galat struct {
	Baris  int    `json:"baris"`
	Alasan string `json:"alasan"`
}

// Hasil ringkasan impor satu berkas.
type Hasil struct {
	Berkas   string
	Baru     int
	Dilewati int     // sudah ada (idempoten)
	Galat    []Galat // baris rusak (Kamus Data bagian 5)
}

type tabel struct {
	berkas string
	kolom  []string
	cek    func(rec []string) error
	// sisip mengembalikan baru=true bila baris benar-benar ditambahkan, false bila sudah ada.
	sisip func(ctx context.Context, db DB, rec []string, hash string) (baru bool, err error)
}

var peranValid = map[string]bool{"mahasiswa": true, "dosen": true, "mitra": true, "koordinator": true}

var urutan = []tabel{
	{
		berkas: "pengguna.csv",
		kolom:  []string{"identitas", "nama", "peran"},
		cek: func(r []string) error {
			if err := wajib(r, "identitas", "nama", "peran"); err != nil {
				return err
			}
			if utf8.RuneCountInString(r[0]) > 64 {
				return errors.New("identitas lebih dari 64 karakter")
			}
			if !peranValid[r[2]] {
				return fmt.Errorf("peran %q tidak dikenal", r[2])
			}
			return nil
		},
		sisip: func(ctx context.Context, db DB, r []string, hash string) (bool, error) {
			return sisipBaru(ctx, db,
				`INSERT INTO pengguna (identitas, nama, peran, password_hash, harus_ganti_password) VALUES ($1, $2, $3, $4, TRUE)
 				 ON CONFLICT (identitas) DO NOTHING`, r[0], r[1], r[2], hash)
		},
	},
	{
		berkas: "kelompok.csv",
		kolom:  []string{"kode_kelompok", "nama"},
		cek:    func(r []string) error { return wajib(r, "kode_kelompok", "nama") },
		sisip: func(ctx context.Context, db DB, r []string, _ string) (bool, error) {
			return sisipBaru(ctx, db,
				`INSERT INTO kelompok (kode_kelompok, nama) VALUES ($1, $2)
				 ON CONFLICT (kode_kelompok) DO NOTHING`, r[0], r[1])
		},
	},
	{
		berkas: "anggota.csv",
		kolom:  []string{"nrp", "kode_kelompok"},
		cek:    func(r []string) error { return wajib(r, "nrp", "kode_kelompok") },
		sisip: func(ctx context.Context, db DB, r []string, _ string) (bool, error) {
			// Hanya mahasiswa yang boleh menjadi anggota kelompok (1 mahasiswa = 1 kelompok).
			peran, ada, err := db.Cari(ctx, `SELECT peran FROM pengguna WHERE identitas = $1`, r[0])
			if err != nil {
				return false, err
			}
			if !ada {
				return false, fmt.Errorf("nrp %s tidak ada di pengguna.csv", r[0])
			}
			if peran != "mahasiswa" {
				return false, fmt.Errorf("%s berperan %s, bukan mahasiswa", r[0], peran)
			}
			baru, err := sisipBaru(ctx, db,
				`INSERT INTO anggota_kelompok (nrp, kode_kelompok) VALUES ($1, $2)
				 ON CONFLICT (nrp) DO NOTHING`, r[0], r[1])
			if err != nil || baru {
				return baru, err
			}
			// Sudah terdaftar: aman bila kelompoknya sama, galat bila berbeda.
			kel, _, err := db.Cari(ctx, `SELECT kode_kelompok FROM anggota_kelompok WHERE nrp = $1`, r[0])
			if err != nil {
				return false, err
			}
			if kel != r[1] {
				return false, fmt.Errorf("nrp %s sudah ada di kelompok %s, bukan %s", r[0], kel, r[1])
			}
			return false, nil
		},
	},
}

// Run mengimpor pengguna.csv, kelompok.csv, lalu anggota.csv dari fsys (urutan penting karena FK).
// Galat dikembalikan hanya untuk kegagalan fatal (berkas hilang, header salah, database mati);
// baris rusak dicatat di Hasil.Galat.
func Run(ctx context.Context, db DB, fsys fs.FS, passwordHash string) ([]Hasil, error) {
	var semua []Hasil
	for _, t := range urutan {
		h, err := impor(ctx, db, fsys, t, passwordHash)
		if err != nil {
			return semua, fmt.Errorf("%s: %w", t.berkas, err)
		}
		semua = append(semua, h)
	}
	return semua, nil
}

func impor(ctx context.Context, db DB, fsys fs.FS, t tabel, hash string) (Hasil, error) {
	h := Hasil{Berkas: t.berkas}
	f, err := fsys.Open(t.berkas)
	if err != nil {
		return h, err
	}
	defer f.Close()

	r := csv.NewReader(f)
	r.FieldsPerRecord = -1 // jumlah kolom diperiksa sendiri agar baris rusak bisa dilaporkan
	r.TrimLeadingSpace = true

	header, err := r.Read()
	if err != nil {
		return h, fmt.Errorf("header tidak terbaca: %w", err)
	}
	header[0] = strings.TrimPrefix(header[0], "\ufeff") // BOM dari Excel
	if !samaKolom(header, t.kolom) {
		return h, fmt.Errorf("header harus %v, ditemukan %v", t.kolom, header)
	}

	for {
		rec, err := r.Read()
		if errors.Is(err, io.EOF) {
			return h, nil
		}
		var pe *csv.ParseError
		if errors.As(err, &pe) {
			h.Galat = append(h.Galat, Galat{pe.Line, pe.Err.Error()})
			continue
		}
		if err != nil {
			return h, err
		}
		baris, _ := r.FieldPos(0)

		for i := range rec {
			rec[i] = strings.TrimSpace(rec[i])
		}
		if len(rec) != len(t.kolom) {
			h.Galat = append(h.Galat, Galat{baris, fmt.Sprintf("butuh %d kolom, ditemukan %d", len(t.kolom), len(rec))})
			continue
		}
		if err := t.cek(rec); err != nil {
			h.Galat = append(h.Galat, Galat{baris, err.Error()})
			continue
		}
		baru, err := t.sisip(ctx, db, rec, hash)
		if err != nil {
			if ctx.Err() != nil {
				return h, ctx.Err()
			}
			h.Galat = append(h.Galat, Galat{baris, err.Error()})
			continue
		}
		if baru {
			h.Baru++
		} else {
			h.Dilewati++
		}
	}
}

func sisipBaru(ctx context.Context, db DB, query string, args ...any) (bool, error) {
	res, err := db.ExecContext(ctx, query, args...)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	return n > 0, err
}

func wajib(rec []string, nama ...string) error {
	for i, n := range nama {
		if rec[i] == "" {
			return fmt.Errorf("kolom %s kosong", n)
		}
	}
	return nil
}

func samaKolom(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if strings.TrimSpace(a[i]) != b[i] {
			return false
		}
	}
	return true
}
