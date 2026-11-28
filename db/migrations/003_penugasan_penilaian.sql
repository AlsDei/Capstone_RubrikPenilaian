-- 003: penugasan, penilaian, skor (E2)

CREATE TABLE penugasan (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    penilai       TEXT NOT NULL REFERENCES pengguna(identitas),
    kode_kelompok TEXT NOT NULL REFERENCES kelompok(kode_kelompok),
    komponen      TEXT NOT NULL REFERENCES komponen(kode),
    dibuat_pada   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (penilai, kode_kelompok, komponen)
);
CREATE INDEX idx_penugasan_kelompok_komponen ON penugasan (kode_kelompok, komponen);

CREATE TABLE penilaian (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    penugasan_id BIGINT NOT NULL UNIQUE REFERENCES penugasan(id) ON DELETE CASCADE,
    catatan      TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'draf' CHECK (status IN ('draf','dikirim')),
    dikirim_pada TIMESTAMPTZ,
    diubah_pada  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK ((status = 'dikirim') = (dikirim_pada IS NOT NULL))
);

CREATE TABLE skor (
    penilaian_id BIGINT NOT NULL REFERENCES penilaian(id) ON DELETE CASCADE,
    kriteria_id  BIGINT NOT NULL REFERENCES kriteria(id),
    nilai        INT NOT NULL CHECK (nilai BETWEEN 0 AND 100),
    PRIMARY KEY (penilaian_id, kriteria_id)
);
