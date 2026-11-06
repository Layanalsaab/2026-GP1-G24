// Writes output/plan.json (from generate.mjs) to Firebase.
//
// WHAT IT TOUCHES (and nothing else):
//   1. `investors` with isDataset == true: ONLY investmentsCount and ticketSize
//      (an update, every other field stays as it is).
//   2. NEW documents in `tickets` (id "<investorId>-T1", isSample: true).
//   It never touches app investors, users, startups or any other collection.
//
// USAGE
//   node upload.mjs <service-account.json>            (dry run: writes nothing)
//   node upload.mjs <service-account.json> --write    (really writes)
//
// Run export_investors.mjs first: output/investors_backup.json is the backup
// that undo.mjs uses.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import fs from 'fs';

const [keyPath, flag] = process.argv.slice(2);
if (!keyPath) {
  console.log('node upload.mjs <service-account.json> [--write]');
  process.exit(1);
}
const write = flag === '--write';
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

// lib/models/investor_criteria.dart and lib/recommender/knowledge_filter.dart
const COUNTS = ['0', '1–3', '4–6', '7–9', '10+'];
const BANDS = ['Under SAR 100K', 'SAR 100K – 500K', 'SAR 500K – 1M', 'SAR 1M – 5M', 'Over SAR 5M'];
const SECTORS = ['HealthTech', 'Fintech', 'EdTech', 'E-commerce', 'Logistics', 'AgriTech',
  'PropTech', 'CleanTech', 'Tourism', 'SaaS', 'AI', 'Cybersecurity', 'Gaming', 'Media',
  'FoodTech', 'Mobility', 'Retail', 'Energy', 'InsurTech', 'LegalTech', 'HR Tech', 'Biotech',
  'Manufacturing', 'Sports', 'Other'];
const STAGES = ['Pre-seed', 'Seed', 'Series A', 'Series B', 'Series C'];

const plan = JSON.parse(fs.readFileSync('output/plan.json', 'utf8'));
if (!fs.existsSync('output/investors_backup.json')) {
  console.log('No output/investors_backup.json. Run export_investors.mjs first.');
  process.exit(1);
}

const problems = [];
const changes = { investmentsCount: 0, ticketSize: 0 };
const live = new Map((await db.collection('investors').get()).docs.map((d) => [d.id, d.data()]));

for (const u of plan.updates) {
  const now = live.get(u.id);
  if (!now) problems.push(`${u.id}: not in investors`);
  else if (now.isDataset !== true) problems.push(`${u.id}: not a dataset investor`);
  if (!COUNTS.includes(u.investmentsCount)) problems.push(`${u.id}: investmentsCount "${u.investmentsCount}"`);
  if (!BANDS.includes(u.ticketSize)) problems.push(`${u.id}: ticketSize "${u.ticketSize}"`);
  if (now && now.investmentsCount !== u.investmentsCount) changes.investmentsCount++;
  if (now && now.ticketSize !== u.ticketSize) changes.ticketSize++;
}

const existing = new Map((await db.collection('tickets').get()).docs.map((d) => [d.id, d.data()]));
for (const t of plan.tickets) {
  const owner = live.get(t.investorId);
  if (!owner) problems.push(`${t.id}: investor ${t.investorId} not found`);
  for (const s of t.sectors) {
    if (!SECTORS.includes(s)) problems.push(`${t.id}: sector "${s}"`);
    if (owner && !(owner.preferredSectors ?? []).includes(s)) problems.push(`${t.id}: sector "${s}" not in the investor's sectors`);
  }
  for (const s of t.stages) {
    if (!STAGES.includes(s)) problems.push(`${t.id}: stage "${s}"`);
    if (owner && !(owner.preferredStages ?? []).includes(s)) problems.push(`${t.id}: stage "${s}" not in the investor's stages`);
  }
  if (!(t.amountMin > 0 && t.amountMax > t.amountMin)) problems.push(`${t.id}: amount ${t.amountMin}–${t.amountMax}`);
  if (existing.has(t.id) && existing.get(t.id).isSample !== true) problems.push(`${t.id}: a real ticket already has this id`);
}

console.log(`Dataset investors to update: ${plan.updates.length}`);
console.log(`  investmentsCount changes: ${changes.investmentsCount}`);
console.log(`  ticketSize changes: ${changes.ticketSize}`);
console.log(`Tickets to write: ${plan.tickets.length} (already in Firebase: ${existing.size})`);
console.log('\nExamples:');
for (const u of plan.updates.slice(0, 3)) {
  const now = live.get(u.id) ?? {};
  console.log(`  ${u.id}: investmentsCount "${now.investmentsCount}" -> "${u.investmentsCount}", ticketSize "${now.ticketSize}" -> "${u.ticketSize}"`);
}

if (problems.length) {
  console.log(`\nStopped, ${problems.length} problem(s):`);
  for (const p of problems) console.log('  ' + p);
  process.exit(1);
}
if (!write) {
  console.log('\nDry run: nothing was written. Add --write to apply.');
  process.exit(0);
}

// batches of at most 400 writes
let batch = db.batch();
let n = 0;
const flush = async () => {
  if (n) await batch.commit();
  batch = db.batch();
  n = 0;
};
for (const u of plan.updates) {
  batch.update(db.collection('investors').doc(u.id), {
    investmentsCount: u.investmentsCount,
    ticketSize: u.ticketSize,
  });
  if (++n === 400) await flush();
}
for (const t of plan.tickets) {
  const { id, createdAt, ...rest } = t;
  batch.set(db.collection('tickets').doc(id), { ...rest, createdAt: Timestamp.fromDate(new Date(createdAt)) });
  if (++n === 400) await flush();
}
await flush();
console.log(`\nDone: ${plan.updates.length} investors updated, ${plan.tickets.length} tickets written.`);
