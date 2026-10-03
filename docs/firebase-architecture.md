# Firebase Architecture — Psychology App (Freemium, ID Market)
*CTO technical spec — v1.0*

## 1. Stack
- **Firebase Auth** — Email/Password, Google Sign-In (dominant in ID), anonymous auth for pre-signup onboarding funnel (convert later via `linkWithCredential`).
- **Cloud Firestore** — primary DB (schema below).
- **Cloud Functions** — ALL coin mutations, IAP receipt validation (Google Play Billing), streak calculation, content unlocks. Clients NEVER write balances directly.
- **Remote Config** — feature flags, price points, paywall A/B (layout A vs B), free-tier limits.
- **Analytics + Crashlytics** — funnel events (see §6).
- **Cloud Messaging (FCM)** — morning check-in reminder, streak-saver, affirmation push.
- **App Check** — enforce on Firestore + Functions (blocks tampering with coin economy).

## 2. Freemium model
| Tier | Access |
|---|---|
| **Free** | Onboarding + assessment, Home, morning check-in, 3 meditations, 2 sleep stories, journaling (max 1 entry/day), daily affirmation, Vault view-only, mini-game 1x/day |
| **Coins (consumable IAP)** | **Focus Mode sessions** (primary coin sink), extra mini-game tickets ("attack tickets"), monster skins in Shop |
| **Premium (subscription)** | Everything unlimited + full "Better me" program + all meditations/sleep + unlimited journaling |

**Focus Mode = coin-gated**: user spends coins to enter a distraction-blocking focus session (25/45/60 min). Rationale is research-backed (screen overuse ↑ anxiety/depression risk 20–30%; sleep disruption from devices) — we productize the fix.

Coin sources: purchase (IAP), daily check-in reward (+5), streak milestones, taming a monster (+50), completing Better me lessons. Coin sinks: Focus Mode (25/40/50 per session length), attack tickets (30), skins (100–500).

## 3. Firestore schema
```
/users/{uid}
  profile: {displayName, avatarId, locale:"id", createdAt, onboardingDone}
  wallet:  {coins:int, lifetimeEarned:int, lifetimeSpent:int}   // written by Functions only
  premium: {active:bool, plan:"monthly|yearly|null", renewsAt}
  streak:  {current:int, longest:int, lastCheckinDate}
  assessment: {dominantSaboteurs:[ids], scores:{sab_id:0-100}, completedAt}

/users/{uid}/checkins/{date}          // mood, energy, sleepQuality, intention
/users/{uid}/journal/{entryId}        // promptId, text, mood, tags, createdAt
/users/{uid}/sessions/{sessionId}     // type: focus|meditation|sleep|minigame, duration, coinsSpent, completedAt
/users/{uid}/monsters/{saboteurId}    // state: wild|taming|tamed, progress:0-100, tamedAt
/users/{uid}/transactions/{txId}      // {type: earn|spend|purchase, amount, reason, ref, ts} — audit log

/content/saboteurs/{saboteurId}       // the 7 monsters + psychoeducation (public read)
/content/meditations/{id} /sleep/{id} /affirmations/{id} /betterme/{lessonId}
/content/research_facts/{factId}      // the evidence base shown in-app ("Tahukah kamu?")

/products/{productId}                 // coin packs, subs — mirrors Play Console SKUs
/config/economy                       // costs & rewards (also in Remote Config)
```

## 4. Security rules (essence)
```
match /users/{uid}/{doc=**} { allow read, write: if request.auth.uid == uid
  && !( 'wallet' in request.resource.data )  // never client-writable
}
match /users/{uid}/transactions/{tx} { allow read: if request.auth.uid==uid; allow write: if false; }
match /content/{doc=**}  { allow read: if true;  allow write: if false; }
match /products/{doc=**} { allow read: if true;  allow write: if false; }
```
Wallet + transactions written exclusively by Cloud Functions (`spendCoins`, `earnCoins`, `validatePurchase` with Play receipt verification, idempotency keys per txId).

## 5. Key Cloud Functions
- `validatePurchase(receipt)` → verify with Play Developer API → credit coins / activate premium → write transaction.
- `spendCoins(reason, amount, ref)` → transactional decrement; rejects if insufficient; returns new balance + unlock token for Focus Mode.
- `dailyCheckin()` → idempotent per date; +5 coins; streak logic (grace period 1 day w/ "streak saver" costing 20 coins).
- `tameProgress(saboteurId, delta)` → progress += delta; at 100 → state=tamed, +50 coins, FCM celebration.

## 6. Analytics events (funnel)
`onboarding_start, q_answered{n}, assessment_result, paywall_view{variant}, purchase{sku}, focus_start{duration,coins}, focus_complete, checkin_done, monster_tamed{id}, minigame_complete, d1/d7/d30 retention (via audiences)`

## 7. Evidence base (why our content claims are defensible)
Shown in-app as sourced "Tahukah kamu?" cards and in saboteur psychoeducation:
- I-NAMHS 2022: 34.9% (≈15.5M) remaja Indonesia punya ≥1 masalah kesehatan mental; kecemasan tertinggi (P 28.2% / L 25.4%).
- SKI 2023 (Kemenkes): prevalensi depresi tertinggi di usia 15–24 (2%); perempuan muda 2.8% vs laki-laki 1.1%; hanya ~10.4% anak muda dengan depresi mencari pengobatan; 61% pernah memiliki pikiran bunuh diri dalam 1 bulan terakhir.
- WHO: ~1 dari 7 usia 10–19 mengalami kondisi kesehatan mental; bunuh diri penyebab kematian ke-4 usia 15–29.
- Digital use: ~95% remaja online harian; pemakaian medsos berlebihan ↑ risiko depresi/kecemasan ~20–30%; gangguan tidur akibat gawai memengaruhi regulasi mood → dasar ilmiah Focus Mode & fitur Sleep.
- Metode: meta-analisis → app berbasis CBT paling efektif (komponen aktif: cognitive restructuring, behavioral activation, goal setting); intervensi digital CBT peringkat efikasi tertinggi pada remaja (SUCRA depresi 79.3%, cemas 83.4%); latihan pernapasan intensif → penurunan kecemasan lebih kuat dalam 6 minggu (dasar mini-game breathing); behavioral activation digital menurunkan gejala depresi hingga 6 bulan.
- Mapping saboteur → distorsi kognitif CBT: Si Meronta=personalization/victim mindset · Si Waswas=catastrophizing · Si Kabut=avoidant procrastination/rumination · Si Cermin=social comparison · Si Sempurna=perfectionism/should-statements · Si Mengelak=experiential avoidance · Si Hakim=inner critic/global labeling.

**Compliance note:** app = wellness/self-help, BUKAN alat diagnosis/terapi. Wajib disclaimer + rujukan bantuan profesional & layanan krisis di Profile dan hasil assessment. Jangan tampilkan statistik bunuh diri di UI konsumen; simpan untuk konteks klinis/dokumentasi.

## 8. Offline-first architecture (v1.1 addendum)
**Principle: everything runs offline except money.** Online required only for: IAP purchases, coin→ticket exchange, content sync, optional backup.

### 8.1 Server-authoritative wallet + prepaid Focus tickets
Problem: coins must be server-side (fraud), but Focus Mode is used precisely when users go offline (airplane/DND).
Solution — **prepaid ticket pattern**:
1. While online, `exchangeCoinsForTickets(n, duration)` (Cloud Function) deducts coins and returns **signed session tokens** `{ticketId, duration, issuedAt, expiry(30d), HMAC}` stored locally.
2. Entering Focus Mode consumes a local ticket — **zero connectivity needed**.
3. On reconnect, client reports consumed ticketIds → server reconciles into /transactions (idempotent).
4. UI: Focus duration picker shows "Tiket tersimpan: 3" alongside coin balance; nudge to stock up tickets while online.
Anti-abuse: HMAC-signed tickets + App Check + expiry. Don't over-engineer for v1.

### 8.2 Local-by-default personal data
- Journal, check-ins, assessment results, monster progress → **local Room/SQLite** (source of truth on-device).
- Cloud backup is **opt-in, encrypted** ("Cadangkan datamu") — also a privacy selling point: "Jurnalmu tersimpan di HP-mu."
- Provide file export from day 1 (device-loss mitigation).
- Sync queue drains silently when connectivity returns (WorkManager).

### 8.3 Content strategy
- Firestore built-in offline persistence for metadata.
- Audio via CDN + download manager; **starter pack bundled in APK** (3 meditations + 2 sleep stories) for a full first-run with no download; rest download-on-WiFi.

### 8.4 Performance budget (light + animated)
- Monster animations: **Lottie** (or **Rive** for interactive/mini-game reactions — state machines in one small file). 14 animated monsters ≈ 1–2 MB total. No video/PNG sequences.
- Images WebP/AVIF; icons as vector drawables.
- APK/AAB download target **< ~40 MB**; App Bundle + R8 + baseline profiles.
- 60fps target on 2–4 GB RAM devices (Redmi/Galaxy A class = majority of ID market); native property/spring animations; avoid layered blur/shadows in lists.
