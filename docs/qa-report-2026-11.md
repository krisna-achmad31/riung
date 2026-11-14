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
