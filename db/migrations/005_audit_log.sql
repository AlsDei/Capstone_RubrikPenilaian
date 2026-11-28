-- 005: jejak audit append-only (E2, E11 no. 4)

CREATE TABLE audit_log (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    waktu         TIMESTAMPTZ NOT NULL DEFAULT now(),
    aktor         TEXT NOT NULL REFERENCES pengguna(identitas),
    aksi          TEXT NOT NULL CHECK (aksi IN
        ('SKOR_DISIMPAN','SKOR_DIKIRIM','FINALISASI','BUKA_KEMBALI','RILIS',
         'PENUGASAN_DITAMBAH','PENUGASAN_DIHAPUS')),
    kode_kelompok TEXT,
    komponen      TEXT,
    nilai_lama    JSONB,
    nilai_baru    JSONB,
    alasan        TEXT,
    CHECK (aksi <> 'BUKA_KEMBALI' OR length(btrim(coalesce(alasan,''))) > 0)
);
CREATE INDEX idx_audit_kelompok_komponen ON audit_log (kode_kelompok, komponen, waktu);

-- audit bersifat append-only: UPDATE dan DELETE ditolak database
CREATE FUNCTION audit_log_tolak_ubah() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'audit_log bersifat append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_append_only
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION audit_log_tolak_ubah();
