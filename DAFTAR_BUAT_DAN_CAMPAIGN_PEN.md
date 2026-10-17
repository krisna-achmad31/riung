# DAFTAR: APA YANG MASIH HARUS DIBUAT + GAP DI `design/campaign.pen`

Diverifikasi 2026-10-17 lewat Pencil MCP (inspeksi langsung `design/campaign.pen`, 50 node top-level) + cek file di repo. Yang sudah ada **tidak** dicantumkan sebagai tugas — lihat bagian C untuk inventaris.

**Fakta dasar:**
- Monster = **13**: 7 Monster Pikiran (**gratis**) + 6 Monster Kebiasaan (frame `xlWFH`).
- **Keputusan 2026-10-17:** 6 Monster Kebiasaan + Kuis Besar-nya = **Premium** ("Season 2 · Premium", trial 7 hari). Gating ini **belum dibangun** di app (kode masih menggratiskan semuanya) → belum boleh diiklankan sebagai Premium. Marketing saat ini **hanya fitur gratis**: 7 monster pikiran, check-in, jurnal, misi menjinakkan, Aplikasi Beku + 1 sesi Fokus/hari, laporan mingguan, tes kepribadian. Kampanye monster Premium belum direncanakan.
- Tes kesehatan mental (Know Yourself) **tidak** punya monster/koin — konten soal topik klinis tetap berbingkai edukasi, jangan ditempeli monster.
- Strategi bilingual yang sudah dipakai di `campaign.pen`: desain EN default, **setiap teks punya i18n key** → versi ID dibuat dari kamus yang sama (catatan di `K8ZWOf` & `lwIL5`). Bukan layout split EN/ID dalam satu slide.

---

## A. DELIVERABLE DI LUAR `campaign.pen`

### 1. Konten sosmed — 3 akun (`.id` / `.global` / `@riung`), campaign 3 minggu

| Jenis | Jumlah | Catatan | Simpan di |
|---|---|---|---|
| Carousel 4:5 | 3 akun × 3 minggu × 4 post = 36 | Basis layout: carousel di `K8ZWOf` (4 slide) & `O8iAw5` (8 + 7 slide). Export ×2 → 1080×1350. | `campaign/carousel/` |
| Reels / Short 9:16 | 3 akun × 3 minggu × 2 = 18 video master | Scene dari `riung_ad_generator.html` (root repo); cover 9:16 sudah ada di `campaign.pen`. Teks penting jauhi bagian bawah (UI TikTok/Reels). | `campaign/reels/`, `campaign/reels/_master/` |
| Chat-style post/story | 3 akun × 6 = 18 | Basis: 8 frame `Riung Glass Chat: Si …` (414×896). | `campaign/chat/` |
| Story interaktif | 3 akun × 3 minggu = 9 | Poll ("Monster mana yang paling berisik?" — contoh layout `Kpuxq`), slider. | `campaign/story/` |
| Caption | 3 versi × 3 minggu = 9 | Template dari `CERNAK_BIRU_MARKETING_3_AKUN.md` bagian 3.3. | `campaign/captions/` |

### 2. Store / ASO

| Item | Status nyata | Yang tersisa |
|---|---|---|
| Feature graphic 1024×500 | **Sudah ada** (`rB1QZ`, EN: "Tame the monsters in your mind.") | Versi ID (lihat B-1) lalu export ×1. `docs/playstore-assets.md` baris 12 masih bilang "belum ada" → perbarui. |
| Screenshot Play | **Layout desain sudah ada**: 7 × 540×960 (`qS16h`) + 7 App Store 645×1398 (`btgSP`) | Pastikan isi mockup = UI app terbaru (Riung Glass) — bandingkan dengan screenshot app berjalan sebelum submit; buat versi ID. |
| Listing teks Play (ID) | Draft ada di `docs/playstore-assets.md` | Final review, privacy policy URL publik, content rating. |
| Listing App Store (EN) | Screenshot ada; teks belum | Judul, subtitle, keyword field, deskripsi EN. |
| Privacy policy | Draft di `docs/playstore-assets.md` | Host publik (GitHub Pages / Notion). |

### 3. Otomasi / workflow

| Item | Yang dibuat |
|---|---|
| SSOT ide | Notion/Airtable atau `campaign/ide_master.md` — 1 halaman/minggu, 1 ide → 3 adaptasi akun |
| Template adaptasi | `campaign/template_3akun.md` (dari bagian 3.3 blueprint) |
| Jadwal | Buffer/Later/n8n, 3 akun |
| Folder | `campaign/draft/`, `campaign/approved/`, `campaign/analytics/` |
| Checklist review | Dari `design/rencana-sosmed-3-akun.html` |

---

## B. GAP DI `design/campaign.pen` — status 2026-10-17

| # | Gap | Status | Frame |
|---|---|---|---|
| 1 | Chat per akun | ✅ Dibuat | `G0znMt` — CHAT_01 `.id` Si Waswas · CHAT_02 `.global` Si Sempurna · CHAT_03 `@riung` Si Kabut + Aplikasi Beku |
| 2 | Storyboard Reels | ✅ Dibuat (5 scene, mengikuti `riung_ad_generator.html`; Si Kabut & Si Waswas, keduanya gratis) | `NDW85` (REELS_01) |
| 3 | Store Listing ID | ✅ Dibuat — feature graphic + 7 screenshot Play, copy dari string app. Screenshot 7 (EN `RGZY1`, App Store `QzEHM`, ID `Gx1Ad`) diganti dari Kuis Besar "Profil Menunda" (Premium) → tes kepribadian gratis "16 tipe gaya Jung", skala 5 jawaban sesuai app | `GctBS` (STORE_ID), di bawah `lwIL5` |
| 4 | Campaign 3 post-launch | ✅ Dibuat ulang — "inti gratis": carousel Si Kabut / Si Mengelak / Si Meronta + CTA "7 monster. Semua gratis.", story Aplikasi Beku / "Yang gratis di Riung" (menggantikan Premium trial) / UGC | `R4qg9` (CAMP3_01) |
| 5 | Timeline internal | ✅ Dibuat — 3 minggu × 3 akun × 4 hari + checklist review (termasuk "hanya fitur gratis") | `ippZL` (AUTO_01) |
| 6 | Token Glass | ◐ Sebagian — token riung.pen yang hilang disinkron (`g-mist-*`, `g-glass-dark`); 97 fill/stroke exact-match → `$g-*`; Inter → `$g-font`. Sisa ±212 hex per board (putih ber-alpha, palet malam layar Tidur, `#B76E52`, `#5D4FA8`) belum punya token di riung.pen — perlu keputusan: tambah token atau biarkan sebagai warna mockup. | `lwIL5`, `GctBS` |

**Masih terbuka:**
- Mockup Tidur di board EN (`lwIL5`) memakai konten yang tidak ada di app ("Rain at the Foot of the Mountain", suara Forest/Campfire). Board ID sudah disamakan dengan app (4 cerita Oscar Wilde, 3 suara: Hujan/Ombak/Kipas angin); board EN belum. Durasi cerita di kedua board belum dicek.
- `riung_ad_generator.html` scene 5 menampilkan "4.9 · 12.400+ ulasan" — rating palsu sebelum rilis. Jangan dipakai di video; REELS_01 sudah menghapusnya.
- **Monster kebiasaan (Premium) masih muncul tanpa label berbayar** di board lama — jangan dijadwalkan sampai kampanye Premium diputuskan: landing page `VvgxP` (bagian "6 Big Quizzes", "Habit Monsters"), Campaign 1 `K8ZWOf` ("In your habits"), Campaign 2 Season 2 `O8iAw5` (Si ??? #08–#13, teaser "Who's still awake at 1 a.m.?"), chat lama Si Gulir (`d9war`, `ooVDO`) & Si Bara (`ChtFK`, `bOe4p`). Landing page perlu label "Premium" atau bagian itu disembunyikan sebelum dipublikasikan.
- Gating Premium monster kebiasaan + Kuis Besar belum ada di kode, dan CLAUDE.md §3 (daftar perk) belum memuatnya. Setelah dibangun: perbarui §3, lalu baru boleh ada kampanye Premium. Tes kesehatan mental tetap gratis.
- Tabel 1.1 di `CERNAK_BIRU_MARKETING_3_AKUN.md` masih menyebut "Bilingual carousel (EN+ID)" / "EN atas / ID bawah" untuk `@riung`; bagian 3.3 sudah diperbarui ke aturan i18n key.

---

## C. SUDAH ADA (jangan dikerjakan ulang)

| Item | Frame / file |
|---|---|
| Konsep 13 monster (7 Pikiran + 6 Kebiasaan) | `xlWFH` |
| Campaign 1 — Meet Riung (waitlist): carousel 4, story/TikTok 3, X/Threads 3 | `K8ZWOf` |
| Campaign 2 — 7 Monster Pikiran (carousel 8) + Season 2 Si ??? #08–#13 (carousel 7) + story/TikTok + X/Threads | `O8iAw5` |
| Feature graphic EN 1024×500 | `rB1QZ` (dalam `lwIL5`) |
| 7 screenshot Play + 7 App Store (EN) | `qS16h`, `btgSP` |
| App icon: A (Si Kabut), B, C "Riung gathering" (dipilih, berisi monster jinak) + adaptive Android + pratinjau mask | `ELS4p` |
| Chat per monster (8 klasik + 8 Riung Glass) | `YP1sE`, `fZAct`, … / `DuEeK`, `Ndm47`, … |
| Landing page EN | `VvgxP` |
| Aset monster & ikon fitur | `campaign/si_*.png` (hakim, hakim_liar, kabut, waswas, waswas_liar), `campaign/ikon_{fokus,meditasi,aplikasi_beku}.png`; ikon lain (termasuk `ikon_checkin.png`) ada di `design/aset3d_cut/` |
| Motion graphics | `campaign/riung_campaign_motion_graphics.html`, `riung_ad_generator.html` (root) |
| App icon sumber | `riung/assets/icon/icon.png` |

---

## URUTAN EKSEKUSI

| # | Apa | Di mana |
|---|---|---|
| 1 | Store Listing ID (B-1) + perbarui status di `docs/playstore-assets.md` | `campaign.pen`, docs |
| 2 | Cocokkan mockup screenshot dengan app berjalan | emulator/HP |
| 3 | Ide master Minggu 1–3 + template 3 akun | `campaign/` |
| 4 | Chat per akun, storyboard Reels, Campaign 3, timeline (B-2 s/d B-5) | `campaign.pen` |
| 5 | Rapikan token (B-6) | `campaign.pen` |
| 6 | Export (PNG ×2; feature graphic ×1) → review checklist → jadwal | Pencil export, Buffer/n8n |
| 7 | Submit Play Store (+ App Store) | Play Console / App Store Connect |

*Referensi: `design/campaign.pen`, `design/riung.pen`, `campaign/`, `CERNAK_BIRU_MARKETING_3_AKUN.md`, `design/rencana-sosmed-3-akun.html`, `docs/playstore-assets.md`, `riung_ad_generator.html`.*
