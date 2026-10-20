# Fix C-01 — Isolasi data lokal per akun (jurnal, check-in, PIN, prefs)

- **Tanggal:** 2026-10-17
- **Branch:** `fix/audit-hardening` (belum di-commit)
- **Sumber temuan:** `docs/audit-kelayakan-2026-10.md` → C-01 (🔴 Critical) & §"Solusi C-01"
- **Hasil:** `flutter analyze` tanpa error/warning baru · `flutter test` **324/324 lulus** (sebelumnya 320; +4 test baru, 2 REPRO dibalik)

## Masalah

Logout tidak membersihkan maupun mengisolasi data lokal. Tabel `journal_entries` & `checkin_history` tidak punya `user_id`, kunci enkripsi jurnal & PIN berlaku untuk seluruh perangkat, dan prefs domain-user (kosmetik, hasil tes, BetterMe, afirmasi, cadangan koin-beli, dll.) bersifat global. Akibatnya **akun B di HP yang sama bisa membaca jurnal, mood, dan prefs akun A**, dan batas jurnal harian ikut terhitung bersama.

## Solusi yang diterapkan

### 1. Database sqflite — migrasi v3
`riung/lib/core/services/local_database_service.dart`
- `version: 3`; `onUpgrade` menambah `user_id TEXT` ke `journal_entries` & `checkin_history`; `onCreate` langsung menyertakan kolom itu.
- Semua akses wajib uid: `insertJournalEntry(uid, row)`, `allJournalEntries(uid)`, `journalEntryById(uid, id)`, `journalEntryCountForDate(uid, iso)`, `insertCheckIn(uid, row)`, `allCheckIns(uid)` — semuanya `WHERE user_id = ?`.
- `adoptOrphanRows(uid)`: baris lama (`user_id IS NULL`) diserahkan ke pemilik terakhir.

### 2. Repository meneruskan uid
`riung/lib/core/services/local_user_repository.dart`
- `getJournalEntries`, `saveJournalEntry`, `journalEntryCountForDate`, `getCheckIns`, `saveCheckIn`, `hasCheckedInToday` kini meneruskan `uid` (sebelumnya diabaikan).
- `deleteAllLocalData()` memanggil `crypto.deleteAllKeys()`.

### 3. Kunci enkripsi & PIN per uid
- `journal_crypto_service.dart`: kunci `riung_jurnal_aes_key_v1_<uid>`, cache per uid. API: `encryptText(uid, text)`, `decryptText(uid, stored)`, `adoptLegacyKey(uid)`, `deleteAllKeys()`.
- `jurnal_pin_service.dart`: PIN `riung_jurnal_pin_v1_<uid>`. API: `hasPin(uid)`, `setPin(uid, pin)`, `verifyPin(uid, pin)`, `clearPin(uid)`, `adoptLegacyPin(uid)`.
- Pemanggil disesuaikan: `jurnal_home_screen`, `jurnal_pin_setup/recover/unlock_screen`, `kepribadian_hub_screen`, `hapus_akun_screen` (PIN dihapus dengan uid yang ditangkap sebelum sign-out).
- `kenali_result_repository.dart`: memakai `prefs.accountUid` untuk kunci; tambah `reload(prefs)` saat akun berganti.

### 4. Prefs domain-user per uid
`riung/lib/core/services/local_prefs_store.dart`
- `bindAccount(() => uid)` + helper `_u(key)` → `'${key}_$uid'` (pola sama dengan `intro_seen_v1_$uid`).
- **Di-scope (33 key):** onboarding_done, coins, lifetime earned/spent, streak current/longest, last check-in, monster progress, user profile, favorit & afirmasi custom, tiket (saldo/earned/fights/reset), kosmetik dimiliki, fokus prabayar, perisai streak, cadangan koin-beli, fokus gratis (tanggal/terpakai), klaim harian Premium, biometrik jurnal, BetterMe (selesai/refleksi), misi, hasil kepribadian, gaya kartu, aksesori, kosmetik monster, peta Waswas, hasil Kenali (cipher), peta kebiasaan.
- **Tetap global (pengaturan perangkat):** bahasa, notifikasi, jam afirmasi, pengingat tidur, sinkron tidur (Health Connect), Aplikasi Beku (daftar app, state harian, mode kunci), `riung_uid`.
- `adoptLegacyAccountData(owner)`: memindahkan key global lama ke key milik pemilik, lalu menghapus key lama. Penanda `riung_account_scope_v1_owner`.
- `notifyAccountChanged()`: menaikkan revisi kepribadian/kosmetik monster/peta kebiasaan supaya UI membaca ulang.
- `LocalPrefsStore.forTesting(...)` (`@visibleForTesting`).

### 5. Migrasi sekali jalan
`riung/lib/core/services/legacy_account_migration.dart` (baru, diekspor dari `services.dart`)
- Pemilik = `riung_uid` ?? uid Firebase yang sedang login. Bila belum diketahui → dicoba lagi saat start berikutnya.
- Urutan: adopsi baris DB → kunci jurnal → PIN → prefs (penanda ditulis terakhir, jadi kegagalan di tengah diulang utuh).
- Dipanggil di `main()` sebelum `KenaliResultRepository.load`, dibungkus try/catch.

### 6. Reset state saat logout / pindah akun
- `clearSession()` baru di `WalletNotifier`, `StreakNotifier`, `MonsterProgressNotifier`, `SessionNotifier` (timer Fokus dihentikan tanpa dihitung selesai).
- `main.dart`: `widget.prefs.bindAccount(() => _authService.currentUid)`; `_onAuthUidChanged` memanggil `_clearAccountState()` → `ApiState.clearSession()`, semua `clearSession()` notifier, reset `_premiumRestoreTried`, `prefs.notifyAccountChanged()`, `KenaliResultRepository.reload()`.

## Test

| File | Perubahan |
|---|---|
| `test/audit_billing_api_test.dart` | REPRO C-01 (prefs) dibalik: B melihat kosmetik/fokus/perisai kosong, A tetap utuh saat masuk lagi. REPRO C-01 (jurnal) dibalik: uid `akun-B` diteruskan ke jurnal, hitungan harian, dan check-in. **Baru:** migrasi prefs global → pemilik terakhir (bahasa tetap global, tidak jalan dua kali); PIN per uid + adopsi PIN lama. |
| `test/critical_logic_test.dart` | Test crypto disesuaikan ke API per uid; `deleteKey` → `deleteAllKeys`. **Baru:** akun B tidak bisa membaca ciphertext A; kunci lama diadopsi pemiliknya. |
| `test/data_export_test.dart` | `riung_account_scope_v1_owner` masuk daftar pengecualian ekspor (penanda migrasi, bukan data user). |

## Menunggu persetujuan — copy `signOutBody`

Copy saat ini menyesatkan ("Progresmu tersimpan…"). Usulan (belum diubah):
- **ID:** "Jurnal dan catatanmu tetap tersimpan aman di HP ini, dan hanya terbuka lagi saat kamu masuk dengan akun yang sama."
- **EN:** "Your journal and notes stay safe on this phone, and only open again when you sign back in with the same account."

Lokasi: `riung/lib/core/l10n/strings/profil_strings.dart` (`signOutBody`, ID & EN).

## Belum terverifikasi / follow-up

1. Migrasi `ALTER TABLE` v2→v3 belum diuji di sqflite asli (proyek tidak punya `sqflite_common_ffi`) — cek sekali di HP: pasang build lama, tulis jurnal, upgrade, pastikan jurnal masih terbaca.
2. `deleteAllLocalData()` (Hapus akun) masih menghapus data **semua** akun di HP, bukan hanya akun yang dihapus.
3. Akun anonim yang logout: datanya tetap di HP tetapi tidak bisa diakses lagi (uid anonim hilang).
4. Uji manual end-to-end di HP: akun A tulis jurnal → logout → masuk akun B → jurnal/mood/kosmetik kosong → masuk lagi akun A → data A kembali.
