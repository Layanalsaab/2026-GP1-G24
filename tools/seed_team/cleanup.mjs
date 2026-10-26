// Undoes seed_team.mjs: puts the ORIGINAL teamMembers back (from the backup
// file) and deletes the sample profiles (isSample == true, id "seed-...").
//
//   node cleanup.mjs <service-account.json> <backups/teams_before_XXX.json> [--write]
//
// Without --write it only prints what it would do.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import fs from 'fs';

const [keyPath, backupPath] = process.argv.slice(2);
const WRITE = process.argv.includes('--write');
if (!keyPath || !backupPath) {
  console.log('Usage: node cleanup.mjs <service-account.json> <backup.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();
const backup = JSON.parse(fs.readFileSync(backupPath, 'utf8'));
const profiles = (await db.collection('publicProfiles').where('isSample', '==', true).get()).docs
  .filter((d) => d.id.startsWith('seed-'));
console.log(JSON.stringify({ startupsToRestore: Object.keys(backup).length, sampleProfilesToDelete: profiles.length, mode: WRITE ? 'WRITE' : 'DRY RUN' }));
if (!WRITE) process.exit(0);
let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const [id, team] of Object.entries(backup)) {
  batch.update(db.collection('startups').doc(id), { teamMembers: team });
  if (++ops >= 400) await flush();
}
for (const d of profiles) {
  batch.delete(d.ref);
  if (++ops >= 400) await flush();
}
await flush();
console.log('Restored.');
