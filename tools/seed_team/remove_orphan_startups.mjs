// Removes the "orphan" startups: startups made by a real account (not the
// dataset) whose owner's sign-in account no longer exists. Startups of a
// current account are never touched, nor are the dataset startups.
//
//   node remove_orphan_startups.mjs <service-account.json> [--write]
//
// Without --write it only prints what it would do. With --write it first
// saves every startup (and its funding rounds and invitations) to
// backups/orphans_<time>.json, then deletes them:
//   - startups/{id} and its fundingRounds,
//   - the invitations that point to the startup.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import fs from 'fs';

const [keyPath] = process.argv.slice(2);
const WRITE = process.argv.includes('--write');
if (!keyPath) {
  console.log('Usage: node remove_orphan_startups.mjs <service-account.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();
const auth = getAuth();

const alive = new Map();
async function accountExists(uid) {
  if (!alive.has(uid)) {
    try { await auth.getUser(uid); alive.set(uid, true); } catch { alive.set(uid, false); }
  }
  return alive.get(uid);
}

const snap = await db.collection('startups').get();
const orphans = [];
for (const d of snap.docs) {
  const v = d.data();
  if (v.founderId === 'crunchbase-dataset') continue; // the dataset: never
  if (typeof v.founderId !== 'string' || v.founderId.startsWith('seed-')) continue;
  if (await accountExists(v.founderId)) continue; // a current account: leave it
  orphans.push(d);
}

console.log(`Orphan startups found: ${orphans.length}`);
if (orphans.length > 25) {
  console.log('That is more than expected (13). Stopping: nothing was changed.');
  process.exit(1);
}

const backup = {};
for (const d of orphans) {
  const v = d.data();
  const rounds = await d.ref.collection('fundingRounds').get();
  const invs = await db.collection('invitations').where('startupId', '==', d.id).get();
  backup[d.id] = {
    startup: v,
    rounds: Object.fromEntries(rounds.docs.map((r) => [r.id, r.data()])),
    invitations: Object.fromEntries(invs.docs.map((i) => [i.id, i.data()])),
  };
  console.log(`- ${v.name} (${d.id}) | public: ${v.isPublic} | members: ${(v.memberIds || []).length} | rounds: ${rounds.size} | invitations: ${invs.size}`);
}

if (!WRITE) {
  console.log('Dry run. Add --write to back them up and delete them.');
  process.exit(0);
}

fs.mkdirSync('backups', { recursive: true });
const file = `backups/orphans_${Date.now()}.json`;
fs.writeFileSync(file, JSON.stringify(backup, null, 2));
console.log(`Backup written: ${file}`);

for (const d of orphans) {
  const b = backup[d.id];
  const batch = db.batch();
  for (const rid of Object.keys(b.rounds)) batch.delete(d.ref.collection('fundingRounds').doc(rid));
  for (const iid of Object.keys(b.invitations)) batch.delete(db.collection('invitations').doc(iid));
  batch.delete(d.ref);
  await batch.commit();
}
console.log(`Deleted ${orphans.length} orphan startups.`);
