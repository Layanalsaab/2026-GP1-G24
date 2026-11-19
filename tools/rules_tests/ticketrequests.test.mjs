// Security-rules tests for `ticketRequests`: a startup's request to an investor,
// sent from one of the investor's open tickets ("Request received" for the
// investor). Run with the Firestore emulator; see README.md.
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
  projectId: 'demo-ticketrequests',
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
const f1 = env.authenticatedContext('f1', { email: 'f1@gmail.com', email_verified: true }).firestore();
const f2 = env.authenticatedContext('f2', { email: 'f2@gmail.com', email_verified: true }).firestore();
const anon = env.unauthenticatedContext().firestore();

const ticketBase = {
  investorId: 'i1', name: 'Health bets', sectors: ['HealthTech'], stages: ['Seed'],
  amountMin: 100000, amountMax: 300000, status: 'open', startupId: null,
  createdAt: new Date(),
};
const startupBase = {
  founderId: 'f1', name: 'Rafeeq', description: 'd', sector: 'healthtech', stage: 'seed',
  commerceModel: 'b2b', location: 'riyadh', lookingFor: ['funding'], isPublic: true,
  fundingRequirement: 500000, raisedInRound: 100000, memberIds: [], memberRoles: {},
};

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'startups', 'S1'), startupBase); // owner f1, needs 400,000
  await setDoc(doc(db, 'startups', 'S2'), { ...startupBase, founderId: 'f2', name: 'Other' });
  const { fundingRequirement, ...notRaising } = startupBase;
  await setDoc(doc(db, 'startups', 'S3'), { ...notRaising, name: 'Idle' });
  await setDoc(doc(db, 'startups', 'S4'), { ...startupBase, status: 'closed', name: 'Gone' });
  await setDoc(doc(db, 'tickets', 'i1-T1'), ticketBase); // open 100K-300K
  await setDoc(doc(db, 'tickets', 'i1-T2'), { ...ticketBase, status: 'closed' });
  await setDoc(doc(db, 'tickets', 'i1-T3'), { ...ticketBase, amountMax: 900000 }); // open 100K-900K
  await setDoc(doc(db, 'tickets', 'i2-T1'), { ...ticketBase, investorId: 'i2' });
});

const body = (extra = {}) => ({
  startupId: 'S1', founderId: 'f1', investorId: 'i1', ticketId: 'i1-T1',
  startupName: 'Rafeeq', amount: 200000, message: 'We fit your ticket.',
  status: 'pending', createdAt: serverTimestamp(), ...extra,
});
const id = (startup, ticket) => `${startup}~${ticket}`;

console.log('--- create: the startup sends');
await check('the owner sends a request on an open ticket', true, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body()));
await check('the ticket minimum is allowed', true, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T3')), body({ ticketId: 'i1-T3', amount: 100000 })));
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'tickets', 'i1-T4'), { ...ticketBase, amountMax: 900000 });
});
await check('exactly what the round still needs is allowed', true, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T4')), body({ ticketId: 'i1-T4', amount: 400000 })));
await check('the id must be startup~ticket', false, () => setDoc(doc(f1, 'ticketRequests', 'whatever'), body()));
await check('below the ticket minimum is refused', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ amount: 99999 })));
await check('above the ticket maximum is refused', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ amount: 300001 })));
await check('more than the round still needs is refused', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T3')), body({ ticketId: 'i1-T3', amount: 400001 })));
await check('a closed ticket cannot receive a request', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T2')), body({ ticketId: 'i1-T2' })));
await check('the request goes to the ticket owner only', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ investorId: 'i2' })));
await check("another founder cannot send for S1", false, () => setDoc(doc(f2, 'ticketRequests', id('S1', 'i1-T1')), body({ founderId: 'f2' })));
await check('cannot claim to be the owner', false, () => setDoc(doc(f2, 'ticketRequests', id('S1', 'i1-T1')), body()));
await check('a startup that is not raising is refused', false, () => setDoc(doc(f1, 'ticketRequests', id('S3', 'i1-T1')), body({ startupId: 'S3', startupName: 'Idle' })));
await check('a closed startup cannot send', false, () => setDoc(doc(f1, 'ticketRequests', id('S4', 'i1-T1')), body({ startupId: 'S4', startupName: 'Gone' })));
await check('the startup name must be the real one', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ startupName: 'Something else' })));
await check('must start as pending', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ status: 'accepted' })));
await check('createdAt must be the server time', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ createdAt: new Date(2020, 1, 1) })));
await check('an unknown field is refused', false, () => setDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1')), body({ extra: 1 })));
await check('the investor cannot send one to themselves', false, () => setDoc(doc(inv1, 'ticketRequests', id('S1', 'i1-T1')), body({ founderId: 'i1' })));
await check('signed out cannot send', false, () => setDoc(doc(anon, 'ticketRequests', id('S1', 'i1-T1')), body()));

console.log('--- read');
await check('the investor reads what they received', true, () => getDocs(query(collection(inv1, 'ticketRequests'), where('investorId', '==', 'i1'))));
await check('the founder reads what they sent', true, () => getDocs(query(collection(f1, 'ticketRequests'), where('founderId', '==', 'f1'))));
await check('the investor reads one', true, () => getDoc(doc(inv1, 'ticketRequests', id('S1', 'i1-T1'))));
await check("another investor cannot read it", false, () => getDoc(doc(inv2, 'ticketRequests', id('S1', 'i1-T1'))));
await check("another founder cannot read it", false, () => getDoc(doc(f2, 'ticketRequests', id('S1', 'i1-T1'))));
await check('signed out cannot read', false, () => getDoc(doc(anon, 'ticketRequests', id('S1', 'i1-T1'))));

console.log('--- the investor answers');
await check('the investor accepts', true, () => updateDoc(doc(inv1, 'ticketRequests', id('S1', 'i1-T1')), { status: 'accepted', respondedAt: serverTimestamp() }));
await check('an answered request cannot change again', false, () => updateDoc(doc(inv1, 'ticketRequests', id('S1', 'i1-T1')), { status: 'declined', respondedAt: serverTimestamp() }));
await check('the investor declines another', true, () => updateDoc(doc(inv1, 'ticketRequests', id('S1', 'i1-T3')), { status: 'declined', respondedAt: serverTimestamp() }));
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'ticketRequests', 'S2~i1-T1'), {
    startupId: 'S2', founderId: 'f2', investorId: 'i1', ticketId: 'i1-T1', startupName: 'Other',
    amount: 150000, message: '', status: 'pending', createdAt: new Date(),
  });
});
await check('the startup cannot answer for the investor', false, () => updateDoc(doc(f2, 'ticketRequests', 'S2~i1-T1'), { status: 'accepted', respondedAt: serverTimestamp() }));
await check("another investor cannot answer", false, () => updateDoc(doc(inv2, 'ticketRequests', 'S2~i1-T1'), { status: 'accepted', respondedAt: serverTimestamp() }));
await check('the answer must be accepted or declined', false, () => updateDoc(doc(inv1, 'ticketRequests', 'S2~i1-T1'), { status: 'pending', respondedAt: serverTimestamp() }));
await check('the investor cannot change the amount', false, () => updateDoc(doc(inv1, 'ticketRequests', 'S2~i1-T1'), { status: 'accepted', amount: 1 }));
await check('the investor cannot change who sent it', false, () => updateDoc(doc(inv1, 'ticketRequests', 'S2~i1-T1'), { status: 'accepted', founderId: 'x' }));

console.log('--- withdraw and delete');
await check('the startup withdraws a pending request', true, () => deleteDoc(doc(f2, 'ticketRequests', 'S2~i1-T1')));
await check('the startup cannot delete an answered request', false, () => deleteDoc(doc(f1, 'ticketRequests', id('S1', 'i1-T1'))));
await check('the investor deletes one they received (account deletion)', true, () => deleteDoc(doc(inv1, 'ticketRequests', id('S1', 'i1-T1'))));
await check("a stranger cannot delete", false, () => deleteDoc(doc(f2, 'ticketRequests', id('S1', 'i1-T3'))));

console.log(fails === 0 ? '\nALL PASSED' : `\n${fails} FAILED`);
await env.cleanup();
process.exit(fails === 0 ? 0 : 1);
