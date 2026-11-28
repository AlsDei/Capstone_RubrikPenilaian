-- 900: data awal rubrik dan komponen (E1, E10, asumsi D4)
-- Sumber: Rubrik Penilaian Capstone Project (Apendiks 2.1.2.18.12).
-- 4 asesmen (= komponen) masing-masing 25%, tiap asesmen 3 aspek (= kriteria), 12 aspek total.
--
-- Skala bobot: dokumen dosen menulis bobot aspek sebagai persen dari NILAI AKHIR
-- (mis. 8% + 7% + 10% = 25% per asesmen). Proposal E6 mewajibkan jumlah bobot kriteria
-- dalam satu rubrik = 100, jadi bobot di sini = bobot dokumen x 4 (8% -> 32).
-- Hasil akhirnya identik: 25% x (32/100) = 8%.
--
-- Kolom deskripsi berisi deskriptor 7 rentang nilai (A..E) dari tabel rubrik dosen.

INSERT INTO rubrik (kode, versi, nama) VALUES
    ('rubrik-user-requirement', 1, 'Rubrik Asesmen 1: User Requirement dan Desain'),
    ('rubrik-laporan-progress', 1, 'Rubrik Asesmen 2: Laporan Progress'),
    ('rubrik-laporan-akhir',    1, 'Rubrik Asesmen 3: Laporan Akhir'),
    ('rubrik-presentasi-akhir', 1, 'Rubrik Asesmen 4: Presentasi Akhir');

INSERT INTO kriteria (rubrik_id, nama, bobot, cpmk, deskripsi)
SELECT r.id, k.nama, k.bobot, k.cpmk, k.deskripsi
FROM (VALUES
    ('rubrik-user-requirement', '1.1 Identifikasi masalah & kebutuhan mitra', 32, 1,
     'A (86–100): Masalah dan kebutuhan mitra teridentifikasi tajam dan spesifik, didukung bukti konkret (wawancara/observasi terstruktur, data mitra) dan dikaitkan dengan studi literatur yang relevan; tujuan proyek terukur dengan metrik spesifik.
AB (76–85): Masalah dan kebutuhan mitra jelas dan didukung bukti; tujuan terukur, namun kaitan dengan studi literatur masih terbatas.
B (66–75): Masalah dan kebutuhan mitra jelas dengan bukti pendukung; sebagian tujuan masih kualitatif atau ruang lingkup kurang tegas.
BC (61–65): Masalah teridentifikasi, namun bukti wawancara/observasi minim; tujuan dan ruang lingkup dinyatakan umum.
C (56–60): Masalah/kebutuhan disebutkan secara umum tanpa bukti yang memadai; tujuan bersifat normatif.
D (41–55): Masalah dan kebutuhan mitra kabur atau kurang relevan dengan solusi yang diajukan.
E (0–40): Project Charter tidak dikumpulkan atau tidak memuat identifikasi masalah/kebutuhan.'),
    ('rubrik-user-requirement', '1.2 Kebutuhan pengguna: user story & acceptance criteria', 28, 1,
     'A (86–100): Seluruh peran pengguna teridentifikasi; setiap user story/PRD memuat prioritas, estimasi, deskripsi, dan acceptance criteria yang spesifik dan dapat diuji.
AB (76–85): Peran pengguna dan user story lengkap dengan acceptance criteria; sebagian kecil kriteria masih umum.
B (66–75): User story lengkap untuk fitur utama; sebagian acceptance criteria belum dapat diuji secara langsung.
BC (61–65): User story mencakup sebagian fitur; prioritas/estimasi/acceptance criteria hilang pada beberapa item.
C (56–60): User story ada tetapi tidak lengkap pada sebagian besar item; peran pengguna belum jelas.
D (41–55): Kebutuhan pengguna hanya berupa daftar fitur tanpa struktur user story/acceptance criteria.
E (0–40): User Story/PRD tidak dikumpulkan.'),
    ('rubrik-user-requirement', '1.3 Desain solusi teknis (arsitektur, data, UI/UX) & traceability', 40, 2,
     'A (86–100): Arsitektur sistem, desain data, dan UI/UX dijabarkan lengkap, konsisten antarbagian, dan setiap elemen desain tertelusur (traceable) ke kebutuhan/user story.
AB (76–85): Desain lengkap dan konsisten; sebagian besar elemen desain tertelusur ke kebutuhan.
B (66–75): Desain lengkap dengan sedikit inkonsistensi; traceability ada untuk fitur utama.
BC (61–65): Desain mencakup sebagian aspek (mis. tanpa desain data atau UI rinci); traceability disebutkan secara umum.
C (56–60): Desain hanya mencakup satu aspek atau tidak rinci; keterkaitan dengan kebutuhan lemah.
D (41–55): Desain tidak relevan dengan kebutuhan atau tidak dapat ditelusuri.
E (0–40): Dokumen desain (PRD) tidak dikumpulkan.'),
    ('rubrik-laporan-progress', '2.1 Penerapan Agile/Scrum & kesesuaian backlog', 32, 3,
     'A (86–100): Sprint planning, review, dan retrospective diterapkan konsisten dan terdokumentasi; backlog/papan kerja terkini dan realisasi sprint sesuai backlog.
AB (76–85): Praktik Scrum diterapkan konsisten; dokumentasi lengkap dengan sedikit celah (mis. retrospective tidak selalu tercatat).
B (66–75): Sebagian besar praktik Scrum diterapkan; backlog ada namun tidak selalu diperbarui.
BC (61–65): Praktik Scrum diterapkan sebagian; kesesuaian realisasi dengan backlog tidak selalu jelas.
C (56–60): Praktik Scrum tidak konsisten; bukti backlog/sprint review minim.
D (41–55): Penerapan Agile/Scrum hanya formalitas tanpa bukti backlog.
E (0–40): Tidak ada bukti penerapan Agile/Scrum atau laporan progress tidak dikumpulkan.'),
    ('rubrik-laporan-progress', '2.2 Kolaborasi tim & disiplin jadwal', 28, 3,
     'A (86–100): Seluruh anggota berkontribusi proporsional dan terdokumentasi (PIC tugas); seluruh laporan tepat waktu; keputusan diambil berbasis data/umpan balik.
AB (76–85): Kontribusi merata dan terdokumentasi; jadwal dipatuhi dengan keterlambatan kecil yang jarang.
B (66–75): Kontribusi cukup merata; jadwal umumnya dipatuhi, beberapa laporan terlambat.
BC (61–65): Kontribusi kurang merata atau beberapa laporan terlambat cukup lama.
C (56–60): Kontribusi tidak merata dan jadwal sering tidak dipatuhi.
D (41–55): Kolaborasi tim lemah; sebagian besar tenggat terlewati.
E (0–40): Tidak ada bukti kolaborasi tim atau disiplin jadwal.'),
    ('rubrik-laporan-progress', '2.3 Progres implementasi & kualitas kode', 40, 4,
     'A (86–100): Seluruh target sprint (modul inti/MVP) selesai dan berfungsi; kode terorganisir sesuai arsitektur; riwayat Git/CI rapi dan konsisten.
AB (76–85): Hampir seluruh target sprint (>90%) selesai; kode dan praktik Git baik dengan sedikit kekurangan.
B (66–75): Sebagian besar target (>80%) selesai dan berfungsi; kode cukup terorganisir.
BC (61–65): Target sprint selesai 65–80%; struktur kode atau praktik Git kurang konsisten.
C (56–60): Target sprint selesai 50–65%; beberapa fitur MVP belum berfungsi.
D (41–55): Sebagian besar target belum selesai; praktik version control minim.
E (0–40): Tidak ada progres implementasi yang dapat dibuktikan.'),
    ('rubrik-laporan-akhir', '3.1 Implementasi, deployment & dokumentasi teknis', 40, 4,
     'A (86–100): Sistem ter-deploy di lingkungan mitra (CI/CD, stabil), integrasi antarmodul/pihak terverifikasi, dokumentasi teknis dan user manual lengkap sehingga dapat dipakai tanpa bantuan tim.
AB (76–85): Sistem ter-deploy dan dapat diakses dengan CI/CD; integrasi dan dokumentasi lengkap dengan sedikit kekurangan.
B (66–75): Sistem ter-deploy dan dapat diakses; sebagian integrasi atau user manual belum lengkap.
BC (61–65): Deployment berhasil namun manual/tidak stabil; dokumentasi teknis atau user manual hanya sebagian.
C (56–60): Deployment terbatas (mis. hanya lingkungan pengembangan); integrasi dan dokumentasi minim.
D (41–55): Sistem belum ter-deploy; dokumentasi sangat terbatas.
E (0–40): Tidak ada bukti implementasi/deployment pada laporan akhir.'),
    ('rubrik-laporan-akhir', '3.2 Pengujian, UAT & evaluasi sistem', 40, 5,
     'A (86–100): Pengujian unit/integrasi mencakup seluruh modul dengan bukti kuantitatif; UAT bersama mitra terdokumentasi dan ditindaklanjuti; evaluasi reflektif terhadap metrik tujuan.
AB (76–85): Pengujian dan UAT lengkap dengan bukti kuantitatif; sebagian kecil umpan balik belum tuntas ditindaklanjuti.
B (66–75): Pengujian mencakup sebagian besar modul; UAT bersama mitra dilakukan; evaluasi memaparkan kelebihan dan kekurangan.
BC (61–65): Pengujian terbatas pada sebagian modul; UAT terbatas atau tindak lanjut tidak jelas.
C (56–60): Pengujian minim; UAT hanya internal tim; evaluasi kurang reflektif.
D (41–55): Bukti pengujian dan evaluasi sangat terbatas.
E (0–40): Tidak ada bukti pengujian, UAT, maupun evaluasi.'),
    ('rubrik-laporan-akhir', '3.3 Analisis dampak, etika & keberlanjutan; kualitas laporan', 20, 6,
     'A (86–100): Analisis dampak, etika (termasuk privasi data/responsible AI), dan keberlanjutan tajam; laporan lengkap, konsisten, bersitasi, dan kesimpulan menjawab tujuan terukur.
AB (76–85): Analisis dampak/etika/keberlanjutan baik; laporan lengkap dengan sedikit inkonsistensi format.
B (66–75): Analisis dampak dan keberlanjutan ada namun ringkas; laporan lengkap, kesimpulan cukup jelas.
BC (61–65): Analisis dampak/etika hanya disebut sekilas; terdapat beberapa inkonsistensi struktur/sitasi.
C (56–60): Analisis dampak/etika tidak ada; bagian struktur wajib laporan kurang lengkap.
D (41–55): Laporan tidak lengkap secara signifikan; kesimpulan tidak menjawab tujuan.
E (0–40): Laporan akhir tidak dikumpulkan.'),
    ('rubrik-presentasi-akhir', '4.1 Demo produk final', 20, 5,
     'A (86–100): Seluruh fitur yang diklaim berfungsi saat demo tanpa error berarti, sesuai klaim laporan.
AB (76–85): Hampir seluruh fitur berfungsi saat demo dengan kendala sangat kecil.
B (66–75): Sebagian besar fitur berfungsi; terdapat kendala minor.
BC (61–65): Beberapa fitur pendukung tidak berfungsi saat demo.
C (56–60): Beberapa fitur inti error atau berbeda dari klaim laporan.
D (41–55): Sebagian besar fitur utama tidak berfungsi saat demo.
E (0–40): Produk tidak didemokan.'),
    ('rubrik-presentasi-akhir', '4.2 Presentasi & tanya jawab', 40, 6,
     'A (86–100): Presentasi runtut dan meyakinkan (masalah–solusi–hasil–dampak); seluruh pertanyaan dosen/mitra dijawab dengan argumentasi teknis yang kuat.
AB (76–85): Presentasi runtut; hampir seluruh pertanyaan dijawab dengan baik.
B (66–75): Presentasi cukup runtut; sebagian besar pertanyaan dijawab, beberapa argumentasi kurang kuat.
BC (61–65): Presentasi kurang runtut pada beberapa bagian; sebagian pertanyaan tidak terjawab tuntas.
C (56–60): Presentasi kurang runtut; tim kesulitan menjawab pertanyaan dasar.
D (41–55): Presentasi sangat tidak runtut; tim tidak mampu mempertahankan hasil proyek.
E (0–40): Tidak mengikuti presentasi akhir.'),
    ('rubrik-presentasi-akhir', '4.3 Penilaian mitra (kepuasan & kolaborasi)', 40, 3,
     'A (86–100): Mitra menyatakan sangat puas: produk bernilai tambah dan siap dipakai; kolaborasi dan komunikasi tim sangat baik (form penilaian mitra).
AB (76–85): Mitra puas terhadap produk dan kolaborasi; catatan perbaikan kecil.
B (66–75): Mitra cukup puas; terdapat beberapa catatan perbaikan produk atau komunikasi.
BC (61–65): Mitra menilai produk bermanfaat sebagian; komunikasi kurang rutin.
C (56–60): Mitra menilai produk belum sesuai kebutuhan utama; kolaborasi kurang.
D (41–55): Mitra tidak puas terhadap produk maupun kolaborasi.
E (0–40): Form penilaian mitra tidak tersedia/mitra tidak memberi penilaian.')
) AS k(rubrik_kode, nama, bobot, cpmk, deskripsi)
JOIN rubrik r ON r.kode = k.rubrik_kode AND r.versi = 1;

INSERT INTO komponen (kode, nama, rubrik_id, bobot_komponen)
SELECT k.kode, k.nama, r.id, 25
FROM (VALUES
    ('user-requirement', 'User Requirement dan Desain', 'rubrik-user-requirement'),
    ('laporan-progress', 'Laporan Progress',            'rubrik-laporan-progress'),
    ('laporan-akhir',    'Laporan Akhir',               'rubrik-laporan-akhir'),
    ('presentasi-akhir', 'Presentasi Akhir',            'rubrik-presentasi-akhir')
) AS k(kode, nama, rubrik_kode)
JOIN rubrik r ON r.kode = k.rubrik_kode AND r.versi = 1;

-- Pengaman: seed ditolak (init database gagal) bila bobot tidak berjumlah 100.
DO $$
DECLARE
    salah TEXT;
BEGIN
    SELECT string_agg(r.kode || '=' || s.total, ', ') INTO salah
    FROM rubrik r
    JOIN (SELECT rubrik_id, sum(bobot) AS total FROM kriteria GROUP BY rubrik_id) s ON s.rubrik_id = r.id
    WHERE s.total <> 100;
    IF salah IS NOT NULL THEN
        RAISE EXCEPTION 'jumlah bobot kriteria harus 100, ditemukan: %', salah;
    END IF;

    IF (SELECT sum(bobot_komponen) FROM komponen) <> 100 THEN
        RAISE EXCEPTION 'jumlah bobot komponen harus 100';
    END IF;
END $$;
