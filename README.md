# Penilaian Multi-Penilai dan Rubrik (Tim 5-B, MyIF Capstone Modul 5)

Layanan backend (Go + PostgreSQL) dan antarmuka web (React + TypeScript) untuk penilaian kelompok capstone oleh banyak penilai.
Kontrak API: [`openapi.yaml`](openapi.yaml).

## Port tim 5-B
| Layanan | Port |
| --- | --- |
| API backend (`APP_PORT`) | 8110 |
| Frontend tersaji (`FE_PORT`) | 3110 |
| Database (`DB_PORT`) | 5510 |
| Database tes (`TEST_DB_PORT`) | 5610 |

## Menjalankan backend
1. Salin `.env.example` menjadi `.env`, lalu isi `DB_PASSWORD` dan `JWT_SECRET` (mis. `openssl rand -hex 32`). `GO_VERSION` samakan dengan baris `go` di `go.mod`.
2. `docker compose up -d --build --wait`
3. Impor akun, kelompok, dan anggota: `docker compose run --rm app seed`
4. Periksa: `curl http://localhost:8110/healthz`

Mati: `docker compose down` (data tetap) atau `docker compose down -v` (data dihapus, migrasi dijalankan ulang).
Log: `docker compose logs -f app`.

## Menjalankan frontend
Folder `frontend/`. Perintah dijalankan di folder itu.

**Dengan mock (tanpa backend)**
1. `npx @stoplight/prism-cli mock ../openapi.yaml` (mock di http://localhost:4010)
2. Biarkan `API_TARGET` kosong di `frontend/.env.local`, lalu `npm install` dan `npm run dev`.

**Dengan backend sungguhan**
1. Jalankan backend (bagian di atas).
2. Isi `API_TARGET=http://localhost:8110` di `frontend/.env.local` (tidak di-commit), lalu `npm run dev`.

**Hasil build tersaji di `FE_PORT`**
1. Isi `VITE_API_URL=http://localhost:8110` (atau alamat VPS port 8110). Nilai ini tertanam di bundel dan bukan rahasia.
2. `npm run build`
3. Di akar repositori: `docker compose --profile frontend up -d frontend`, lalu buka http://localhost:3110.

Pastikan `CORS_ALLOWED_ORIGINS` di `.env` memuat asal frontend (`http://localhost:3110`, dan alamat VPS port 3110 saat deploy).

## Tes
- Backend: `docker compose --profile db_test up -d db_test`, lalu `go test ./...`
- Frontend: `npm test`, `npm run lint`, dan `npm run build` (di folder `frontend/`)