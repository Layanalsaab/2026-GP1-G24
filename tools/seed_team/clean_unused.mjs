// Removes the attributes the app no longer uses from the live data. Nothing else
// is touched; every removed value is saved to backups/ first.
//
//   startups        marketSizeSam, marketSizeSom, oneLinePitch, expectedGrowth,
//                   wantsLeadInvestor, lookingForOther, stageOther,
//                   crunchbaseRank, logoUrl, foundedBy, formerFounderId,
//                   ownerChangedAt
//   fundingRounds   wantsLeadInvestor
//   invitations     lastSentAt, respondedAt
//   investors       crunchbaseRank, photoUrl, preferredStagesOther
//   users           photoUrl, ticketSizeOther, preferredStagesOther
//   publicProfiles  photoUrl
//
// RUN IT RIGHT AFTER deploying the new firestore.rules.
//
//   node clean_unused.mjs <service-account.json>            dry run
//   node clean_unused.mjs <service-account.json> --write    applies it

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const keyPath = process.argv[2];
const WRITE = process.argv.includes('--write');
if (!keyPath) {
  console.log('Usage: node clean_unused.mjs <service-account.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const PLAN = [
  { label: 'startups', query: () => db.collection('startups'),
    fields: ['marketSizeSam', 'marketSizeSom', 'oneLinePitch', 'expectedGrowth', 'wantsLeadInvestor', 'lookingForOther', 'stageOther', 'crunchbaseRank', 'logoUrl', 'foundedBy', 'formerFounderId', 'ownerChangedAt'] },
  { label: 'fundingRounds', query: () => db.collectionGroup('fundingRounds'), fields: ['wantsLeadInvestor'] },
  { label: 'invitations', query: () => db.collection('invitations'), fields: ['lastSentAt', 'respondedAt'] },
  { label: 'investors', query: () => db.collection('investors'), fields: ['crunchbaseRank', 'photoUrl', 'preferredStagesOther'] },
  { label: 'users', query: () => db.collection('users'), fields: ['photoUrl', 'ticketSizeOther', 'preferredStagesOther'] },
  { label: 'publicProfiles', query: () => db.collection('publicProfiles'), fields: ['photoUrl'] },
];

const jobs = [];
const report = {};
for (const p of PLAN) {
  const snap = await p.query().get();
  let docs = 0, fieldsRemoved = 0;
  const perField = {};
  for (const d of snap.docs) {
    const x = d.data();
    const present = p.fields.filter((f) => f in x);
    if (!present.length) continue;
    docs++;
    fieldsRemoved += present.length;
    present.forEach((f) => (perField[f] = (perField[f] || 0) + 1));
    jobs.push({ path: d.ref.path, ref: d.ref, update: Object.fromEntries(present.map((f) => [f, FieldValue.delete()])), before: Object.fromEntries(present.map((f) => [f, x[f] ?? null])) });
  }
  report[p.label] = { scanned: snap.size, documentsToChange: docs, fieldsRemoved, perField };
}
console.log(JSON.stringify({ mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)', totalDocuments: jobs.length, ...report }, null, 1));
if (!WRITE) { console.log('\nDry run only. Add --write to apply.'); process.exit(0); }

const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const stamp = Date.now();
fs.writeFileSync(path.join(backupDir, `unused_fields_before_${stamp}.json`), JSON.stringify(Object.fromEntries(jobs.map((j) => [j.path, j.before])), null, 1));
console.log('Backup saved: backups/unused_fields_before_' + stamp + '.json');
let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const j of jobs) {
  batch.update(j.ref, j.update);
  if (++ops >= 400) await flush();
}
await flush();
console.log('Done. Documents changed:', jobs.length);
