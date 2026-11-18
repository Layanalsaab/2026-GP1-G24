// One-time data migration that goes with the field clean-up in the app code:
//
//   1. startups:   marketSizeTam  ->  marketSize   (value copied, old field removed)
//   2. users + investors:  hasLedRound, roundsLed, coInvest  removed
//   3. users:      gain  ->  lookingFor  (copied only when lookingFor is empty;
//                  `gain` is removed either way)
//
// Nothing else is touched. Before writing, every value it changes or removes is
// saved to backups/.
//
// RUN IT RIGHT AFTER deploying the new firestore.rules (the old rules do not know
// `marketSize`, the new ones do not know the old names):
//
//   node migrate_fields.mjs <service-account.json>            dry run
//   node migrate_fields.mjs <service-account.json> --write    applies it

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const keyPath = process.argv[2];
const WRITE = process.argv.includes('--write');
if (!keyPath) {
  console.log('Usage: node migrate_fields.mjs <service-account.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const plan = []; // { ref, update, before }
const count = { startupsRenamed: 0, ledRoundFieldsRemoved: 0, gainMoved: 0, gainRemoved: 0 };

for (const d of (await db.collection('startups').get()).docs) {
  const x = d.data();
  if (!('marketSizeTam' in x)) continue;
  plan.push({ ref: d.ref, update: { marketSize: x.marketSizeTam ?? null, marketSizeTam: FieldValue.delete() }, before: { marketSizeTam: x.marketSizeTam ?? null } });
  count.startupsRenamed++;
}

for (const col of ['users', 'investors']) {
  for (const d of (await db.collection(col).get()).docs) {
    const x = d.data();
    const update = {}, before = {};
    for (const k of ['hasLedRound', 'roundsLed', 'coInvest']) {
      if (k in x) { update[k] = FieldValue.delete(); before[k] = x[k] ?? null; count.ledRoundFieldsRemoved++; }
    }
    if (col === 'users' && 'gain' in x) {
      const hasLooking = typeof x.lookingFor === 'string' && x.lookingFor.trim() !== '';
      if (!hasLooking && typeof x.gain === 'string' && x.gain.trim() !== '') { update.lookingFor = x.gain; count.gainMoved++; }
      update.gain = FieldValue.delete();
      before.gain = x.gain ?? null;
      before.lookingFor = x.lookingFor ?? null;
      count.gainRemoved++;
    }
    if (Object.keys(update).length) plan.push({ ref: d.ref, update, before });
  }
}

console.log(JSON.stringify({ mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)', documentsToChange: plan.length, ...count }, null, 2));
if (!WRITE) { console.log('\nDry run only. Add --write to apply.'); process.exit(0); }

const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const stamp = Date.now();
fs.writeFileSync(path.join(backupDir, `fields_before_${stamp}.json`), JSON.stringify(Object.fromEntries(plan.map((p) => [p.ref.path, p.before])), null, 1));
console.log('Backup saved: backups/fields_before_' + stamp + '.json');
let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const p of plan) {
  batch.update(p.ref, p.update);
  if (++ops >= 400) await flush();
}
await flush();
console.log('Done. Documents changed:', plan.length);
