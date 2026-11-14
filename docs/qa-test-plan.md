# Riung — QA Full-App Test Plan (2026-11-14)

Device: Infinix `1215125453004629` (adb ok). Branch: `dev`.
Status: PLAN — eksekusi menunggu sesi Clubby selesai (pakai device & token bergantian).

## Fase 0 — Baseline otomatis (tanpa device, murah)
1. `flutter analyze` → 0 error/warning baru.
2. `flutter test` (48 file di `test/`) → catat yang gagal.
3. Grep guard: hex literal di `features/**/screens`, angka ekonomi lepas (bukan dari `economy.dart`), string UI di luar file strings.

## Fase 1 — Audit statis rute & konsistensi (subagent caveman, paralel per flow)
Tiap agent `caveman:cavecrew-investigator` 1 flow, output tabel `file:line`:
- Semua `Navigator.push*/pop` + target layar (88 file) → graf rute. Cari: layar yatim (tak pernah dibuka), dead-end (tak ada back/keluar), push ke layar salah, `pop` ganda, argumen null.
- Bandingkan urutan layar, copy, tombol vs `design/<Flow>.dc.html` → daftar missing/beda.
- Cek 5 state (empty/loading/error/success/offline) per layar.

Flow (13 desain + fitur tambahan):
| Flow | Layar (`lib/features/...`) |
|---|---|
| Launch | splash, masuk, daftar, lupa_sandi, izin_notifikasi |
| Onboarding | onboarding_flow |
| Home | root_shell, beranda, jelajah, kartu_pemain, koin_histori, focus_timer, sesi_selesai, beranda_tiket_serangan |
| Focus | focus_mode_entry, toko/beli_sesi_fokus |
| Meditasi | list, search, detail, player, selesai |
| Tidur | list, detail, player, selesai, pengingat, laporan_pagi |
| Jurnal | home, prompt, editor, simpan, detail, pin_setup/unlock/recover, backup |
| Afirmasi | kategori, kartu, buat, bagikan, pengingat |
| Checkin | mood, factor, note, hasil, riwayat |
| Monster | vault, saboteur_detail, hakim_detail, waswas_stage_map, waswas_breathing_node, habit_stage_map/detail/practice, tamed_celebration |
| Minigame | intro, waswas_reaction, block_breaker, win, lose, daily_cap |
| Profil | profil, edit, pengaturan, notifikasi, langganan, kalender_latihan, jurnal_pin_setting, ekspor_data, hapus_akun, kebijakan_privasi, bantuan_krisis |
| Toko | toko, lemari, koin_kurang, paywall_premium, pembelian_sukses, pembelian_dipulihkan |
| AppBeku | setup, permission, picker, interstitial, napas, post_breathing, rekap |
| Ekstra | betterme (6), kenali_dirimu (6), kepribadian (3), laporan |

## Fase 2 — E2E manual di Infinix (adb + screenshot, `device_snap/`)
`flutter run --release` / `-d 1215125453004629`. Per flow: jalankan happy path, back button tiap layar, rotasi/kill-restore, mode pesawat (offline).
Skenario wajib:
- Akun: anon → daftar/link, masuk, lupa sandi, keluar, hapus akun.
- Ekonomi: check-in +5, jurnal +4, meditasi +3, misi +3, menang game +8, jinak +50; saldo hanya berubah via server (cek setelah reload).
- Tiket: 1 gratis/hari, max 3 dari latihan, max 4 fight/hari → daily_cap muncul.
- Koin kurang → tawarkan latihan dulu sebelum beli (garis etis).
- Billing: test purchase koin pack 80 & Premium trial (akun tester Play), restore.
- Premium gate: konten terkunci tampil paywall; perk sesuai CLAUDE.md.
- AppBeku: izin overlay+usage, kunci app, buka-berbayar max 3/hari, +10 koin, jeda 60 dtk, hanya koin latihan.
- Krisis: `bantuan_krisis` terjangkau dari mana saja, tidak dilog.
- Jurnal PIN: setup, unlock, recover, backup/restore terenkripsi.
- Monster: render art + aksesori, celebrate jinak, progres tak naik via beli.
- Notifikasi: pengingat afirmasi/tidur/check-in muncul.
- Layar 360dp: cek overflow (adb `wm size 720x1520` lalu reset).

## Fase 3 — Laporan
`docs/qa-report-2026-11.md`: tabel temuan (flow, layar, severity, repro, screenshot). Bug → `MOBILE_TASKS.md`; butuh desain → `DESIGN_TASKS.md`; backend → `BACKEND_TASKS.md`. Fix menyusul setelah review user.

## Hemat token
- Caveman mode on; subagent `cavecrew-investigator` untuk audit statis (output terkompresi).
- Screenshot device scale kecil, hanya saat ada anomali.
- Jalankan Fase 0–1 dulu (tanpa device) — bisa paralel dengan Clubby; Fase 2 setelah Clubby lepas device.
