# Riung — QA Report Fase 0–1 (2026-11-14)

Scope: audit statis (tanpa device). Fase 2 (E2E Infinix) belum jalan. Temuan Fase 1 dari subagent, belum diverifikasi manual satu-satu.

## Fase 0 — Otomatis
- `flutter test`: **367 lulus, 1 gagal** — `test/screen_state_contract_test.dart:63`: `lib/features/jurnal/screens/jurnal_backup_screen.dart` memuat data tanpa `RiungStateView/RiungAsyncView` (dari commit 03d68fe).
- `flutter analyze`: 0 error, 2 warning `unawaited_return_in_try_block` di `core/services/firebase/firestore_content_repository.dart:31,47` (error Future lolos dari try), ~60 info (lint gaya).
- Guard token/copy:
  - Hex literal: `features/onboarding/widgets/rate_us_step.dart:144-150,242` (8 warna Google), `features/kepribadian/widgets/card_background_painter.dart:23`.
  - `features/profil/screens/pengaturan_screen.dart:170` — `'Riung v1.0.0'` hardcode, app = 1.1.0+10.

## Fase 1 — Pelanggaran aturan non-negotiable (prioritas 1)
| # | File | Masalah |
|---|---|---|
| E1 | `appbeku/screens/appbeku_post_breathing_screen.dart:82-85` | Buka-berbayar tanpa jeda 60 dtk, tanpa cek cap 3/hari di UI |
| E2 | `appbeku/widgets/appbeku_toko_section.dart:171-200` | Grid buka-waktu & bundel di toko tanpa jeda 60 dtk |
| E3 | `core/state/appbeku_notifier.dart:42` | Bundel: hanya app pertama dihitung buka → cap 3/hari bocor |
| E4 | `appbeku/widgets/appbeku_toko_section.dart:93-96` | Koin latihan kurang → snackbar saja, tidak tawarkan latihan (KoinKurang) |
| E5 | home/checkin/jurnal | `BantuanKrisisScreen` tidak terjangkau dari beranda/check-in/jurnal ("selalu bisa diakses"). Tidak dilog — OK |

### Status perbaikan (14/11, 1.2.2+13)
- E1, E2: FIXED — `CooldownPaidUnlockButton` (post-breathing) & `cooldownSeconds` di `showKonfirmasiPembelianSheet` (toko); + busy guard, info sisa jatah.
- E3: BUKAN BUG — bundel = 1 pembelian = 1 buka-berbayar, disengaja (doc `unlockMinutes` "satu bundel dihitung sekali"); harga bundel lebih mahal.
- E4: FIXED — snackbar + aksi check-in (KoinKurang tidak cocok: koin total cukup, tombol top-up tak berguna).
- E5: FIXED sebagian — `BantuanKrisisLink` di hasil check-in & simpan jurnal; dari Beranda via tab Profil (2 ketuk). Belum ada di desain → perlu tugas DESIGN.

## Fase 1 — Bug HIGH/MED
**Route / layar yatim**
- `home/screens/beranda_tiket_serangan_screen.dart` — tak pernah dibuka (ada di desain Home).
- `tidur/screens/tidur_laporan_pagi_screen.dart` — tak pernah dibuka (ada di desain Tidur); tombol `tryTonightStory` cuma `maybePop` (:48).
- `focus/screens/focus_mode_entry_screen.dart:47` — di-push dari beranda/pembelian_sukses/kenali tanpa tombol back/header.
- `toko/screens/toko_screen.dart` — hanya dari profil & koin_kurang; cek entry dari KoinChip/Beranda vs desain.

**Data hilang / salah**
- `checkin/screens/checkin_note_screen.dart:41-60` — tanpa try/catch; gagal → tombol macet.
- `checkin/screens/checkin_note_screen.dart:49` — `uid == null` skip simpan tapi tampil sukses.
- `checkin/screens/checkin_note_screen.dart:65` — back dari Hasil ke Faktor → bisa submit ulang.
- `home/screens/sesi_selesai_screen.dart:41` — jalur offline hardcode `saboteurId 'waswas'` → progres ke monster salah. `:18` ticketId null online → sesi tak tercatat; `:34` analytics hanya offline.
- `appbeku/screens/appbeku_interstitial_screen.dart:58-77`, `appbeku_post_breathing_screen.dart:18-36`, `minigame/screens/minigame_intro_screen.dart:36` — tanpa busy guard → double-tap potong koin/tiket 2×.
- `core/state/appbeku_notifier.dart:65` — ApiException (offline) di-rethrow, caller tanpa catch → error tak tertangani.
- `toko/screens/lemari_screen.dart:50` — simpan loadout tanpa try/catch/busy.
- `profil/screens/langganan_screen.dart:36` — `PremiumOffer.load()` gagal → loading selamanya.

**Gating Premium tidak konsisten**
- BetterMe: gate hanya di `betterme_home_screen.dart:48,65,191`; `level_intro/sesi_detail/sesi_content` tanpa cek; `saboteur_detail_screen.dart:49` & `hakim_detail_screen.dart:175` push level 1 langsung (dan selalu level 1, abaikan progres).
- Kenali: hub tampilkan tile terbuka untuk user gratis dengan hasil lama, tapi quiz (`kenali_quiz_screen.dart:86`) paywall; retake (`kenali_hasil_screen.dart:104`) pushReplacement → hasil hilang, mendarat di paywall.
- Kepribadian: tile terkunci tetap push quiz (`kepribadian_hub_screen.dart:35`).

**Navigasi**
- `meditasi/screens/meditasi_selesai_screen.dart:91` — "Ulangi sesi ini" balik ke Detail, bukan ulang.
- `betterme/screens/betterme_sesi_selesai_screen.dart:83-85` — `pop()` ganda, asumsi stack.
- `betterme/screens/betterme_milestone_screen.dart:106` — `popUntil(isFirst)` buang asal.
- `appbeku/screens/appbeku_post_breathing_screen.dart:80` — "Tutup aplikasi" tidak `moveToBack` saat fromLock.
- `minigame/screens/minigame_daily_cap_screen.dart:66-68` — cara dapat tiket tidak bisa ditap (dead-end).
- `toko/screens/koin_kurang_screen.dart:120` — pushReplacement ke Toko → result caller hilang.
- `checkin/screens/checkin_hasil_screen.dart:22` — `pushAndRemoveUntil(RootShell)` reset state tab.

**Fitur di desain tapi palsu/hilang**
- Tombol "Unduh" meditasi (`meditasi_detail_screen.dart:71`) & tidur (`tidur_detail_screen.dart:66`) cuma snackbar.
- Layar "Meditasi offline": error audio ditelan, timer jalan (`meditasi_player_screen.dart:54`, `tidur_player_screen.dart:55`).

**Error state hilang (MED)**
- Pengingat afirmasi/tidur `_simpan` tanpa error/busy; favorit afirmasi tanpa rollback; laporan: gagal Health Connect menimpa laporan jadi error (`laporan_screen.dart:55-60`).

## LOW (ringkas)
~35 item: force-unwrap (`bantuan_krisis_screen.dart:143` `line.url!` — crash bila line tanpa tel & url), `firstWhere` tanpa orElse (`sesi_content_screen.dart:57`), `unlocksLeftToday` bisa negatif, nama monster hardcode `'kabut'` (`appbeku_interstitial_screen.dart:86`), state loading/error kurang di rekap/picker/kartu_pemain/profil/jelajah/jurnal_pin_setting, retake minigame potong tiket tanpa konfirmasi, dll. Detail di transkrip sesi audit.

## Lolos
- Koin kurang tawarkan latihan dulu (`koin_kurang_screen.dart:116`). Progres monster tak bisa dibeli. Interstitial AppBeku patuhi 3/hari, +10, 60 dtk, koin latihan.
- Laporan: bulanan Premium, mingguan gratis. Layar krisis tidak dilog.
- Semua layar `.dc.html` (13 flow) punya padanan kode kecuali 2 yatim di atas.

## Next
Fase 2 di Infinix setelah Clubby: verifikasi E1–E5 + HIGH di device, lalu fix.

## Fase 2 — Infinix (15/11, debug 1.2.2+13) — sebagian
Bukti: `device_snap/qa/`.

| # | Sev | Temuan | Repro |
|---|---|---|---|
| D1 | BUKAN BUG | Jurnal sempat terbuka saat uji awal karena pemilik HP menyentuh sensor sidik jari (dikonfirmasi user 15/11). Uji ulang 4× dengan log: jurnal tetap terkunci. Ditutup | — |
| D2 | MED | Layar krisis default **United States / 988** untuk user Indonesia: negara diambil dari locale HP (`en-US`), bukan SIM (`id`) — `bantuan_krisis_screen.dart:31` | HP berbahasa Inggris, SIM Indonesia |
| D3 | LOW | Sapaan check-in "Pagi, . Gimana rasanya hari ini?" — nama kosong tidak ditangani | User anonim tanpa nama |

Terverifikasi OK: check-in penuh (mood → faktor → catatan → hasil), +5 koin & streak 1; tautan krisis di Hasil check-in (E5) membuka layar krisis & back kembali ke Hasil.

Belum diuji di device: E1/E2 (saldo 9 < harga 15; layar "Setelah napas" butuh pemicu kunci), E5 di Simpan jurnal (butuh sidik jari pemilik), flow lain Fase 2.

## Perbaikan pra-rilis (15/11, 1.2.3+14)
FIXED: check-in tanpa uid/gagal simpan (pesan + coba lagi), back dari Hasil → Beranda; ketuk-ganda interstitial AppBeku & mulai minigame; `sesi_selesai` offline pakai `saboteurId`; D2 negara krisis dari SIM (`AppUsageService.simCountry`); `line.url!`; buka-waktu offline → `showApiError`; Langganan gagal muat → fallback; versi app dari PackageInfo; 2 warning analyze. `jurnal_backup_screen` masuk `loaderAllowed` (memuat hanya saat tombol diketuk).
Sisa → `MOBILE_TASKS.md` MOB-005…MOB-010.

## Fase 2b — E2E install bersih (15/11 malam, debug 1.2.3+14, data app dihapus)
Bukti: `device_snap/qa/e2e_*.png`. PIN jurnal uji di HP: 135790.

Lolos: sambutan 3 hlm → asesmen 17 soal → cerita → nama → 4 fakta → hasil monster → paywall → versi gratis → Beranda; check-in +5 & streak 1; back dari Hasil → Beranda; buat PIN jurnal + entri +4; misi harian +3 (sekali); 4 serangan memotong tiket 4→0, layar "Tiket harianmu habis"; koin kurang di Fokus menawarkan latihan dulu; transisi meredup ke Tidur (Beranda & tab Jelajah).

| # | Sev | Temuan | Lokasi/catatan |
|---|---|---|---|
| T1 | HIGH | Mode server: tiket = `fightsRemainingToday` (4) — user baru langsung 4 serangan tanpa latihan; check-in/jurnal tidak menambah tiket. Aturan "1 gratis + maks 3 dari latihan" tidak berlaku. Teks "1 gratis + 3 latihan" dihitung, bukan nyata | `wallet_notifier.dart:50,257,270`; server tidak punya saldo tiket → BACKEND |
| F1 | HIGH | Tab Fokus: tombol "Mulai fokus" tertutup navbar bawah saat pesan koin-kurang muncul (y 2214–2376 vs nav 2202–2370) | `focus_mode_entry_screen` mode tab |
| F2 | MED | Label tombol "Mulai fokus 45 menit • gratis hari ini" — gratis hanya 25 mnt; 45 = 40 koin | focus entry |
| G1 | MED | HP Si Hakim selalu 100% di awal game walau tiap kalah tertulis "−2%" (4×) | minigame |
| G2 | MED | "Coba lagi (1 tiket)" & "Mulai serangan" tetap aktif di 0 tiket (baru ditolak setelah ditekan) | minigame lose/intro |
| G3 | LOW | "Kembali ke Vault" di layar tiket habis mendarat di Beranda | `minigame_daily_cap_screen` |
| K1 | MED | Histori koin: jam UTC (12.52 padahal 19.52 WIB); semua label "Koin masuk", bukan sumbernya | `koin_histori_screen` |
| C1 | LOW | Check-in jam 19:50 menyapa "Pagi, Tester" & "SARAN BUAT PAGIMU" | checkin mood/hasil |
| O1 | LOW | Opsi berkutip asesmen (soal 9, 13) tanpa label aksesibilitas | onboarding question |
| O2 | INFO | "Isi nanti" di soal Cerita = jeda seluruh asesmen; Beranda lalu bilang "belum selesai" walau 17/17 dijawab. Cerita wajib | by design? |
| O3 | INFO | Paywall: harga "tampil di Google Play" + Coba lagi — wajar untuk APK debug sideload; cek di build Play internal |
| J1 | LOW | Beranda jurnal "Tulis bebas" membuka layar pilih yang menampilkan "Tulis bebas" lagi (2 ketuk) | jurnal |

Belum diuji: login/daftar/masuk akun, meditasi +3 (sesi penuh), menang game +8, jinak +50, streak hari ke-2, pelindung streak, Toko/kosmetik, Aplikasi Beku di device, billing nyata.

### Perbaikan fase 2b (15/11/2026)

| ID | Status | Verifikasi |
|---|---|---|
| F1 | ✅ | Tombol "Mulai fokus" dipaku di bawah, y 1914–2076 di atas navbar app (2130) dengan navbar sistem 3-tombol aktif — tanpa scroll |
| F2 | ✅ | 45 menit → "Mulai fokus 45 menit • 40 koin"; jatah gratis offline juga hanya untuk 25 menit |
| G1 | ⚠️ kode | HP bos mulai dari 100 − progres; belum diuji main (tiket 0 di HP uji) |
| G2 | ✅ | Intro tiket 0 → tombol "Tiket harianmu habis"; layar kalah/menang juga |
| G3 | ✅ | "Kembali ke Vault" mendarat di tab Monster |
| K1 | ✅ | Histori: "Misi harian · 20.04", "Entri jurnal · 19.53", "Check-in harian · 19.52" (jam lokal) |
| C1 | ⚠️ kode | Sapaan & label saran ikut jam; check-in hari ini sudah dipakai, belum diuji di HP |
| Chip | ✅ | Chip "−5%" sejajar dengan chip berikon (intro serangan) |
| Navbar sistem | ✅ | Diuji dengan overlay `navbar.threebutton`: navbar app, tombol intro & Fokus di atas navbar sistem; sheet bahasa & pilih aplikasi diberi padding inset |
