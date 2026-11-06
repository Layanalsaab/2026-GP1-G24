// Undoes upload.mjs: puts the ORIGINAL investmentsCount and ticketSize back
// (from output/investors_backup.json) and deletes the sample tickets
// (isSample == true).
//
//   node undo.mjs <service-account.json> [--write]
//
// Without --write it only prints what it would do.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';

const [keyPath, flag] = process.argv.slice(2);
if (!keyPath) {
  console.log('node undo.mjs <service-account.json> [--write]');
  process.exit(1);
}
const write = flag === '--write';
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const backup = JSON.parse(fs.readFileSync('output/investors_backup.json', 'utf8'))
  .filter((d) => d.data.isDataset === true);
const samples = (await db.collection('tickets').where('isSample', '==', true).get()).docs;

console.log(`Investors to restore: ${backup.length}`);
console.log(`Sample tickets to delete: ${samples.length}`);
if (!write) {
  console.log('\nDry run: nothing was written. Add --write to apply.');
  process.exit(0);
}

let batch = db.batch();
let n = 0;
const flush = async () => {
  if (n) await batch.commit();
  batch = db.batch();
  n = 0;
};
// a field that wasn't there before is removed again
const old = (v) => (v === undefined ? FieldValue.delete() : v);
for (const { id, data } of backup) {
  batch.update(db.collection('investors').doc(id), {
    investmentsCount: old(data.investmentsCount),
    ticketSize: old(data.ticketSize),
  });
  if (++n === 400) await flush();
}
for (const d of samples) {
  batch.delete(d.ref);
  if (++n === 400) await flush();
}
await flush();
console.log('\nDone.');
