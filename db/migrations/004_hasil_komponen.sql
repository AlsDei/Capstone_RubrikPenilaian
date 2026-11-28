-- 004: hasil agregat per kelompok x komponen (E2)
-- Baris dibuat saat penugasan pertama; juga menjadi KUNCI konkurensi
-- (SELECT ... FOR UPDATE lewat KunciHasil(), E4 dan E11 no. 1).

CREATE TABLE hasil_komponen (
    kode_kelompok   TEXT NOT NULL REFERENCES kelompok(kode_kelompok),
    komponen        TEXT NOT NULL REFERENCES komponen(kode),
    nilai_gabungan  NUMERIC(5,2) CHECK (nilai_gabungan BETWEEN 0 AND 100),
    status          TEXT NOT NULL DEFAULT 'berjalan' CHECK (status IN ('berjalan','final','dirilis')),
    perlu_kalibrasi BOOLEAN NOT NULL DEFAULT FALSE,
    diubah_pada     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (kode_kelompok, komponen),
    CHECK (status = 'berjalan' OR nilai_gabungan IS NOT NULL)
);
