#!/usr/bin/env node
'use strict';
// ============================================================================
// Regression test: JVHD APK authentication FLOW (not just the hash formula).
//
// Run by the "Build JVHD APK" workflow on every push/PR, right after
// scripts/test_auth_hash.js. Fully offline: no network, no dependencies.
//
// It loads the REAL assets/app.js as an IIFE inside a stubbed WebView, exposes
// the auth internals and drives the real submitJvhdUserGate() against a
// scripted XMLHttpRequest. It guards, in code:
//   1. success parsing for the old protocol ("bind"/"challenge"/"ok") AND for
//      alternative/current API shapes ({"success":true}, {"valid":true},
//      {"status":"success"}, token/user) - a changed response format must never
//      be reported as "Ten nguoi dung khong dung";
//   2. honest, differentiated error messages (401 / 5xx / 400 / offline /
//      invalid JSON / wrong Salt.txt / server allowlist unloaded) and that
//      non-credential faults are NOT counted towards the 3-attempt lock;
//   3. Salt.txt validation + canonical fallback, lowercase hex hashes;
//   4. no regression of the deployed protocol: /auth/start -> /auth/bind ->
//      status ok, and /auth/start -> challenge -> /auth/verify -> status ok,
//      with POST + Content-Type: application/json and
//      h = SHA-256(lowercase(username) + SALT).
//
// Nothing here touches production data: the server side is a scripted stub.
// If assets/app.js changes shape in a way this test cannot parse, the test
// FAILS loudly instead of silently passing.
// ============================================================================
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');

const APP = path.join(path.resolve(__dirname, '..'), 'assets', 'app.js');
let src = fs.readFileSync(APP, 'utf8');
const EXPORTS = [
  'jvhdNormalizeSalt', 'jvhdShort', 'jvhdSha256Hex', 'jvhdComputeSaltedHash',
  'jvhdUserNativeHash', 'jvhdAuthStatusOf', 'jvhdUserAuthRequest', 'jvhdUserAuthDiagnose',
  'submitJvhdUserGate', 'fetchJvhdSalt', 'jvhdUserAuthFail', 'jvhdUserAuthNetworkError',
];
const marker = /\}\)\(\);\s*$/;
if (!marker.test(src)) throw new Error('IIFE tail not found');
src = src.replace(marker, `
window.__T = {
  fn: { ${EXPORTS.join(', ')} },
  setSalt: function (v, fromFile) { jvhdSalt = v; jvhdSaltFromFile = !!fromFile; },
  getSalt: function () { return jvhdSalt; },
  getSaltFromFile: function () { return jvhdSaltFromFile; },
  setGateOpen: function (v) { jvhdUserGateOpen = v; },
  isGateOpen: function () { return jvhdUserGateOpen; },
  setChecking: function (v) { jvhdUserChecking = v; },
  isChecking: function () { return jvhdUserChecking; }
};
})();`);

// ---- stubbed WebView -------------------------------------------------------
const SALT = '4f4e804da5c307dd7d88d2b58e1a44c6b312c1430ff4d29d';
const LOGS = [];
const storage = {};
const statusEl = { textContent: '', classList: { add() {}, remove() {}, toggle() {} }, focus() {}, value: '' };
const inputEl = { value: '', focus() {}, addEventListener() {}, classList: { add() {}, remove() {} } };
const scripted = [];
const sentRequests = [];

function pickResponse(method, url) {
  for (let i = 0; i < scripted.length; i++) {
    const s = scripted[i];
    if (s.url && url.indexOf(s.url) === -1) continue;
    if (s.path && url.indexOf(s.path) === -1) continue;
    if (s.method && s.method !== method) continue;
    scripted.splice(i, 1);
    return s;
  }
  return { status: 200, body: '{"status":"unknown"}' };
}
class XHR {
  constructor() { this.readyState = 0; this.status = 0; this.responseText = ''; this.headers = {}; this._hdl = {}; }
  open(m, u) { this.method = m; this.url = u; this.readyState = 1; }
  setRequestHeader(k, v) { this.headers[k] = v; }
  getResponseHeader(k) { return k.toLowerCase() === 'content-type' ? 'application/json' : null; }
  abort() { this._aborted = true; }
  send(body) {
    sentRequests.push({ method: this.method, url: this.url, body: body, headers: Object.assign({}, this.headers) });
    const res = pickResponse(this.method, this.url);
    setTimeout(() => {
      if (this._aborted) return;
      if (res.networkError) { this.readyState = 4; this.status = 0; if (this._hdl.onerror) this._hdl.onerror(); return; }
      this.readyState = 4; this.status = res.status; this.responseText = res.body || '';
      if (this._hdl.onreadystatechange) this._hdl.onreadystatechange();
    }, 0);
  }
}
['onreadystatechange', 'onerror', 'ontimeout'].forEach((prop) => {
  Object.defineProperty(XHR.prototype, prop, { get() { return this._hdl[prop]; }, set(v) { this._hdl[prop] = v; } });
});

const doc = {
  getElementById: (id) => (id === 'bintv-jvhd-user-status' ? statusEl : (id === 'bintv-jvhd-user-input' ? inputEl : null)),
  createElement: () => ({ style: {}, classList: { add() {}, remove() {}, toggle() {} }, appendChild() {}, addEventListener() {}, setAttribute() {}, querySelector: () => null, innerHTML: '' }),
  addEventListener() {}, querySelector: () => null, querySelectorAll: () => [],
  body: { classList: { add() {}, remove() {}, toggle() {} }, appendChild() {}, contains: () => false }, head: { appendChild() {} },
  documentElement: { style: {} }, title: '', hidden: false, visibilityState: 'visible'
};
const win = {
  document: doc,
  localStorage: {
    getItem: (k) => (k in storage ? storage[k] : null),
    setItem: (k, v) => { storage[k] = String(v); },
    removeItem: (k) => { delete storage[k]; },
  },
  addEventListener() {}, removeEventListener() {}, XMLHttpRequest: XHR,
  setTimeout, clearTimeout, setInterval: () => 0, clearInterval() {},
  console: { log: (...a) => LOGS.push(a.join(' ')), warn() {}, error: (...a) => LOGS.push('ERR ' + a.join(' ')) },
  navigator: { userAgent: 'test' }, location: { href: 'http://localhost/', origin: 'http://localhost' }, AndroidBridge: null
};
win.window = win;
const sandbox = {
  window: win, document: doc, localStorage: win.localStorage, XMLHttpRequest: XHR,
  navigator: win.navigator, location: win.location, console: win.console,
  setTimeout, clearTimeout, setInterval: () => 0, clearInterval: () => {},
  JSON, String, Number, Math, Date, RegExp, Object, Array, Error, Boolean,
  isFinite, parseFloat, parseInt, encodeURIComponent, decodeURIComponent,
  btoa: (s) => Buffer.from(s, 'binary').toString('base64'),
  atob: (s) => Buffer.from(s, 'base64').toString('binary')
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(src, sandbox, { filename: 'app.js' });
const T = win.__T;
if (!T) throw new Error('internals were not exposed');

let failures = 0, checks = 0;
function eq(a, b, name) { checks++; if (a !== b) { failures++; console.log('  FAIL ' + name + '\n       got: ' + JSON.stringify(a) + '\n       exp: ' + JSON.stringify(b)); } else console.log('  ok   ' + name); }
function ok(c, name) { eq(!!c, true, name); }
function reset() { statusEl.textContent = ''; inputEl.value = ''; scripted.length = 0; sentRequests.length = 0; LOGS.length = 0; for (const k of Object.keys(storage)) delete storage[k]; win.AndroidBridge = null; }
const H = (s) => crypto.createHash('sha256').update(s, 'utf8').digest('hex');
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
// Wait until the gate is no longer mid-request (retries take ~1.2s by design).
async function idle(ms = 4000) {
  const started = Date.now();
  while (T.isChecking() && Date.now() - started < ms) await wait(50);
  await wait(25);
}

console.log('\n[1] Response-shape tolerance (old protocol + new API)');
const S = T.fn.jvhdAuthStatusOf;
eq(S({ status: 'bind', nonce: 'n' }), 'bind', 'legacy {"status":"bind"}');
eq(S({ status: 'challenge', challenge: 'c' }), 'challenge', 'legacy {"status":"challenge"}');
eq(S({ status: 'ok' }), 'ok', 'legacy {"status":"ok"}');
eq(S({ status: 'unknown' }), 'unknown', 'legacy {"status":"unknown"}');
eq(S({ status: 'denied' }), 'denied', 'legacy {"status":"denied"}');
eq(S({ status: 'unavailable' }), 'unavailable', 'legacy {"status":"unavailable"}');
eq(S({ success: true }), 'ok', 'NEW {"success":true}');
eq(S({ valid: true }), 'ok', 'NEW {"valid":true}');
eq(S({ status: 'success' }), 'ok', 'NEW {"status":"success"}');
eq(S({ token: 'jwt' }), 'ok', 'NEW {"token":...}');
eq(S({ user: { id: 1 } }), 'ok', 'NEW {"user":...}');
eq(S(null), 'unknown', 'null body');
eq(S('<html>'), 'unknown', 'non-object body');

console.log('\n[2] Salt normalisation (rejects garbage instead of hashing it)');
const N = T.fn.jvhdNormalizeSalt;
eq(N(SALT + '\n'), SALT, 'plain + newline');
eq(N('\uFEFF' + SALT + '\r\n'), SALT, 'BOM + CRLF');
eq(N('"' + SALT + '"'), SALT, 'quoted');
eq(N(SALT.toUpperCase()), SALT, 'uppercase -> lowercase');
eq(N('{"salt":"' + SALT + '"}'), SALT, 'JSON object');
eq(N('SALT=' + SALT), SALT, 'SALT= prefix');
eq(N('not-a-salt'), null, 'garbage -> null');
eq(N('<html></html>'), null, 'HTML -> null');
eq(N('4f4e804d'), null, 'too short -> null');

console.log('\n[3] Hashing: native c0 first, JS salted fallback, lowercase out');
T.setSalt(null, false);
win.AndroidBridge = null;
eq(T.fn.jvhdUserNativeHash('admin2'), null, 'no salt + no c0 -> null (fail-closed)');
T.setSalt(SALT, true);
eq(T.fn.jvhdUserNativeHash('admin2'), H('admin2' + SALT), 'JS salted hash = canonical');
eq(T.fn.jvhdUserNativeHash('admin2'), '37b5d924f34f64ed7e88033b8c31db39b314ddca0ec624ea94d5b8056467ca5b', 'matches production Admin2 binding hash');
win.AndroidBridge = { c0: (n) => H(n + SALT).toUpperCase() };
eq(T.fn.jvhdUserNativeHash('admin2'), H('admin2' + SALT), 'native c0 preferred, lowercased');

async function scenarioLegacyBind() {
  console.log('\n[4] Old protocol still works end-to-end (no regression)');
  reset();
  const digest = H('admin2' + SALT);
  T.setSalt(SALT, true);
  win.AndroidBridge = { c0: () => digest, d0: () => 'B' + 'A'.repeat(86) + '=', e0: () => 'SIG' };
  inputEl.value = '  ADMIN2  ';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'bind', nonce: 'NONCE' }) });
  scripted.push({ path: '/auth/bind', status: 200, body: JSON.stringify({ status: 'ok' }) });
  T.setGateOpen(true);
  T.fn.submitJvhdUserGate();
  await idle();
  eq(sentRequests.length, 2, 'bind flow sends /auth/start then /auth/bind');
  eq(sentRequests[0].method, 'POST', '/auth/start uses POST');
  eq(sentRequests[0].headers['Content-Type'], 'application/json', 'Content-Type: application/json');
  eq(JSON.parse(sentRequests[0].body).h, H('admin2' + SALT), 'payload {"h": SHA-256(trim+lowercase(user)+SALT)}');
  eq(JSON.parse(sentRequests[0].body).h, digest, 'hash matches the native c0 value');
  eq(storage.jvhdUserHash, digest, 'success stores the digest for next launch');
}

async function scenarioLegacyVerify() {
  reset();
  const digest = H('admin2' + SALT);
  T.setSalt(SALT, true);
  win.AndroidBridge = { c0: () => digest, d0: () => 'Bpub', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'challenge', challenge: 'CHAL' }) });
  scripted.push({ path: '/auth/verify', status: 200, body: JSON.stringify({ status: 'ok' }) });
  T.setGateOpen(true);
  T.fn.submitJvhdUserGate();
  await idle();
  eq(sentRequests.length, 2, 'verify flow sends /auth/start then /auth/verify');
  eq(storage.jvhdUserHash, digest, 'verify success also stores the digest');
}

async function scenarioMessages() {
  console.log('\n[5] The reported bug: message must match the real cause');

  reset(); T.setSalt(SALT, true);
  win.AndroidBridge = { c0: () => H('admin2' + SALT), d0: () => 'B', e0: () => 'S' };
  inputEl.value = 'admin2';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ success: true, token: 't' }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  eq(storage.jvhdUserHash, H('admin2' + SALT), '{"success":true} now logs in (was impossible before)');
  eq(sentRequests.length, 1, 'no bogus /auth/bind call for a token response');

  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('admin2' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  for (let i = 0; i < 4; i++) scripted.push({ path: '/auth/start', status: 500, body: '{"error":"boom"}' });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(/Máy chủ xác thực đang gặp sự cố\. Vui lòng thử lại sau\. \(HTTP 500\)/.test(statusEl.textContent), 'HTTP 500 -> "server problem" message');
  eq(storage.jvhdUserFails === undefined, true, 'server fault is NOT counted as a wrong password');

  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('admin2' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  for (let i = 0; i < 4; i++) scripted.push({ path: '/auth/start', networkError: true });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  eq(statusEl.textContent, 'Không thể kết nối đến máy chủ xác thực. Vui lòng kiểm tra lại mạng.', 'network down -> connection message');
  eq(storage.jvhdUserFails === undefined, true, 'network error is NOT counted as a wrong password');

  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('admin2' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  for (let i = 0; i < 4; i++) scripted.push({ path: '/auth/start', status: 200, body: '<html>oops</html>' });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(/Không thể kết nối đến máy chủ xác thực/.test(statusEl.textContent), 'HTML instead of JSON -> connection message (not a user accusation)');

  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('admin2' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  for (let i = 0; i < 4; i++) scripted.push({ path: '/auth/start', status: 400, body: '{"status":"bad"}' });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(/400/.test(statusEl.textContent) && /giao thức/.test(statusEl.textContent), 'HTTP 400 -> protocol mismatch message');

  reset(); T.setSalt('deadbeef'.repeat(6), true);
  win.AndroidBridge = { c0: () => H('admin2' + 'deadbeef'.repeat(6)), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'unknown' }) });
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'bind', nonce: 'N' }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  const probe = sentRequests[1] && JSON.parse(sentRequests[1].body).h;
  eq(probe, H('admin2' + SALT), 'diagnosis probed the canonical-salt digest');
  ok(/Salt\.txt/.test(statusEl.textContent), 'wrong Salt.txt is named as the cause');
  ok(!/Tên người dùng không đúng/.test(statusEl.textContent), 'never blames the username when Salt.txt is wrong');

  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('typo' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  storage.jvhdUserHash = H('admin2' + SALT);
  inputEl.value = 'typo';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'unknown' }) });
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'bind', nonce: 'N' }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(/Tên đăng nhập hoặc thông tin xác thực không hợp lệ/.test(statusEl.textContent), 'genuinely unknown user -> requested credential message');
  ok(/còn 2 lần/.test(statusEl.textContent), 'fail counter still works');

  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('nobody' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'nobody';
  for (let i = 0; i < 3; i++) scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'unknown' }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(statusEl.textContent.indexOf('Tên đăng nhập hoặc thông tin xác thực không hợp lệ') === 0, 'unverifiable user -> credential message (no invented server fault)');
}

async function scenarioHealth() {
  console.log('\n[5b] Server-side allowlist diagnosis via read-only GET /health');
  // (i) server itself reports the Hash4 store failed to load -> name the server,
  //     never the credentials (this is the suspected production root cause)
  reset(); T.setSalt(SALT, true);
  win.AndroidBridge = { c0: () => H('nobody' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'nobody';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'unknown' }) });
  scripted.push({ url: '/health', status: 200, body: JSON.stringify({ ok: true, onedrive: { hash4: { ok: false, count: 0 } } }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(/chưa nạp được danh sách người dùng/.test(statusEl.textContent), 'health hash4.ok=false -> server data fault reported');
  ok(!/thông tin xác thực không hợp lệ/.test(statusEl.textContent), 'not blamed on the user credentials');
  eq(storage.jvhdUserFails === undefined, true, 'server data fault is NOT counted as a wrong password');
  eq(sentRequests.filter(r => r.url.indexOf('/health') !== -1).length, 1, 'one read-only /health probe, GET method');
  eq(sentRequests.filter(r => r.url.indexOf('/health') !== -1)[0].method, 'GET', '/health probed with GET');

  // (j) health endpoint absent/405 (as the deployed host once answered) -> no invented fault
  reset(); T.setSalt(SALT, true);
  win.AndroidBridge = { c0: () => H('nobody' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'nobody';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'unknown' }) });
  scripted.push({ url: '/health', status: 405, body: '{"error":"method"}' });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(statusEl.textContent.indexOf('Tên đăng nhập hoặc thông tin xác thực không hợp lệ') === 0, '/health 405 -> no invented server fault');

  // (k) health says the allowlist loaded fine -> credentials really are wrong
  reset(); T.setSalt(SALT, true);
  win.AndroidBridge = { c0: () => H('nobody' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'nobody';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'unknown' }) });
  scripted.push({ url: '/health', status: 200, body: JSON.stringify({ ok: true, onedrive: { hash4: { ok: true, count: 26 } } }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(/thông tin xác thực không hợp lệ/.test(statusEl.textContent), 'healthy allowlist -> credential message is honest');
}

async function scenarioSalt() {
  console.log('\n[6] Salt loading (validation + fallback)');
  reset(); T.setSalt(null, false);
  scripted.push({ url: 'Salt.txt', status: 200, body: '\uFEFF"  ' + SALT.toUpperCase() + '  "\r\n' });
  await new Promise((r) => T.fn.fetchJvhdSalt(() => r()));
  eq(T.getSalt(), SALT, 'GitLab body with BOM/quotes/spaces/uppercase -> clean salt');
  eq(T.getSaltFromFile(), true, 'source flagged as Salt.txt');

  reset(); T.setSalt(null, false);
  for (let i = 0; i < 4; i++) scripted.push({ url: 'Salt.txt', networkError: true });
  await new Promise((r) => T.fn.fetchJvhdSalt(() => r()));
  eq(T.getSalt(), SALT, 'unreachable Salt.txt -> canonical fallback');
  eq(T.getSaltFromFile(), false, 'fallback is flagged (so a wrong salt can be named later)');
  ok(LOGS.some((l) => /fallback salt/.test(l)), 'fallback use is logged');

  reset(); T.setSalt(null, false);
  for (let i = 0; i < 4; i++) scripted.push({ url: 'Salt.txt', status: 200, body: 'not-a-salt-value' });
  await new Promise((r) => T.fn.fetchJvhdSalt(() => r()));
  eq(T.getSaltFromFile(), false, 'non-hex Salt.txt is no longer silently accepted');
  eq(T.getSalt(), SALT, 'falls back to the canonical salt instead');
}

async function scenarioLogs() {
  console.log('\n[7] Dev logging for Logcat/DevTools');
  reset(); T.setSalt(SALT, true); win.AndroidBridge = { c0: () => H('admin2' + SALT), d0: () => 'BPUB', e0: () => 'SIG' };
  inputEl.value = 'admin2';
  scripted.push({ path: '/auth/start', status: 200, body: JSON.stringify({ status: 'bind', nonce: 'N' }) });
  T.setGateOpen(true); T.fn.submitJvhdUserGate();
  await idle();
  ok(LOGS.some((l) => /\[JVHD-AUTH\] \/auth\/start -> POST/.test(l)), 'request payload logged');
  ok(LOGS.some((l) => /\[JVHD-AUTH\] \/auth\/start <- HTTP 200/.test(l)), 'raw response + status logged');
  ok(!LOGS.some((l) => l.indexOf(SALT) !== -1), 'salt value itself never logged');
}

(async () => {
  await scenarioLegacyBind();
  await scenarioLegacyVerify();
  await scenarioMessages();
  await scenarioHealth();
  await scenarioSalt();
  await scenarioLogs();
  console.log('\n' + (failures
    ? 'RESULT: FAIL (' + failures + '/' + checks + ' checks failed)'
    : 'RESULT: PASS — ' + checks + ' checks, all green (auth flow, old + new API shapes)'));
  process.exit(failures ? 1 : 0);
})();
