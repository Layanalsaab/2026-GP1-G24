// Writes new texts into the DATASET startups: the revenue model
// (revenueModel), the target customers, and any of
// differentiation / problem / solution / description that was empty or tiny.
//
// WHAT IT TOUCHES (and nothing else): those fields of startups whose founderId
// is "crunchbase-dataset". Startups made by real accounts are never touched.
//
//   node rewrite_startup_text.mjs <service-account.json> <folder-with-out_N.json>          dry run
//   node rewrite_startup_text.mjs <service-account.json> <folder-with-out_N.json> --write  applies it
//
// Before writing, the old values of every field it changes are saved to backups/.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const [keyPath, dir] = process.argv.slice(2);
const WRITE = process.argv.includes('--write');
if (!keyPath || !dir) {
  console.log('Usage: node rewrite_startup_text.mjs <service-account.json> <folder> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

// The limits of the app's own forms.
const LIMIT = { revenueModel: 250, targetCustomers: 250, differentiation: 1000, problem: 350, solution: 350, description: 150 };
const FIELDS = Object.keys(LIMIT);

const startups = new Map();
for (const d of (await db.collection('startups').get()).docs) {
  const s = { id: d.id, ...d.data() };
  if (s.founderId === 'crunchbase-dataset') startups.set(s.id, s);
}

const updates = new Map();
const problems = [];
const files = fs.readdirSync(dir).filter((f) => /^out_\d+\.json$/.test(f)).sort();
for (const f of files) {
  let rows;
  try { rows = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')); } catch (e) { problems.push(`${f}: not valid JSON`); continue; }
  for (const row of rows) {
    const s = startups.get(row.id);
    if (!s) { problems.push(`${f}: ${row.id} is not a dataset startup`); continue; }
    const patch = {};
    for (const k of Object.keys(row)) {
      if (k === 'id') continue;
      if (!FIELDS.includes(k)) { problems.push(`${row.id}: unexpected field ${k}`); continue; }
      const v = String(row[k] ?? '').replace(/\s+/g, ' ').trim();
      if (v.length < 25 && k !== 'description') problems.push(`${row.id}.${k}: too short`);
      else if (v.length < 15) problems.push(`${row.id}.${k}: too short`);
      else if (v.length > LIMIT[k]) problems.push(`${row.id}.${k}: ${v.length} > ${LIMIT[k]}`);
      else if (/^[\s.\-–—_?,;:!]*$/.test(v) || /\b(n\/a|lorem|todo|tbd)\b/i.test(v)) problems.push(`${row.id}.${k}: placeholder`);
      else if (/["“”]/.test(v)) problems.push(`${row.id}.${k}: has quotation marks`);
      else patch[k] = v;
    }
    if (Object.keys(patch).length) updates.set(row.id, { ...(updates.get(row.id) || {}), ...patch });
  }
}

// Every startup must have both main fields, and the revenue texts must differ.
for (const id of startups.keys()) {
  const u = updates.get(id) || {};
  if (!u.revenueModel) problems.push(`${id}: no revenue model text`);
  if (!u.targetCustomers) problems.push(`${id}: no target customers text`);
}
const seen = new Map();
for (const [id, u] of updates) {
  for (const k of ['revenueModel', 'targetCustomers']) {
    const key = `${k}:${u[k]}`;
    if (seen.has(key)) problems.push(`${id}.${k}: same text as ${seen.get(key)}`);
    else seen.set(key, id);
  }
}

const count = {};
for (const u of updates.values()) for (const k of Object.keys(u)) count[k] = (count[k] || 0) + 1;
console.log(JSON.stringify({ mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)', outFiles: files.length, startupsToUpdate: updates.size, fields: count, problems: problems.length }, null, 2));
for (const p of problems.slice(0, 40)) console.log(' !', p);
if (problems.length > 40) console.log(`  ... and ${problems.length - 40} more`);
for (const id of ['1stech', 'PIEHSIP', 'aamar']) {
  const u = updates.get(id), s = startups.get(id);
  if (!u || !s) continue;
  console.log(`\n--- ${s.name} ---`);
  for (const k of Object.keys(u)) console.log(`${k}\n  before: ${s[k] ?? '(empty)'}\n  after:  ${u[k]}`);
}
if (problems.length) { console.log('\nProblems found: nothing written.'); process.exit(2); }
if (!WRITE) { console.log('\nDry run only. Add --write to apply.'); process.exit(0); }

const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const stamp = Date.now();
fs.writeFileSync(path.join(backupDir, `startup_text_before_${stamp}.json`), JSON.stringify(Object.fromEntries(
  [...updates].map(([id, u]) => [id, Object.fromEntries(Object.keys(u).map((k) => [k, startups.get(id)[k] ?? null]))])), null, 1));
console.log('Backup saved: backups/startup_text_before_' + stamp + '.json');
let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const [id, u] of updates) {
  batch.update(db.collection('startups').doc(id), u);
  if (++ops >= 400) await flush();
}
await flush();
console.log('Done. Startups updated:', updates.size);
