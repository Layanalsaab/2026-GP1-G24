// Security-rules tests for team invitations (run with the Firestore emulator;
// see README.md).
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  setDoc, getDoc, getDocs, updateDoc, doc, collection, query, where,
  writeBatch, serverTimestamp, arrayUnion, deleteField,
} from 'firebase/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const rules = fs.readFileSync(path.join(here, '..', '..', 'firestore.rules'), 'utf8');
const env = await initializeTestEnvironment({
  projectId: 'demo-inv',
  firestore: { rules, host: '127.0.0.1', port: 8080 },
});

let fails = 0;
async function check(label, expectOk, fn) {
  let ok = true;
  try { await fn(); } catch (e) { ok = false; }
  const good = ok === expectOk;
  if (!good) fails++;
  console.log(good ? 'PASS' : 'FAIL', (expectOk ? '[allow] ' : '[deny]  ') + label);
}

const founder = env.authenticatedContext('f1', { email: 'f1@gmail.com', email_verified: true }).firestore();
const coFounder = env.authenticatedContext('c1', { email: 'c1@gmail.com', email_verified: true }).firestore();
const stranger = env.authenticatedContext('x1', { email: 'x1@gmail.com', email_verified: true }).firestore();
const sara = env.authenticatedContext('s1', { email: 'Sara@Gmail.com', email_verified: true }).firestore();
const saraUnverified = env.authenticatedContext('s1', { email: 'sara@gmail.com', email_verified: false }).firestore();
const anon = env.unauthenticatedContext().firestore();

await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'startups', 'S1'), {
    founderId: 'f1', name: 'Rafeeq', description: 'd', sector: 'fintech', stage: 'seed',
    businessModel: 'b2b', location: 'riyadh', lookingFor: ['funding'], isPublic: true,
    memberIds: ['c1'], memberRoles: { c1: 'coFounder' }, teamMembers: [],
  });
});

const inv = (extra = {}) => ({
  startupId: 'S1', startupName: 'Rafeeq', emailLower: 'sara@gmail.com',
  role: 'coFounder', roleText: 'CTO', contribution: 'Builds', invitedBy: 'f1',
  invitedByName: 'Fahad', status: 'pending', emailSent: false,
  createdAt: serverTimestamp(), ...extra,
});

await check('founder creates an invitation', true, () => setDoc(doc(founder, 'invitations', 'S1~sara@gmail.com'), inv()));
await check('co-founder creates another', true, () => setDoc(doc(coFounder, 'invitations', 'S1~omar@gmail.com'), inv({ emailLower: 'omar@gmail.com', invitedBy: 'c1' })));
await check('stranger cannot create', false, () => setDoc(doc(stranger, 'invitations', 'S1~zed@gmail.com'), inv({ emailLower: 'zed@gmail.com', invitedBy: 'x1' })));
await check('wrong id is refused', false, () => setDoc(doc(founder, 'invitations', 'S1~other'), inv({ emailLower: 'q@gmail.com' })));
await check('claiming to be someone else is refused', false, () => setDoc(doc(founder, 'invitations', 'S1~liar@gmail.com'), inv({ emailLower: 'liar@gmail.com', invitedBy: 'c1' })));
await check('bad role is refused', false, () => setDoc(doc(founder, 'invitations', 'S1~bad@gmail.com'), inv({ emailLower: 'bad@gmail.com', role: 'owner' })));
await check('invalid e-mail is refused', false, () => setDoc(doc(founder, 'invitations', 'S1~nope'), inv({ emailLower: 'nope' })));

await check('anyone can get ONE invitation by id', true, () => getDoc(doc(anon, 'invitations', 'S1~sara@gmail.com')));
await check('nobody can list all invitations', false, () => getDocs(collection(anon, 'invitations')));
await check('invited person lists their own (verified)', true, () => getDocs(query(collection(sara, 'invitations'), where('emailLower', '==', 'sara@gmail.com'), where('status', '==', 'pending'))));
await check('unverified e-mail cannot list', false, () => getDocs(query(collection(saraUnverified, 'invitations'), where('emailLower', '==', 'sara@gmail.com'))));
await check('stranger cannot list someone else\'s', false, () => getDocs(query(collection(stranger, 'invitations'), where('emailLower', '==', 'sara@gmail.com'))));
await check('sender lists what they sent', true, () => getDocs(query(collection(founder, 'invitations'), where('invitedBy', '==', 'f1'))));

await check('founder marks the e-mail sent', true, () => updateDoc(doc(founder, 'invitations', 'S1~sara@gmail.com'), { emailSent: true, lastSentAt: serverTimestamp() }));
await check('stranger cannot cancel', false, () => updateDoc(doc(stranger, 'invitations', 'S1~sara@gmail.com'), { status: 'cancelled' }));

// Sara accepts: the startup and the invitation change together.
await check('accept with the WRONG role is refused', false, async () => {
  const b = writeBatch(sara);
  b.update(doc(sara, 'startups', 'S1'), { memberIds: ['c1', 's1'], memberRoles: { c1: 'coFounder', s1: 'member' }, teamMembers: [], updatedAt: serverTimestamp() });
  b.update(doc(sara, 'invitations', 'S1~sara@gmail.com'), { status: 'accepted', respondedAt: serverTimestamp(), acceptedBy: 's1', acceptedByName: 'Sara Alswailem' });
  await b.commit();
});
await check('accept while unverified is refused', false, async () => {
  const b = writeBatch(saraUnverified);
  b.update(doc(saraUnverified, 'startups', 'S1'), { memberIds: ['c1', 's1'], memberRoles: { c1: 'coFounder', s1: 'coFounder' }, teamMembers: [], updatedAt: serverTimestamp() });
  b.update(doc(saraUnverified, 'invitations', 'S1~sara@gmail.com'), { status: 'accepted', respondedAt: serverTimestamp() });
  await b.commit();
});
await check('stranger cannot join without an invitation', false, () => updateDoc(doc(stranger, 'startups', 'S1'), { memberIds: ['c1', 'x1'], memberRoles: { c1: 'coFounder', x1: 'member' }, teamMembers: [], updatedAt: serverTimestamp() }));
await check('accept ALSO adding someone else is refused', false, () => updateDoc(doc(sara, 'startups', 'S1'), { memberIds: ['c1', 's1', 'evil'], memberRoles: { c1: 'coFounder', s1: 'coFounder', evil: 'coFounder' }, teamMembers: [], updatedAt: serverTimestamp() }));
await check('a co-founder accepting WITHOUT joining coFounderIds is refused', false, () => updateDoc(doc(sara, 'startups', 'S1'), { memberIds: ['c1', 's1'], memberRoles: { c1: 'coFounder', s1: 'coFounder' }, teamMembers: [], updatedAt: serverTimestamp() }));
await check('accept with the right role works', true, async () => {
  const b = writeBatch(sara);
  b.update(doc(sara, 'startups', 'S1'), { memberIds: ['c1', 's1'], memberRoles: { c1: 'coFounder', s1: 'coFounder' }, coFounderIds: ['s1'], teamMembers: [{ fullName: 'Sara', role: 'CTO' }], updatedAt: serverTimestamp() });
  b.update(doc(sara, 'invitations', 'S1~sara@gmail.com'), { status: 'accepted', respondedAt: serverTimestamp() });
  await b.commit();
});
await check('cannot accept twice', false, () => updateDoc(doc(sara, 'invitations', 'S1~sara@gmail.com'), { status: 'accepted', respondedAt: serverTimestamp() }));
await check('decline is allowed for the invited person', true, async () => {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'invitations', 'S1~dina@gmail.com'), { ...inv({ emailLower: 'dina@gmail.com' }), createdAt: new Date(0) }));
  const dina = env.authenticatedContext('d1', { email: 'dina@gmail.com', email_verified: true }).firestore();
  await updateDoc(doc(dina, 'invitations', 'S1~dina@gmail.com'), { status: 'declined', respondedAt: serverTimestamp() });
});
await check('a new-user flag on a new invitation is allowed', true, () => setDoc(doc(founder, 'invitations', 'S1~newbie@gmail.com'), inv({ emailLower: 'newbie@gmail.com', newUser: true })));
await check('a non-boolean new-user flag is refused', false, () => setDoc(doc(founder, 'invitations', 'S1~bad2@gmail.com'), inv({ emailLower: 'bad2@gmail.com', newUser: 'yes' })));
await check('the team re-invites and updates the new-user flag', true, () => updateDoc(doc(founder, 'invitations', 'S1~newbie@gmail.com'), { newUser: false }));
await check('a 60-letter joiner name is refused', false, async () => {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'invitations', 'S1~long@gmail.com'), { ...inv({ emailLower: 'long@gmail.com' }), createdAt: new Date(0) }));
  const longp = env.authenticatedContext('l1', { email: 'long@gmail.com', email_verified: true }).firestore();
  await updateDoc(doc(longp, 'invitations', 'S1~long@gmail.com'), { status: 'accepted', respondedAt: serverTimestamp(), acceptedBy: 'l1', acceptedByName: 'x'.repeat(60) });
});
await check('founder cancels', true, () => updateDoc(doc(founder, 'invitations', 'S1~omar@gmail.com'), { status: 'cancelled' }));

// emailIndex
await check('owner writes their emailIndex (verified)', true, () => setDoc(doc(sara, 'emailIndex', 'sara@gmail.com'), { uid: 's1', fullName: 'Sara', role: 'founder', updatedAt: serverTimestamp() }));
await check('cannot write the index of another e-mail', false, () => setDoc(doc(sara, 'emailIndex', 'boss@gmail.com'), { uid: 's1', fullName: 'Sara', role: 'founder', updatedAt: serverTimestamp() }));
await check('unverified cannot write the index', false, () => setDoc(doc(saraUnverified, 'emailIndex', 'sara@gmail.com'), { uid: 's1', fullName: 'Sara', role: 'founder', updatedAt: serverTimestamp() }));
await check('signed-in user looks one up', true, () => getDoc(doc(founder, 'emailIndex', 'sara@gmail.com')));
await check('guest cannot look up', false, () => getDoc(doc(anon, 'emailIndex', 'sara@gmail.com')));
await check('nobody lists the index', false, () => getDocs(collection(founder, 'emailIndex')));

// inviteEmails
await check('anyone reads one inviteEmails doc', true, () => getDoc(doc(anon, 'inviteEmails', 'sara@gmail.com')));
await check('signed-in adds a startup name', true, () => setDoc(doc(founder, 'inviteEmails', 'sara@gmail.com'), { names: arrayUnion('Rafeeq'), updatedAt: serverTimestamp() }));
await check('guest cannot write it', false, () => setDoc(doc(anon, 'inviteEmails', 'sara@gmail.com'), { names: ['x'], updatedAt: serverTimestamp() }));


// publicProfiles: always public, e-mail / phone only when set to Public
const owner = env.authenticatedContext('f9', { email: 'f9@gmail.com', email_verified: true }).firestore();
const profile = (extra = {}) => ({ fullName: 'Sara Alamri', role: 'founder', city: 'Riyadh', bio: 'Builds', sectorsOfInterest: ['Fintech'], emailPublic: false, phonePublic: false, updatedAt: serverTimestamp(), ...extra });
await check('owner writes a public profile (no contact)', true, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile()));
await check('anyone (even a guest) reads a profile', true, () => getDoc(doc(anon, 'publicProfiles', 'f9')));
await check('e-mail listed while PRIVATE is refused', false, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ email: 'f9@gmail.com' })));
await check('phone listed while PRIVATE is refused', false, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ phone: '551234567' })));
await check('e-mail listed when Public is allowed', true, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ email: 'f9@gmail.com', emailPublic: true })));
await check('phone Public + e-mail Private: only the phone', true, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ phone: '551234567', phonePublic: true })));
await check('somebody else cannot write my profile', false, () => setDoc(doc(stranger, 'publicProfiles', 'f9'), profile()));
await check('a role other than founder / investor is refused', false, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ role: 'admin' })));

// Leave startup / delete account: a member drops their own card from the team
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'startups', 'S2'), {
    founderId: 'f1', name: 'Naql', description: 'd', sector: 'fintech', stage: 'seed',
    businessModel: 'b2b', location: 'riyadh', lookingFor: ['funding'], isPublic: true,
    memberIds: ['c1', 'm1'], memberRoles: { c1: 'coFounder', m1: 'member' },
    teamMembers: [{ fullName: 'Founder', uid: 'f1' }, { fullName: 'Omar', uid: 'c1' }, { fullName: 'Mona', uid: 'm1' }],
  });
});
const mona = env.authenticatedContext('m1', { email: 'm1@gmail.com', email_verified: true }).firestore();
const fcard = { fullName: 'Founder', uid: 'f1' }, ccard = { fullName: 'Omar', uid: 'c1' }, mcard = { fullName: 'Mona', uid: 'm1' };
await check('leave while ADDING a card is refused', false, () => updateDoc(doc(mona, 'startups', 'S2'), { memberIds: ['c1'], memberRoles: { c1: 'coFounder' }, teamMembers: [fcard, ccard, mcard, { fullName: 'Evil', uid: 'e1' }] }));
await check('leave while EDITING a card is refused', false, () => updateDoc(doc(mona, 'startups', 'S2'), { memberIds: ['c1'], memberRoles: { c1: 'coFounder' }, teamMembers: [fcard, { fullName: 'Hacked', uid: 'c1' }] }));
await check('leave while changing the name is refused', false, () => updateDoc(doc(mona, 'startups', 'S2'), { memberIds: ['c1'], memberRoles: { c1: 'coFounder' }, name: 'Mine' }));
await check('member leaves and drops their card', true, () => updateDoc(doc(mona, 'startups', 'S2'), { memberIds: ['c1'], memberRoles: { c1: 'coFounder' }, teamMembers: [fcard, ccard] }));
await check('a stranger cannot drop cards', false, () => updateDoc(doc(stranger, 'startups', 'S2'), { teamMembers: [fcard] }));

// Profile photo and startup logo: small pictures saved as base64 text
const pic = (n) => 'A'.repeat(n);
await check('photoData within 150000 chars is allowed', true, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ photoData: pic(1000) })));
await check('photoData over 150000 chars is refused', false, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ photoData: pic(150001) })));
await check('photoData that is not text is refused', false, () => setDoc(doc(owner, 'publicProfiles', 'f9'), profile({ photoData: 12345 })));
await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'startups', 'S3'), {
  founderId: 'f1', name: 'Rafeeq', description: 'd', sector: 'fintech', stage: 'seed',
  businessModel: 'b2b', location: 'riyadh', lookingFor: ['funding'], isPublic: true,
  createdAt: new Date(0), fundingRequirement: 500000, memberIds: [], memberRoles: {}, teamMembers: [],
}));
const touch = (extra) => ({ ...extra, updatedAt: serverTimestamp() });
await check('founder updates a startup (baseline)', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ problem: 'x' })));
await check('logoData of 1000 chars is allowed', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ logoData: pic(1000) })));
await check('logoData of 140000 chars (a ~100 KB picture) is allowed', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ logoData: pic(140000) })));
await check('logoData over 150000 chars is refused', false, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ logoData: pic(150001) })));
await check('logoData that is not text is refused', false, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ logoData: 42 })));
await check('a future founded year (2030) is allowed', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ foundedYear: 2030 })));
await check('founded year 2999 is allowed', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ foundedYear: 2999 })));
await check('founded year 3000 is refused', false, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ foundedYear: 3000 })));
await check('founded year 1850 is refused', false, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ foundedYear: 1850 })));
await check('an older saved year (1995) still saves', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ foundedYear: 1995 })));
await check('a stranger cannot set logoData', false, () => updateDoc(doc(stranger, 'startups', 'S3'), touch({ logoData: pic(10) })));
await check('removing the logo (deleting the field) is allowed', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ logoData: deleteField() })));

// Several sectors: a startup keeps its main sector and a list of the others
const sectorLabels = Array.from({ length: 25 }, (_, i) => 'Sector ' + i);
const maxStartup = (extra = {}) => ({
  founderId: 'f1', name: 'Rafeeq Health', description: 'd', sector: 'other', sectorOther: 'Beekeeping',
  otherSectors: sectorLabels, stage: 'other', stageOther: 'Stage text', businessModel: 'other',
  businessModelOther: 'Model text', location: 'riyadh', lookingFor: ['funding', 'partnership', 'support', 'other'],
  lookingForOther: 'Something', fundingRequirement: 500000, isPublic: true,
  problem: 'p', solution: 's', targetCustomers: 'c', differentiation: 'd', marketSizeTam: 1000000,
  currentAvailableCapital: 0, revenueThisYear: 0, monthlyBurnRate: 0, valuation: 0, raisedInRound: 0,
  expectedRevenueYear1: 1, expectedRevenueYear2: 2, expectedRevenueYear3: 3,
  businessModelExplanation: 'e', partnerTypes: ['a', 'b', 'c'], supportTypes: ['a', 'b'],
  teamMembers: Array.from({ length: 20 }, (_, i) => ({ fullName: 'Member ' + i, role: 'r', uid: 'u' + i })),
  memberIds: [], memberRoles: {}, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
});
await check('the biggest startup (25 other sectors, every Other text, 20 team cards) can be created', true, () => setDoc(doc(founder, 'startups', 'M1'), maxStartup()));
const allMoney = {
  marketSizeTam: 9e12, marketSizeSam: 9e12, marketSizeSom: 9e12, currentAvailableCapital: 9e12,
  expectedRevenueYear1: 9e12, expectedRevenueYear2: 9e12, expectedRevenueYear3: 9e12, valuation: 9e12,
  revenueThisYear: 9e12, monthlyBurnRate: 9e12, raisedInRound: 9e12, fundingRequirement: 9e12,
};
await check('a startup that fills in all 12 amounts and picks Other three times can be created', true, () => setDoc(doc(founder, 'startups', 'M5'), maxStartup(allMoney)));
await check('every amount, every Other, 10 looking-for values and 20 team cards together can be created', true, () => setDoc(doc(founder, 'startups', 'M6'), maxStartup({
  ...allMoney, lookingFor: ['funding', 'cofounder', 'talent', 'partnership', 'support', 'mentorship', 'advisors', 'marketing', 'tech_development', 'other'],
  partnerTypes: Array.from({ length: 10 }, (_, i) => 'p' + i), supportTypes: Array.from({ length: 10 }, (_, i) => 's' + i),
  logoData: 'a'.repeat(1000), websiteUrl: 'https://example.com', foundedYear: 2024,
})));
await check('an amount that is not a whole number is refused', false, () => setDoc(doc(founder, 'startups', 'M8'), maxStartup({ valuation: 1.5 })));
await check('an amount written as text is refused', false, () => setDoc(doc(founder, 'startups', 'M9'), maxStartup({ valuation: '100' })));
for (const field of ['name', 'description', 'sector', 'stage', 'businessModel', 'location', 'lookingFor', 'isPublic']) {
  await check('a startup without ' + field + ' is refused', false, () => {
    const d = maxStartup(); delete d[field];
    return setDoc(doc(founder, 'startups', 'N-' + field), d);
  });
}
await check('a startup with a field the app does not know is refused', false, () => setDoc(doc(founder, 'startups', 'M10'), maxStartup({ isAdmin: true })));
await check('more than 30 other sectors is refused', false, () => setDoc(doc(founder, 'startups', 'M2'), maxStartup({ otherSectors: Array.from({ length: 31 }, (_, i) => 's' + i) })));
await check('otherSectors must be a list', false, () => setDoc(doc(founder, 'startups', 'M3'), maxStartup({ otherSectors: 'Fintech' })));
await check('a startup without otherSectors (an older one) still saves', true, async () => {
  const d = maxStartup(); delete d.otherSectors;
  await setDoc(doc(founder, 'startups', 'M4'), d);
});

// Ownership, closing and transfer (deleting a startup)
await check('a new startup as the app writes it (foundedBy, status, empty coFounderIds) can be created', true, () => setDoc(doc(founder, 'startups', 'O1'), maxStartup({ foundedBy: 'f1', status: 'active', coFounderIds: [] })));
await check('creating a startup that names someone else as its founder is refused', false, () => setDoc(doc(founder, 'startups', 'O2'), maxStartup({ foundedBy: 'x1' })));
await check('creating an already closed startup is refused', false, () => setDoc(doc(founder, 'startups', 'O3'), maxStartup({ status: 'closed' })));
await check('creating a startup with a "Founder (former)" name is refused', false, () => setDoc(doc(founder, 'startups', 'O5'), maxStartup({ formerFounderId: 'f1' })));

await check('an unknown status is refused', false, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ status: 'paused' })));
await check('the owner closes a startup with no co-founder', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ status: 'closed' })));
await check('a closed startup cannot reopen as Public', false, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ status: 'active', isPublic: true })));
await check('a closed startup reopens as Private', true, () => updateDoc(doc(founder, 'startups', 'S3'), touch({ status: 'active', isPublic: false })));

await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'startups', 'S4'), {
  founderId: 'f1', foundedBy: 'f1', status: 'active', name: 'Nova', description: 'd', sector: 'fintech', stage: 'seed',
  businessModel: 'b2b', location: 'riyadh', lookingFor: ['funding'], isPublic: true, createdAt: new Date(0),
  memberIds: ['c1', 'm1'], memberRoles: { c1: 'coFounder', m1: 'member' }, coFounderIds: ['c1'],
  teamMembers: [{ fullName: 'Founder', uid: 'f1', isFounder: true }, { fullName: 'Omar', uid: 'c1' }, { fullName: 'Mona', uid: 'm1' }],
}));
await check('the owner cannot close while a co-founder is on it', false, () => updateDoc(doc(founder, 'startups', 'S4'), touch({ status: 'closed' })));
await check('a co-founder cannot change who created the startup', false, () => updateDoc(doc(coFounder, 'startups', 'S4'), touch({ foundedBy: 'c1' })));
await check('a co-founder edits the startup', true, () => updateDoc(doc(coFounder, 'startups', 'S4'), touch({ problem: 'x' })));
await check('ownership cannot go to a member (only a joined co-founder)', false, () => updateDoc(doc(founder, 'startups', 'S4'), touch({ founderId: 'm1', memberIds: ['c1', 'f1'], memberRoles: { c1: 'coFounder', f1: 'coFounder' }, coFounderIds: ['c1', 'f1'] })));
await check('the owner hands the startup to a joined co-founder', true, () => updateDoc(doc(founder, 'startups', 'S4'), touch({ founderId: 'c1', memberIds: ['m1', 'f1'], memberRoles: { m1: 'member', f1: 'coFounder' }, coFounderIds: ['f1'] })));

console.log(fails === 0 ? 'ALL PASSED' : fails + ' FAILED');
await env.cleanup();
process.exit(fails === 0 ? 0 : 1);
