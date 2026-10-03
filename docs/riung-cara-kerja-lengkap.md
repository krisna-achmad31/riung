# Riung — Cara Kerja Aplikasi (Dokumen Lengkap)
*Untuk review: rekan psikolog (sisi klinis) & calon pengguna (sisi pengalaman). Status: desain final terkunci, pra-pengembangan.*

---

## 1. Riung itu apa?
Aplikasi Android kesehatan mental & pengembangan diri untuk orang Indonesia usia **15–40**. Ide intinya: pola pikir negatif yang menyabotase kita (cemas berlebih, perfeksionisme, menunda, membanding-bandingkan diri) divisualkan sebagai **7 monster batin** yang bisa dikenali → dihadapi → **dijinakkan** lewat latihan psikologis harian. Riung = "duduk bersama" — aplikasi ini menemani, bukan menggurui.

**Riung BUKAN alat diagnosis dan bukan pengganti psikolog.** Disclaimer ini tampil di hasil asesmen & pengaturan, plus halaman bantuan krisis (119 ext. 8 Kemenkes, SEJIWA, Into The Light, direktori IPK) yang bisa diakses kapan pun — dan aplikasi tidak mencatat siapa yang membukanya.

## 2. Dasar psikologinya (untuk rekan psikolog)
Kerangka utamanya **CBT (Cognitive Behavioral Therapy)** — pendekatan yang dalam meta-analisis aplikasi digital menunjukkan efektivitas tertinggi untuk gejala cemas & depresi, dengan komponen aktif: *cognitive restructuring, behavioral activation, goal setting*, dan latihan pernapasan.

Setiap monster = satu **distorsi kognitif** yang mapan:

| Monster | Distorsi kognitif | Suaranya |
|---|---|---|
| **Si Hakim** (bos) | Inner critic / global labeling | "Kamu pasti gagal — kayak biasanya." |
| Si Waswas | Catastrophizing | "Gimana kalau besok semuanya berantakan?" |
| Si Sempurna | Perfectionism / should-statements | "Harusnya bisa lebih baik." |
| Si Cermin | Social comparison | "Hidup orang lain lebih oke." |
| Si Kabut | Ruminasi & prokrastinasi | "Nanti saja." |
| Si Mengelak | Experiential avoidance | "Hindari saja, aman." |
| Si Meronta | Personalization / victim mindset | "Kenapa selalu aku?" |

Prinsip klinis yang dijaga di seluruh aplikasi:
- **Semua monster ada pada semua orang** — asesmen mengukur *tingkat aktivitas* (0–100%), bukan "punya/tidak punya". Setiap persen bisa ditelusuri ke jawaban kuis (tidak ada skor karangan).
- **Eksternalisasi**: "Si Kabut yang ngajak scroll — bukan kamu" (memisahkan orang dari polanya, teknik naratif yang menurunkan self-blame).
- **Normalisasi relapse**: monster yang sudah jinak bisa "mampir lagi — itu normal".
- **Anti-guilt design**: kalah di mini-game tetap dapat progres ("gagal sekali bukan berarti 'pasti gagal'"); kalender bulanan tanpa warna merah ("hari kosong bukan kegagalan — kalender ini catatan, bukan rapor"); keluar darurat dari sesi fokus tanpa bahasa hukuman.
- **Tanpa statistik palsu**: kartu "Apa katanya vs Faktanya" memakai reframe CBT atau fakta bersumber (I-NAMHS 2022, SKI 2023, Sakernas 2025) — tidak pernah angka fiktif.
- **Progres tidak bisa dibeli** — hanya latihan yang menggerakkan persentase penjinakan (garis etis monetisasi, lihat §6).

*Masukan yang kami harapkan darimu: ketepatan pemetaan distorsi→monster, kualitas latihan mikro-CBT, dan apakah ada framing yang berisiko secara klinis.*

## 3. Alur pengguna dari awal (sisi user)
**A. Onboarding (sekali, ±5 menit).** Kuis 17 pertanyaan santai ("Setelah scroll medsos lama, biasanya kamu merasa…"). 12 pertanyaan mengukur aktivitas monster, 5 lainnya mengatur pengalaman (pelajar/pekerja, tujuan, durasi realistis, jam check-in). Hasilnya: **profil monster** — Si Hakim sebagai bos + 6 anak buah diurutkan dari yang paling aktif, lalu penawaran Premium (bisa dilewati, gratis tetap jalan).

**B. Ritual harian (5–15 menit).**
1. **Check-in pagi** (1 menit): mood, energi, niat hari ini → +5 koin, streak jalan.
2. **Misi harian** (3 misi mikro-CBT sesuai monster aktif — mis. untuk Si Waswas: "tunda khawatirmu ke slot 10 menit") → +3 koin/misi.
3. **Latihan pilihan**: meditasi (termasuk "Jeda di Tengah Kerja"), cerita tidur, jurnal (terkunci PIN, tersimpan di HP), kartu afirmasi.
4. **Pertarungan monster** (mini-game, lihat §5): 1 tiket gratis/hari + hingga 3 dari latihan.

**C. Fitur fokus & anti-scroll (nilai jual utama).**
- **Mode Fokus**: bayar koin (25/40/50 untuk 25/45/60 menit) → aplikasi pengganggu diblokir, timer jalan, bisa offline (tiket prabayar). Selesai → progres monster naik.
- **Aplikasi Beku**: pilih app yang dibatasi (IG, TikTok, dst.) + limit harian. Saat limit habis dan kamu tetap membuka, muncul layar Riung: **"Tarik napas 1 menit dulu (gratis)"** → atau buka 10 menit (15 koin) → atau kembali. Scroll jadi pilihan sadar, bukan refleks — dan Riung tidak pernah memblokir total.

**D. Jangka panjang**: monster jinak satu per satu (bisa dipakaikan kosmetik dari Toko), program "Better me" 22 sesi, kalender latihan bulanan, kartu pemain yang bisa dibagikan (tanpa membagikan isi jurnal).

## 4. Sistem monster & progres
Tiap monster punya dua wujud: **liar** (pudar, tegang) dan **jinak** (cerah, ramah). Progres 0–100% "menuju jinak" naik lewat: sesi fokus (+4% ke monster aktif), menang/kalah mini-game (+% / tetap +2%), misi harian, dan latihan terkait. Halaman detail tiap monster berisi: penjelasan distorsinya, pemicu, **"Apa katanya vs Faktanya"**, dan **teknik penangkal** berbobot (5×/3×/2×) yang juga berlaku di mini-game. Mencapai 100% = monster jinak → perayaan + 50 koin + slot kosmetik.

## 5. "Game"-nya apa?
**Pecahkan Balok & Serang Saboteur** — mini-game berbasis **latihan napas**: intro singkat → tarik napas / hembuskan mengikuti irama → tiap napas yang benar "memecahkan balok" pikiran negatif → serangan ke monster aktif. Menang: +8 koin & progres; kalah: tetap +2% progres, dibingkai sebagai latihan ("persis pikiran yang lagi kamu lawan"). **Dibatasi maksimal 4 pertarungan/hari** (1 gratis + 3 dari latihan) — sengaja, supaya tetap jadi latihan pernapasan, bukan grinding. Memakai teknik penangkal yang tepat untuk monster itu = serangan lebih besar (pengetahuan CBT jadi strategi).

## 6. Monetisasi (freemium — transparan)
**Gratis selamanya**: onboarding + profil monster, check-in, misi harian, jurnal 1 entri/hari, 3 meditasi + 2 cerita tidur, mini-game harian, Vault, bantuan krisis.

**Koin** (mata uang dalam app):
- *Didapat dari latihan*: check-in +5 · jurnal +4 · meditasi +3 · misi +3 · menang game +8 · monster jinak +50 · bonus streak +20 (7 hari) / +100 (30 hari). Latihan penuh ≈ cukup untuk 1 sesi fokus/hari.
- *Dipakai untuk*: sesi fokus (25/40/50), buka waktu scroll (mulai 15), kosmetik monster (100–500), pelindung streak (20).
- *Bisa dibeli* bagi yang butuh lebih: Kantong 80 = Rp15rb · Peti 330 = Rp49rb · Brankas 820 = Rp99rb.

**Premium** (Rp59rb/bln atau Rp399rb/thn, trial 7 hari): semua meditasi/cerita tidur, jurnal tanpa batas, program Better me lengkap.

**Garis etis yang dikunci di desain**: (1) **progres monster tidak pernah bisa dibeli** — uang membeli waktu/akses, bukan "kesembuhan"; (2) tiket pertarungan tidak dijual; (3) saat koin kurang, aplikasi *pertama-tama* menawarkan latihan gratis ("cara tercepat dapat koin: check-in +5…"), baru opsi beli; (4) tidak ada iklan.

## 7. Privasi & keamanan
Jurnal, check-in, dan hasil asesmen tersimpan **di perangkat** (terenkripsi, PIN/sidik jari); cadangan cloud hanya jika diaktifkan. Halaman krisis tidak dicatat. Berbagi kartu pemain tidak pernah menyertakan isi jurnal. Fitur Aplikasi Beku meminta izin "akses data penggunaan" dengan penjelasan jujur dan bisa ditolak.

## 8. Pertanyaan untuk kalian
**Untuk rekan psikolog**: apakah pemetaan distorsi→monster tepat? Ada latihan yang perlu diganti? Framing mana yang berisiko? **Untuk calon user**: bagian mana yang bikin kamu mau kembali besok — dan bagian mana yang terasa "jualan"? Di titik mana kamu akan berhenti memakai?
