# REELS_01 — "Midnight Scroll Trap" · Prompt Google Flow (ID + EN)

Sumber: storyboard `NDW85` di `design/campaign.pen` (5 scene, 20 dtk). Dibuat 2026-10-17.
Hanya monster **gratis** (Si Kabut + Si Waswas, keduanya Monster Pikiran).

## Kenapa dipecah

- Satu generate di Flow (Omni 1.1 Flash) **maksimal 10 detik** (pilihan 4/6/8/10 dtk). Jadi 20 dtk tidak bisa sekali jadi.
- Flow punya **Extend**: melanjutkan klip per 10 dtk, total maksimal 40 dtk. Tapi Extend menyambung **satu shot kontinu**. Storyboard kita terdiri dari 5 scene dengan potongan (cut), jadi lebih hemat dan lebih bisa dikontrol kalau tiap scene dibuat sebagai klip terpisah lalu dirangkai di editor (CapCut/Premiere).
- **Teks TIDAK dibuat di Flow.** Model video sering salah mengeja, apalagi teks Bahasa Indonesia. Video dibuat **tanpa teks** dan teks ditempel di editor. Hasilnya: **satu set video untuk ID dan EN**, yang beda hanya layer teksnya.
- **Tanpa dialog/voice-over** dari Flow, supaya video bisa dipakai untuk dua bahasa. SFX boleh dari Flow. Kalau hasilnya jelek, mute lalu pakai SFX/musik bebas royalti di editor.

## Aset yang harus ada di Flow

| Nama di Flow | Status | Sumber di repo |
|---|---|---|
| `kabut_liar.webp` | **BELUM di-upload** — wajib | `riung/assets/monsters/3d/kabut_liar.webp` |
| `waswas_liar.webp` | **BELUM di-upload** — wajib | `riung/assets/monsters/3d/waswas_liar.webp` |
| `kabut_jinak.webp` | sudah ada | — |
| `waswas_jinak.webp` | sudah ada | — |
| `scene4_awal_liar.png` | upload (frame awal Scene 4) | `campaign/reels/flow_frames/scene4_awal_liar.png` |
| `scene4_akhir_jinak.png` | upload (frame akhir Scene 4) | `campaign/reels/flow_frames/scene4_akhir_jinak.png` |

**Jangan pakai** aset monster kebiasaan yang ada di library Flow (nanti, gulir, bunglon, bimbang, begadang, bara). Semuanya Premium dan belum boleh diiklankan. `Glass — Beranda.png` juga jangan dipakai sebagai layar HP di video AI, karena model akan mengubah UI-nya jadi tidak akurat.

## Setting umum (semua klip)

- **Video** (bukan Image) · **9:16** · model **Omni 1.1 Flash** · **720p**
- **x2** saat mencoba (dapat 2 variasi untuk dipilih), lalu **x1** kalau tinggal mengulang satu yang hampir pas.
- Hemat kredit: tes prompt dulu di **360p** (sekitar ⅓ biaya), lalu render final di 720p.
- Acuan dari screenshot kamu: 8 dtk · 720p · x1 = 12 kredit. Perkiraan total satu take final (8 + 6 + 4 + 4 dtk) sekitar 33 kredit untuk x1. Ini estimasi, angka pastinya lihat di Flow.

## Rencana klip → timeline ±21 dtk

| Klip | Scene storyboard | Timeline final | Mode Flow | Durasi pilih | Dipakai |
|---|---|---|---|---|---|
| A | 1 Hook + 2 Eksternalisasi | 0.0–8.0 | Ingredients | **8s** | utuh |
| B | 3 Demo Aplikasi Beku | 8.0–12.0 | Ingredients | **6s** | ambil 1.0–5.0 (4 dtk) |
| C | 4 Transformasi | 12.0–16.0 | Frames (awal + akhir) | **4s** | utuh |
| D | 5 CTA — transisi | 16.0–20.0 | Frames (awal + akhir) | **4s** | utuh, lalu crossfade ke PNG CTA |
| — | 5 CTA — teks | 19.5–21.0 | bukan Flow | — | `scene5_cta_ID.png` / `scene5_cta_EN.png`, ditahan sampai akhir |

Klip D dibuat **tanpa teks** dan berakhir di frame netral (latar + ikon + wordmark), yang identik dengan PNG CTA tanpa teks. Jadi crossfade 0,5 dtk ke PNG CTA terlihat seperti teks yang muncul, dan satu klip D bisa dipakai untuk ID maupun EN. Ikon app dan teks tetap persis karena berasal dari PNG.

---

## Klip A — Scene 1 + 2 (8s)

**Setting:** Video · Ingredients · 9:16 · Omni 1.1 Flash · 720p · **8s** · x2
**Ingredients:** `kabut_liar.webp`, `waswas_liar.webp`

**Prompt:**
```
Vertical 9:16 cinematic shot. A dark bedroom at 2:34 AM, lit only by the cold blue glow of a smartphone. Close-up over-the-shoulder view of a young person lying in bed, face not visible, thumb endlessly scrolling a phone; the screen shows only a soft, blurry, abstract colorful feed with no readable text and no logos. From the phone's glow, two small soft-vinyl 3D toy monsters float up and hover beside the screen: a gray puffy cloud-shaped monster with sleepy half-closed eyes, a wavy mouth and a little curl on top (exactly like the kabut_liar reference), and a round khaki three-eyed monster with zigzag antennae and a worried wavy mouth (exactly like the waswas_liar reference). They drift lazily around the phone, keeping the thumb scrolling. Around the 4-second mark the camera slowly pushes in past the phone and the two monsters turn to face the camera and hover side by side in the center of the frame, slightly mischievous, with empty space above and below them. Moody blue and lavender palette, soft pastel 3D render style, shallow depth of field, gentle camera motion. Sound: a slow tense heartbeat, soft digital glitch ticks, faint clock ticking. No dialogue, no voice, no music with lyrics. No text, no captions, no subtitles, no watermark, no app logos.
```

## Klip B — Scene 3 (6s → ambil 4 dtk)

**Setting:** Video · Ingredients · 9:16 · Omni 1.1 Flash · 720p · **6s** · x2
**Ingredients:** `kabut_liar.webp`

**Prompt:**
```
Vertical 9:16 shot, continuing a dark bedroom at night. Close-up of a smartphone held in a hand, its screen showing a blurry, abstract scrolling feed with no readable text. Suddenly delicate ice crystals spread across the screen from the edges and the scrolling freezes in place; the glass frosts over with a soft icy blue light. The gray puffy cloud monster from the kabut_liar reference, hovering beside the phone, gets lightly dusted with frost and slows down, blinking in surprise. Then a soft glowing circle of warm light appears in front of the phone and gently expands and contracts in a slow, calm rhythm, like guided breathing (expand 4 seconds, hold, contract). The mood shifts from tense to calm: colors warm from cold blue to soft lavender and peach. Soft pastel 3D render style, smooth slow camera. Sound: crystalline freezing shimmer, one soft bell, quiet airy breathing whoosh. No dialogue, no voice. No text, no numbers, no captions, no watermark, no logos.
```

Saat editing, ambil 1.0–5.0 dtk (bagian beku + napas).

## Klip C — Scene 4 (4s)

**Setting:** Video · **Frames** · 9:16 · Omni 1.1 Flash · 720p · **4s** · x2
**Frame awal:** `scene4_awal_liar.png` · **Frame akhir:** `scene4_akhir_jinak.png`

**Prompt:**
```
Vertical 9:16, locked-off camera, soft pastel lavender-to-peach studio background. The two soft-vinyl 3D toy monsters stay in place and gently transform from their wild form to their tamed form: the gray clay-like cloud monster softens into a fluffy pale-blue cloud with closed happy eyes and a small smile, with little wisps of mist; the khaki worried three-eyed monster brightens into a warm orange round monster with curly antennae, rosy cheeks and a calm smile. Smooth, magical but gentle morph, small sparkles, soft bounce at the end. Keep their positions, size and floor shadows consistent. Sound: a warm rising arpeggio chime. No dialogue. No text, no captions, no watermark.
```

---

## Klip D — Scene 5 transisi ke CTA (4s)

**Setting:** Video · **Frames** · 9:16 · Omni 1.1 Flash · 720p · **4s** · x2
**Frame awal:** `scene5_awal_dari_klipC.png` (frame terakhir Klip C) · **Frame akhir:** `scene5_akhir_netral.png`
File ada di `campaign/reels/flow_frames/`. Frame akhir adalah export `tW37G` di campaign.pen.

**Prompt:**
```
Vertical 9:16, locked-off camera, continuous shot with no cuts. Continue from the first frame: the fluffy pale-blue smiling cloud monster and the warm-orange three-eyed monster with curly antennae, standing on a soft pastel lavender-to-peach background. They look at each other, give a happy little bounce, then hop toward the center and float upward together, shrinking and gliding into a soft glowing circle that settles into the rounded-square app icon from the last frame, where they appear small and cozy inside the icon's glass bubble. The background gently brightens into the soft lavender, mint and peach gradient of the last frame. Gentle, warm, satisfying motion with a few tiny sparkles. End exactly on the last frame: the app icon centered with the word "Riung" below it, everything still. Sound: a cheerful soft outro chime with a light pop as they enter the icon. No dialogue, no voice. No other text, no captions, no watermark.
```

Kalau wordmark "Riung" di akhir klip sedikit meleset atau berubah bentuk, aman saja: 0,5 dtk terakhir ditutup crossfade ke PNG CTA yang persis.

## Teks overlay (tempel di editor) — ID dan EN

Font: Plus Jakarta Sans / Inter tebal, putih dengan bayangan lembut. Taruh di tengah layar. **15% bawah tetap kosong** untuk UI Reels/TikTok.

| Waktu | Elemen | ID (`@riung.id`) | EN (`@riung.global`) |
|---|---|---|---|
| 0.0–4.0 | Jam | 02:34 | 2:34 AM |
| 0.0–4.0 | Besar | Lagi-lagi terjebak scroll medsos sampai jam 2 pagi? | Doomscrolling till 2 a.m. again? |
| 4.0–8.0 | Besar | Bukan kamu yang lemah kendali diri. | It's not that you lack willpower. |
| 4.0–8.0 | Sub | Itu Si Kabut & Si Waswas yang lagi membajak perhatianmu. | It's Si Kabut & Si Waswas hijacking your attention. |
| 4.0–8.0 | Kartu 1 | MONSTER PIKIRAN · Si Kabut · Scroll tanpa sadar · “Nanti aja, masih ada waktu.” | THOUGHT MONSTER · Si Kabut · Mindless scrolling · “Later. There's still time.” |
| 4.0–8.0 | Kartu 2 | MONSTER PIKIRAN · Si Waswas · Catastrophizing · “Gimana kalau besok semuanya berantakan?” | THOUGHT MONSTER · Si Waswas · Catastrophizing · “What if it all falls apart tomorrow?” |
| 7.0–8.0 | Penutup | Riung memanggilnya saat mereka datang — menjinakkan, bukan melawan. | Riung names them when they show up — tame them, don't fight them. |
| 8.0–12.0 | Besar | Membekukan doomscroll. | Freeze the doomscroll. |
| 8.0–12.0 | Sub | Napas 4-4-4 · gratis | 4-4-4 breathing · free |
| 8.0–12.0 | Label | APLIKASI BEKU · Tarik napas · 4 · 4 · 4 | FROZEN APPS · Breathe in · 4 · 4 · 4 |
| 12.0–16.0 | Besar | Menjinakkan, bukan melawan. | Tame them, don't fight them. |
| 12.0–16.0 | Sub | Pola pikir negatif gak perlu dimusuhi. Di Riung, kamu belajar mengenali dan menjinakkannya. | Negative thought patterns aren't the enemy. In Riung, you learn to spot them and tame them. |
| 19.5–21.0 | Besar | Jinakkan monstermu — coba gratis sekarang. | Tame your monsters — try it free. |
| 19.5–21.0 | Sub | Riung: Duduk Bersama Pikiranmu. | Riung: Sit With Your Thoughts. |
| 19.5–21.0 | Tombol | Download gratis di Android | Free on Android |
| 19.5–21.0 | Disclaimer | Bukan pengganti bantuan profesional. | Not a substitute for professional help. |

"Frozen Apps" dan "Breathe in" diambil dari string EN app. Tagline EN "Sit With Your Thoughts" masih **usulan**, karena belum ada di repo; setujui dulu sebelum dipakai. Nama monster tetap "Si …" di kedua bahasa, seperti di app.

**Jangan tampilkan** rating/ulasan (mis. "4.9 · 12.400+ ulasan") sebelum ada data nyata dari Play Console.

## Varian per akun (dari jadwal AUTO_01)

- `@riung.id` Minggu 1 Senin: render ID.
- `@riung.global` Minggu 1 Senin: render EN. Minggu 2 Jumat "repackage subtitle EN" pakai video yang sama dengan teks EN dalam gaya subtitle.
- `@riung` Minggu 1 Senin: render EN + stiker link Play Store. Minggu 2 Jumat "demo app" **bukan Flow**: rekam layar app asli (adb screenrecord), supaya UI yang tampil akurat.
