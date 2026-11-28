package seed

import (
	"context"
	"database/sql"
	"strings"
	"testing"
	"testing/fstest"
)

type hasilSQL int64

func (hasilSQL) LastInsertId() (int64, error)   { return 0, nil }
func (h hasilSQL) RowsAffected() (int64, error) { return int64(h), nil }

// fakeDB meniru ON CONFLICT DO NOTHING dan pencarian peran/kelompok.
type fakeDB struct {
	ada    map[string]bool
	peran  map[string]string
	grup   map[string]string
	hashes []string
}

func (f *fakeDB) init() {
	if f.ada == nil {
		f.ada, f.peran, f.grup = map[string]bool{}, map[string]string{}, map[string]string{}
	}
}

func (f *fakeDB) ExecContext(_ context.Context, q string, args ...any) (sql.Result, error) {
	f.init()
	tabel := strings.Fields(q[strings.Index(q, "INTO")+4:])[0]
	k := tabel + "/" + args[0].(string)
	if f.ada[k] {
		return hasilSQL(0), nil
	}
	f.ada[k] = true
	switch tabel {
	case "pengguna":
		f.peran[args[0].(string)] = args[2].(string)
		f.hashes = append(f.hashes, args[3].(string))
	case "anggota_kelompok":
		f.grup[args[0].(string)] = args[1].(string)
	}
	return hasilSQL(1), nil
}

func (f *fakeDB) Cari(_ context.Context, q, arg string) (string, bool, error) {
	f.init()
	if strings.Contains(q, "FROM pengguna") {
		v, ok := f.peran[arg]
		return v, ok, nil
	}
	v, ok := f.grup[arg]
	return v, ok, nil
}

func fsBagus() fstest.MapFS {
	return fstest.MapFS{
		"pengguna.csv": {Data: []byte("identitas,nama,peran\nK1,Koor,koordinator\nD1,Dosen,dosen\n111,Mhs,mahasiswa\n")},
		"kelompok.csv": {Data: []byte("kode_kelompok,nama\nCP-01,Kelompok 1\n")},
		"anggota.csv":  {Data: []byte("nrp,kode_kelompok\n111,CP-01\n")},
	}
}

func TestRunImporSemua(t *testing.T) {
	db := &fakeDB{}
	hs, err := Run(context.Background(), db, fsBagus(), "HASH")
	if err != nil {
		t.Fatal(err)
	}
	want := []int{3, 1, 1}
	for i, h := range hs {
		if h.Baru != want[i] || len(h.Galat) != 0 {
			t.Errorf("%s: baru=%d galat=%v, want baru=%d", h.Berkas, h.Baru, h.Galat, want[i])
		}
	}
	for _, h := range db.hashes {
		if h != "HASH" {
			t.Fatalf("hash tidak diteruskan: %q", h)
		}
	}
}

func TestRunIdempoten(t *testing.T) {
	db := &fakeDB{}
	if _, err := Run(context.Background(), db, fsBagus(), "H"); err != nil {
		t.Fatal(err)
	}
	hs, err := Run(context.Background(), db, fsBagus(), "H")
	if err != nil {
		t.Fatal(err)
	}
	for _, h := range hs {
		if h.Baru != 0 || h.Dilewati == 0 {
			t.Errorf("%s: baru=%d dilewati=%d, want 0 baru", h.Berkas, h.Baru, h.Dilewati)
		}
	}
}

func TestBarisRusakDilaporkanBarisLainMasuk(t *testing.T) {
	fsys := fsBagus()
	fsys["pengguna.csv"] = &fstest.MapFile{Data: []byte(strings.Join([]string{
		"identitas,nama,peran",
		"K1,Koor,koordinator",
		"X1,Nama,presiden",                         // peran salah
		",Tanpa Id,dosen",                          // identitas kosong
		"D2,Kurang Kolom",                          // kolom kurang
		strings.Repeat("a", 65) + ",Panjang,dosen", // identitas > 64
		"D3,Dosen Tiga,dosen",
	}, "\n") + "\n")}
	hs, err := Run(context.Background(), &fakeDB{}, fsys, "H")
	if err != nil {
		t.Fatal(err)
	}
	p := hs[0]
	if p.Baru != 2 {
		t.Errorf("baru = %d, want 2", p.Baru)
	}
	if len(p.Galat) != 4 {
		t.Fatalf("galat = %d (%v), want 4", len(p.Galat), p.Galat)
	}
	if p.Galat[0].Baris != 3 {
		t.Errorf("nomor baris salah: %+v", p.Galat[0])
	}
}

func TestHeaderSalahFatal(t *testing.T) {
	fsys := fsBagus()
	fsys["kelompok.csv"] = &fstest.MapFile{Data: []byte("kode,nama\nCP-01,x\n")}
	if _, err := Run(context.Background(), &fakeDB{}, fsys, "H"); err == nil {
		t.Fatal("header salah seharusnya galat fatal")
	}
}

func TestBerkasHilangFatal(t *testing.T) {
	fsys := fsBagus()
	delete(fsys, "anggota.csv")
	if _, err := Run(context.Background(), &fakeDB{}, fsys, "H"); err == nil {
		t.Fatal("berkas hilang seharusnya galat fatal")
	}
}

func TestBOMDiterima(t *testing.T) {
	fsys := fsBagus()
	fsys["kelompok.csv"] = &fstest.MapFile{Data: []byte("\ufeffkode_kelompok,nama\nCP-01,Kelompok 1\n")}
	if _, err := Run(context.Background(), &fakeDB{}, fsys, "H"); err != nil {
		t.Fatal(err)
	}
}

func TestAnggotaBukanMahasiswaDanPindahKelompokDilaporkan(t *testing.T) {
	fsys := fsBagus()
	fsys["anggota.csv"] = &fstest.MapFile{Data: []byte(strings.Join([]string{
		"nrp,kode_kelompok",
		"111,CP-01",
		"111,CP-01", // sama persis: dilewati, bukan galat
		"111,CP-02", // mahasiswa sama, kelompok lain: galat
		"D1,CP-01",  // dosen: galat
		"999,CP-01", // tidak ada di pengguna: galat
	}, "\n") + "\n")}
	hs, err := Run(context.Background(), &fakeDB{}, fsys, "H")
	if err != nil {
		t.Fatal(err)
	}
	a := hs[2]
	if a.Baru != 1 || a.Dilewati != 1 || len(a.Galat) != 3 {
		t.Fatalf("baru=%d dilewati=%d galat=%v, want 1/1/3 galat", a.Baru, a.Dilewati, a.Galat)
	}
}
