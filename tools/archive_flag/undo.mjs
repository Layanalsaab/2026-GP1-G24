// Undoes migrate.mjs: puts isArchived and isDataset back exactly as they were
// (from output/backup.json).
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
if (!fs.existsSync('output/backup.json')) {
  console.log('No output/backup.json, so there is nothing to undo.');
  process.exit(1);
}
const write = flag === '--write';
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

const backup = JSON.parse(fs.readFileSync('output/backup.json', 'utf8'));
console.log(`Documents to restore: ${backup.length}`);
if (!write) {
  console.log('Dry run: nothing was written. Add --write to apply.');
  process.exit(0);
}

let batch = db.batch();
let n = 0;
for (const b of backup) {
  batch.update(db.doc(b.path), {
    isArchived: b.hadIsArchived ? b.isArchived : FieldValue.delete(),
    isDataset: b.hadIsDataset ? b.isDataset : FieldValue.delete(),
  });
  if (++n === 400) {
    await batch.commit();
    batch = db.batch();
    n = 0;
  }
}
if (n) await batch.commit();
console.log('Restored.');
