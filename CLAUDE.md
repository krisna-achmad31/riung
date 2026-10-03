# Riung — Project Rules (CLAUDE.md)
Aplikasi Android kesehatan mental (Flutter). Desain adalah sumber kebenaran, bukan interpretasi: arah visual terbaru = **Riung Glass 2026** di `design/riung.pen` (frame `Glass — <Flow> · <Layar>`, aset 3D, token `g-*`); alur, copy & state per layar tetap mengacu `design/*.dc.html` (13 file).

## Non-negotiable rules
1. **Design fidelity**: setiap layar diimplement persis mengikuti desainnya — visual (warna, kaca, spacing, radius, aset 3D) dari frame `Glass — …` di `design/riung.pen`, alur/copy/urutan tombol dari `design/<Flow>.dc.html`. Layar yang belum dimigrasi ke Riung Glass tetap mengikuti `.dc.html`. Jangan "memperbaiki" desain tanpa diminta. Semua warna/tipografi HANYA dari `lib/core/theme/` (di-port dari `design/Design System.dc.html`) — tidak ada hex literal di file layar.
2. **Copy**: seluruh teks UI Bahasa Indonesia persis seperti di desain (tone: hangat, "kamu", tidak menggurui). Simpan di file strings terpusat.
3. **Ekonomi**: semua angka (harga, reward, cap) HANYA dari `lib/core/config/economy.dart` (mirror `docs/economy-props.json`) — tidak ada angka lepas. Earn: check-in +5, jurnal +4, meditasi +3, misi +3, menang game +8, jinak +50, streak +20/+100. Spend: fokus 25/40/50, scroll unlock mulai 15, kosmetik 100/300/500, aksesori karakter kepribadian 60/100/300 (kecil/biasa/langka), gaya kartu 100/300 (dipilih per karakter), paket aksesori diskon 20% dari item yang belum dimiliki (dibulatkan ke 5), pelindung streak 20. Kepemilikan kosmetik global (beli sekali, semua karakter); item eksklusif per kategori tes hanya bisa dipakai di karakter tes itu. Tiket: 1 gratis/hari + max 3 dari latihan, max 4 fight/hari, tidak dijual. Koin packs 80/Rp15rb · 330/Rp49rb · 820/Rp99rb. Premium Rp59rb/bln · tahunan = bayar 10 bulan (Rp590rb, gratis 2 bulan) trial 7 hari; pelanggan tahunan dapat +2 koin/hari (masuk cadangan koin-beli). Pengaman etis buka-waktu Aplikasi Beku: maks 3 buka-berbayar/hari, harga naik +10 koin tiap kali, jeda 60 dtk, hanya koin hasil latihan (bukan koin beli); 1 sesi Fokus gratis/hari (Premium: 3). Perk Premium (semua NYATA, jangan iklankan yang belum dibangun): semua konten meditasi/tidur/jurnal CBT/Better Me, 3 sesi Fokus gratis/hari, semua gaya kartu karakter, laporan bulanan + pola faktor↔mood (`features/laporan`, dihitung di perangkat tanpa AI; mingguan gratis), tahunan +2 koin/hari.
4. **Garis etis (tidak boleh dilanggar oleh kode)**: progres monster TIDAK PERNAH bisa naik karena pembelian; layar koin-kurang selalu menawarkan latihan dulu sebelum beli; tidak ada dark pattern; layar krisis selalu bisa diakses & tidak dilog.
5. **Offline-first**: jurnal/check-in/asesmen/progres → lokal (drift/sqflite + enkripsi), sync opsional. Focus Mode jalan offline via tiket prabayar (signed). Wallet/koin HANYA dimutasi Cloud Functions — client tidak pernah menulis saldo.
6. **Payment**: Google Play Billing via `in_app_purchase` saja (consumables = coin packs, subscription = Premium). Receipt diverifikasi server (`validatePurchase` Cloud Function) sebelum koin/premium aktif.
7. **Monster & karakter rendering (art 3D raster)**: art 3D WebP di `assets/monsters/3d/` (monster liar/jinak, kanvas persegi 512, garis lantai seragam) & `assets/characters/` (24 karakter hasil tes + `accessories/`), dibangun ulang dengan `riung/tools/build_3d_assets.py` dari `design/aset3d_cut/` — jangan edit WebP manual. `RiungMonster` = Stack/Positioned dengan anchor dari `assets/monsters/anchors.json` (v2, `render: raster`). Base art immutable; kosmetik = layer di slot (`zIndex 0` = di bawah badan, `2` = di atas); lebar = `width` × lebar render × `anchor.scale`, tinggi dari `aspect`, titik `pivot` gambar ditempel ke anchor x/y × ukuran render & jadi pusat `rotationDeg` (Si Mengelak diagonal). Pose liar berbeda → `anchorsLiar` menimpa `anchors` per slot. Boss scale dibaca dari `bossScale` (Hakim 1.4×), bukan hardcode. **Pengecualian**: kosmetik `slot: "none"` (bingkai_emas, khusus Cermin) TIDAK pakai anchor — overlay kanvas penuh 1:1 yang sudah di-precompose per wujud (`file`/`fileLiar`). Renderer wajib menangani cabang ini. Gambar di-decode seukuran tampil (`cacheWidth`, min 3× untuk kartu ekspor). `CharacterAvatar`: art dari `CharacterArt` (kunci `CharacterSpec.artKey`, geometri badan/mata hasil ukur); aksesori yang punya art 3D (`AccessoryArt`) tampil sebagai gambar, sisanya digambar painter di geometri itu; tanpa art → fallback prosedural. Setiap file yang dirujuk wajib ada (dijaga `test/art_assets_test.dart`).
8. **Skoring asesmen**: implement persis `docs/assessment-scoring-spec.md` — mapping di config, bukan hardcode; setiap % harus bisa dihitung ulang dari jawaban.

## Arsitektur
Flutter (Android-first) · Firebase: Auth (anon → link), Firestore (content, offline persistence), Functions (wallet/receipt), Remote Config (harga/AB), FCM, Analytics · local DB: drift/sqflite (jurnal, check-in, progres — terenkripsi).

### State management — bawaan Flutter saja (tanpa package eksternal)
- State lokal layar → `setState` / `StatefulWidget`.
- State yang dibagi antar layar → `ChangeNotifier` + `ListenableBuilder` (atau `ValueNotifier` untuk nilai tunggal), diakses via `InheritedNotifier` sederhana.
- Notifier global HANYA untuk domain yang benar-benar lintas layar: `WalletNotifier` (koin/tiket), `StreakNotifier`, `MonsterProgressNotifier`, `SessionNotifier` (fokus/timer), `AuthNotifier`. Jangan buat notifier baru per layar tanpa alasan.
- Dilarang menambah Riverpod/Bloc/GetX dsb. tanpa keputusan eksplisit.

### Struktur folder — konsisten, per fitur (mengikuti 13 flow desain)
```
lib/
  core/
    theme/        # tokens & type scale dari Design System.dc.html — satu-satunya sumber warna
    config/       # economy.dart, scoring_config.dart — satu-satunya sumber angka
    models/       # model lintas fitur (UserProfile, Wallet, Saboteur, ...)
    services/     # firebase_service, local_db, billing_service, notif_service
    widgets/      # komponen bersama: RiungButton, KoinChip, StreakChip, TiketChip,
                  # TahukahKamuCard, RiungMonster, RiungBottomNav, RiungSheet
  features/
    launch/  onboarding/  home/  focus/  meditasi/  tidur/  jurnal/
    afirmasi/  checkin/  monster/  minigame/  profil/  toko/  appbeku/
      # tiap fitur: screens/  widgets/  (widget khusus fitur)  logic/ (notifier & helper)
```

### Aturan widget — rapi & enak diedit
- Layar = komposisi widget kecil bernama, BUKAN satu `build()` raksasa. Bagian layar yang >~40 baris dipecah jadi widget sendiri (class, bukan method `_buildXxx()` yang mengembalikan Widget).
- Komponen yang muncul di ≥2 layar → `core/widgets/`. Komponen khusus satu fitur → `features/<fitur>/widgets/`.
- Nama file snake_case = nama class (`koin_chip.dart` → `KoinChip`). Satu widget publik per file.
- `const` constructor di mana pun bisa; hindari rebuild besar (letakkan `ListenableBuilder` sedekat mungkin ke widget yang berubah).

### Aturan model — tidak ada akses Firestore via string manual
- SETIAP dokumen Firestore & tabel lokal punya class model di `models/`: field final + typed, `factory X.fromMap(Map)`, `Map toMap()`, `copyWith()`.
- Nama field Firestore sebagai konstanta di model (`static const fCoins = 'coins';`) — dipakai di fromMap/toMap dan query. String field TIDAK PERNAH ditulis lepas di UI/service.
- Konversi tipe di satu tempat: `Timestamp`→`DateTime`, num→int, enum via `X.values.byName` dengan fallback aman untuk data lama.
- UI hanya menerima model, tidak pernah `Map<String, dynamic>` mentah. Fungsi Cloud Functions juga dipanggil lewat service typed (request/response model), bukan map literal di layar.

## Definition of done (per layar)
Sesuai .dc.html-nya (side-by-side check) · semua state ada (empty/loading/error/success/offline) · token & economy props only · copy persis · lolos di layar 360dp / HP RAM 2–4GB.
