-- 002: rubrik, kriteria, komponen (E2)

CREATE TABLE rubrik (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode        TEXT NOT NULL,
    versi       INT NOT NULL CHECK (versi >= 1),
    nama        TEXT NOT NULL,
    terkunci    BOOLEAN NOT NULL DEFAULT FALSE,
    dibuat_pada TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (kode, versi)
);

CREATE TABLE kriteria (
    id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rubrik_id BIGINT NOT NULL REFERENCES rubrik(id) ON DELETE CASCADE,
    nama      TEXT NOT NULL,
    bobot     INT NOT NULL CHECK (bobot BETWEEN 1 AND 100),
    deskripsi TEXT NOT NULL DEFAULT '',
    cpmk      INT NOT NULL CHECK (cpmk > 0),
    UNIQUE (rubrik_id, nama)
); -- jumlah bobot per rubrik = 100 dicek di service dalam satu transaksi

CREATE TABLE komponen (
    kode           TEXT PRIMARY KEY, -- mis. sidang-proposal
    nama           TEXT NOT NULL,
    rubrik_id      BIGINT NOT NULL REFERENCES rubrik(id),
    bobot_komponen INT NOT NULL CHECK (bobot_komponen BETWEEN 1 AND 100)
); -- jumlah seluruh bobot = 100 dicek saat PUT /komponen (atomik)
