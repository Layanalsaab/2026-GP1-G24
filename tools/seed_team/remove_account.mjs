// Removes ONE account (by e-mail) from everywhere:
//   - the sign-in account (Authentication),
//   - users/{uid} (+ its bookmarks), publicProfiles/{uid}, investors/{uid},
//     emailIndex/{email}, inviteEmails/{email},
//   - every startup the account FOUNDED (with its funding rounds and the
//     invitations that point to it),
//   - the account's card and membership on startups that belong to OTHER
//     people (those startups stay),
//   - the invitations the account sent or received.
//
//   node remove_account.mjs <service-account.json> <email> [--write]
//
// Without --write it only prints what it would do. With --write it first
// saves everything it is about to delete to backups/account_<time>.json.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import fs from 'fs';

const [keyPath, rawEmail] = process.argv.slice(2);
const WRITE = process.argv.includes('--write');
if (!keyPath || !rawEmail || rawEmail.startsWith('--')) {
  console.log('Usage: node remove_account.mjs <service-account.json> <email> [--write]');
  process.exit(1);
}
const email = rawEmail.trim().toLowerCase();
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();
const auth = getAuth();

let uid = null;
try { uid = (await auth.getUserByEmail(email)).uid; } catch { /* no sign-in account */ }
// An older `users` record of the same e-mail whose sign-in account was deleted
// earlier (a different uid) belongs to this e-mail too.
const staleUids = [];
for (const d of (await db.collection('users').where('email', '==', email).get()).docs) {
  if (d.id !== uid) staleUids.push(d.id);
}
const uids = [uid, ...staleUids].filter(Boolean);
console.log(`E-mail: ${email} | sign-in account: ${uid ?? 'none'}${staleUids.length ? ` | older records: ${staleUids.join(', ')}` : ''}`);

const backup = { email, uid, docs: {}, startups: {}, invitations: {}, cardsRemovedFrom: {} };
const plan = []; // human lines
const deletes = []; // refs
const updates = []; // [ref, data]

async function planDoc(path) {
  const ref = db.doc(path);
  const d = await ref.get();
  if (!d.exists) return;
  backup.docs[path] = d.data();
  deletes.push(ref);
  plan.push(`delete ${path}`);
}

for (const u of uids) {
  await planDoc(`users/${u}`);
  const bm = await db.collection('users').doc(u).collection('bookmarks').get();
  for (const b of bm.docs) { backup.docs[`users/${u}/bookmarks/${b.id}`] = b.data(); deletes.push(b.ref); }
  if (bm.size) plan.push(`delete ${bm.size} bookmarks`);
  await planDoc(`publicProfiles/${u}`);
  await planDoc(`investors/${u}`);
}
await planDoc(`emailIndex/${email}`);
await planDoc(`inviteEmails/${email}`);

const invitationIds = new Set();
const addInvitations = async (snap) => {
  for (const i of snap.docs) {
    if (invitationIds.has(i.id)) continue;
    invitationIds.add(i.id);
    backup.invitations[i.id] = i.data();
    deletes.push(i.ref);
    plan.push(`delete invitations/${i.id}`);
  }
};
await addInvitations(await db.collection('invitations').where('emailLower', '==', email).get());
for (const u of uids) await addInvitations(await db.collection('invitations').where('invitedBy', '==', u).get());

const all = await db.collection('startups').get();
for (const s of all.docs) {
  const v = s.data();
  if (v.founderId === 'crunchbase-dataset') continue; // the dataset: never
  if (uids.includes(v.founderId)) {
    backup.startups[s.id] = { startup: v, rounds: {} };
    const rounds = await s.ref.collection('fundingRounds').get();
    for (const r of rounds.docs) { backup.startups[s.id].rounds[r.id] = r.data(); deletes.push(r.ref); }
    await addInvitations(await db.collection('invitations').where('startupId', '==', s.id).get());
    deletes.push(s.ref);
    plan.push(`delete startup "${v.name}" (${s.id}) with ${rounds.size} rounds`);
    continue;
  }
  const team = v.teamMembers || [];
  const mine = team.filter((m) => uids.includes(m.uid) || (m.email || '').toLowerCase() === email);
  const isMember = uids.some((u) => (v.memberIds || []).includes(u));
  if (mine.length || isMember) {
    backup.cardsRemovedFrom[s.id] = { name: v.name, teamMembers: team, memberIds: v.memberIds, memberRoles: v.memberRoles };
    const data = { teamMembers: team.filter((m) => !mine.includes(m)) };
    for (const u of uids) {
      data.memberIds = FieldValue.arrayRemove(...uids);
      data[`memberRoles.${u}`] = FieldValue.delete();
    }
    updates.push([s.ref, data]);
    plan.push(`remove the account from "${v.name}" (${s.id}): ${mine.length} card(s)${isMember ? ' + membership' : ''}`);
  }
}
if (uid) plan.push('delete the sign-in account');

console.log(plan.length ? plan.map((p) => ' - ' + p).join('\n') : 'Nothing found.');
if (!WRITE) {
  console.log('Dry run. Add --write to back up and delete.');
  process.exit(0);
}

fs.mkdirSync('backups', { recursive: true });
const file = `backups/account_${Date.now()}.json`;
fs.writeFileSync(file, JSON.stringify(backup, null, 2));
console.log(`Backup written: ${file}`);

for (const [ref, data] of updates) await ref.update(data);
let batch = db.batch(), n = 0;
for (const ref of deletes) {
  batch.delete(ref);
  if (++n >= 400) { await batch.commit(); batch = db.batch(); n = 0; }
}
if (n) await batch.commit();
if (uid) await auth.deleteUser(uid);
console.log('Done. The e-mail is free again.');
