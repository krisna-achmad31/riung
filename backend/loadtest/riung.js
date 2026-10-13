// k6 load test for the riung API (B6 gate: p95 < 200 ms at the target load).
//
// Runs against a DEV_AUTH server (dev tokens "dev:<uid>:<provider>"), never
// production. Each virtual user is one app user doing what the app does:
// bootstrap, report practice, read wallet/journal access, buy, sync the
// offline outbox. See backend/loadtest/README.md.
//
//   k6 run -e BASE=http://127.0.0.1:18080 backend/loadtest/riung.js
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE || 'http://127.0.0.1:8080';
const PEAK = Number(__ENV.VUS || 200);

export const options = {
  scenarios: {
    app: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: PEAK },
        { duration: __ENV.HOLD || '3m', target: PEAK },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<200', 'p(99)<500'],
    http_req_failed: ['rate<0.001'],
    checks: ['rate>0.999'],
  },
  summaryTrendStats: ['avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

// 409 is a normal business answer (daily limit, not enough coins).
http.setResponseCallback(http.expectedStatuses({ min: 200, max: 299 }, 304, 409));

function uuid() {
  const h = '0123456789abcdef';
  let s = '';
  for (let i = 0; i < 32; i++) s += h[Math.floor(Math.random() * 16)];
  return `${s.slice(0, 8)}-${s.slice(8, 12)}-4${s.slice(13, 16)}-8${s.slice(17, 20)}-${s.slice(20, 32)}`;
}

function jakartaDate(d) {
  return new Date(d.getTime() + 7 * 3600 * 1000).toISOString().slice(0, 10);
}

function headers(token, mutating) {
  const h = { Authorization: `Bearer ${token}`, 'X-Firebase-AppCheck': 'dev', 'X-App-Version': '1.0.0', 'X-Platform': 'android' };
  if (mutating) {
    h['Content-Type'] = 'application/json';
    h['Idempotency-Key'] = uuid();
  }
  return { headers: h, tags: {} };
}

function get(token, path, name) {
  const p = headers(token, false);
  p.tags.name = name || path;
  return http.get(BASE + path, p);
}

function post(token, path, body, name) {
  const p = headers(token, true);
  p.tags.name = name || path;
  return http.post(BASE + path, JSON.stringify(body), p);
}

function event(type) {
  const now = new Date();
  const at = now.toISOString();
  switch (type) {
    case 'checkin':
      return { type, occurredAt: at, date: jakartaDate(now) };
    case 'mission':
      return { type: 'mission_completed', occurredAt: at, date: jakartaDate(now), index: Math.floor(Math.random() * 3) };
    case 'journal':
      return { type: 'journal_saved', occurredAt: at, entryId: uuid(), promptId: 'p_hakim' };
    default:
      return { type: 'minigame_finished', occurredAt: at, ref: uuid(), saboteurId: 'waswas', won: Math.random() < 0.5 };
  }
}

const ok = (r) => r.status >= 200 && r.status < 300 || r.status === 304 || r.status === 409;

export default function () {
  const token = `dev:lt-${__VU}:anonymous`;
  if (__ITER === 0) {
    // App start: config (cached afterwards with ETag) and bootstrap.
    check(get(token, '/v1/config'), { config: ok });
  }
  const roll = Math.random();
  let r;
  if (roll < 0.30) r = get(token, '/v1/me');
  else if (roll < 0.50) r = post(token, '/v1/activities', event(['checkin', 'mission', 'journal', 'minigame'][Math.floor(Math.random() * 4)]));
  else if (roll < 0.65) r = get(token, '/v1/wallet');
  else if (roll < 0.75) r = get(token, '/v1/journal/access');
  else if (roll < 0.83) r = post(token, '/v1/activities/batch', { events: [event('journal'), event('minigame'), event('mission'), event('journal'), event('minigame')] });
  else if (roll < 0.88) r = post(token, '/v1/shop/purchase', { itemType: 'streak_shield', itemId: 'streak_shield', expectedPrice: 20 });
  else if (roll < 0.93) r = post(token, '/v1/focus/tickets', { source: 'free_daily', durationMin: 25 });
  else if (roll < 0.97) r = get(token, '/v1/wallet/transactions?limit=20', '/v1/wallet/transactions');
  else r = get(token, '/v1/focus/tickets');
  check(r, { 'status ok': ok });
  sleep(1 + Math.random() * 2);
}
