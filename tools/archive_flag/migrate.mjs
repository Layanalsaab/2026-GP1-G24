// Gives every startup, investor and funding round an `isArchived` field:
// true for the ones imported from the dataset (Crunchbase), false for the
// ones made in the app. The old `isDataset` field (investors and rounds) is
// removed, because isArchived replaces it.
//
// HOW IT DECIDES
//   startups:  founderId == "crunchbase-dataset"            -> true
//   investors: isDataset == true (the "ANG-..." documents)   -> true
//   rounds:    isDataset == true                             -> true
//   everything else                                          -> false
// It also checks the result against the real accounts in Authentication and
// against each other, and stops before writing if anything disagrees.
//
// WHAT IT TOUCHES (and nothing else):
//   only the fields isArchived and isDataset of `startups`, `investors` and
//   every `startups/*/fundingRounds` document.
//
// USAGE
//   node migrate.mjs <service-account.json>            (dry run: writes nothing)
//   node migrate.mjs <service-account.json> --write    (really writes)
//
// Before writing, the old values are saved to output/backup.json, which
// undo.mjs puts back.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import fs from 'fs';

const [keyPath, flag] = process.argv.slice(2);
if (!keyPath) {
  console.log('node migrate.mjs <service-account.json> [--write]');
  process.exit(1);
}
const write = flag === '--write';
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();
const DATASET_OWNER = 'crunchbase-dataset';

// ---- real accounts (Authentication) ----
const accounts = new Set();
let pageToken;
do {
  const page = await getAuth().listUsers(1000, pageToken);
  page.users.forEach((u) => accounts.add(u.uid));
  pageToken = page.pageToken;
} while (pageToken);

// ---- read everything ----
const startups = (await db.collection('startups').get()).docs;
const investors = (await db.collection('investors').get()).docs;
const rounds = (await db.collectionGroup('fundingRounds').get()).docs;

const problems = []; // stop the write
const notes = []; // only shown
const plan = []; // { ref, path, value, before }

const datasetStartup = new Map(); // startup id -> true / false
for (const d of startups) {
  const x = d.data();
  const value = x.founderId === DATASET_OWNER;
  datasetStartup.set(d.id, value);
  if (!value && x.founderId && !accounts.has(x.founderId)) {
    notes.push(`startup ${d.id} "${x.name}": its founder ${x.founderId} has no account (kept as NOT archived)`);
  }
  if (!value && !x.founderId) {
    notes.push(`startup ${d.id} "${x.name}": has no owner (kept as NOT archived)`);
  }
  plan.push({ ref: d.ref, path: d.ref.path, value, before: x });
}

for (const d of investors) {
  const x = d.data();
  const value = x.isDataset === true;
  if (value && accounts.has(d.id)) problems.push(`investor ${d.id}: marked dataset but is a real account`);
  if (!value && d.id.startsWith('ANG-')) problems.push(`investor ${d.id}: looks like a dataset investor (ANG-) but isDataset is not true`);
  if (!value && !accounts.has(d.id)) notes.push(`investor ${d.id} "${x.fullName}": no account in Authentication (kept as NOT archived)`);
  plan.push({ ref: d.ref, path: d.ref.path, value, before: x });
}

for (const d of rounds) {
  const x = d.data();
  const value = x.isDataset === true;
  const startupId = d.ref.parent.parent.id;
  const parent = datasetStartup.get(startupId);
  if (parent === undefined) notes.push(`round ${d.ref.path}: its startup no longer exists`);
  else if (parent !== value) problems.push(`round ${d.ref.path}: isDataset=${x.isDataset} but its startup is ${parent ? '' : 'NOT '}a dataset startup`);
  plan.push({ ref: d.ref, path: d.ref.path, value, before: x });
}

// ---- report ----
const count = (prefix, v) => plan.filter((p) => p.path.startsWith(prefix) && !p.path.includes('/fundingRounds/') && p.value === v).length;
const roundCount = (v) => plan.filter((p) => p.path.includes('/fundingRounds/') && p.value === v).length;
console.log(`Accounts in Authentication: ${accounts.size}`);
console.log(`Startups:  ${startups.length}  -> archived ${count('startups/', true)}, not archived ${count('startups/', false)}`);
console.log(`Investors: ${investors.length}  -> archived ${count('investors/', true)}, not archived ${count('investors/', false)}`);
console.log(`Rounds:    ${rounds.length}  -> archived ${roundCount(true)}, not archived ${roundCount(false)}`);
const changes = plan.filter((p) => p.before.isArchived !== p.value || 'isDataset' in p.before);
console.log(`Documents that will change: ${changes.length}`);

console.log('\nNot archived (made in the app):');
for (const p of plan) {
  if (p.value) continue;
  const label = p.before.name ?? p.before.fullName ?? `${p.before.stage ?? ''} round`;
  console.log(`  ${p.path}  ${label}`);
}

if (notes.length) {
  console.log(`\nWorth a look (${notes.length}), nothing wrong with the write:`);
  notes.forEach((n) => console.log('  - ' + n));
}
if (problems.length) {
  console.log(`\nSTOPPED: ${problems.length} problem(s). Nothing was written:`);
  problems.forEach((p) => console.log('  - ' + p));
  process.exit(1);
}
if (!write) {
  console.log('\nDry run: nothing was written. Add --write to apply.');
  process.exit(0);
}

// ---- backup, then write ----
fs.mkdirSync('output', { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const backup = changes.map((p) => ({
  path: p.path,
  isArchived: 'isArchived' in p.before ? p.before.isArchived : null,
  hadIsArchived: 'isArchived' in p.before,
  isDataset: 'isDataset' in p.before ? p.before.isDataset : null,
  hadIsDataset: 'isDataset' in p.before,
}));
fs.writeFileSync('output/backup.json', JSON.stringify(backup, null, 1));
fs.writeFileSync(`output/backup-${stamp}.json`, JSON.stringify(backup, null, 1));
console.log(`\nBackup saved: output/backup.json (${backup.length} documents)`);

let batch = db.batch();
let n = 0;
let done = 0;
for (const p of changes) {
  const update = { isArchived: p.value };
  if ('isDataset' in p.before) update.isDataset = FieldValue.delete();
  batch.update(p.ref, update);
  n++;
  if (n === 400) {
    await batch.commit();
    done += n;
    batch = db.batch();
    n = 0;
    console.log(`  written ${done}`);
  }
}
if (n) await batch.commit();
done += n;
console.log(`Done: ${done} documents updated.`);
