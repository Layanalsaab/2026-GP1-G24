// Security-rules tests for the Investment Wallet: `tickets` (run with the
// Firestore emulator; see README.md).
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
const stranger = env.authenticatedContext('x1', { email: 'x1@gmail.com', email_verified: true }).firestore();
const anon = env.unauthenticatedContext().firestore();

const ticketBase = {
  investorId: 'i1', name: 'Health bets', sectors: ['HealthTech'], stages: ['Seed'],
  amountMin: 100000, amountMax: 300000, status: 'open', startupId: null,
  createdAt: new Date(),
};

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
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

console.log('--- requests are not part of this release');
for (const c of ['requests', 'ticketRequests', 'interests']) {
  await check(`nobody writes ${c}`, false, () => setDoc(doc(inv1, c, 'r1'), { investorId: 'i1', status: 'pending' }));
  await check(`nobody reads ${c}`, false, () => getDocs(query(collection(inv1, c), where('investorId', '==', 'i1'))));
}

await env.cleanup();
console.log(fails === 0 ? 'ALL PASSED' : `${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
