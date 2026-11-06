// READ-ONLY copy of the `investors` and `startups` collections. Writes nothing.
//
// MAKES
//   output/investors_backup.json   exact copy (timestamps kept as text)
//   output/investors.csv           the same data as a table
//   output/startups.json           the startups, so generate.mjs can fit tickets to real rounds
// and lists any sector, stage, model, ticket size or investments count that
// isn't one of the app's options.
//
// USAGE
//   node export_investors.mjs <service-account.json>
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import fs from 'fs';

const [keyPath] = process.argv.slice(2);
if (!keyPath) {
  console.log('node export_investors.mjs <service-account.json>');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

// lib/recommender/knowledge_filter.dart
const SECTORS = ['HealthTech', 'Fintech', 'EdTech', 'E-commerce', 'Logistics', 'AgriTech',
  'PropTech', 'CleanTech', 'Tourism', 'SaaS', 'AI', 'Cybersecurity', 'Gaming', 'Media',
  'FoodTech', 'Mobility', 'Retail', 'Energy', 'InsurTech', 'LegalTech', 'HR Tech', 'Biotech',
  'Manufacturing', 'Sports', 'Other'];
const STAGES = ['Pre-seed', 'Seed', 'Series A', 'Series B', 'Series C', 'Other'];
const MODELS = ['Business-to-Government (B2G)', 'Business-to-Business (B2B)',
  'Business-to-Business-to-Consumer (B2B2C)', 'Direct-to-Consumer (D2C)',
  'Business-to-Consumer (B2C)', 'Consumer-to-Consumer (C2C)', 'Business-to-Employee (B2E)',
  'Consumer-to-Business (C2B)', 'Government-to-Citizen (G2C)', 'Government-to-Government (G2G)',
  'Other'];
const TICKETS = ['Under SAR 100K', 'SAR 100K – 500K', 'SAR 500K – 1M', 'SAR 1M – 5M',
  'Over SAR 5M', 'Other'];
// lib/models/investor_criteria.dart (dealsOptions, ticketOptions)
const COUNTS = ['0', '1–3', '4–6', '7–9', '10+'];

// timestamps as text so they fit in JSON
const plain = (v) => {
  if (v instanceof Timestamp) return { __timestamp: v.toDate().toISOString() };
  if (Array.isArray(v)) return v.map(plain);
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, plain(x)]));
  return v;
};

const snap = await db.collection('investors').get();
const docs = snap.docs.map((d) => ({ id: d.id, data: plain(d.data()) }));
docs.sort((a, b) => a.id.localeCompare(b.id));

fs.mkdirSync('output', { recursive: true });
fs.writeFileSync('output/investors_backup.json', JSON.stringify(docs, null, 2));

// one column per field, lists joined with " | "
const fields = [...new Set(docs.flatMap((d) => Object.keys(d.data)))].sort();
const cell = (v) => {
  if (v === undefined || v === null) return '';
  if (Array.isArray(v)) v = v.join(' | ');
  else if (typeof v === 'object') v = v.__timestamp ?? JSON.stringify(v);
  const s = String(v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
const rows = [['id', ...fields].join(',')];
for (const d of docs) rows.push([d.id, ...fields.map((f) => cell(d.data[f]))].join(','));
// BOM so Excel reads the long dash (–) correctly
fs.writeFileSync('output/investors.csv', '﻿' + rows.join('\n'));

// checks
const problems = [];
const check = (id, field, values, allowed) => {
  for (const v of [].concat(values ?? [])) {
    if (!allowed.includes(v)) problems.push(`${id}: ${field} has "${v}"`);
  }
};
const counts = {};
for (const { id, data } of docs) {
  check(id, 'preferredSectors', data.preferredSectors, SECTORS);
  check(id, 'preferredStages', data.preferredStages, STAGES);
  check(id, 'preferredCommerceModels', data.preferredCommerceModels, MODELS);
  if (data.ticketSize != null) check(id, 'ticketSize', data.ticketSize, TICKETS);
  if (data.investmentsCount != null) check(id, 'investmentsCount', data.investmentsCount, COUNTS);
  for (const f of Object.keys(data)) counts[f] = (counts[f] ?? 0) + 1;
}

console.log(`Investors: ${docs.length}`);
console.log(`  dataset (ANG-...): ${docs.filter((d) => d.id.startsWith('ANG-')).length}`);
console.log(`  others (signed up in the app): ${docs.filter((d) => !d.id.startsWith('ANG-')).length}`);
console.log('\nFields (how many investors have each):');
for (const f of fields) console.log(`  ${f}: ${counts[f]}`);
console.log(problems.length ? `\nValues not in the app's lists (${problems.length}):` : '\nAll values match the app\'s lists.');
for (const p of problems) console.log('  ' + p);
const startups = (await db.collection('startups').get()).docs
  .map((d) => ({ id: d.id, data: plain(d.data()) }))
  .sort((a, b) => a.id.localeCompare(b.id));
fs.writeFileSync('output/startups.json', JSON.stringify(startups, null, 2));
const raising = startups.filter((s) => (s.data.lookingFor ?? []).includes('funding') && (s.data.fundingRequirement ?? 0) > 0);
console.log(`\nStartups: ${startups.length} (raising: ${raising.length})`);

console.log('\nSaved output/investors_backup.json, output/investors.csv and output/startups.json');
