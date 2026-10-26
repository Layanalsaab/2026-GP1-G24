// Removes the leftovers of accounts that were DELETED before the app removed
// them from teams by itself: for every startup, a team member (or member /
// co-founder id) whose Firebase Auth account no longer exists is taken out of
// teamMembers, memberIds and memberRoles; their emailIndex entry, public
// profile and invitations to that e-mail are deleted.
//
//   node remove_deleted_members.mjs <service-account.json> [--write]
//
// Without --write it only prints what it would do. Sample people (ids that
// start with "seed-") and the dataset startups are never touched.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import fs from 'fs';

const [keyPath] = process.argv.slice(2);
const WRITE = process.argv.includes('--write');
if (!keyPath) {
  console.log('Usage: node remove_deleted_members.mjs <service-account.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();
const auth = getAuth();

const exists = new Map();
async function accountExists(uid) {
  if (!exists.has(uid)) {
    try { await auth.getUser(uid); exists.set(uid, true); } catch { exists.set(uid, false); }
  }
  return exists.get(uid);
}

const snap = await db.collection('startups').get();
let changed = 0;
for (const doc of snap.docs) {
  const s = doc.data();
  if (s.founderId === 'crunchbase-dataset') continue; // dataset startups: never
  const ids = new Set([...(s.memberIds || []), ...(s.teamMembers || []).map((m) => m.uid).filter(Boolean)]);
  const gone = [];
  for (const uid of ids) {
    if (uid.startsWith('seed-') || uid === s.founderId) continue;
    if (!(await accountExists(uid))) gone.push(uid);
  }
  if (!gone.length) continue;
  changed++;
  const cards = (s.teamMembers || []).filter((m) => gone.includes(m.uid));
  console.log(`${s.name} (${doc.id}): removing ${cards.map((m) => `${m.fullName} <${m.email || ''}>`).join(', ') || gone.join(', ')}`);
  if (!WRITE) continue;
  const update = {
    memberIds: FieldValue.arrayRemove(...gone),
    teamMembers: (s.teamMembers || []).filter((m) => !gone.includes(m.uid)),
  };
  for (const uid of gone) update[`memberRoles.${uid}`] = FieldValue.delete();
  await doc.ref.update(update);
  for (const m of cards) {
    const email = (m.email || '').toLowerCase();
    if (email) {
      await db.collection('emailIndex').doc(email).delete();
      await db.collection('invitations').doc(`${doc.id}~${email}`).delete();
    }
    await db.collection('publicProfiles').doc(m.uid).delete();
  }
}
console.log(WRITE ? `Done. Startups cleaned: ${changed}` : `Dry run. Startups to clean: ${changed}. Add --write to apply.`);
