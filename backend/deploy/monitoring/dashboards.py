# Generates the Riung Grafana dashboards (runbook step 8c):
#   python3 deploy/monitoring/dashboards.py deploy/monitoring     (from backend/)
# Writes grafana-dashboard-riung-teknis.json (Loki) and
# grafana-dashboard-riung-bisnis.json (Postgres view schema `metrics`, read-only
# role riung_metrics). Edit here, not the JSON.
import json, sys

OUT = sys.argv[1]
LOKI = {"type": "loki", "uid": "loki"}
PG = {"type": "grafana-postgresql-datasource", "uid": "riung-postgres"}
API = '{container="riung-api"}'
REQ = API + ' | json | event="http_request"'


class Board:
    def __init__(self):
        self.panels, self.y, self.id = [], 0, 1

    def row(self, title):
        self.panels.append({"id": self.id, "type": "row", "title": title, "collapsed": False,
                            "gridPos": {"h": 1, "w": 24, "x": 0, "y": self.y}, "panels": []})
        self.id += 1
        self.y += 1

    def add(self, panels, h=8):
        """panels: list of (width, panel dict) laid out left to right."""
        x = 0
        for w, p in panels:
            p["id"] = self.id
            p["gridPos"] = {"h": h, "w": w, "x": x, "y": self.y}
            self.panels.append(p)
            self.id += 1
            x += w
        self.y += h


def loki_target(expr, ref="A", legend=None, instant=False):
    t = {"refId": ref, "datasource": LOKI, "expr": expr, "queryType": "instant" if instant else "range"}
    if legend:
        t["legendFormat"] = legend
    return t


def sql_target(sql, ref="A", fmt="time_series"):
    return {"refId": ref, "datasource": PG, "rawQuery": True, "editorMode": "code", "format": fmt, "rawSql": sql}


def ts(title, targets, unit=None, desc="", stack=False, ds=LOKI, bars=False):
    p = {"type": "timeseries", "title": title, "description": desc, "datasource": ds, "targets": targets,
         "fieldConfig": {"defaults": {"custom": {"drawStyle": "bars" if bars else "line", "fillOpacity": 60 if bars else 10,
                                                 "stacking": {"mode": "normal" if stack else "none"}}}, "overrides": []},
         "options": {"legend": {"displayMode": "list", "placement": "bottom"}, "tooltip": {"mode": "multi"}}}
    if unit:
        p["fieldConfig"]["defaults"]["unit"] = unit
    return p


def stat(title, targets, unit=None, desc="", ds=LOKI, thresholds=None):
    p = {"type": "stat", "title": title, "description": desc, "datasource": ds, "targets": targets,
         "options": {"reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}, "colorMode": "value",
                     "graphMode": "none", "textMode": "auto"},
         "fieldConfig": {"defaults": {}, "overrides": []}}
    if unit:
        p["fieldConfig"]["defaults"]["unit"] = unit
    if thresholds:
        p["fieldConfig"]["defaults"]["thresholds"] = {"mode": "absolute", "steps": thresholds}
    return p


def table(title, targets, desc="", ds=LOKI):
    return {"type": "table", "title": title, "description": desc, "datasource": ds, "targets": targets,
            "options": {"showHeader": True}, "fieldConfig": {"defaults": {}, "overrides": []}}


def logs(title, expr, desc=""):
    return {"type": "logs", "title": title, "description": desc, "datasource": LOKI, "targets": [loki_target(expr)],
            "options": {"showTime": True, "wrapLogMessage": True, "sortOrder": "Descending", "enableLogDetails": True}}


def dashboard(uid, title, board, desc, time_from):
    return {"uid": uid, "title": title, "description": desc, "tags": ["riung"], "timezone": "browser",
            "schemaVersion": 39, "version": 1, "editable": False, "refresh": "1m",
            "time": {"from": time_from, "to": "now"}, "panels": board.panels, "templating": {"list": []},
            "annotations": {"list": []}}


GREEN, AMBER, RED = "green", "orange", "red"

# --- Teknis (Loki) ----------------------------------------------------------------------
t = Board()
t.row("Ringkas (rentang waktu dashboard)")
t.add([
    (6, stat("Request", [loki_target(f'sum(count_over_time({REQ} | route!="/healthz" [$__range]))', instant=True)],
             desc="Semua request API kecuali /healthz.")),
    (6, stat("Error 5xx", [loki_target(f'sum(count_over_time({REQ} | status >= 500 [$__range]))', instant=True)],
             thresholds=[{"color": GREEN, "value": None}, {"color": RED, "value": 1}])),
    (6, stat("p95 latensi", [loki_target(
        f'max(quantile_over_time(0.95, {REQ} | route!="/healthz" | route!="/readyz" | unwrap durationMs [$__range]) by (container))',
        instant=True)], unit="ms", thresholds=[{"color": GREEN, "value": None}, {"color": AMBER, "value": 200}, {"color": RED, "value": 500}])),
    (6, stat("Log ERROR", [loki_target(f'sum(count_over_time({API} | json | level="ERROR" [$__range]))', instant=True)],
             thresholds=[{"color": GREEN, "value": None}, {"color": RED, "value": 1}])),
], h=4)
t.row("Lalu lintas & latensi")
t.add([
    (12, ts("Request per menit menurut status", [
        loki_target(f'sum(count_over_time({REQ} | route!="/healthz" | status < 400 [1m]))', "A", "2xx/3xx"),
        loki_target(f'sum(count_over_time({REQ} | status >= 400 | status < 500 [1m]))', "B", "4xx"),
        loki_target(f'sum(count_over_time({REQ} | status >= 500 [1m]))', "C", "5xx")], stack=True, bars=True)),
    (12, ts("Latensi (ms)", [
        loki_target(f'max(quantile_over_time(0.5, {REQ} | route!="/healthz" | route!="/readyz" | unwrap durationMs [5m]) by (container))', "A", "p50"),
        loki_target(f'max(quantile_over_time(0.95, {REQ} | route!="/healthz" | route!="/readyz" | unwrap durationMs [5m]) by (container))', "B", "p95"),
        loki_target(f'max(quantile_over_time(0.99, {REQ} | route!="/healthz" | route!="/readyz" | unwrap durationMs [5m]) by (container))', "C", "p99")],
        unit="ms", desc="Batas alarm watchdog: p95 > 500 ms (10 menit, min. 50 request).")),
])
t.add([
    (12, table("Route terbanyak", [loki_target(f'topk(15, sum by (route) (count_over_time({REQ} [$__range])))', instant=True)])),
    (12, ts("Event peringatan (WARN) per jenis", [loki_target(f'sum by (event) (count_over_time({API} | json | level="WARN" [5m]))', legend="{{event}}")],
            desc="rate_limited, auth_failed, appcheck_failed, purchase_rejected, pin_locked, …", stack=True, bars=True)),
])
t.row("Keamanan & App Check")
t.add([
    (12, ts("Hasil App Check", [loki_target(f'sum by (appCheck) (count_over_time({REQ} | appCheck!="" [15m]))', legend="{{appCheck}}")],
            desc="Pindah ke enforce bila 'valid' ≥ 99% selama 7 hari (docs/backend-b6-review.md §4).", stack=True)),
    (12, ts("Login gagal, rate limit, batas akun baru", [
        loki_target(f'sum by (event) (count_over_time({API} | json | event=~"auth_failed|rate_limited|signup_limited|pin_locked" [15m]))', legend="{{event}}")],
        stack=True, bars=True)),
])
t.row("Billing")
t.add([
    (12, ts("Pembelian & notifikasi toko", [
        loki_target(f'sum by (event) (count_over_time({API} | json | event=~"purchase_verified|purchase_rejected|refund_applied|rtdn_received|rtdn_rejected" [1h]))',
                    legend="{{event}}")], stack=True, bars=True)),
    (12, logs("Refund & penolakan pembelian", f'{API} | json | event=~"refund_applied|purchase_rejected|rtdn_rejected"')),
])
t.row("Job & watchdog")
t.add([
    (12, logs("Job cron (job_run)", f'{API} | json | event="job_run"', desc="cleanup, cleanup_anon, billing_sync, reconcile.")),
    (12, logs("Watchdog (alarm & pulih)", '{container="riung-watchdog"} | json | event="watchdog_alert"')),
])
t.row("Error")
t.add([(24, logs("Log ERROR", f'{API} | json | level="ERROR"'))], h=10)

# --- Bisnis (Postgres, schema metrics) --------------------------------------------------
DAY = "day >= $__timeFrom()::date AND day <= $__timeTo()::date"
b = Board()
b.row("Pengguna")
b.add([
    (5, stat("Akun", [sql_target("SELECT accounts FROM metrics.users_summary", fmt="table")], ds=PG)),
    (5, stat("Akun permanen", [sql_target("SELECT permanent FROM metrics.users_summary", fmt="table")], ds=PG)),
    (5, stat("Aktif 1 hari", [sql_target("SELECT active_1d FROM metrics.users_summary", fmt="table")], ds=PG,
             desc="Membuka app (GET /v1/me) dalam 24 jam terakhir.")),
    (5, stat("Aktif 7 hari", [sql_target("SELECT active_7d FROM metrics.users_summary", fmt="table")], ds=PG)),
    (4, stat("Aktif 30 hari", [sql_target("SELECT active_30d FROM metrics.users_summary", fmt="table")], ds=PG)),
], h=4)
b.add([
    (12, ts("Akun baru per hari", [sql_target(f"SELECT day::timestamp AS time, accounts AS \"akun baru\", permanent_now AS \"sekarang permanen\" FROM metrics.daily_signups WHERE {DAY} ORDER BY 1")],
            ds=PG, bars=True)),
    (12, ts("Pengguna berlatih per hari", [sql_target(f"SELECT day::timestamp AS time, users AS \"berlatih\" FROM metrics.daily_active_users WHERE {DAY} ORDER BY 1")],
            ds=PG, desc="User dengan minimal satu latihan tercatat (check-in, jurnal, meditasi, misi, …).", bars=True)),
])
b.row("Latihan")
b.add([
    (12, ts("Latihan per jenis per hari", [sql_target(f"SELECT day::timestamp AS time, type AS metric, events AS value FROM metrics.daily_activity WHERE {DAY} ORDER BY 1")],
            ds=PG, stack=True, bars=True)),
    (12, table("Monster per saboteur", [sql_target("SELECT saboteur_id AS saboteur, state, users FROM metrics.monster_states ORDER BY 1, 2", fmt="table")], ds=PG)),
])
b.row("Koin")
b.add([
    (12, ts("Koin masuk & keluar per hari", [sql_target(
        f"SELECT day::timestamp AS time, sum(earned) FILTER (WHERE type = 'earn') AS \"dari latihan\", "
        f"sum(purchased) FILTER (WHERE type = 'purchase') AS \"dibeli\", -sum(coins) FILTER (WHERE type = 'spend') AS \"dibelanjakan\", "
        f"-sum(coins) FILTER (WHERE type = 'refund') AS \"ditarik refund\" FROM metrics.daily_coins WHERE {DAY} GROUP BY 1 ORDER BY 1")], ds=PG, bars=True)),
    (12, table("Belanja koin per alasan", [sql_target(
        f"SELECT reason AS alasan, sum(entries) AS transaksi, -sum(coins) AS koin FROM metrics.daily_coins WHERE type = 'spend' AND {DAY} GROUP BY 1 ORDER BY 3 DESC",
        fmt="table")], ds=PG)),
])
b.row("Pembelian & Premium")
b.add([
    (12, ts("Pembelian per hari (tanpa uji)", [sql_target(
        f"SELECT day::timestamp AS time, store || ' ' || product_id AS metric, sum(purchases) AS value FROM metrics.daily_purchases "
        f"WHERE NOT test AND {DAY} GROUP BY 1, 2 ORDER BY 1")], ds=PG, stack=True, bars=True,
        desc="Pembelian uji (license tester Play, sandbox/TestFlight App Store) dipisah di tabel kanan.")),
    (12, table("Pembelian per toko & produk", [sql_target(
        f"SELECT store AS toko, product_id AS produk, test AS uji, sum(purchases) AS pembelian, sum(refunded) AS refund FROM metrics.daily_purchases "
        f"WHERE {DAY} GROUP BY 1, 2, 3 ORDER BY 1, 2, 3", fmt="table")], ds=PG)),
])
b.add([
    (12, table("Langganan Premium", [sql_target(
        "SELECT plan, status, subscriptions AS langganan, not_expired AS \"belum habis\", auto_renewing AS \"auto-renew\" FROM metrics.premium_status ORDER BY 1, 2",
        fmt="table")], ds=PG)),
    (12, ts("Mode Fokus: tiket per hari", [sql_target(
        f"SELECT day::timestamp AS time, source AS metric, sum(tickets) AS value FROM metrics.daily_focus WHERE {DAY} GROUP BY 1, 2 ORDER BY 1")],
        ds=PG, stack=True, bars=True)),
])
b.add([
    (12, ts("Aplikasi Beku: buka-berbayar per hari", [sql_target(
        f"SELECT day::timestamp AS time, unlocks AS \"buka\", coins AS \"koin\" FROM metrics.daily_appbeku WHERE {DAY} ORDER BY 1")], ds=PG, bars=True)),
    (12, ts("Waitlist per hari", [sql_target(
        f"SELECT day::timestamp AS time, sum(signups) AS \"daftar\" FROM metrics.daily_waitlist WHERE {DAY} GROUP BY 1 ORDER BY 1")], ds=PG, bars=True)),
])

for name, obj in [
    ("grafana-dashboard-riung-teknis.json", dashboard("riung-teknis", "Riung — Teknis", t,
                                                       "API riung dari log Loki: lalu lintas, latensi, error, App Check, billing, job, watchdog.", "now-6h")),
    ("grafana-dashboard-riung-bisnis.json", dashboard("riung-bisnis", "Riung — Bisnis", b,
                                                       "Angka agregat dari view metrics (role baca-saja riung_metrics): tanpa user id atau data pribadi.", "now-30d")),
]:
    with open(f"{OUT}/{name}", "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(name, len(obj["panels"]), "panels")
