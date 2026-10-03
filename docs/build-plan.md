# Riung — Build Plan (Claude Code, per milestone)
Cara pakai: satu milestone = satu (atau beberapa) sesi Claude Code. Selalu mulai sesi dengan: "Baca CLAUDE.md dan file design yang relevan dulu." QA visual di tiap akhir milestone sebelum lanjut.

## M0 — Fondasi (1 sesi)
Init Flutter project + struktur folder · port Design System.dc.html → `core/theme/` (tokens, type scale, komponen dasar: tombol, chip koin/streak/tiket, kartu, bottom nav) · `docs/` diisi economy-props.json, assessment-scoring-spec.md, dummy seed · `assets/monsters/` (SVG + anchors.json).
**Gate QA**: satu layar galeri komponen dibandingkan dengan Design System.dc.html.

## M1 — Monster renderer (1 sesi)
Widget `RiungMonster(id, state, cosmetics, size)` — SVG layered + anchors, boss scale, rotasi Mengelak · uji di 48dp & 160dp.
**Gate**: contact sheet in-app vs desain.

## M2 — Jalur revenue (3–4 sesi) ← prioritas bisnis
Launch (5) → Onboarding funnel + skoring (39) → Home (5) → Focus timer + tiket lokal. Firebase Auth anonim + local DB. Paywall UI (belum live billing).
**Gate**: jalan penuh dari splash → hasil asesmen (skor benar per spec) → home → sesi fokus selesai, offline.

## M3 — Fitur inti (3 sesi)
Meditasi · Tidur · Jurnal (PIN + enkripsi + offline save) · Afirmasi · Check-in pagi + streak + misi harian.

## M4 — Sistem monster (2 sesi)
Vault + detail (Apa katanya/Faktanya, teknik penangkal) · mini-game breathing (AnimationController) · progres & perayaan jinak · kosmetik terpasang.

## M5 — Ekonomi live (2 sesi)
Firestore + Cloud Functions (spendCoins/earnCoins/dailyCheckin/tameProgress) · Toko · Play Billing via in_app_purchase + validatePurchase · Premium gating.
**Gate**: uji beli sandbox (license tester), koin masuk hanya via server.

## M6 — AppBeku + Profil + Better me (2–3 sesi)
UsageStats permission + interstisi limit · Profil + kalender + pengaturan + krisis + hapus akun · Better me 22 sesi · Paywall live.

## M7 — Rilis (1–2 sesi)
Ikon/splash · Proguard/AAB <40MB · Crashlytics · privacy policy + data safety form · closed testing Play Console.

Estimasi realistis: 15–20 sesi kerja. Jangan lompati gate QA — bug fondasi (theme/ekonomi/skoring) paling mahal diperbaiki belakangan.
