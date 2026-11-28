-- 001: pengguna, kelompok, anggota kelompok (E2)
-- Data awal (pengguna, kelompok, anggota) berasal dari impor CSV (subperintah seed).

CREATE TABLE pengguna (
    identitas     TEXT PRIMARY KEY, -- nrp / kode_dosen / kode_mitra / kode koordinator
    nama          TEXT NOT NULL,
    peran         TEXT NOT NULL CHECK (peran IN ('mahasiswa','dosen','mitra','koordinator')),
    password_hash TEXT NOT NULL
);

CREATE TABLE kelompok (
    kode_kelompok TEXT PRIMARY KEY,
    nama          TEXT NOT NULL
);

CREATE TABLE anggota_kelompok (
    nrp           TEXT PRIMARY KEY REFERENCES pengguna(identitas), -- 1 mahasiswa = 1 kelompok
    kode_kelompok TEXT NOT NULL REFERENCES kelompok(kode_kelompok)
);
CREATE INDEX idx_anggota_kelompok ON anggota_kelompok (kode_kelompok);
