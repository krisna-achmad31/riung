# Generates the Riung Postman collection and environments (v2.1):
#   python3 postman/generate.py postman     (from backend/)
import json, sys, uuid

OUT = sys.argv[1]
NS = uuid.UUID("6f1c2e1a-7d4b-4c55-9a39-0b1c6f1d2e10")
def uid(name): return str(uuid.uuid5(NS, name))

def js(lines): return {"type": "text/javascript", "exec": lines}

def url(path, base="{{baseUrl}}", query=None):
    raw = base + path
    q = query or []
    if q:
        raw += "?" + "&".join(f"{k}={v}" for k, v, _ in q)
    u = {"raw": raw, "host": [base], "path": [p for p in path.strip("/").split("/") if p]}
    if q:
        u["query"] = [{"key": k, "value": v, "description": d} for k, v, d in q]
    return u

def req(name, method, path, body=None, desc="", auth="inherit", base="{{baseUrl}}", query=None, tests=None, pre=None, headers=None):
    r = {"method": method, "header": headers or [], "url": url(path, base, query), "description": desc}
    if body is not None:
        r["body"] = {"mode": "raw", "raw": json.dumps(body, indent=2, ensure_ascii=False), "options": {"raw": {"language": "json"}}}
        r["header"] = r["header"] + [{"key": "Content-Type", "value": "application/json"}]
    if auth == "none":
        r["auth"] = {"type": "noauth"}
    elif auth != "inherit":
        r["auth"] = {"type": "bearer", "bearer": [{"key": "token", "value": auth, "type": "string"}]}
    item = {"id": uid(name + method + path), "name": name, "request": r, "response": []}
    ev = []
    if pre: ev.append({"listen": "prerequest", "script": js(pre)})
    if tests: ev.append({"listen": "test", "script": js(tests)})
    if ev: item["event"] = ev
    return item

def folder(name, desc, items):
    return {"id": uid("folder" + name), "name": name, "description": desc, "item": items}

def ev(type_, **fields):
    return {"type": type_, "occurredAt": "{{now}}", **fields}

save_me = [
    "if (pm.response.code === 200) {",
    "  const j = pm.response.json();",
    "  pm.environment.set('userId', j.user.id);",
    "  pm.environment.set('billingAccountId', j.user.billingAccountId);",
    "  pm.test('billingAccountId tersimpan', () => pm.expect(j.user.billingAccountId).to.match(/^ba_/));",
    "}",
]
save_ticket = [
    "if (pm.response.code === 200) {",
    "  const j = pm.response.json();",
    "  pm.environment.set('ticketId', j.ticket.id);",
    "  pm.test('ticketId tersimpan', () => pm.expect(j.ticket.id).to.be.a('string'));",
    "}",
]
save_etag = [
    "const tag = pm.response.headers.get('ETag');",
    "if (tag) pm.environment.set('configEtag', tag);",
]
# Token dev disimpan supaya Restore mengirim pembelian yang sama seperti di HP. Produksi (devBilling kosong):
# isi coinToken/subToken dengan purchaseToken asli dari app.
coin_token_pre = [
    "if (pm.environment.get('devBilling') === 'true') pm.environment.set('coinToken', `dev-coin:${pm.environment.get('billingAccountId')}:coin_pack_large:${Date.now()}`);",
]
sub_token_pre = [
    "if (pm.environment.get('devBilling') === 'true') pm.environment.set('subToken', `dev-sub:${pm.environment.get('billingAccountId')}:premium_yearly:365:${Date.now()}`);",
]
coin_verify_test = [
    "if (pm.response.code === 200) {",
    "  const j = pm.response.json();",
    "  pm.test('paket koin dikreditkan', () => pm.expect(j.result.status).to.be.oneOf(['credited', 'already_credited']));",
    "}",
]
sub_verify_test = [
    "if (pm.response.code === 200) {",
    "  const j = pm.response.json();",
    "  pm.test('langganan aktif', () => pm.expect(j.result.status).to.eql('active'));",
    "  pm.test('premium tahunan', () => pm.expect(j.premium.plan).to.eql('premium_yearly'));",
    "}",
]
restore_pre = [
    "// Lokal tanpa Verifikasi lebih dulu: buat token baru (dikreditkan saat restore).",
    "if (pm.environment.get('devBilling') === 'true') {",
    "  const ba = pm.environment.get('billingAccountId');",
    "  if (!pm.environment.get('coinToken')) pm.environment.set('coinToken', `dev-coin:${ba}:coin_pack_large:${Date.now()}`);",
    "  if (!pm.environment.get('subToken')) pm.environment.set('subToken', `dev-sub:${ba}:premium_yearly:365:${Date.now()}`);",
    "}",
]
restore_test = [
    "if (pm.response.code === 200) {",
    "  const sent = JSON.parse(pm.variables.replaceIn(pm.request.body.raw)).purchases;",
    "  const rows = pm.response.json().results;",
    "  pm.test('satu baris per pembelian, urutan sama', () => pm.expect(rows.map(r => r.purchaseToken)).to.eql(sent.map(p => p.purchaseToken)));",
    "  pm.test('productId ikut dikembalikan', () => pm.expect(rows.map(r => r.productId)).to.eql(sent.map(p => p.productId)));",
    "  // Di app: cocokkan lewat purchaseToken, bukan posisi baris.",
    "  const byToken = Object.fromEntries(rows.map(r => [r.purchaseToken, r]));",
    "  const coin = byToken[pm.environment.get('coinToken')], sub = byToken[pm.environment.get('subToken')];",
    "  pm.test('paket koin tidak dikreditkan dua kali', () => pm.expect(coin.ok && coin.result.status).to.be.oneOf(['credited', 'already_credited']));",
    "  pm.test('langganan dipulihkan', () => pm.expect(sub.ok && sub.result.status).to.eql('active'));",
    "  pm.test('token akun lain ditolak', () => pm.expect(rows[2].ok === false && rows[2].error.code).to.eql('purchase_invalid'));",
    "}",
]
rtdn_pre = [
    "// Pub/Sub push body: base64 DeveloperNotification + messageId unik.",
    "const n = { version: '1.0', packageName: 'com.riung.riung', eventTimeMillis: String(Date.now()), testNotification: { version: '1.0' } };",
    "pm.variables.set('rtdnData', btoa(JSON.stringify(n)));",
    "pm.variables.set('rtdnMessageId', String(Date.now()));",
]

collection_pre = [
    "// Header yang sama untuk semua request (docs/panduan-integrasi-app.md §2).",
    "pm.request.headers.upsert({ key: 'X-App-Version', value: pm.variables.get('appVersion') || '1.0.0' });",
    "pm.request.headers.upsert({ key: 'X-Platform', value: 'android' });",
    "const appCheck = pm.variables.get('appCheckToken');",
    "if (appCheck) pm.request.headers.upsert({ key: 'X-Firebase-AppCheck', value: appCheck });",
    "// Satu Idempotency-Key baru per kirim. Untuk menguji replay, isi header Idempotency-Key sendiri di request-nya.",
    "if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(pm.request.method) && !pm.request.headers.has('Idempotency-Key')) {",
    "  pm.request.headers.add({ key: 'Idempotency-Key', value: pm.variables.replaceIn('{{$guid}}') });",
    "}",
    "// now = occurredAt; today = tanggal lokal Asia/Jakarta (zona waktu default user).",
    "const now = new Date();",
    "pm.variables.set('now', now.toISOString());",
    "pm.variables.set('today', new Date(now.getTime() + 7 * 3600 * 1000).toISOString().slice(0, 10));",
]
collection_test = [
    "pm.test('bukan 5xx', () => pm.expect(pm.response.code).to.be.below(500));",
    "if (pm.response.code >= 400) {",
    "  try { const e = pm.response.json().error; console.log(`${pm.info.requestName}: ${pm.response.code} ${e.code} — ${e.message} (requestId ${e.requestId})`); } catch (_) {}",
    "}",
]

items = [
    folder("0. Sistem", "Liveness & readiness. `/readyz` hanya bisa dari dalam network Docker di produksi (dari luar 404).", [
        req("Healthz", "GET", "/healthz", auth="none"),
        req("Readyz (lokal)", "GET", "/readyz", auth="none", desc="Produksi: 404 dari luar (sengaja)."),
    ]),
    folder("1. Publik & konfigurasi", "Tanpa login; App Check wajib (mode `monitor` di produksi baru mencatat).", [
        req("Config", "GET", "/v1/config", auth="none", tests=save_etag,
            desc="Harga, katalog (`catalog`), batas setelah override admin, `minAppVersion`, `focusTicketKeys`. Cache di app; kirim ulang dengan `If-None-Match` (request berikut) → 304."),
        req("Config (If-None-Match → 304)", "GET", "/v1/config", auth="none",
            headers=[{"key": "If-None-Match", "value": "{{configEtag}}"}], desc="Jalankan **Config** dulu supaya `configEtag` terisi."),
        req("Content", "GET", "/v1/content/saboteurs", auth="none",
            query=[("locale", "id", "id | en (fallback ke id)")],
            desc="`kind`: saboteurs, affirmations, research_facts, meditations, sleep_stories, betterme_lessons. Ganti segmen terakhir path."),
        req("Waitlist", "POST", "/v1/waitlist", auth="none",
            body={"email": "contoh@example.com", "lang": "id", "source": "postman", "website": ""},
            desc="Selalu 202 (email baru atau lama). `website` = honeypot, harus kosong. Tanpa App Check/Idempotency."),
    ]),
    folder("2. Akun", "Akun dibuat otomatis di panggilan pertama `GET /v1/me` (termasuk anonim).", [
        req("Me (bootstrap)", "GET", "/v1/me", tests=save_me,
            desc="Profil, `billingAccountId`, Premium, streak, wallet, monster, inventori, loadout, `today`. Menyimpan `userId` & `billingAccountId` ke environment."),
        req("Update profil", "PATCH", "/v1/me/profile",
            body={"displayName": "Rani", "avatarId": "av2", "locale": "id", "persona": "mahasiswa", "onboardingDone": True, "tz": "Asia/Jakarta"},
            desc="Kirim hanya field yang berubah. `avatarId` av1–av6; `persona` pelajar|mahasiswa|pekerja|lainnya; `tz` IANA."),
        req("Simpan asesmen", "PUT", "/v1/me/assessment",
            body={"dominantSaboteurs": ["hakim", "kabut"], "scores": {"hakim": 72, "kabut": 64, "waswas": 40}, "completedAt": "{{now}}"},
            desc="Ringkasan saja; jawaban & hasil detail tetap di HP."),
        req("Tautkan akun (anonim → permanen)", "POST", "/v1/me/link",
            desc="Setelah `linkWithCredential` di Firebase. Token harus sudah provider `password`/`google.com`. Tanpa body."),
        req("Ekspor data server", "GET", "/v1/me/export", desc="3/jam."),
    ]),
    folder("3. Backup PIN jurnal", "Hanya akun permanen. Hash PIN dihitung di HP.", [
        req("Simpan backup PIN", "PUT", "/v1/me/journal-pin-backup",
            body={"hash": "c2FsdGVkLXBpbi1oYXNoLWRhcmktaHA=", "salt": "c2FsdC0xMjM0NTY="}),
        req("Ambil salt", "GET", "/v1/me/journal-pin-backup", desc="Hanya `salt` + `updatedAt`; hash tidak pernah dikirim balik."),
        req("Verifikasi PIN", "POST", "/v1/me/journal-pin-backup/verify",
            body={"hash": "c2FsdGVkLXBpbi1oYXNoLWRhcmktaHA="},
            desc="`{match, attemptsLeft}`; terkunci 1 jam setelah 10 gagal/hari (`pin_locked`). App Check limited-use."),
        req("Hapus backup PIN", "DELETE", "/v1/me/journal-pin-backup"),
    ]),
    folder("4. Aktivitas (koin & progres)", "App mengirim apa yang terjadi; server menentukan koin. `occurredAt` = `{{now}}`, `date` = `{{today}}` (diisi script koleksi). Event di atas batas harian → 200 `capped: true`.", [
        req("Check-in", "POST", "/v1/activities", body=ev("checkin", date="{{today}}")),
        req("Jurnal disimpan", "POST", "/v1/activities", body=ev("journal_saved", entryId="{{$guid}}", promptId="p_hakim"),
            desc="Teks jurnal TIDAK dikirim."),
        req("Meditasi selesai", "POST", "/v1/activities", body=ev("meditation_completed", sessionId="napas_4_7_8")),
        req("Better Me selesai", "POST", "/v1/activities", body=ev("betterme_lesson_completed", lessonId="l1_s1")),
        req("Misi selesai", "POST", "/v1/activities", body=ev("mission_completed", date="{{today}}", index=0),
            desc="`index` 0–2."),
        req("Minigame selesai", "POST", "/v1/activities", body=ev("minigame_finished", ref="{{$guid}}", saboteurId="waswas", won=True)),
        req("Batch (outbox offline)", "POST", "/v1/activities/batch",
            body={"events": [ev("journal_saved", entryId="{{$guid}}"), ev("minigame_finished", ref="{{$guid}}", saboteurId="kabut", won=False),
                             ev("mission_completed", date="{{today}}", index=1)]},
            desc="≤ 50 event, hasil per event. Kirim ulang request ini (Idempotency-Key baru otomatis): event yang sama dikenali dari `entryId`/`ref`/tanggal → `replayed: true`, tanpa koin dobel. Di app, `entryId`/`ref` dibuat sekali saat kejadian."),
    ]),
    folder("5. Wallet & jurnal", "", [
        req("Wallet", "GET", "/v1/wallet", desc="Termasuk `debtCoins` (utang dari refund)."),
        req("Riwayat transaksi", "GET", "/v1/wallet/transactions", query=[("limit", "20", "1–100")],
            desc="Halaman berikut: tambah `cursor` = `nextCursor`."),
        req("Akses jurnal", "GET", "/v1/journal/access", query=[("promptId", "p_hakim", "opsional")]),
    ]),
    folder("6. Google Play billing", "Akun permanen. **Produksi**: `verify`/`restore` belum aktif (503), webhook 404 selama billing mati; setelah aktif butuh `purchaseToken` asli dari Play. **Lokal** (`DEV_BILLING`, env `devBilling`): token palsu dibuat otomatis dan disimpan di `coinToken`/`subToken`; di produksi isi keduanya dengan token asli.", [
        req("Verifikasi paket koin (dev)", "POST", "/v1/billing/verify", pre=coin_token_pre, tests=coin_verify_test,
            body={"productId": "coin_pack_large", "purchaseToken": "{{coinToken}}"},
            desc="Jalankan **Me** dulu (`billingAccountId`). Status `credited`/`already_credited` → app meng-*consume* paket koin (`consumePurchase`; beli dengan `autoConsume: false`)."),
        req("Verifikasi langganan (dev)", "POST", "/v1/billing/verify", pre=sub_token_pre, tests=sub_verify_test,
            body={"productId": "premium_yearly", "purchaseToken": "{{subToken}}"},
            desc="Status `active`/`inactive` → app memanggil `completePurchase` (acknowledge langganan)."),
        req("Restore", "POST", "/v1/billing/restore", pre=restore_pre, tests=restore_test,
            body={"purchases": [{"productId": "coin_pack_large", "purchaseToken": "{{coinToken}}"},
                                {"productId": "premium_yearly", "purchaseToken": "{{subToken}}"},
                                {"productId": "coin_pack_small", "purchaseToken": "dev-coin:ba_akun_lain:coin_pack_small:1"}]},
            desc="Hasil `restorePurchases()` di app, ≤ 20 pembelian. Satu baris per pembelian dengan urutan yang sama, masing-masing membawa `purchaseToken` — **cocokkan lewat token**, bukan posisi. Dua token pertama = pembelian dari dua request sebelumnya (`already_credited`/`active`, tanpa koin dobel); baris ke-3 = token akun lain → `ok: false`, `purchase_invalid`. Daftar kosong ditolak (400): kalau Play tidak mengembalikan apa pun, app tidak memanggil endpoint ini."),
        req("Status Premium", "GET", "/v1/billing/subscription"),
        req("Koin harian Premium tahunan", "POST", "/v1/premium/daily-coins",
            desc="Akun permanen + Premium **tahunan** aktif (lokal: setelah *Verifikasi langganan*); +2 koin 1×/hari."),
        req("Webhook RTDN (dev)", "POST", "/v1/webhooks/google-play", auth="{{pubsubToken}}", pre=rtdn_pre,
            body={"message": {"data": "{{rtdnData}}", "messageId": "{{rtdnMessageId}}"}, "subscription": "projects/riung-5e979/subscriptions/play-rtdn"},
            desc="Lokal (bearer `dev-pubsub`) → 204. Produksi: 404 selama billing belum aktif; setelah aktif hanya Pub/Sub dengan token OIDC Google."),
    ]),
    folder("7. Toko & loadout", "Harga dari `Config` → `catalog`; `expectedPrice` harus sama.", [
        req("Beli kosmetik monster", "POST", "/v1/shop/purchase", body={"itemType": "cosmetic", "itemId": "topi_rajut", "expectedPrice": 100}),
        req("Beli aksesori karakter", "POST", "/v1/shop/purchase", body={"itemType": "cosmetic", "itemId": "acc_beanie", "expectedPrice": 60}),
        req("Beli gaya kartu", "POST", "/v1/shop/purchase", body={"itemType": "cosmetic", "itemId": "cardstyle_taman", "expectedPrice": 100}),
        req("Beli bundel aksesori", "POST", "/v1/shop/purchase", body={"itemType": "cosmetic_bundle", "itemId": "cozy", "expectedPrice": 0},
            desc="Harga = 80% item yang belum dimiliki (dibulatkan ke 5). Kirim sekali dengan 0 → `409 price_changed` berisi `details.price`, lalu kirim ulang."),
        req("Beli pelindung streak", "POST", "/v1/shop/purchase", body={"itemType": "streak_shield", "itemId": "streak_shield", "expectedPrice": 20}),
        req("Beli paket Fokus", "POST", "/v1/shop/purchase", body={"itemType": "focus_pack", "itemId": "focus_5", "expectedPrice": 100}),
        req("Pasang kosmetik monster", "PUT", "/v1/loadouts/monsters/kabut", body={"items": ["topi_rajut"]}),
        req("Pasang aksesori karakter", "PUT", "/v1/loadouts/characters/jung", body={"accessories": ["beanie"], "cardStyle": "taman"}),
    ]),
    folder("8. Fokus (tiket offline)", "Tiket Ed25519 untuk sesi tanpa internet (`focusTicketKeys` di Config).", [
        req("Tiket gratis harian", "POST", "/v1/focus/tickets", body={"source": "free_daily", "durationMin": 25}, tests=save_ticket,
            desc="1/hari (Premium 3), berlaku sampai tengah malam. Menyimpan `ticketId`."),
        req("Tiket prabayar", "POST", "/v1/focus/tickets", body={"source": "prepaid", "durationMin": 45}, tests=save_ticket,
            desc="Memakai satu sesi dari paket `focus_1`/`focus_5` (beli di Toko)."),
        req("Tiket koin", "POST", "/v1/focus/tickets", body={"source": "coins", "durationMin": 25, "expectedPrice": 25}, tests=save_ticket,
            desc="25/40/50 koin untuk 25/45/60 menit."),
        req("Tiket aktif", "GET", "/v1/focus/tickets"),
        req("Sesi Fokus selesai", "POST", "/v1/activities", body=ev("focus_completed", ticketId="{{ticketId}}", saboteurId="nanti"),
            desc="Memakai `ticketId` dari request tiket terakhir. Langsung dikirim → `409 ticket_invalid` `too_early`: server menerima setelah durasi sesi berlalu (dikirim app lewat outbox)."),
    ]),
    folder("9. Aplikasi Beku", "Hanya koin latihan; maks 3/hari; +10 tiap buka; jeda 60 detik. `expectedPrice` = harga dasar + 10 × `today.paidUnlocksUsed`. Dijalankan berurutan, request ke-2 dan ke-3 dijawab `409 cooldown` — tunggu 60 detik dan naikkan `expectedPrice` (+10 untuk buka ke-2, +20 untuk ke-3).", [
        req("Buka 10 menit", "POST", "/v1/appbeku/unlocks", body={"appId": "com.instagram.android", "minutes": 10, "expectedPrice": 15}),
        req("Bundel santai", "POST", "/v1/appbeku/unlocks", body={"bundleId": "santai", "expectedPrice": 35}),
        req("Bundel sosmed", "POST", "/v1/appbeku/unlocks",
            body={"bundleId": "sosmed", "appIds": ["com.instagram.android", "com.google.android.youtube"], "expectedPrice": 75}),
    ]),
    folder("10. Admin API (port 8081)", "Tidak lewat nginx. Produksi: dari laptop yang tersambung VPN (`{{adminBaseUrl}}` = http://172.19.0.16:8081), token akun admin (login ≤ 15 menit). Lokal: `docker compose -f deploy/docker-compose.yml exec api /riung admin grant dev:postman-admin \"postman lokal\"` setelah sekali memanggil `GET /v1/me` dengan `dev:postman-admin:google.com`.", [
        req("Daftar pengaturan", "GET", "/admin/v1/settings", base="{{adminBaseUrl}}", auth="{{adminToken}}"),
        req("Ubah pengaturan", "PUT", "/admin/v1/settings/journalRewardsPerDay", base="{{adminBaseUrl}}", auth="{{adminToken}}",
            body={"value": 4, "reason": "uji batas baru dari Postman"},
            desc="Key: journalRewardsPerDay (0–20), meditationRewardsPerDay (0–20), maxNewAccountsPerIpPerDay (1–1000)."),
        req("Kembalikan ke default", "DELETE", "/admin/v1/settings/journalRewardsPerDay", base="{{adminBaseUrl}}", auth="{{adminToken}}",
            body={"reason": "kembali ke default"}),
        req("Audit log", "GET", "/admin/v1/audit", base="{{adminBaseUrl}}", auth="{{adminToken}}", query=[("limit", "50", "1–200")]),
    ]),
    folder("11. Hapus akun", "Jalankan terakhir: menghapus akun yang dipakai koleksi ini.", [
        req("Hapus akun", "DELETE", "/v1/me",
            desc="⚠️ Menghapus semua data + user Firebase. Akun permanen: login ≤ 5 menit (`recent_login_required`). App Check limited-use. 204. Langganan Play **tidak** ikut berhenti: bila `premium.autoRenewing` (dari **Me**/**Status Premium**) = true, app menampilkan peringatan + tautan kelola langganan Play sebelum tombol hapus."),
    ]),
]

desc = """Koleksi semua endpoint backend Riung (`/v1`). Panduan: `docs/panduan-integrasi-app.md`; kontrak lengkap: `docs/backend-api-spec.md`.

**Pakai**
1. Import koleksi ini + salah satu environment (`riung-local` atau `riung-prod`).
2. Lokal: `cd backend && make dev-up` lalu seed konten. Token sudah terisi (`dev:postman:google.com`, App Check `dev`).
3. Produksi: isi `idToken` dengan ID token Firebase (berlaku 1 jam) dan `appCheckToken` bila ada (App Check masih `monitor`).
4. Jalankan **2. Akun → Me** dulu: menyimpan `userId` dan `billingAccountId`.

Script koleksi menambah `X-App-Version`, `X-Platform`, `X-Firebase-AppCheck`, dan `Idempotency-Key` (baru tiap kirim) otomatis, serta mengisi `{{now}}` dan `{{today}}` (Asia/Jakarta). Error ditampilkan di Postman Console beserta `requestId`.
"""

collection = {
    "info": {"_postman_id": uid("collection"), "name": "Riung API v1", "description": desc,
             "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"},
    "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{idToken}}", "type": "string"}]},
    "event": [{"listen": "prerequest", "script": js(collection_pre)}, {"listen": "test", "script": js(collection_test)}],
    "item": items,
}

def env(name, values):
    return {"id": uid("env" + name), "name": name, "_postman_variable_scope": "environment",
            "values": [{"key": k, "value": v, "type": t, "enabled": True} for k, v, t in values]}

local = env("riung-local", [
    ("baseUrl", "http://localhost:8080", "default"),
    ("adminBaseUrl", "http://localhost:8081", "default"),
    ("idToken", "dev:postman:google.com", "default"),
    ("appCheckToken", "dev", "default"),
    ("adminToken", "dev:postman-admin:google.com:admin", "default"),
    ("pubsubToken", "dev-pubsub", "default"),
    ("appVersion", "1.0.0", "default"),
    ("userId", "", "default"), ("billingAccountId", "", "default"), ("ticketId", "", "default"), ("configEtag", "", "default"),
    ("devBilling", "true", "default"), ("coinToken", "", "default"), ("subToken", "", "default"),
])
prod = env("riung-prod", [
    ("baseUrl", "https://riung.e55techlab.com", "default"),
    ("adminBaseUrl", "http://172.19.0.16:8081", "default"),
    ("idToken", "", "secret"),
    ("appCheckToken", "", "secret"),
    ("adminToken", "", "secret"),
    ("pubsubToken", "", "secret"),
    ("appVersion", "1.0.0", "default"),
    ("userId", "", "default"), ("billingAccountId", "", "default"), ("ticketId", "", "default"), ("configEtag", "", "default"),
    ("coinToken", "", "secret"), ("subToken", "", "secret"),
])

for fname, obj in [("riung-api.postman_collection.json", collection), ("riung-local.postman_environment.json", local),
                   ("riung-prod.postman_environment.json", prod)]:
    with open(f"{OUT}/{fname}", "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)
        f.write("\n")
count = sum(len(fol["item"]) for fol in items)
print("requests:", count)
