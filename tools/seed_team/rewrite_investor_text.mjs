// Writes new texts into the DATASET investors (investors/{id} with isArchived
// == true): `bio` (only the ones that were just a name or tiny), `offer` (only
// the generic "Funding as an angel investor.") and `lookingFor`.
//
// WHAT IT TOUCHES (and nothing else): those three fields on investors whose
// isArchived is true. Investors who signed up in the app (isArchived false),
// and every other field (sectors, stages, ticket, round size...), are never
// touched.
//
//   node rewrite_investor_text.mjs <service-account.json> <out_investors.json>          dry run
//   node rewrite_investor_text.mjs <service-account.json> <out_investors.json> --write  applies it
//
// Before writing, the old values are saved to backups/.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const [keyPath, file] = process.argv.slice(2);
const WRITE = process.argv.includes('--write');
if (!keyPath || !file) {
  console.log('Usage: node rewrite_investor_text.mjs <service-account.json> <out_investors.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const LIMIT = { bio: 1000, offer: 1000, lookingFor: 1000 };
const investors = new Map();
for (const d of (await db.collection('investors').get()).docs) {
  const i = { id: d.id, ...d.data() };
  if (i.isArchived === true) investors.set(i.id, i);
}

const updates = new Map();
const problems = [];
for (const row of JSON.parse(fs.readFileSync(file, 'utf8'))) {
  const inv = investors.get(row.id);
  if (!inv) { problems.push(`${row.id}: not a dataset investor`); continue; }
  const patch = {};
  for (const k of Object.keys(row)) {
    if (k === 'id') continue;
    if (!(k in LIMIT)) { problems.push(`${row.id}: unexpected field ${k}`); continue; }
    const v = String(row[k] ?? '').replace(/\s+/g, ' ').trim();
    if (v.length < 40) problems.push(`${row.id}.${k}: too short`);
    else if (v.length > 400) problems.push(`${row.id}.${k}: too long (${v.length})`);
    else if (/["“”]/.test(v) || /\b(n\/a|lorem|todo|tbd)\b/i.test(v)) problems.push(`${row.id}.${k}: placeholder or quotes`);
    else if (k === 'bio' && !v.toLowerCase().includes(String(inv.fullName).split(' ')[0].toLowerCase())) problems.push(`${row.id}.bio: does not use the name`);
    else patch[k] = v;
  }
  if (Object.keys(patch).length) updates.set(row.id, patch);
}
for (const id of investors.keys()) if (!updates.get(id)?.lookingFor) problems.push(`${id}: no lookingFor text`);
const seen = new Map();
for (const [id, u] of updates) for (const k of Object.keys(u)) {
  const key = `${k}:${u[k]}`;
  if (seen.has(key)) problems.push(`${id}.${k}: same text as ${seen.get(key)}`);
  else seen.set(key, id);
}

const count = {};
for (const u of updates.values()) for (const k of Object.keys(u)) count[k] = (count[k] || 0) + 1;
console.log(JSON.stringify({ mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)', datasetInvestors: investors.size, investorsToUpdate: updates.size, fields: count, problems: problems.length }, null, 2));
for (const p of problems.slice(0, 30)) console.log(' !', p);
let shown = 0;
for (const [id, u] of updates) {
  if (shown++ >= 3 || !u.bio) continue;
  const i = investors.get(id);
  console.log(`\n--- ${i.fullName} ---`);
  for (const k of Object.keys(u)) console.log(`${k}\n  before: ${i[k] ?? '(empty)'}\n  after:  ${u[k]}`);
}
if (problems.length) { console.log('\nProblems found: nothing written.'); process.exit(2); }
if (!WRITE) { console.log('\nDry run only. Add --write to apply.'); process.exit(0); }

const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const stamp = Date.now();
fs.writeFileSync(path.join(backupDir, `investor_text_before_${stamp}.json`), JSON.stringify(Object.fromEntries(
  [...updates].map(([id, u]) => [id, Object.fromEntries(Object.keys(u).map((k) => [k, investors.get(id)[k] ?? null]))])), null, 1));
console.log('Backup saved: backups/investor_text_before_' + stamp + '.json');
let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const [id, u] of updates) {
  batch.update(db.collection('investors').doc(id), u);
  if (++ops >= 400) await flush();
}
await flush();
console.log('Done. Investors updated:', updates.size);
