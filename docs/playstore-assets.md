# Aset Play Store — Riung

Draft siap pakai untuk listing Play Console. Semua teks dalam Bahasa Indonesia, sesuai tone app (hangat, "kamu", tidak menggurui — CLAUDE.md §2).

## 1. Checklist aset yang dibutuhkan

Yang harus disiapkan manual sebelum submit (Claude tidak bisa generate gambar/screenshot asli dari app):

| Aset | Spesifikasi | Status |
|---|---|---|
| Ikon aplikasi (hi-res) | 512×512 px, PNG 32-bit, tanpa alpha untuk store listing | Bisa diekspor dari `assets/icon/icon.png` (upscale/crop jika perlu — sumbernya sudah 1024×1024) |
| Feature graphic | 1024×500 px, JPG/PNG, tanpa teks kecil (terpotong di beberapa device) | **Belum ada — perlu didesain manual** |
| Screenshot HP | Min. 2, maks. 8. Rasio 16:9 atau 9:16, sisi pendek min. 320px, sisi panjang maks. 3840px | **Belum ada — ambil dari app berjalan di HP/emulator** |
| Screenshot tablet 7" (opsional) | Sama rasio, kalau app dioptimasi tablet | Opsional — app ini Android-first HP, boleh dilewati dulu |
| Screenshot tablet 10" (opsional) | Sama | Opsional |
| Video promo (opsional) | Link YouTube, maks 30 detik disarankan | Opsional, boleh nyusul |
| Short description | Maks 80 karakter | Draft ada di bawah ✓ |
| Full description | Maks 4000 karakter | Draft ada di bawah ✓ |
| Privacy policy URL | Wajib untuk app dengan akun/data personal | Draft ada di bawah — perlu di-host (GitHub Pages/Notion) lalu masukkan URL-nya ✓ (draft) |
| Kategori aplikasi | — | Saran: **Kesehatan & Kebugaran** atau **Gaya Hidup** |
| Content rating questionnaire | Diisi di Play Console | Perlu diisi manual — app menyinggung topik kesehatan mental, jujur isi apa adanya |
| Data safety form | Wajib sejak 2022 | Isi sesuai daftar data di draft privacy policy bagian bawah |
| Target audience & content | Wajib deklarasi umur target | App untuk 13+ (topik kesehatan mental, bukan untuk anak) |

### Rekomendasi screenshot (5-6 layar yang paling representatif)

1. **Beranda** — check-in card + streak/koin + kartu Si Hakim
2. **Brankas monster** — Si Hakim + 6 anak buah, progres jinak
3. **Mode Fokus** — timer + pilihan durasi
4. **Jinakkan monster (mini-game)** — momen serangan ke saboteur
5. **Jurnal / Check-in** — layar mood + catatan (nggak perlu isi data asli, pakai akun test)
6. **Toko** — kosmetik monster, biar keliatan progres itu kosmetik-only, bukan pay-to-win

## 2. Short description (maks 80 karakter)

```
Jinakkan monster pikiranmu. Fokus, tidur, dan jurnal harian — gratis.
```

(69 karakter — aman di bawah batas 80.)

## 3. Full description (maks 4000 karakter)

```
Di kepala kita semua ada suara-suara kecil yang bikin hari terasa lebih berat: yang bilang "kamu pasti gagal", yang bikin kamu overthinking sampai susah tidur, yang bikin scroll medsos jadi pelarian, atau yang nggak pernah puas sama hasil kerjamu. Riung menyebut suara-suara itu monster — dan kamu bisa belajar menjinakkannya, bukan melawannya.

MONSTERMU, TUJUH SABOTEUR
Riung memvisualisasikan 7 pola pikir yang sering muncul jadi karakter monster yang bisa kamu kenali:
• Si Hakim — suara batin yang menghakimi dirimu dan orang lain, sumber yang "membangunkan" monster lainnya
• Si Waswas — selalu membayangkan skenario terburuk yang belum tentu terjadi
• Si Kabut — mengaburkan tujuanmu sampai semua terasa berat untuk dimulai (scroll tanpa sadar, menunda-nunda)
• Si Cermin — memantulkan versi dirimu yang terdistorsi lewat perbandingan di media sosial
• Si Sempurna — bawa "pena merah", nggak pernah puas dengan usahamu
• Si Mengelak — licin, selalu membawamu kabur dari hal yang tidak nyaman
• Si Meronta — membesar-besarkan kemalangan, bikin kamu merasa tak berdaya

Tiap monster jinak lewat latihan nyata berbasis CBT (cognitive behavioral therapy) — bukan lewat pembelian.

FITUR UTAMA
🎯 Mode Fokus — jauhkan diri dari distraksi dengan sesi fokus bertimer, ditemani monster yang lagi kamu latih
🧘 Meditasi — sesi terpandu untuk meredakan cemas, fokus belajar, sampai tekanan kerja
🌙 Tidur — cerita malam & suasana suara untuk menenangkan pikiran sebelum tidur
📓 Jurnal — ruang privat terkunci PIN untuk menulis apa yang kamu rasakan, tersimpan terenkripsi di HP-mu
✨ Afirmasi — koleksi kalimat penguat, bisa kamu buat versi sendiri
🧠 Better Me — program CBT terstruktur, kenali pola pikirmu langkah demi langkah, mulai dari mengenal Si Hakim
📵 Aplikasi Beku — set batas harian buat aplikasi yang suka nyedot waktumu (medsos dll), begitu lewat batas, Riung ajak kamu jeda 1 menit dulu, bukan mengunci paksa
📅 Check-in harian & kalender latihan — pantau mood dan konsistensi latihanmu dari waktu ke waktu

GRATIS, DENGAN OPSI PREMIUM
Riung bisa dipakai penuh secara gratis — check-in, meditasi dasar, jurnal, afirmasi, dan menjinakkan monster semua bisa dilakukan tanpa bayar. Riung Premium (opsional) membuka akses tanpa batas ke seluruh koleksi meditasi/tidur/jurnal dan program Better Me lengkap.

Progres monstermu nggak bisa dibeli — cuma latihan yang bisa. Koin dan kosmetik di Toko cuma untuk mendandani monster jinakanmu, sama sekali tidak mempercepat atau membeli progres menjinakkan. Kalau koinmu kurang, Riung selalu tawarkan latihan dulu sebelum nawarin beli.

Riung adalah alat bantu kesejahteraan mental berbasis latihan CBT, bukan pengganti diagnosis, terapi, atau penanganan profesional. Kalau kondisimu terasa berat atau membahayakan, layar "Butuh bantuan sekarang" selalu bisa diakses kapan saja dan nggak pernah dicatat riwayatnya.

Yuk mulai kenalan sama monster pertamamu.
```

(Draft di atas ±2900 karakter dari batas 4000 — masih ada ruang kalau mau nambah detail lain sebelum submit; hitung ulang di Play Console karena karakter khusus seperti emoji bisa dihitung berbeda oleh sistemnya.)

## 4. Draft privacy policy (ringkas)

Host draft di bawah ini di GitHub Pages atau Notion (publish sebagai halaman publik), lalu masukkan URL-nya ke field "Privacy policy" di Play Console.

```
Kebijakan Privasi Riung

Terakhir diperbarui: [isi tanggal saat publish]

Riung ("kami") menghargai privasimu. Halaman ini menjelaskan data apa yang Riung kumpulkan dan bagaimana data itu digunakan.

DATA YANG DIKUMPULKAN

1. Email (opsional)
   Kalau kamu memilih daftar akun (bukan wajib — Riung bisa dipakai dengan akun anonim), kami menyimpan alamat emailmu untuk keperluan masuk akun dan pemulihan akun. Email tidak pernah dibagikan ke pihak ketiga untuk keperluan iklan.

2. Data penggunaan aplikasi (untuk fitur Aplikasi Beku)
   Kalau kamu mengaktifkan fitur "Aplikasi Beku", Riung membaca durasi pemakaian aplikasi lain di HP-mu (lewat izin Akses Data Penggunaan Android) semata-mata untuk menghitung apakah batas harian yang kamu atur sendiri sudah tercapai. Data ini disimpan lokal di HP-mu dan tidak dikirim ke server kami.

3. Jurnal
   Entri jurnalmu dienkripsi dan disimpan lokal di HP-mu, dikunci PIN terpisah. Riung tidak pernah mengirim isi jurnalmu ke server kami maupun pihak ketiga mana pun.

4. Data progres & preferensi aplikasi
   Streak check-in, progres menjinakkan monster, saldo koin, dan preferensi notifikasi disimpan untuk menjaga pengalaman aplikasimu tetap konsisten antar sesi. Sebagian tersimpan lokal, sebagian (kalau kamu punya akun) tersinkron ke server kami supaya progresmu tidak hilang saat ganti HP.

5. Analytics (teragregasi/anonim)
   Kami menggunakan analitik penggunaan aplikasi (fitur mana yang dipakai, kapan) dalam bentuk teragregasi dan anonim untuk memahami fitur mana yang berguna dan mana yang perlu diperbaiki. Data ini tidak dipakai untuk mengidentifikasi kamu secara personal.

6. Pembelian dalam aplikasi
   Kalau kamu membeli koin atau Riung Premium, transaksi diproses lewat Google Play Billing. Kami menerima konfirmasi pembelian dari Google untuk mengaktifkan koin/premium-mu, tapi tidak pernah melihat atau menyimpan detail kartu/pembayaranmu — itu sepenuhnya ditangani Google.

YANG TIDAK KAMI LAKUKAN
- Kami tidak menjual data pribadimu ke pihak ketiga.
- Kami tidak membaca isi jurnalmu.
- Kami tidak melacak aktivitasmu di luar aplikasi Riung, kecuali sejauh yang diperlukan fitur Aplikasi Beku (yang kamu aktifkan sendiri, dan bisa dimatikan kapan saja).

HAK KAMU
Kamu bisa mengunduh semua datamu atau menghapus akunmu kapan saja lewat menu Pengaturan di aplikasi.

KONTAK
Pertanyaan soal privasi? Hubungi kami di: [isi alamat email kontak]
```

**Catatan**: draft ini merangkum praktik yang sudah diimplementasikan di app (jurnal terenkripsi lokal, wallet cuma dimutasi lewat Cloud Functions/Firestore rules, dsb — lihat CLAUDE.md §5). Sebelum publish, cek ulang poin data safety form di Play Console satu-satu supaya deklarasinya cocok persis dengan draft ini (Play Console akan tanya hal spesifik seperti "apakah data dienkripsi in transit", "apakah user bisa minta hapus data", dll — jawab sesuai apa yang app ini benar-benar lakukan).
