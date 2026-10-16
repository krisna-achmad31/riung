# PSIKOLOGI KONVERSI & MOMEN PAYWALL — APLIKASI RIUNG
*CBT Kesehatan Mental · Flutter · Indonesia · 15–40 th*

---

## 1. MOMEN PAYWALL / PREMIUM (ALUR PENGGUNA + ALASAN PSIKOLOGIS)

### Alur Lengkap

| Fase | Momen | Tipe | Alasan Psikologis | Implementasi Riung |
|---|---|---|---|---|
| Splash → Onboarding (17 Q) | ❌ JANGAN | — | Cognitive Load awal (Sweller): user belum punya nilai. SDT: autonomy rusak jika dipaksa berbayar sebelum tahu manfaat. | Zero paywall. Branding hangat + "kamu bukan sendiri". |
| Post-Onboarding | ⚠️ Soft teaser (bukan paywall) | Teaser hasil monster + tantangan lanjut | Reciprocity: user sudah investasi 3–5 menit. Berikan hasil dulu (gangguan teridentifikasi). Tidak blok; hanya "Lihat analisis lengkap + 22 sesi Better Me di Premium". | Hasil monster bebas. Tombol "Pelajari 22 sesi Better Me" — buka halaman fitur. |
| Home / Ritual Pagi | ⚠️ Soft offer context | Eksposur nilai ringan | Mere Exposure / Familiarity: user harus melihat nilai Premium 3–5x sebelum mempertimbangkan. Peak-End Rule: akhir ritual = momen baik untuk tawaran ringan. | Banner kecil: "Hari ini kamu sudah menaklukkan 2 misi. Lanjutkan dengan meditasi penuh (Premium)." |
| Saat mencoba fitur berbayar (Fokus / Beku / Meditasi penuh) | ✅ Hard paywall + Soft alternatif | Hard blok akses penuh; alternatif latihan gratis langsung tersedia | Loss Aversion (Kahneman): user sudah dalam flow, kehilangan fitur terasa. SDT: harus ada pilihan ("Latihan dulu atau naik Premium?"). | Bukan "Bayar atau pergi". Itu: "Ini butuh Premium agar fokusmu tidak terganggu. Sementara, coba 5 menit latihan napas gratis?" |
| Setelah ritual selesai (malam) | ✅ Re-engagement / Trial | Penawaran kontekstual + streak | Peak-End Rule: akhir hari = momen ingat pengalaman. Variable Reward: streak hari ini = "Jika lanjut 3 hari dengan Premium, unlock laporan bulan ini." | Notifikasi ringan: "Streak-mu 7 hari! Mau lanjut? Coba Premium 7 hari gratis." |
| Koin habis saat mencoba beli | ✅ Soft conversion | Tawaran latihan dulu (etika) | Garis etis: saat koin kurang → tawarkan latihan dulu sebelum beli. Reciprocity terbalik jika hanya minta uang saat lemah. | Modal: "Koinmu habis. Sebelum beli, coba latihan 3 menit untuk mengurangi monster [X]. Kalau sudah siap, Premium bisa dibeli kapan saja." |

---

## 2. TEORI PERILAKU YANG DITERAPKAN

- **Loss Aversion (Kahneman)**: Paywall paling efektif saat user sudah *di tengah* tindakan (sedang buka Meditasi / Fokus), bukan saat baru buka aplikasi.
- **Reciprocity (Cialdini)**: Onboarding harus memberikan nilai dulu (hasil monster, 3 misi mikro, jurnal 1 hari). Setelah user merasa "dibantu", tawaran Premium lebih diterima.
- **Peak-End Rule (Kahneman)**: Paywall jangan di awal atau di tengah krisis. Letakkan di akhir ritual atau saat user mencoba akses fitur — tapi selalu dengan alternatif.
- **Self-Determination Theory (Deci & Ryan)**: Autonomy (pilih latihan atau bayar), Competence (tunjukkan latihannya berhasil), Relatedness (tone "kamu", bukan "pasien"). Jangan pakai dark pattern yang menghilangkan pilihan.
- **Cognitive Load (Sweller)**: Jangan tampilkan 10 bullet jika user sedang cemas. Maksimal 3 value prop + 1 CTA.
- **Mere Exposure / Familiarity**: Paywall baru bekerja setelah user melihat 3–5 eksposur nilai Premium (teaser, banner, reminder). Jangan dulu di splash.

---

## 3. YANG TIDAK BOLEH DILAKUKAN (GARIS ETIS + PSIKOLOGI)

> **Garis etis Riung**: Progres monster TIDAK bisa dibeli; tiket pertarungan TIDAK dijual; saat koin kurang → tawarkan latihan dulu sebelum beli; tidak ada iklan.

| Larangan | Alasan Psikologis / Etis | Konsekuensi jika Dilanggar |
|---|---|---|
| **Paywall sebelum onboarding 17 Q selesai** | Cognitive Load awal + rantai kepercayaan belum terbentuk. User merasa "dipuji dulu, dibayar setelah" → benci. | Churn instan; rating buruk; pelanggaran etika kesehatan mental. |
| **Paywall saat user dalam mode cemas / krisis** | Emotional Contagion / Trigger: saat risiko tinggi (jurnal ideasi, skor monster sangat tinggi), paywall = eksploitasi emosional. Dark pattern eksplisit. | Risiko hukum/etika serius; reputasi hancur; bisa memicu pengguna rentan untuk membeli karena panic, bukan keputusan. |
| **Hard-block ritual harian (check-in / 3 misi / jurnal)** | Ritual adalah inti CBT. Menyumbatnya = merusak efektivitas terapi. SDT: autonomy hilang jika user tidak bisa melakukan tugas dasar tanpa bayar. | User berhenti sama sekali (churn tinggi). Ganti dengan soft limit (jurnal 1/hari tetap gratis; jurnal tanpa batas = Premium). |
| **False urgency / dark pattern** ("Hanya 2 jam!", timer palsu) | Deceptive Design; melanggar kepercayaan. Di kesehatan mental, kepercayaan adalah aset utama. | User merasa dimanipulasi; churn; ulasan negatif. |
| **Menjual progres monster / tiket pertarungan** | Melanggar garis etis. Monster adalah distorsi kognitif — mengubahnya jadi transaksi merusak integritas CBT (rewear, bukan reward). | Validasi klinis hilang; aplikasi tidak bisa claim sebagai alat CBT serius. |
| **Iklan dalam aplikasi** | Attention Residue / Cognitive Load: iklan mengganggu fokus CBT. Di Indonesia 15–40 th, iklan bisa menurunkan kesan profesional. | Menurunkan retensi; konflik dengan tone hangat, bukan komersial. |
| **Paywall tanpa alternatif latihan saat koin habis** | Reciprocity terbalik: kita sudah memberikan hasil, tapi saat user lemah (koin habis), kita hanya minta uang — bukan bantuan. | User merasa dijebak; retensi turun drastis setelah penolakan. |

---

## 4. DESAIN COPY & VISUAL PAYWALL (TONE: HANGAT, "KAMU", ANTI-GUILT)

### Prinsip Kopi
- Gunakan **"kamu"** hampir selalu.
- Hindari kata menyalahkan: "Kamu harus...", "Jangan malas...", "Kamu gagal..."
- Gunakan **"Bersama"**, **"Sambil"**, **"Jika kamu siap..."** — memberi ruang menolak tanpa rasa bersalah.
- **Tidak ada countdown palsu**. Tidak ada "Dahulu!" yang tidak benar.

### Struktur Visual (3 Bagian)

**Headline (besar, hangat):**
> "Kamu sudah melepas 2 misi hari ini. Mau lanjut?"

**Subheadline (lembut):**
> "Premium membuka meditasi lengkap, jurnal tanpa batas, dan laporan bulan untuk melihat pola pikirmu. Tanpa buru-buru. Tanpa rasa bersalah."

**3 Bullet Value (max 3):**
- ✓ Meditasi tanpa batas (bukan hanya 1/hari)
- ✓ Jurnal tanpa batas + pola pikir bulan ini (22 sesi Better Me)
- ✓ Fokus 3x/hari — tanpa gangguan aplikasi lain

*Catatan: Tidak menyebutkan "monster maju" atau "tiket pertarungan" — dilarang oleh garis etis.*

**CTA + Off-Ramp:**
- [CTA Utama] "Coba Premium — 7 hari gratis"
- [Off-Ramp] "Atau lanjutkan latihan 5 menit gratis dulu? Tidak ada tekanan. Kamu yang memutuskan."

**Visual:**
- Warna: **Hijau daun / oranye tanah** (hangat, bukan merah alarm atau biru klinis dingin).
- Ilustrasi: **Karakter monster tersenyum / duduk bersama user** (bukan marah — menyiratkan "kamu dan monster ini bisa berdamai").
- Tidak ada foto manusia sempurna; ilustrasi abstrak atau karakter Riung.
- **Tidak ada tanda seru merah besar** (mengindikasikan bahaya/darurat).

---

## 5. SOFT PAYWALL VS HARD PAYWALL PER FITUR

| Fitur | Tipe | Alasan | Desain Tiap Tipe |
|---|---|---|---|
| **Check-in pagi** | ❌ Gratis selamanya | Ritual dasar CBT; menyumbat = merusak terapi. | Selalu gratis. |
| **3 Misi Mikro-CBT** | ❌ Gratis (1/hari, bisa lebih?) | Inti intervensi; harus bisa dilakukan tanpa biaya. | 3 misi/hari gratis. Setelah 3, bisa lanjut (bonus) tapi tidak diblok. |
| **Jurnal 1/hari** | ⚠️ Soft | Jurnal ekspresi; tanpa batas = nilai Premium. | 1 jurnal/hari gratis. Saat coba jurnal ke-2: "Kamu sudah menulis hari ini — bagus. Kalau mau lanjut tanpa batas, coba Premium. Sementara, mau coba latihan napas 3 menit?" |
| **Meditasi** | ✅ Hard + Soft alt | Meditasi penuh (semua sesi) = nilai utama Premium. | Blok akses semua meditasi lengkap. Tampilkan teaser 30 detik. Lalu: "Ini meditasi lengkap (Premium). Sementara, coba latihan napas 3 menit gratis — sama besarnya." |
| **Mini-game** | ❌ Gratis (max 4/hari) | Game adalah reward/CFS; tidak boleh dibeli. | 4/hari gratis. Tidak ada "beli lebih". |
| **Mode Fokus** | ✅ Hard + Soft alt | Fokus = utilitas; tapi alternatif latihan harus ada. | Saat coba aktifkan: "Fokus butuh Premium atau 15 koin. Sebelum itu, coba latihan fokus 2 menit (gratis) — latihan ini sudah membantu banyak orang." |
| **Aplikasi Beku** | ✅ Hard + Soft alt | Kontrol diri; tapi jangan hanya minta uang. | Blok scroll otomatis + buka berbayar 15 koin. Tapi jika koin kurang: "Koinmu habis. Sebelum beli, coba latihan 'tunduk 3 menit' gratis. Kalau sudah siap, Premium bisa dibeli kapan saja." |
| **Know Yourself (tes klinis)** | ⚠️ Soft teaser | Tes sudah nilai; laporan lengkap = Premium. | 15+ tes bisa diisi. Hasil ringkas gratis. Laporan lengkap = Premium (teaser: "Kamu sudah menyelesaikan 3 tes. Lihat pola lengkapnya di Premium?"). |
| **Better Me (22 sesi)** | ✅ Hard | Inti premium; tapi bisa di-teaser lewat sesi 1. | Sesi 1 gratis (teaser). Sesi 2+: "Lanjutkan 21 sesi lain — semua di Premium." Tidak ada pembelian per sesi. |
| **Laporan bulanan** | ✅ Hard | Nilai agregasi data; hanya bisa setelah data cukup. | Tidak bisa sebelum 30 hari atau tanpa Premium. Saat coba akses: "Data bulan ini sudah lengkap — lihat pola pikirmu. Coba Premium? Atau lanjutkan jurnal hari ini dulu." |
| **Streak / Gamifikasi** | ❌ Tidak paywall | Motivasi internal; jangan dijual. | Streak selalu gratis. Tidak ada "beli streak". |
| **Tiket Pertarungan** | ❌ Tidak dijual (etis) | Monster tidak boleh dibeli progress-nya. | Tidak ada transaksi untuk progres monster. Pertarungan tetap gratis, hanya hasilnya terbatas (bisa lanjut dengan latihan, bukan bayar). |

---

## 6. MENGURANGI PAYWALL FATIGUE & RETENSI SETELAH PENOLAKAN

### Masalah
User menolak 2–3 kali → mulai menganggap aplikasi "hanya jualan" → churn.

### Solusi

| Strategi | Implementasi Riung | Teori / Alasan |
|---|---|---|
| **Re-Engagement lewat Streak / Misi** | Setelah penolakan, kirim notifikasi ringan: "Streak-mu 5 hari! Hari ini 1 misi mikro saja. Tidak perlu Premium untuk ini." | SDT (Relatedness): user masih bagian komunitas. Variable Reward: streak = hadiah intrinsik. |
| **Reminder Kontekstual, Bukan Bombardir** | Maksimal 1/day, hanya jika user aktif 2 hari terakhir. Pesan: "Karena kamu sudah 2 hari melakukan misi, ini mungkin saatnya lihat laporan bulan ini?" | Mere Exposure: frekuensi rendah tapi konsisten lebih baik. Cognitive Load: tidak membebani. |
| **Trial Berkelanjutan** | Tawarkan "7 hari gratis" ulang setelah 30 hari jika user aktif tapi belum convert (maksimal 2x). | Foot-in-the-Door: user sudah terbiasa dengan fitur. Reciprocity: kita sudah memberikan nilai 7 hari, sekarang minta balasan. |
| **Penawaran Kontekstual** | Jika user meditasi gratis 3x dalam seminggu, tawarkan Premium saat mereka merasa manfaat: "Kamu sudah meditasi 3x minggu ini. Mau buka semua meditasi?" | Peak-End Rule: tawaran saat user merasa sukses, bukan saat frustasi. State-Dependent Memory: keputusan lebih baik saat mood positif. |
| **Off-Ramp Selalu Ada** | Setelah penolakan: "Tidak apa-apa. Kamu sudah melakukan hal besar hari ini (misi + jurnal). Mari lanjutkan besok." | SDT (Autonomy): tidak ada paksaan = user tidak merasa diperintah. Psychological Safety: aman menolak tanpa rasa bersalah. |
| **Tidak Ada FOMO Palsu** | Tidak boleh "99 orang sedang menunggu" atau "Diskon habis 1 jam" jika tidak benar. | Trust / Credibility: di kesehatan mental, kepercayaan lebih penting dari konversi jangka pendek. |
| **Re-Engagement lewat Edukasi Ringan** | Kirim 1 email/SMS/minggu: "Apa yang kamu rasakan minggu ini? Ini bukan penjualan — hanya tanya kabar." Setelah 2 minggu, tawarkan Premium lembut. | Relationship-first: bukan transaksi. Social Proof ringan: "Banyak orang dengan pola pikiran seperti kamu merasa lebih tenang setelah 22 sesi." |

---

## 7. A/B TESTING PAYWALL

### Variabel yang Diuji

| Variabel | Variasi A | Variasi B | Hipotesis |
|---|---|---|---|
| Headline | "Premium membuka meditasi lengkap" (fungsional) | "Kamu sudah melakukan 5 misi. Lanjutkan tanpa batas?" (personal + kebanggaan) | B lebih tinggi karena SDT + Peak-End. |
| Waktu penampilan | Saat user coba meditasi penuh (hard) | Setelah ritual pagi selesai (soft teaser + hard 2 menit) | B lebih rendah churn setelah penolakan karena autonomy lebih terasa. |
| Off-ramp copy | "Tidak ada masalah, coba nanti" (netral) | "Tidak apa-apa. Kamu sudah melakukan hal besar hari ini. Mari lanjut besok." (validasi + aman) | B meningkatkan retensi 7 hari setelah penolakan. |
| Visual karakter | Monster tersenyum (koeksisten) | Monster berlari ke user (energi positif) | A lebih baik untuk skor monster tinggi (kurangi cemas). B mungkin lebih baik skor rendah (motivasi). |
| CTA | "Coba Premium — 7 hari gratis" | "Mulai 7 hari gratis dulu" | B lebih rendah friction (low commitment: "mulai" vs "coba"). |
| Jumlah bullet | 5 bullet | 3 bullet + ilustrasi | B lebih baik karena Cognitive Load lebih rendah. |

### Metrik Utama (Primary)

1. **Conversion Rate Paywall**: % user yang melihat paywall → membeli Premium dalam 7 hari.
2. **Retention 7 Hari Setelah Penolakan**: % user kembali ritual dalam 7 hari setelah menolak. Ini metrik etika — jika turun drastis, paywall terlalu agresif.
3. **Churn Rate 30 Hari**: % user tidak aktif sama sekali dalam 30 hari setelah penolakan pertama.
4. **Task Completion Rate**: % ritual harian tetap dilakukan setelah penolakan paywall.
5. **NPS / Rating**: Kepuasan setelah melihat paywall (survei 1 pertanyaan ringan).

### Durasi & Metodologi

- **Durasi**: **2 minggu** per variasi (minimum 500 user per variasi, atau 10% user aktif harian).
- **Randomisasi**: User dibagi acak saat pertama kali melihat paywall (saat pertama coba fitur berbayar, bukan onboarding).
- **Statistik**: **t-test** untuk conversion rate; **survival analysis** untuk retention 7 hari setelah penolakan.
- **Etika**: Pastikan tidak ada variasi yang melanggar garis etis (tidak false urgency, tidak paywall saat krisis, tidak hard-block ritual). Variasi hanya pada copy, waktu, visual, jumlah bullet — bukan akses fitur dasar.
- **Segmentasi**: Uji per segmen — user baru (< 7 hari) vs lama (> 30 hari). User baru mungkin responsif terhadap personalisasi; user lama mungkin terhadap fungsionalitas.

---

## RINGKASAN EKSEKUTIF

1. **Paywall paling baik** saat user sudah dalam flow (mencoba fitur berbayar) dan sudah menerima nilai dari onboarding + ritual. Jangan di splash atau saat krisis.
2. **Selalu ada alternatif latihan gratis** saat paywall ditampilkan — terutama saat koin habis. Ini bukan hanya etika, tapi juga retensi.
3. **Tidak pernah jual progres monster atau tiket pertarungan**. Monster adalah distorsi kognitif — mengubahnya jadi transaksi merusak integritas CBT.
4. **Tone**: Hangat, "kamu", anti-guilt, anti-urgensi palsu. Gunakan ilustrasi, bukan foto sempurna.
5. **A/B test** pada headline, waktu, off-ramp, visual, CTA. Metrik utama bukan hanya conversion, tapi retensi setelah penolakan.
6. **Paywall fatigue** dikurangi dengan reminder kontekstual (bukan bombardir), streak, trial berkelanjutan, dan penawaran saat mood positif (setelah ritual).

---

*Disusun untuk Aplikasi Riung · CBT Kesehatan Mental · Indonesia · 2026*
*Referensi: Kahneman (Loss Aversion, Peak-End), Cialdini (Reciprocity), Deci & Ryan (SDT), Sweller (Cognitive Load), Mere Exposure.*
