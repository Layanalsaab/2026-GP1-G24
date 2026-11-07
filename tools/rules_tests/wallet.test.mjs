// Security-rules tests for the Investment Wallet: `tickets` and the requests an
// investor sends with a ticket (run with the Firestore emulator; see README.md).
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  setDoc, getDoc, getDocs, updateDoc, deleteDoc, doc, collection, query, where,
  serverTimestamp,
} from 'firebase/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const rules = fs.readFileSync(path.join(here, '..', '..', 'firestore.rules'), 'utf8');
const env = await initializeTestEnvironment({
  projectId: 'demo-wallet',
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

const inv1 = env.authenticatedContext('i1', { email: 'i1@gmail.com', email_verified: true }).firestore();
const inv2 = env.authenticatedContext('i2', { email: 'i2@gmail.com', email_verified: true }).firestore();
const founder = env.authenticatedContext('f1', { email: 'f1@gmail.com', email_verified: true }).firestore();
const stranger = env.authenticatedContext('x1', { email: 'x1@gmail.com', email_verified: true }).firestore();
const anon = env.unauthenticatedContext().firestore();

const ticketBase = {
  investorId: 'i1', name: 'Health bets', sectors: ['HealthTech'], stages: ['Seed'],
  amountMin: 100000, amountMax: 300000, status: 'open', startupId: null,
  createdAt: new Date(),
};

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'startups', 'S1'), {
    founderId: 'f1', name: 'Rafeeq', description: 'd', sector: 'healthtech', stage: 'seed',
    businessModel: 'b2b', location: 'riyadh', lookingFor: ['funding'], isPublic: true,
    fundingRequirement: 500000, raisedInRound: 100000, memberIds: [], memberRoles: {},
  });
  await setDoc(doc(db, 'startups', 'S3'), {
    founderId: 'f1', name: 'Idle', description: 'd', sector: 'healthtech', stage: 'seed',
    businessModel: 'b2b', location: 'riyadh', lookingFor: ['talent'], isPublic: true,
    memberIds: [], memberRoles: {},
  });
  await setDoc(doc(db, 'tickets', 'i1-T1'), ticketBase);
  await setDoc(doc(db, 'tickets', 'i1-T2'), { ...ticketBase, status: 'closed' });
  await setDoc(doc(db, 'tickets', 'i1-T4'), { ...ticketBase, amountMax: 900000 });
  await setDoc(doc(db, 'tickets', 'i2-T1'), { ...ticketBase, investorId: 'i2' });
  await setDoc(doc(db, 'tickets', 'i1-T5'), { ...ticketBase, status: 'used', startupId: 'S1' });
});

const newTicket = (extra = {}) => ({
  investorId: 'i1', name: 'Ticket 9', sectors: ['Fintech'], stages: ['Seed'],
  amountMin: 100000, amountMax: 300000, status: 'open', startupId: null,
  createdAt: serverTimestamp(), ...extra,
});

console.log('--- tickets: create');
await check('investor creates their own ticket', true, () => setDoc(doc(inv1, 'tickets', 'i1-T9'), newTicket()));
await check("cannot create under another investor's id", false, () => setDoc(doc(inv1, 'tickets', 'i2-T9'), newTicket()));
await check('cannot create with a made-up id', false, () => setDoc(doc(inv1, 'tickets', 'i1-extra'), newTicket()));
await check('cannot claim to be another investor', false, () => setDoc(doc(inv1, 'tickets', 'i1-T10'), newTicket({ investorId: 'i2' })));
await check('signed out cannot create', false, () => setDoc(doc(anon, 'tickets', 'i1-T11'), newTicket()));
await check('a new ticket must be open', false, () => setDoc(doc(inv1, 'tickets', 'i1-T12'), newTicket({ status: 'closed' })));
await check('a new ticket is not used for a startup', false, () => setDoc(doc(inv1, 'tickets', 'i1-T13'), newTicket({ startupId: 'S1' })));
await check('createdAt must be the server time', false, () => setDoc(doc(inv1, 'tickets', 'i1-T14'), newTicket({ createdAt: new Date(2020, 1, 1) })));
await check('empty name is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T15'), newTicket({ name: '' })));
await check('41-character name is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T16'), newTicket({ name: 'x'.repeat(41) })));
await check('40-character name is fine', true, () => setDoc(doc(inv1, 'tickets', 'i1-T17'), newTicket({ name: 'x'.repeat(40) })));
await check('no sectors is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T18'), newTicket({ sectors: [] })));
await check('no stages is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T19'), newTicket({ stages: [] })));
await check('a minimum under 1,000 is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T25'), newTicket({ amountMin: 999, amountMax: 5000 })));
await check('a minimum of exactly 1,000 is fine', true, () => setDoc(doc(inv1, 'tickets', 'i1-T26'), newTicket({ amountMin: 1000, amountMax: 2000 })));
await check('maximum equal to the minimum is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T20'), newTicket({ amountMax: 100000 })));
await check('a large ticket is fine (no limit from the usual ticket size)', true, () => setDoc(doc(inv1, 'tickets', 'i1-T21'), newTicket({ amountMin: 20000000, amountMax: 90000000 })));
await check('an absurd maximum is still refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T24'), newTicket({ amountMax: 100000000000000 })));
await check('amounts must be whole numbers', false, () => setDoc(doc(inv1, 'tickets', 'i1-T22'), newTicket({ amountMin: 100000.5 })));
await check('an unknown field is refused', false, () => setDoc(doc(inv1, 'tickets', 'i1-T23'), newTicket({ admin: true })));

console.log('--- tickets: read, edit, close, delete');
await check('a signed-in user reads a ticket (matching)', true, () => getDoc(doc(stranger, 'tickets', 'i1-T1')));
await check('signed out cannot read', false, () => getDoc(doc(anon, 'tickets', 'i1-T1')));
await check('investor lists their own tickets', true, () => getDocs(query(collection(inv1, 'tickets'), where('investorId', '==', 'i1'))));
await check('investor edits their open ticket', true, () => updateDoc(doc(inv1, 'tickets', 'i1-T1'), { name: 'Renamed', sectors: ['Fintech', 'AI'], amountMin: 150000, amountMax: 400000 }));
await check('investor closes their open ticket', true, () => updateDoc(doc(inv1, 'tickets', 'i1-T4'), { status: 'closed' }));
await check('a closed ticket cannot be edited', false, () => updateDoc(doc(inv1, 'tickets', 'i1-T2'), { name: 'Again' }));
await check('a closed ticket cannot be reopened', false, () => updateDoc(doc(inv1, 'tickets', 'i1-T2'), { status: 'open' }));
await check('a used ticket cannot be edited', false, () => updateDoc(doc(inv1, 'tickets', 'i1-T5'), { name: 'Again' }));
await check('the investor cannot mark a ticket used', false, () => updateDoc(doc(inv1, 'tickets', 'i1-T9'), { status: 'used', startupId: 'S1' }));
await check('cannot give a ticket to another investor', false, () => updateDoc(doc(inv1, 'tickets', 'i1-T9'), { investorId: 'i2' }));
await check('an edit still has to be valid', false, () => updateDoc(doc(inv1, 'tickets', 'i1-T9'), { amountMax: 50000 }));
await check("another investor cannot edit", false, () => updateDoc(doc(inv2, 'tickets', 'i1-T9'), { name: 'Mine now' }));
await check("another investor cannot close", false, () => updateDoc(doc(inv2, 'tickets', 'i1-T9'), { status: 'closed' }));
await check("another investor cannot delete", false, () => deleteDoc(doc(inv2, 'tickets', 'i1-T9')));
await check('investor deletes their own ticket (account deletion)', true, () => deleteDoc(doc(inv1, 'tickets', 'i1-T9')));

console.log('--- requests sent with a ticket');
const req = (extra = {}) => ({
  startupId: 'S1', founderId: 'f1', investorId: 'i1', message: '', amount: 200000,
  status: 'pending', createdAt: serverTimestamp(), ticketId: 'i1-T5x', startupName: 'Rafeeq', ...extra,
});
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'tickets', 'i1-T6'), ticketBase); // open 100K-300K
  await setDoc(doc(ctx.firestore(), 'tickets', 'i1-T7'), { ...ticketBase, amountMax: 900000 }); // open 100K-900K
});
const ok = (extra = {}) => req({ ticketId: 'i1-T6', ...extra });
await check('investor sends a request with their open ticket', true, () => setDoc(doc(inv1, 'requests', 'r1'), ok()));
await check('the minimum is allowed', true, () => setDoc(doc(inv1, 'requests', 'r2'), ok({ amount: 100000 })));
await check('the ticket maximum is allowed', true, () => setDoc(doc(inv1, 'requests', 'r3'), ok({ amount: 300000 })));
await check('below the ticket minimum is refused', false, () => setDoc(doc(inv1, 'requests', 'r4'), ok({ amount: 99999 })));
await check('above the ticket maximum is refused', false, () => setDoc(doc(inv1, 'requests', 'r5'), ok({ amount: 300001 })));
await check('the round still needs 400,000: exactly that is allowed', true, () => setDoc(doc(inv1, 'requests', 'r6'), req({ ticketId: 'i1-T7', amount: 400000 })));
await check('more than the round still needs is refused', false, () => setDoc(doc(inv1, 'requests', 'r7'), req({ ticketId: 'i1-T7', amount: 400001 })));
await check('a closed ticket cannot be used', false, () => setDoc(doc(inv1, 'requests', 'r8'), ok({ ticketId: 'i1-T2' })));
await check('a used ticket cannot be used again', false, () => setDoc(doc(inv1, 'requests', 'r9'), ok({ ticketId: 'i1-T5' })));
await check("cannot use another investor's ticket", false, () => setDoc(doc(inv1, 'requests', 'r10'), ok({ ticketId: 'i2-T1' })));
await check('cannot send as another investor', false, () => setDoc(doc(inv1, 'requests', 'r11'), ok({ investorId: 'i2' })));
await check('the founder must be the startup owner', false, () => setDoc(doc(inv1, 'requests', 'r12'), ok({ founderId: 'x1' })));
await check('a startup that is not raising is refused', false, () => setDoc(doc(inv1, 'requests', 'r13'), ok({ startupId: 'S3' })));
await check('a ticket request has no equity', false, () => setDoc(doc(inv1, 'requests', 'r14'), ok({ equity: 10 })));
await check('startupName over 60 characters is refused', false, () => setDoc(doc(inv1, 'requests', 'r15'), ok({ startupName: 'x'.repeat(61) })));
await check('must start as pending', false, () => setDoc(doc(inv1, 'requests', 'r16'), ok({ status: 'accepted' })));
await check('an unknown field is refused', false, () => setDoc(doc(inv1, 'requests', 'r17'), ok({ extra: 1 })));
await check('signed out cannot send', false, () => setDoc(doc(anon, 'requests', 'r18'), ok()));

console.log('--- requests: the existing request (no ticket) is unchanged');
const legacy = { startupId: 'S1', founderId: 'f1', investorId: 'i1', message: 'Hello', amount: 300000, equity: 15, status: 'pending', createdAt: serverTimestamp() };
await check('a request with an equity is still allowed', true, () => setDoc(doc(inv1, 'requests', 'l1'), legacy));
await check('a request without a ticket still needs an equity', false, () => setDoc(doc(inv1, 'requests', 'l2'), { ...legacy, equity: undefined }));
await check('equity 100 is still refused', false, () => setDoc(doc(inv1, 'requests', 'l3'), { ...legacy, equity: 100 }));

console.log('--- requests: read, decide, withdraw, delete');
await check('investor reads their own requests', true, () => getDocs(query(collection(inv1, 'requests'), where('investorId', '==', 'i1'))));
await check('the startup owner reads the request', true, () => getDoc(doc(founder, 'requests', 'r1')));
await check('a stranger cannot read it', false, () => getDoc(doc(stranger, 'requests', 'r1')));
await check('another investor cannot read it', false, () => getDoc(doc(inv2, 'requests', 'r1')));
await check('the owner can still accept (status only)', true, () => updateDoc(doc(founder, 'requests', 'r3'), { status: 'accepted' }));
await check('the investor cannot change the status', false, () => updateDoc(doc(inv1, 'requests', 'r1'), { status: 'accepted' }));
await check('a stranger cannot withdraw', false, () => deleteDoc(doc(stranger, 'requests', 'r1')));
await check('another investor cannot withdraw', false, () => deleteDoc(doc(inv2, 'requests', 'r1')));
await check('the investor withdraws their request', true, () => deleteDoc(doc(inv1, 'requests', 'r1')));
await check('the startup owner removes requests of a deleted startup', true, () => deleteDoc(doc(founder, 'requests', 'r2')));

await env.cleanup();
console.log(fails === 0 ? 'ALL PASSED' : `${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
