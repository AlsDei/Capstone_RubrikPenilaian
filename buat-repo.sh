#!/usr/bin/env bash
# Membuat kerangka repositori tim 5-B sesuai E1 dan E10 proposal backend.
# Pemakaian:  bash buat-repo.sh [nama-folder]
set -euo pipefail

ROOT="${1:-capstone-m5b}"
mkdir -p "$ROOT"
cd "$ROOT"

# --- Folder (E1) ---
for d in \
  cmd/server cmd/seed \
  internal/config internal/http internal/auth \
  internal/domain internal/service internal/repository \
  db/migrations db/seed docs \
  frontend/src/pages/penilaian frontend/src/pages/hasil \
  frontend/src/pages/rekap frontend/src/pages/rubrik frontend/src/api
do
  mkdir -p "$d"
  touch "$d/.gitkeep"
done

# --- .gitignore: .env tidak boleh dikomit (E5, E8) ---
cat > .gitignore <<'EOF'
.env
node_modules/
frontend/dist/
EOF

# --- .env.example: hanya nama variabel dan nilai contoh (E10) ---
cat > .env.example <<'EOF'
# Salin menjadi .env lalu isi. Jangan komit .env.
COMPOSE_PROJECT_NAME=capstone-m5b
APP_PORT=8110
DB_PORT=5510
TEST_DB_PORT=5610
FE_PORT=3110
DB_BIND=
DB_USER=
DB_PASSWORD=
DB_NAME=
JWT_SECRET=
CORS_ALLOWED_ORIGINS=http://localhost:3110
GO_VERSION=
MAIN_PKG=./cmd/server
EOF

# --- README (BASE-08), perintah dari E10 ---
cat > README.md <<'EOF'
# Penilaian Multi-Penilai dan Rubrik (Tim 5-B, MyIF Capstone Modul 5)

## Menjalankan
1. Salin `.env.example` menjadi `.env`, lalu isi nilainya.
2. `docker compose up -d --build --wait`
3. Impor akun, kelompok, dan anggota: `docker compose run --rm app seed`

Mati: `docker compose down` (data tetap) atau `docker compose down -v` (data dihapus).
Log: `docker compose logs -f app`.
EOF

# --- AI-LOG (J) ---
cat > AI-LOG.md <<'EOF'
# AI-LOG

| Tanggal | Anggota | Tujuan | Ringkasan permintaan | Bagian yang dipakai | Perubahan yang dilakukan |
| --- | --- | --- | --- | --- | --- |
EOF

# --- openapi.yaml: kerangka kosong, diisi sesuai tabel E3 ---
cat > openapi.yaml <<'EOF'
openapi: 3.0.3
info:
  title: Penilaian Multi-Penilai dan Rubrik (Tim 5-B)
  version: 0.1.0
paths: {}
EOF

# --- Berkas operasional (E1): isi menyusul ---
echo '# TODO: citra dua tahap, pengguna nonroot (E10)' > Dockerfile
echo '# TODO: layanan db dan app; profil db_test dan frontend (E10)' > docker-compose.yml
echo '-- 001: skema awal (E2)' > db/migrations/001_skema.sql

git init -q 2>/dev/null || true
echo "Selesai: $(pwd)"
