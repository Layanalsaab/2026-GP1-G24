// READ-ONLY consistency scan of the live database. Writes nothing.
//   node audit_consistency.mjs <service-account.json>
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import fs from 'fs';

const [keyPath] = process.argv.slice(2);
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();
const auth = getAuth();

const problems = {};
const add = (kind, msg) => (problems[kind] ??= []).push(msg);

const authUsers = new Map();
let page;
do {
  page = await auth.listUsers(1000, page?.pageToken);
  for (const u of page.users) authUsers.set(u.uid, u);
} while (page.pageToken);

const get = async (c) => (await db.collection(c).get()).docs;
const users = await get('users');
const publics = await get('publicProfiles');
const investors = await get('investors');
const startups = await get('startups');
const invitations = await get('invitations');
const emailIndex = await get('emailIndex');
const inviteEmails = await get('inviteEmails');

const userIds = new Set(users.map((d) => d.id));
const publicIds = new Set(publics.map((d) => d.id));
const startupIds = new Set(startups.map((d) => d.id));
const emailRe = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const ROLES = new Set(['founder', 'investor']);
const MEMBER_ROLES = new Set(['founder', 'coFounder', 'member']);
const INV_STATUS = new Set(['pending', 'accepted', 'declined', 'cancelled', 'revoked']);

console.log(`auth ${authUsers.size} | users ${users.length} | publicProfiles ${publics.length} | investors ${investors.length} | startups ${startups.length} | invitations ${invitations.length} | emailIndex ${emailIndex.length} | inviteEmails ${inviteEmails.length}`);

// ---- users
for (const d of users) {
  const v = d.data();
  if (!authUsers.has(d.id)) add('users without a sign-in account', d.id + ' ' + (v.email ?? ''));
  if (!publicIds.has(d.id)) add('users without a publicProfile', d.id + ' ' + (v.email ?? ''));
  if (!v.email || !emailRe.test(v.email)) add('users with a bad e-mail', d.id + ' ' + v.email);
  if (v.email && v.email !== v.email.toLowerCase()) add('users e-mail not lowercase', d.id + ' ' + v.email);
  if (!v.role) add('users without role', d.id); else if (!ROLES.has(v.role)) add('users with an odd role', d.id + ' ' + v.role);
  if (!v.fullName?.trim?.()) add('users without a full name', d.id);
  if (v.fullName && /\d/.test(v.fullName)) add('users name has a digit', d.id + ' ' + v.fullName);
  if (v.role === 'investor' && !investors.find((i) => i.id === d.id)) add('investor users without investors doc', d.id + ' ' + v.email);
  if (v.role === 'founder' && investors.find((i) => i.id === d.id)) add('founder users WITH investors doc', d.id + ' ' + v.email);
}
for (const [uid, u] of authUsers) if (!userIds.has(uid)) add('sign-in accounts without users doc', uid + ' ' + u.email);

// ---- publicProfiles
for (const d of publics) {
  const v = d.data();
  const isSample = v.isSample === true || d.id.startsWith('seed-');
  if (!isSample && !userIds.has(d.id)) add('publicProfiles without an account (not sample)', d.id + ' ' + (v.fullName ?? ''));
  if (!v.fullName?.trim?.()) add('publicProfiles without a name', d.id);
  if (v.fullName && /\d/.test(v.fullName)) add('publicProfiles name has a digit', d.id + ' ' + v.fullName);
  if (v.photoData && typeof v.photoData === 'string' && v.photoData.length > 150000) add('photoData too large', d.id);
  const u = users.find((x) => x.id === d.id)?.data();
  if (u) {
    if (v.email && v.email !== u.email) add('publicProfile e-mail differs from users', d.id);
    if (v.email && u.emailPublic === false) add('publicProfile shows an e-mail the user made private', d.id);
    if (v.phone && u.phonePublic === false) add('publicProfile shows a phone the user made private', d.id);
  }
}

// ---- investors
for (const d of investors) {
  if (!userIds.has(d.id) && !d.data().isSample && !d.id.startsWith('ANG-')) add('investors doc without account', d.id + ' ' + (d.data().name ?? ''));
}

// ---- startups
const emailsOfUsers = new Map(users.map((d) => [d.data().email, d.id]));
for (const d of startups) {
  const v = d.data();
  const tag = `${d.id} "${v.name}"`;
  const dataset = v.founderId === 'crunchbase-dataset';
  if (!v.name?.trim?.()) add('startups without name', d.id);
  if (!v.sector) add('startups without sector', tag);
  if (!v.stage) add('startups without stage', tag);
  if (!v.businessModel) add('startups without businessModel', tag);
  if (!v.location) add('startups without location', tag);
  if (typeof v.isPublic !== 'boolean') add('startups isPublic not boolean', tag);
  if (!dataset && !userIds.has(v.founderId)) add('startups whose founder has no account', tag + ' founder=' + v.founderId);
  if (!dataset && v.sector === 'other' && !v.sectorOther?.trim?.()) add('sector other without text', tag);
  if (v.sector !== 'other' && v.sectorOther) add('sectorOther set but sector is not other', tag);
  if (v.otherSectors && !Array.isArray(v.otherSectors)) add('otherSectors not a list', tag);
  if (Array.isArray(v.otherSectors) && v.otherSectors.includes(v.sector)) add('otherSectors repeats main sector', tag);
  const team = v.teamMembers ?? [];
  const mids = v.memberIds ?? [];
  const roles = v.memberRoles ?? {};
  const seenUid = new Set();
  const seenEmail = new Set();
  for (const m of team) {
    if (!(m.fullName ?? m.name)?.trim?.()) add('team member without name', tag);
    if (m.uid) {
      if (seenUid.has(m.uid)) add('duplicate team member uid', tag + ' ' + m.uid);
      seenUid.add(m.uid);
      if (!m.uid.startsWith('seed-') && !dataset && !userIds.has(m.uid)) add('team member uid without account', tag + ' ' + m.uid + ' ' + (m.fullName ?? m.name));
    }
    if (m.email) {
      const e = m.email.toLowerCase();
      if (seenEmail.has(e)) add('duplicate team member e-mail', tag + ' ' + e);
      seenEmail.add(e);
    }
  }
  for (const id of mids) {
    if (!roles[id]) add('memberIds without memberRoles', tag + ' ' + id);
    else if (!MEMBER_ROLES.has(roles[id])) add('odd memberRole', tag + ' ' + roles[id]);
    if (!userIds.has(id)) add('memberIds without account', tag + ' ' + id);
    if (!team.some((m) => m.uid === id)) add('memberIds without a team card', tag + ' ' + id);
  }
  for (const id of Object.keys(roles)) if (!mids.includes(id)) add('memberRoles without memberIds', tag + ' ' + id);
  if (!dataset) {
    if (!team.some((m) => m.uid === v.founderId || m.isFounder)) add('startup without founder card', tag);
    if (mids.includes(v.founderId)) add('founder listed among memberIds', tag);
  }
  if (v.logoData && v.logoData.length > 150000) add('logoData too large', tag);
}

// ---- invitations
for (const d of invitations) {
  const v = d.data();
  const idOk = d.id === `${v.startupId}~${v.emailLower}`;
  if (!idOk) add('invitation id mismatch', d.id);
  if (!startupIds.has(v.startupId)) add('invitation for a missing startup', d.id);
  if (!INV_STATUS.has(v.status)) add('invitation odd status', d.id + ' ' + v.status);
  if (!emailRe.test(v.emailLower ?? '')) add('invitation bad e-mail', d.id);
  if (v.status === 'pending' && emailsOfUsers.has(v.emailLower)) {
    const uid = emailsOfUsers.get(v.emailLower);
    const st = startups.find((s) => s.id === v.startupId)?.data();
    if (st && ((st.memberIds ?? []).includes(uid) || st.founderId === uid)) add('pending invitation for someone already in the team', d.id);
  }
  if (v.status === 'accepted') {
    const uid = emailsOfUsers.get(v.emailLower);
    const st = startups.find((s) => s.id === v.startupId)?.data();
    if (uid && st && !(st.memberIds ?? []).includes(uid) && st.founderId !== uid) add('accepted invitation but person is not in the team', d.id);
  }
}

// ---- emailIndex / inviteEmails
for (const d of emailIndex) {
  const uid = d.data().uid;
  if (uid && !userIds.has(uid) && !publicIds.has(uid)) add('emailIndex points to nothing', d.id + ' -> ' + uid);
}
for (const d of inviteEmails) {
  if (!emailRe.test(d.id)) add('inviteEmails odd id', d.id);
}

// ---- funding rounds (user startups only)
for (const s of startups) {
  const v = s.data();
  if (v.founderId === 'crunchbase-dataset') continue;
  const rounds = await s.ref.collection('fundingRounds').get();
  const open = rounds.docs.filter((r) => r.data().status === 'active');
  if (open.length > 1) add('startup with more than one open round', `${s.id} "${v.name}"`);
  for (const r of rounds.docs) {
    const rv = r.data();
    if (rv.startupId && rv.startupId !== s.id) add('round startupId mismatch', `${s.id}/${r.id}`);
    if (rv.raised != null && rv.amount != null && rv.raised > rv.amount) add('round raised more than target', `${s.id}/${r.id}`);
  }
}

let total = 0;
for (const [k, list] of Object.entries(problems)) {
  total += list.length;
  console.log(`\n## ${k} (${list.length})`);
  for (const m of list.slice(0, 12)) console.log('  - ' + m);
  if (list.length > 12) console.log(`  ... and ${list.length - 12} more`);
}
console.log(total ? `\n${total} finding(s).` : '\nNo inconsistencies found.');
