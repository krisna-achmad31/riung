# Bahasa (l10n), audio, mini-game, kunci Aplikasi Beku, Premium, dan Kenali dirimu

## 1. Ganti bahasa

- Bahasa didukung: Indonesia (default) dan Inggris. `lib/core/l10n/app_language.dart`.
- Semua teks UI ada di `lib/core/l10n/strings/<fitur>_strings.dart`: satu class abstrak
  per fitur, dengan implementasi `*Id` dan `*En` di berkas yang sama. Kompiler memaksa
  kedua bahasa lengkap. Layar membaca lewat `context.s.<fitur>` (dalam `build()`,
  jangan di `initState`; di callback pakai `AppScope.of(context).language.strings`).
- `LanguageNotifier` (notifier global ke-7) menyimpan pilihan ke prefs; `LanguageScope`
  membuat seluruh UI ikut berganti seketika tanpa mengulang navigasi.
- Menambah bahasa: tambah nilai di `AppLanguage`, lalu implementasikan tiap class strings
  (kompiler menunjukkan yang kurang). Tambah fitur baru: tulis `<fitur>_strings.dart`,
  daftarkan getter di `AppStrings` dan ekspor di `l10n.dart`.
- Layer service tidak membuat kalimat (mis. `AuthServiceException(AuthError)`,
  `BillingUpdate.errorKind`); UI yang menerjemahkan.
- Nama monster sengaja tidak diterjemahkan (`common.monsterName`). Konten dari Firestore
  tidak dilokalisasi (kecuali deskripsi saboteur dan 4 afirmasi bawaan).
- `test/l10n_test.dart` memastikan tiap katalog (prompt jurnal, meditasi, tidur, Better Me)
  punya teks di kedua bahasa dan tanpa em-dash.

## 2. Audio (lisensi komersial-aman)

Semua audio dibundel di `assets/audio/` (offline-first); sumber & lisensi di
`assets/audio/CREDITS.md`.

- Cerita tidur: rekaman LibriVox (domain publik / CC0), berbahasa Inggris.
- Suara latar (hujan, ombak, kipas): CC0, Joseph Sardin.
- Meditasi: suara latar tanpa narasi. Set meditasi gratis populer (UCLA Mindful, Free
  Mindfulness Project) berlisensi non-komersial, jangan dipakai. Model suara Piper
  (lessac, news_tts) juga tidak aman komersial.

## 3. Mini-game pecahkan balok

`features/minigame/`: `block_breaker_engine.dart` (fisika murni, ditest di
`test/block_breaker_engine_test.dart`), `block_breaker_painter.dart`,
`block_breaker_screen.dart`. Bos di tengah dikelilingi balok "vonis"; balok pecah dan
tubuh bos yang kena menurunkan HP; 3 nyawa, 60 detik. Angka ada di `MinigameConfig`,
hadiah/progres tetap dari `economy.dart`.

## 4. Kunci Aplikasi Beku

- Saklar "Kunci saat batas tercapai" di Pengaturan > Aplikasi Beku (default nyala, bisa
  dimatikan kapan saja). Mati = Riung hanya mengingatkan.
- Native (`android/.../kotlin/com/riung/riung/`): `AppLockService` (foreground service,
  tipe `specialUse`) memantau aplikasi di depan tiap detik lewat event UsageStats
  (`UsageCalculator`). Kalau aplikasi beku melewati batas efektif (batas harian + menit
  ekstra hari ini), Riung dibuka di depannya lewat `startActivity`, yang di Android 10+
  hanya boleh dari background bila punya izin "Tampil di atas aplikasi lain".
  Tidak ada overlay yang digambar.
- Flutter mendorong konfigurasi (`syncLockConfig`) tiap berubah (`AppBekuNotifier`);
  `LockConfig` menyimpannya di prefs native supaya service jalan tanpa UI Flutter.
  `LockBootReceiver` menyalakan ulang service setelah reboot.
- Jalan keluar selalu ada (garis etis): tarik napas 1 menit gratis, buka waktu dengan
  koin, "Kembali" ke layar utama, dan saklar kunci. Aplikasi komunikasi (WhatsApp) tidak
  pernah dikunci; layar krisis tidak terpengaruh.
- Izin: "Akses data penggunaan" dan "Tampil di atas aplikasi lain" (layar
  `AppBekuPermissionScreen` menyesuaikan izin mana yang kurang).
- Catatan Play: izin `SYSTEM_ALERT_WINDOW` dan foreground service `specialUse` perlu
  dijelaskan di deklarasi Play Console. Beberapa OEM (Infinix/XOS dkk) agresif mematikan
  service latar; minta pengguna mengecualikan Riung dari penghemat baterai bila perlu.

## 5. Kunci lewat Aksesibilitas (menggantikan foreground service)

- Alasan: di XOS (dan OEM sejenis) menggeser Riung dari recents mematikan prosesnya
  beserta foreground service tanpa menghidupkannya lagi, jadi kunci hilang. Sistem
  Android sendiri yang menjaga AccessibilityService tetap hidup.
- `AppLockAccessibilityService` + `LockEngine` (keputusan bersama). Service dibatasi:
  `canRetrieveWindowContent=false` (tidak bisa membaca isi layar), hanya event
  perpindahan jendela, dan `packageNames` dibatasi ke aplikasi yang dibekukan.
- Alur pengguna (pilihan, tidak dipaksa): saklar kunci di Pengaturan Aplikasi Beku
  -> layar penjelasan jujur (apa yang dibaca / tidak) -> tombol buka Pengaturan
  Aksesibilitas + langkah singkat -> kembali ke Riung, status dicek ulang.
- STATUS: DIVERIFIKASI di Infinix X6851 (Android 16): Instagram yang melewati batas
  diblokir tanpa izin overlay, dan tetap bekerja setelah Riung digeser dari recents
  (proses tetap hidup karena service Aksesibilitas terikat).
- CATATAN: Android otomatis mematikan izin Aksesibilitas sebuah app kalau app itu di-Force
  Stop (dan kadang saat diperbarui). Riung mendeteksinya (`lockNeedsAttention`) dan
  menampilkan pemberitahuan sekali per sesi dengan tombol "Aktifkan".
- Tombol "Kembali" di layar jeda hanya menutup layar jeda (tidak lagi ke layar utama
  Android). Kode lama (AppLockService foreground service,
  LockBootReceiver, izin SYSTEM_ALERT_WINDOW) masih ada di repo sebagai cadangan;
  hapus setelah Aksesibilitas terbukti. Play Console: butuh deklarasi Aksesibilitas
  dengan pengungkapan mencolok (sudah ada di layar izin).

## 6. Pengaman etis buka-berbayar (CLAUDE.md aturan #4)

`EconomyScroll`: maks 3 buka-berbayar/hari, harga naik +10 koin tiap kali, jeda 60 dtk
sebelum tombol aktif; hanya koin hasil latihan (`WalletNotifier.earnedCoins`, koin beli
dilacak sebagai `purchasedCoinsReserve`); tidak ada tombol isi ulang di layar kunci;
1 sesi Fokus gratis per hari. Tes: `test/ethics_guardrails_test.dart`.

## 7. Premium

Tahunan = bayar 10 bulan (Rp590rb, `EconomyPremium`), +2 koin/hari khusus tahunan
(sekali per hari, tidak menumpuk; masuk cadangan koin-beli). Status: `PremiumStatus`
(none / active / renewsSoon / expired) menghitung tanggal perpanjangan + toleransi 3
hari; gerbang fitur memakai `UserProfile.premiumNow`. Setelah lewat tanggal
perpanjangan Riung menanyakan Google Play sekali (`restorePurchases`). `firestore.rules`
diperbarui (earn 2, harga buka-waktu bertingkat); PUBLISH ULANG rules ke Firebase.
Belum ada verifikasi server (Spark plan, tanpa Cloud Functions).

## 8. Kenali dirimu (`features/kepribadian/`)

Tiga tes refleksi: 16 tipe gaya Jung (24 butir; tidak memakai nama dagang MBTI),
empat temperamen (20 butir), gaya keterikatan (12 butir, 2 dimensi). Butir asli,
skoring berbasis config di `personality_config.dart` (`personality_scoring.dart`,
`test/personality_scoring_test.dart`). Hanya skor yang disimpan, bukan jawaban.
Karakter digambar dengan kanvas (`character_avatar.dart`) dari `CharacterSpec`.
Kartu bagikan 9:16 (`personality_share_card.dart`) via `CardImageExporter`; hanya
memuat hasil, tidak pernah data jurnal. Gaya kartu (add-on kosmetik) dibeli dengan
koin lewat `WalletNotifier.buyCosmetic` (tier harga sama dengan skin). Pola jurnal
hanya dari metadata (mood, jam, tema) dan dibuka lewat PIN jurnal.

### Kustomisasi karakter (aksesori, paket, gaya kartu)
- Kepemilikan kosmetik **global**: beli sekali, dipakai di ketiga karakter (Jung,
  temperamen, keterikatan). Yang dipakai (satu per slot: kepala/wajah/leher/punggung)
  dan gaya kartu disimpan **per karakter**.
- 14 aksesori umum + 12 eksklusif (4 per kategori tes, `CharacterAccessory.category`);
  eksklusif hanya tampil/bisa dipakai di karakter kategorinya.
- Harga per tier: kecil 60, biasa 100, langka 300 (`EconomySpend`).
- 6 paket (`AccessoryBundle`): 3 umum + 1 per kategori. Harga = jumlah harga satuan
  item yang **belum dimiliki** x (100 - 20)%, dibulatkan ke 5. Paket disembunyikan
  bila sisa < 2 item. Dibeli sebagai satu potongan (`WalletNotifier.buyCosmeticBundle`)
  lalu semua itemnya langsung dipakai. Koin kurang -> layar latihan dulu.
- `firestore.rules`: harga paket dinamis diizinkan lewat kelipatan 5 antara 40-1500;
  rules perlu dipublikasikan ulang.

### Laporan refleksi & data tidur (Health Connect)
- `features/laporan`: `ReportEngine` (kode murni, tanpa AI, tidak membaca isi jurnal),
  ambang di `report_config.dart`, teks di `LaporanStrings`. Mingguan gratis; bulanan,
  pola faktor↔mood, dan pola tidur↔mood Premium.
- Data tidur opsional lewat Health Connect (`SleepDataService`, paket `health`): izin
  READ_SLEEP diminta hanya setelah persetujuan di dialog, data dibaca di perangkat dan
  tidak disimpan/dikirim. `minSdk` 26 (syarat Health Connect).
- Sebelum rilis Play: isi formulir deklarasi Health Connect & Data Safety, sediakan
  kebijakan privasi (tautan "cara data dipakai" dari layar izin mengarah ke aplikasi).

