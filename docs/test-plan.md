# Riung — Test Plan & Laporan Pengujian

Tanggal: 2026-10-17 · Branch: `fix/audit-hardening` · Versi: 1.0.2+3
Perintah: `cd riung && flutter test` (semua test berjalan offline, tanpa Firebase/server asli).

## Ringkasan eksekusi

| | Jumlah |
|---|---|
| Test sebelum sesi ini (baseline) | 242 — semua PASS |
| Test baru (`test/critical_logic_test.dart`) | 34 |
| Total setelah perbaikan | **276 — semua PASS** |
| Bug ditemukan oleh test baru | 2 (sudah diperbaiki) + 1 robustness (rekomendasi) + 4 minor |

> Catatan cakupan: semua test adalah unit/widget test dengan fake & mock
> (`SharedPreferences.setMockInitialValues`, `FlutterSecureStorage.setMockInitialValues`,
> fake HTTP transport). Belum ada integration test di perangkat
> (`integration_test/`), test aturan `firestore.rules` (emulator), atau test
> Google Play Billing sungguhan — lihat "Celah yang tersisa".

---

## 1. Skenario pengujian

Legenda status: ✅ tercakup test otomatis · 🆕 ditambah sesi ini · ⚠️ manual/belum otomatis.

### 1.1 Ekonomi & Wallet (aturan CLAUDE.md #3, #5)
| # | Skenario | Jenis | Status |
|---|---|---|---|
| W1 | Angka earn/spend/tiket/coin pack/Premium sama dengan CLAUDE.md §3 | happy | ✅ `economy_and_wallet_test` |
| W2 | Earn lalu spend → saldo, lifetimeEarned/Spent benar & persist | happy | 🆕 |
| W3 | Spend > saldo → `InsufficientCoinsException`, saldo tidak berubah | error | 🆕 ✅ |
| W4 | Spend tepat = saldo → saldo 0 | edge | 🆕 |
| W5 | Jumlah **negatif** pada earn/spend ditolak | input tidak valid | 🆕 (BUG-1) |
| W6 | Spend 0 koin (sub-langkah bundel Aplikasi Beku) = no-op | edge | 🆕 |
| W7 | Koin beli tidak bisa dipakai buka-waktu Aplikasi Beku; harga bertingkat, maks 3×/hari | etis | ✅ `appbeku_test`, `ethics_guardrails_test` |
| W8 | Tiket: 1 gratis/hari, max 3 dari latihan, max 4 fight/hari, reset harian | edge | ✅ |
| W9 | Anonim → wallet lokal; login → cloud; status auth dibaca ulang per panggilan | routing | 🆕 |
| W10 | Respons mutasi server otoritatif walau bootstrap berikutnya offline | jaringan buruk | ✅ `api_outbox_test` |
| W11 | Riwayat transaksi lokal kosong (bukan data karangan) | empty state | 🆕 |

### 1.2 Monster & progres (aturan #4, #7)
| # | Skenario | Jenis | Status |
|---|---|---|---|
| M1 | wild → taming → tamed; progres dijepit 0..100 | happy/edge | 🆕 |
| M2 | Reward jinak (+50) hanya sekali, tidak dobel setelah tamed | edge | 🆕 |
| M3 | Delta negatif tidak membuat progres < 0 | input tidak valid | 🆕 |
| M4 | Progres per monster terisolasi | happy | 🆕 |
| M5 | Pembelian tidak pernah menaikkan progres monster | etis | ⚠️ belum ada test otomatis (lihat §3) |
| M6 | Anchor, `bossScale`, slot `none`, semua file art ada | render | ✅ `riung_monster_render_test`, `art_assets_test` |

### 1.3 Jurnal & enkripsi (aturan #5)
| # | Skenario | Jenis | Status |
|---|---|---|---|
| J1 | Roundtrip enkripsi teks (emoji, multi-baris) | happy | 🆕 |
| J2 | IV acak: teks sama → ciphertext berbeda | keamanan | 🆕 |
| J3 | Kunci persist antar instance | happy | 🆕 |
| J4 | Data rusak tanpa pemisah → `''`, bukan crash | input tidak valid | 🆕 |
| J5 | Teks kosong dienkripsi/didekripsi | edge | 🆕 (BUG-2) |
| J6 | Setelah `deleteKey` (hapus akun) ciphertext lama tak terbaca | keamanan | 🆕 (lihat BUG-3) |
| J7 | Editor tidak menyimpan jurnal kosong; gagal simpan → sheet error | error | ⚠️ manual |
| J8 | Sinyal jurnal: hanya metadata 30 hari, batas jam pagi/siang/sore/malam | edge | 🆕 |

### 1.4 Asesmen & skoring (aturan #8)
| # | Skenario | Status |
|---|---|---|
| A1 | Skor onboarding sesuai `docs/assessment-scoring-spec.md`, bisa dihitung ulang | ✅ `scoring_engine_test` |
| A2 | Kenali Dirimu & kepribadian: mapping dari config, terjemahan lengkap | ✅ `kenali_*`, `personality_scoring_test` |
| A3 | Draft asesmen tersimpan & pulih setelah app ditutup | ✅ `assessment_draft_test` |
| A4 | Tes klinis tidak memberi monster/koin | ✅ |

### 1.5 API / jaringan buruk
| # | Skenario | Status |
|---|---|---|
| N1 | Path & body sesuai kontrak Postman untuk semua domain | ✅ `api_client_test`, `api_contract_parity_test` |
| N2 | Retry aksi finansial memakai idempotency key yang sama | ✅ |
| N3 | Balasan delete hilang lalu 401 → dianggap terhapus | ✅ |
| N4 | Outbox: event offline dikirim ulang, dibuang setelah `maxOutboxAttempts` | ✅ `api_outbox_test` |
| N5 | Retry tidak melebihi `maxRetryLimit` | ✅ |
| N6 | Tanggal mengikuti zona waktu server melewati batas hari UTC | ✅ `api_outbox_test`, `device_time_zone_test` |
| N7 | Validasi receipt pembelian sebelum koin/Premium aktif | ✅ `api_billing_test`, `toko_and_billing_test` |
| N8 | Konten gagal dimuat → state error + retry; offline → banner | ✅ `api_content_loading_test`, `screen_state_contract_test` |

### 1.6 Input tidak valid
| # | Skenario | Status |
|---|---|---|
| I1 | Karakter kontrol & penanda arah (U+202E dsb.) dibuang | 🆕 |
| I2 | Baris baru dibuang pada field satu-baris | 🆕 |
| I3 | Dipotong ke batas (nama 40, jurnal 5000, …), spasi tepi dirapikan | 🆕 |
| I4 | Pemotongan tidak membelah emoji (surrogate pair) | 🆕 |
| I5 | Parser model toleran tipe salah (string angka, double, map Timestamp, enum lama) | 🆕 |

### 1.7 UI, layar & etis
| # | Skenario | Status |
|---|---|---|
| U1 | App boot ke Splash lalu navigasi tanpa error | ✅ `widget_test` |
| U2 | Layar data memakai `RiungStateView`/skeleton (kontrak state seragam) | ✅ `screen_state_contract_test` |
| U3 | Tidak overflow di 360dp | ✅ (sebagian layar) |
| U4 | Layar koin-kurang menawarkan latihan sebelum beli; krisis selalu terbuka & tidak dilog | ⚠️ belum ada test otomatis (lihat §3) |
| U5 | Copy Bahasa Indonesia lengkap di semua string | ✅ `l10n_test` |
| U6 | Kunci Aplikasi Beku (overlay, izin, rute keluar) di perangkat | ⚠️ manual di HP |

---

## 2. Laporan bug

### BUG-1 — Spend dengan jumlah negatif MENAMBAH koin · Severity: Sedang · ✅ diperbaiki
- **Gejala**: `spendCoins(amount: -100)` lolos cek `coins < amount`, lalu `coins - (-100)` = saldo bertambah 100 dan `lifetimeSpent` jadi negatif. `earnCoins` dengan nilai negatif juga diterima.
- **Penyebab**: `LocalWalletFunctionsService` & `FirestoreWalletFunctionsService` tidak memvalidasi tanda `amount`. Saat ini semua pemanggil memakai konstanta `economy.dart` sehingga belum tereksploitasi, tapi satu harga hasil hitungan yang salah (mis. diskon bundel) bisa langsung mencetak koin — melanggar invarian wallet.
- **Perbaikan**: helper `checkCoinAmount()` di `lib/core/services/wallet_functions_service.dart` menolak `amount < 0` dengan `ArgumentError`, dipanggil di awal earn/spend kedua implementasi. Nol tetap diizinkan karena `AppBekuNotifier.unlockMinutes` memang memotong 0 koin untuk sub-langkah bundel.
- **Test**: `jumlah negatif ditolak…`, `spend 0 koin … adalah no-op`.

### BUG-2 — Enkripsi teks kosong crash (`RangeError`) · Severity: Rendah (laten) · ✅ diperbaiki
- **Gejala**: `JournalCryptoService.encryptText('')` melempar `RangeError (start): Invalid value: Only valid value is 0: -16` dari pointycastle.
- **Penyebab**: bug padding di package `encrypt` 5.x untuk input kosong. Editor jurnal saat ini menolak teks kosong, jadi belum terpicu dari UI, tapi `encryptText` dipakai juga oleh `KenaliResultRepository` dan jalur lain di masa depan.
- **Perbaikan**: `encryptText` mengembalikan `''` untuk input kosong; `decryptText('')` sudah mengembalikan `''` (tidak ada pemisah), jadi formatnya tetap konsisten.

### BUG-3 — Satu entri jurnal tak terdekripsi menggagalkan seluruh daftar · Severity: Rendah · rekomendasi
- **Gejala**: `LocalUserRepository.getJournalEntries` memanggil `decryptText` per baris tanpa `try/catch`. Bila satu ciphertext tidak bisa dibuka (kunci Keystore hilang/korup di beberapa OEM, data parsial), seluruh layar jurnal masuk state error dan pengguna tidak bisa melihat entri lain.
- **Mitigasi yang sudah ada**: backup cloud/transfer perangkat dimatikan (`data_extraction_rules.xml`), sehingga skenario "DB pulih tanpa kunci" sangat jarang.
- **Rekomendasi**: tangkap error per baris di `_journalEntryFromRow`, lewati atau tandai entri sebagai "tidak bisa dibuka", catat ke Crashlytics tanpa isi jurnal. Tidak saya ubah karena ini keputusan UX (copy & tampilan entri rusak perlu desain).

### Temuan minor (tidak diubah)
1. `JournalSignals.from` — saat jumlah seri, pemenang `topMood/topTag` bergantung urutan `List.sort` (tidak stabil). Rekomendasi: tie-break berdasarkan entri terbaru atau abjad.
2. `colorToHex` membuang kanal alfa → roundtrip warna transparan hilang. Aman selama hanya dipakai untuk warna opak.
3. `parseHexColor('#FFF')` (shorthand 3 digit) menghasilkan warna hampir transparan, bukan putih. Tambahkan ekspansi 3 digit atau tolak ke fallback.
4. `parseDate` untuk map Timestamp hanya menerima `seconds` bertipe `int` dan mengabaikan `nanoseconds`.

---

## 3. Celah yang tersisa (rekomendasi berikutnya)
0. **Garis etis CLAUDE.md #4 belum dijaga test**: (a) tidak ada jalur pembelian yang memanggil `tameProgress`/`tambahProgres`, (b) layar koin-kurang menampilkan opsi latihan sebelum tombol beli, (c) layar krisis bisa dibuka dari mana pun & tidak mengirim analytics. Ini prioritas tertinggi untuk ditambah.
1. **Firestore rules** — wallet saat anonim-ke-login memakai validasi `firestore.rules`; tambahkan test di Firebase Emulator (`@firebase/rules-unit-testing`) untuk memastikan delta koin di luar daftar sah ditolak dan replay terdeteksi.
2. **Integration test perangkat** (`integration_test/`): alur onboarding → check-in → jurnal → fight monster, mode pesawat di tengah alur, dan kunci Aplikasi Beku.
3. **Billing sungguhan**: uji di track internal Play Console dengan akun penguji lisensi (pembelian, pending, refund/RTDN).
4. **Layar 360dp & RAM 2–4GB**: golden test atau uji manual di emulator low-end untuk semua layar, bukan hanya galeri.
