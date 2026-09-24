#!/usr/bin/env node
'use strict';
// ============================================================================
// Regression test for JVHD APK username authentication.
//
// ROOT CAUSE it guards against (fixed in assets/app.js):
//   The APK must send  h = SHA-256( toLowerCase(username) + SALT )  to the auth
//   server, where SALT comes from Salt.txt and the server checks membership in
//   Hash4.txt (a JSON array of lowercase-hex SHA-256). A previous build hashed
//   ONLY the username (the salt was never applied by the opaque native lib), so
//   every valid username was rejected with "Tên người dùng không đúng".
//
// This test loads the EXACT jvhdSha256Hex implementation shipped in
// assets/app.js and asserts that, for every username in Member.txt, the value
//   SHA-256( toLowerCase(username) + SALT )
// is present in Hash4.txt (i.e. the APK will compute a digest the server
// accepts). It also asserts the server/auth-side invariants that must hold.
//
// Data is fetched live from the canonical GitLab source when reachable, and
// falls back to an embedded snapshot (the real values at the time of the fix)
// so the test is deterministic in offline CI.
// ============================================================================

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const REPO_ROOT = path.resolve(__dirname, '..');
const APP_JS = path.join(REPO_ROOT, 'assets', 'app.js');

// ---- Embedded snapshot (real data at time of fix) ---------------------------
const SNAPSHOT = {
  members: ["BKyo112","JVHD112","Vip1","Tienvip","Admin","TranCayFree","IvisibleManFree","Admin2","Vip2","Vip3","PhuongThFree","Vip4","BonsaiPFree","Vip5","Vip6","Free1","Free2","Free3","Free4","Vip7","Vip8","Free5","Free6","Free7","Vip9","Free8"],
  salt: "4f4e804da5c307dd7d88d2b58e1a44c6b312c1430ff4d29d",
  hash4: ["7da8858b1877fe47ddd270f7a400e4c4f207a8cbaae44c247de9e9aa8869f979","a4c80b2e8656306f4a3a95b96e8cf857950c12d6e38452538d624b5a8608597d","48550fdfae46bcbba317cb84c0595a757cdd6f7ecc6dcd61be45b4c9009b4fad","b785b11bc9e37f158e54337a0329cb4391ccc8212192079821f261f9cb5d122b","7f51d87ee6e2857954ecdec75d9d2cbca9b9e428e3b66ce740dc5fdb8b1fa1e1","ff580dbf2a7e031029d66130a9992337fa6e705a540de792f9f12329c69b38cc","d0a9ccf6f6010740d83b45c04a54a12a6067fafbb0d4fa24abd539eefb85254d","37b5d924f34f64ed7e88033b8c31db39b314ddca0ec624ea94d5b8056467ca5b","75981e41aeb227415d31da60c28183ff750b2f680b5994972e055439b06a4a24","f31c56925593b1d3497dae5fb29997b037c0029ab92f8b476e0756ad305c9c70","4922a9086aabde2e562055050bdea70ca7c009b9d36c494aec37c0cce5f77753","52d11bd1914589d2a6ac72ad9eb2e5fc0e3cf3c02b02f64f0425e929230bce10","0011f93c70f95f00aef662489635d17e41fc34453e56f62d8371c41106137c98","f8fed9da90344167b4bd2a5f8c2adf65364ed853069272b05919661e3b3396ae","43afff83d68270bc7235113257d18ba793e61440096001a5640e9c9952d5801f","56cd671032471301cdf718249ca145fccbd9444121c458195483e8d5c775e20e","b3d03fb09e748f69e3b79fd5767fdf4523887d173afff705e463c29ca61c417d","86f0668892d8c63803922e95a36dc3ee0874d704fafd68ce4c6d9a52a9e43f17","58cbe9ffb9ef71bc26eb284b4030b86701adfc475aeffd206c88c6eb37bcf284","2a4a9dd53d95ac68c13dbbaab88a99e9d9b30a36be4e5a769c63c9f8dcaf5d8e","ed76be9e2e0a44e71534a511a1144515a5c7c9d34c980dfb879b089d008d12e4","5c7ed62deb292c4f836759b84cee749f1a4a66ec439a5e56324750d709544ed5","7ceefb7a2b322f41b16896a66d12ec6aeda26bcbcc07def89b1894a858c18a15","d5e83428c7dea2e27c8413fa577f62ce89cf925d59cf835fd0621696e4293328","f632c00fe80966437c17a8b4ac7e80f7f0ab033ab4473d7ae353f74b00fd7c4a","f07f58ce2c757e4bd131021d3c70e0a36c1d046ad5fd8a9d76db337da3d7e895"]
};

const GITLAB = {
  member: "https://gitlab.com/binmedia-group/jvhd-sever2/-/raw/main/Member.txt?ref_type=heads",
  salt:   "https://gitlab.com/binmedia-group/jvhd-sever2/-/raw/main/Salt.txt?ref_type=heads",
  hash4:  "https://gitlab.com/binmedia-group/jvhd-sever2/-/raw/main/Hash4.txt?ref_type=heads"
};

const HEX64 = /^[0-9a-f]{64}$/;

function get(url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    const req = lib.get(url, { timeout: 20000 }, (res) => {
      if (res.statusCode < 200 || res.statusCode >= 400) {
        res.resume();
        return reject(new Error('HTTP ' + res.statusCode));
      }
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (c) => (body += c));
      res.on('end', () => resolve(body));
    });
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
    req.on('error', (e) => reject(e));
  });
}

// Extract the EXACT jvhdSha256Hex implementation from assets/app.js.
function loadSha256FromAppJs() {
  const src = fs.readFileSync(APP_JS, 'utf8');
  const start = src.indexOf('function jvhdSha256Hex(message) {');
  if (start < 0) throw new Error('jvhdSha256Hex not found in app.js');
  // match braces from the opening brace
  let i = src.indexOf('{', start);
  let depth = 0;
  for (; i < src.length; i++) {
    const ch = src[i];
    if (ch === '{') depth++;
    else if (ch === '}') { depth--; if (depth === 0) break; }
  }
  const fnSrc = src.slice(start, i + 1);
  // eslint-disable-next-line no-eval
  return eval('(' + fnSrc + ')');
}

async function loadLiveData() {
  try {
    const [memberRaw, saltRaw, hash4Raw] = await Promise.all([
      get(GITLAB.member), get(GITLAB.salt), get(GITLAB.hash4)
    ]);
    const members = JSON.parse(memberRaw);
    if (!Array.isArray(members)) throw new Error('Member.txt not array');
    const salt = String(saltRaw).replace(/^﻿/, '').trim();
    const hash4 = JSON.parse(hash4Raw);
    if (!Array.isArray(hash4)) throw new Error('Hash4.txt not array');
    return { members, salt, hash4, live: true };
  } catch (e) {
    return { ...SNAPSHOT, live: false, error: e.message };
  }
}

async function main() {
  const sha256hex = loadSha256FromAppJs();
  const data = await loadLiveData();

  const source = data.live ? 'LIVE (GitLab)' : 'SNAPSHOT (embedded)';
  if (!data.live) {
    console.log('[warn] live GitLab fetch failed (' + (data.error || '?') + '); using embedded snapshot.');
  }
  console.log('Data source: ' + source);
  console.log('members=' + data.members.length + '  hash4=' + data.hash4.length + '  salt=' + (data.salt ? data.salt.length + ' chars' : 'MISSING'));

  let failures = 0;

  // 1) SALT must be a non-empty, sane value.
  if (!data.salt) { console.error('FAIL: salt missing'); failures++; }

  // 2) Every Hash4 entry must be a 64-char lowercase hex string (server side
  //    CRYPTO_HASH_RE requires this; mismatched case/length would never match).
  const hashSet = new Set();
  for (const h of data.hash4) {
    if (typeof h === 'string' && HEX64.test(h)) hashSet.add(h);
    else { console.error('FAIL: invalid Hash4 entry: ' + JSON.stringify(h)); failures++; }
  }

  // 3) THE CORE ASSERTION: for every member, SHA-256(lowercase(username)+salt)
  //    must be present in Hash4. This is exactly what the APK now sends.
  let matched = 0;
  for (const m of data.members) {
    const digest = sha256hex(String(m).toLowerCase() + data.salt);
    if (!HEX64.test(digest)) { console.error('FAIL: sha256 produced bad output for ' + m); failures++; continue; }
    if (hashSet.has(digest)) { matched++; }
    else { console.error('FAIL: ' + m + ' -> ' + digest + ' NOT in Hash4'); failures++; }
  }
  console.log('members matched by APK hash formula: ' + matched + '/' + data.members.length);

  // 4) Negative control: a bogus username must NOT match (proves the check is
  //    real, not a wildcard).
  const bogus = sha256hex('this-username-does-not-exist' + data.salt);
  if (hashSet.has(bogus)) { console.error('FAIL: bogus username unexpectedly matched'); failures++; }
  else console.log('negative control OK (bogus username rejected)');

  if (failures === 0) {
    console.log('\nRESULT: PASS — APK hash formula matches server Hash4 for all members.');
    process.exit(0);
  } else {
    console.error('\nRESULT: FAIL (' + failures + ' failure(s)).');
    process.exit(1);
  }
}

main().catch((e) => { console.error('ERROR', e); process.exit(2); });
