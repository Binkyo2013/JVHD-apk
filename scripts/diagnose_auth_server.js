#!/usr/bin/env node
'use strict';
// ============================================================================
// Read-only diagnostic for the JVHD auth server (report item E.0).
//
// WHY: the APK login depends on three things that live OUTSIDE the APK -
//   1. the deployed server code (old jvhd-auth vs new jvhd-server),
//   2. the allowlist it actually loads (Hash4.txt: GitLab vs OneDrive copy),
//   3. Salt.txt matching whatever salt Salt.txt/Hash4 were generated with.
// This script asks the server directly, so a failure can be attributed to the
// server side instead of being guessed from the APK screen.
//
// SAFETY (read-only, no side effects on data):
//   * GET  /health       - status only
//   * POST /auth/start   - allowlist membership + in-memory nonce only
//   Both handlers on both server versions only READ the allowlist and store a
//   short-lived nonce in RAM (pending[h]); nothing is written to disk or to
//   GitHub. /auth/bind, /auth/verify and /admin/* are NEVER called, so no
//   binding can be created, overwritten or removed.
//   Member.txt / Salt.txt / Hash4.txt are only read (over HTTPS) and printed
//   in a redacted/truncated form; they are never modified.
//
// USAGE
//   node scripts/diagnose_auth_server.js                      # default server
//   node scripts/diagnose_auth_server.js https://jvhd-server.onrender.com
//   JVHD_AUTH_BASE=... JVHD_DIAG_LIMIT=5 node scripts/diagnose_auth_server.js
//   node scripts/diagnose_auth_server.js <base> Salt.txt Hash4.txt Member.txt
//
// It exits 0 even when the server is down or the allowlist is empty: this is a
// diagnostic, not a build gate (the build must not fail because Render sleeps).
// ============================================================================
const fs = require('fs');
const https = require('https');
const http = require('http');
const crypto = require('crypto');

const BASE = (process.env.JVHD_AUTH_BASE || process.argv[2] || 'https://jvhd-auth.onrender.com')
  .replace(/\/+$/, '');
const SALT_FILE = process.argv[3] || '';
const HASH4_FILE = process.argv[4] || '';
const MEMBER_FILE = process.argv[5] || '';
const LIMIT = Math.max(1, Math.min(50, parseInt(process.env.JVHD_DIAG_LIMIT || '4', 10) || 4));
const TIMEOUT = parseInt(process.env.JVHD_DIAG_TIMEOUT_MS || '45000', 10);

const GITLAB_RAW = 'https://gitlab.com/binmedia-group/jvhd-sever2/-/raw/main/';
const SOURCES = {
  salt: GITLAB_RAW + 'Salt.txt?ref_type=heads',
  hash4: GITLAB_RAW + 'Hash4.txt?ref_type=heads',
  member: GITLAB_RAW + 'Member.txt?ref_type=heads',
};

const sha256hex = (s) => crypto.createHash('sha256').update(s, 'utf8').digest('hex');
const HEX64 = /^[0-9a-f]{64}$/;
const rule = (t) => console.log('\n' + '='.repeat(74) + '\n' + t + '\n' + '='.repeat(74));
const cut = (s, n) => String(s == null ? '' : s).replace(/\s+/g, ' ').trim().slice(0, n || 300);

function fetchUrl(url) {
  return new Promise((resolve) => {
    let u;
    try { u = new URL(url); } catch (e) { return resolve({ ok: false, error: 'bad url' }); }
    const lib = u.protocol === 'https:' ? https : http;
    const req = lib.request({
      hostname: u.hostname,
      port: u.port || (u.protocol === 'https:' ? 443 : 80),
      path: u.pathname + u.search,
      method: 'GET',
      headers: { 'User-Agent': 'jvhd-diagnose/1.0' },
      timeout: TIMEOUT,
    }, (res) => {
      let text = '';
      res.setEncoding('utf8');
      res.on('data', (c) => { text += c; });
      res.on('end', () => resolve({ ok: true, status: res.statusCode, text }));
    });
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, error: 'timeout after ' + TIMEOUT + 'ms' }); });
    req.on('error', (e) => resolve({ ok: false, error: e.code ? (e.code + ' - ' + e.message) : e.message }));
    req.end();
  });
}

function postJson(url, body) {
  return new Promise((resolve) => {
    let u;
    try { u = new URL(url); } catch (e) { return resolve({ ok: false, error: 'bad url' }); }
    const lib = u.protocol === 'https:' ? https : http;
    const payload = JSON.stringify(body);
    const req = lib.request({
      hostname: u.hostname,
      port: u.port || (u.protocol === 'https:' ? 443 : 80),
      path: u.pathname + u.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
        'User-Agent': 'jvhd-diagnose/1.0',
      },
      timeout: TIMEOUT,
    }, (res) => {
      let text = '';
      res.setEncoding('utf8');
      res.on('data', (c) => { text += c; });
      res.on('end', () => resolve({ ok: true, status: res.statusCode, text }));
    });
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, error: 'timeout after ' + TIMEOUT + 'ms' }); });
    req.on('error', (e) => resolve({ ok: false, error: e.code ? (e.code + ' - ' + e.message) : e.message }));
    req.write(payload);
    req.end();
  });
}

const parseJson = (t) => { try { return JSON.parse(t); } catch (e) { return null; } };

function readLocal(file) {
  if (!file) return null;
  try { return fs.readFileSync(file, 'utf8'); } catch (e) { return null; }
}

async function loadData() {
  const local = { salt: readLocal(SALT_FILE), hash4: readLocal(HASH4_FILE), member: readLocal(MEMBER_FILE) };
  const out = {};
  for (const key of ['salt', 'hash4', 'member']) {
    if (local[key] != null) { out[key] = local[key]; out[key + 'Source'] = 'file'; continue; }
    const r = await fetchUrl(SOURCES[key]);
    if (r.ok && r.status === 200) { out[key] = r.text; out[key + 'Source'] = 'gitlab'; }
    else { out[key] = null; out[key + 'Source'] = 'unavailable (' + (r.ok ? 'HTTP ' + r.status : r.error) + ')'; }
  }
  return out;
}

function cleanSalt(raw) {
  if (raw == null) return null;
  const s = String(raw).replace(/^\uFEFF/, '').replace(/\s+/g, '').replace(/^["']|["']$/g, '').toLowerCase();
  const m = s.match(/([0-9a-f]{16,128})/);
  return m ? m[1] : null;
}

(async function main() {
  const results = { health: null, probes: [], accepted: 0, unknown: 0, control: null, saltMatchesData: null };
  console.log('JVHD auth server diagnostic (READ-ONLY)');
  console.log('server  :', BASE);
  console.log('started :', new Date().toISOString());
  console.log('safety  : GET /health + POST /auth/start only; /auth/bind never called.');

  // ---------------------------------------------------------------- step 1 ---
  rule('1) GET /health - which server code is deployed, did the allowlist load?');
  const h = await fetchUrl(BASE + '/health');
  if (!h.ok) {
    console.log('UNREACHABLE: ' + h.error);
    console.log('(Render free instances sleep; a cold start can take ~30-60s, rerun to check.)');
    results.health = 'unreachable';
  } else {
    console.log('HTTP ' + h.status);
    console.log(cut(h.text, 1200));
    const hj = parseJson(h.text);
    results.health = h.status;
    if (h.status === 405 || h.status === 404) {
      console.log('\nVERDICT: /health is not served with GET here although both repo versions');
      console.log('implement it -> the deployed build matches NEITHER repository commit.');
      results.health = 'mismatch-' + h.status;
    } else if (hj && hj.onedrive) {
      const h4 = hj.onedrive.hash4 || {};
      console.log('\nVERDICT: this is the NEW server (jvhd-server, "onedrive" block present).');
      results.health = 'new';
      if (h4.ok === false || h4.count === 0) {
        console.log('  !! ALLOWLIST NOT LOADED (ok=' + h4.ok + ', count=' + h4.count + ')');
        console.log('  !! => every username returns "unknown": server-side data fault, not a user error.');
      } else {
        console.log('  allowlist loaded: ' + h4.count + ' hash(es).');
      }
    } else if (hj) {
      console.log('\nVERDICT: this is the OLD server (jvhd-auth: bindings/bindingSource, no "onedrive").');
      results.health = 'old';
    } else {
      console.log('\nVERDICT: /health answered, but not in a recognised shape (see body above).');
      results.health = 'unknown-shape';
    }
  }

  // ---------------------------------------------------------------- step 2 ---
  rule('2) canonical data (Salt.txt / Hash4.txt / Member.txt) + server agreement');
  const data = await loadData();
  console.log('Salt.txt   : ' + data.saltSource);
  console.log('Hash4.txt  : ' + data.hash4Source);
  console.log('Member.txt : ' + data.memberSource);

  const salt = cleanSalt(data.salt);
  let hashSet = null;
  if (data.hash4) {
    const arr = parseJson(data.hash4);
    if (Array.isArray(arr)) hashSet = new Set(arr.map((x) => String(x).trim().toLowerCase()));
  }
  let members = null;
  if (data.member) {
    const arr = parseJson(data.member);
    if (Array.isArray(arr)) members = arr.map((x) => String(x).trim()).filter(Boolean);
  }
  console.log('salt parsed: ' + (salt ? salt.length + ' hex chars' : 'NO usable salt'));
  console.log('Hash4       : ' + (hashSet ? hashSet.size + ' entries' : 'not parsed'));
  console.log('Member      : ' + (members ? members.length + ' usernames' : 'not parsed'));

  if (!salt || !members) {
    console.log('\nCannot cross-check the formula without Salt.txt + Member.txt (see above).');
    console.log('Probing /auth/start with a control (bogus) hash only.');

    const bogus = sha256hex('diagnostic-control-' + Date.now());
    const c = await postJson(BASE + '/auth/start', { h: bogus });
    console.log('control ' + bogus.slice(0, 16) + '... -> ' + (c.ok ? 'HTTP ' + c.status + ' ' + cut(c.text, 200) : c.error));
    results.control = c.ok ? (parseJson(c.text) || {}).status : null;
    return finish(results, false);
  }

  // Which member digests does the canonical Hash4 actually contain?
  const digests = members.map((m) => ({ member: m, h: sha256hex(m.trim().toLowerCase() + salt) }));
  const inHash4 = digests.filter((d) => hashSet && hashSet.has(d.h));
  console.log('member digests present in Hash4: ' + inHash4.length + '/' + digests.length);
  results.saltMatchesData = inHash4.length === digests.length
    ? 'all'
    : (inHash4.length > 0 ? 'partial (' + inHash4.length + '/' + digests.length + ')' : 'none');
  if (results.saltMatchesData !== 'all') {
    console.log('  !! Salt.txt and Hash4.txt are NOT consistent -> the allowlist was produced with');
    console.log('     a different salt than Salt.txt currently published (or vice versa).');
  }

  // Probe the server with digests a working APK would send.
  const sample = digests.slice(0, LIMIT);
  console.log('\nPOST /auth/start with canonical digests (sample of ' + sample.length + '):');
  for (const d of sample) {
    const r = await postJson(BASE + '/auth/start', { h: d.h });
    const status = r.ok ? (parseJson(r.text) || {}).status || '?' : 'UNREACHABLE';
    const body = r.ok ? cut(r.text, 200) : r.error;
    console.log('  ' + d.member.padEnd(16) + ' ' + d.h.slice(0, 16) + '... -> HTTP ' +
      (r.ok ? r.status : '-') + ' ' + body);
    results.probes.push({ member: d.member, status: status });
    if (status === 'bind' || status === 'challenge' || status === 'ok') results.accepted++;
    else if (status === 'unknown') results.unknown++;
  }

  // Negative control: a random digest must be rejected, otherwise the server
  // is accepting anything (which would be a far more serious problem).
  const bogus = sha256hex('diagnostic-control-' + Date.now());
  const ctl = await postJson(BASE + '/auth/start', { h: bogus });
  const ctlStatus = ctl.ok ? (parseJson(ctl.text) || {}).status || '?' : 'UNREACHABLE';
  console.log('\nnegative control (random hash) -> HTTP ' + (ctl.ok ? ctl.status : '-') + ' ' + ctlStatus);
  results.control = ctlStatus;

  finish(results, true);
})().catch((e) => { console.error('ERROR', e); process.exitCode = 0; });

function finish(results, full) {
  rule('3) VERDICT');
  const unreachable = results.probes.length > 0 && results.probes.every((p) => p.status === 'UNREACHABLE');
  if (results.health === 'unreachable' || unreachable) {
    console.log('Server NOT reachable (or asleep). This run proves nothing about the login:');
    console.log('  * Render free tier sleeps - rerun, or use the APK once to wake it.');
    console.log('  * if it stays unreachable from here, the APK must show exactly that:');
    console.log('    "Không thể kết nối đến máy chủ xác thực" (never "Tên người dùng không đúng").');
    return;
  }
  if (!full) {
    console.log('Only the health/control probe ran (see above). Server status: ' + results.health + '.');
    return;
  }
  const bad = results.control !== 'unknown';
  if (results.accepted > 0) {
    console.log('OK: the server ACCEPTED ' + results.accepted + '/' + results.probes.length +
      ' canonical digest(s) -> allowlist + formula are healthy server-side.');
    console.log('If a user still gets "Tên người dùng không đúng", the username is genuinely not');
    console.log('in Member.txt/Hash4.txt (or Salt.txt downloaded by that device is stale).');
  } else if (results.unknown === results.probes.length) {
    console.log('ROOT CAUSE CONFIRMED (server side): every canonical digest is "unknown".');
    console.log('  => the deployed allowlist does not contain Hash4.txt from');
    console.log('     gitlab.com/binmedia-group/jvhd-sever2 (stale/mirror/empty source).');
    console.log('  => fix the server data source (ONEDRIVE_HASH4_URL / Hash4 file) to the canonical');
    console.log('     Hash4.txt and make it FAIL LOUD when the allowlist is empty.');
    console.log('  NOTE: the APK can no longer report this as a wrong username - it says the');
    console.log('  server rejected the credentials, and only counts it after a real 2xx/401.');
  } else {
    console.log('Mixed result: ' + JSON.stringify(results.probes));
  }
  if (bad) {
    console.log('!! the negative control was NOT "unknown" -> the server accepted a random hash.');
    console.log('   That means the server is not really checking the allowlist; investigate immediately.');
  } else {
    console.log('Negative control OK (random digest rejected), so the check above is meaningful.');
  }
  console.log('Salt.txt vs Hash4.txt consistency: ' + results.saltMatchesData + '.');
}
