// One-time data migration that goes with the rename in the code and rules:
//   startups.businessModel            -> commerceModel
//   startups.businessModelOther       -> commerceModelOther
//   startups.businessModelExplanation -> revenueModel
// The value is copied and the old field removed. Nothing else is touched; the
// old values are saved to backups/ first.
//
// RUN IT RIGHT AFTER deploying the new firestore.rules.
//
//   node rename_commerce_model.mjs <service-account.json>            dry run
//   node rename_commerce_model.mjs <service-account.json> --write    applies it

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const keyPath = process.argv[2];
const WRITE = process.argv.includes('--write');
if (!keyPath) {
  console.log('Usage: node rename_commerce_model.mjs <service-account.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const MAP = { businessModel: 'commerceModel', businessModelOther: 'commerceModelOther', businessModelExplanation: 'revenueModel' };
const jobs = [];
const perField = {};
for (const d of (await db.collection('startups').get()).docs) {
  const x = d.data();
  const update = {}, before = {};
  for (const [from, to] of Object.entries(MAP)) {
    if (from in x) { update[to] = x[from] ?? null; update[from] = FieldValue.delete(); before[from] = x[from] ?? null; perField[from] = (perField[from] || 0) + 1; }
  }
  if (Object.keys(update).length) jobs.push({ path: d.ref.path, ref: d.ref, update, before });
}
console.log(JSON.stringify({ mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)', startupsToChange: jobs.length, perField }, null, 1));
if (!WRITE) { console.log('\nDry run only. Add --write to apply.'); process.exit(0); }

const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const stamp = Date.now();
fs.writeFileSync(path.join(backupDir, `commerce_model_before_${stamp}.json`), JSON.stringify(Object.fromEntries(jobs.map((j) => [j.path, j.before])), null, 1));
console.log('Backup saved: backups/commerce_model_before_' + stamp + '.json');
let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const j of jobs) { batch.update(j.ref, j.update); if (++ops >= 400) await flush(); }
await flush();
console.log('Done. Startups changed:', jobs.length);
