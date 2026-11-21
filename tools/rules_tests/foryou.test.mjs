// Security-rules tests for For You: `users/{uid}/notInterested` (owner only) and
// `vectorChunks` (no client access; the server uses the Admin SDK).
// Run with the Firestore emulator; see README.md.
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { setDoc, getDoc, deleteDoc, doc, serverTimestamp } from 'firebase/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const rules = fs.readFileSync(path.join(here, '..', '..', 'firestore.rules'), 'utf8');
const env = await initializeTestEnvironment({
  projectId: 'demo-foryou',
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

const u1 = env.authenticatedContext('u1', { email: 'u1@gmail.com', email_verified: true }).firestore();
const u2 = env.authenticatedContext('u2', { email: 'u2@gmail.com', email_verified: true }).firestore();
const anon = env.unauthenticatedContext().firestore();

await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'users', 'u1', 'notInterested', 's-b'),
    { type: 'startup', targetId: 'b', createdAt: new Date() });
  await setDoc(doc(ctx.firestore(), 'vectorChunks', 'c00'), { vectors: {} });
});

const item = () => ({ type: 'startup', targetId: 'a', createdAt: serverTimestamp() });

console.log('--- notInterested');
await check('owner writes their own item', true, () => setDoc(doc(u1, 'users', 'u1', 'notInterested', 's-a'), item()));
await check('owner reads their own item', true, () => getDoc(doc(u1, 'users', 'u1', 'notInterested', 's-a')));
await check('owner deletes their own item (Undo)', true, () => deleteDoc(doc(u1, 'users', 'u1', 'notInterested', 's-a')));
await check("another user cannot read it", false, () => getDoc(doc(u2, 'users', 'u1', 'notInterested', 's-b')));
await check("another user cannot write it", false, () => setDoc(doc(u2, 'users', 'u1', 'notInterested', 's-c'), item()));
await check("another user cannot delete it", false, () => deleteDoc(doc(u2, 'users', 'u1', 'notInterested', 's-b')));
await check('signed out cannot read', false, () => getDoc(doc(anon, 'users', 'u1', 'notInterested', 's-b')));
await check('signed out cannot write', false, () => setDoc(doc(anon, 'users', 'u1', 'notInterested', 's-d'), item()));

console.log('--- vectorChunks');
await check('a signed-in user cannot read a chunk', false, () => getDoc(doc(u1, 'vectorChunks', 'c00')));
await check('a signed-in user cannot write a chunk', false, () => setDoc(doc(u1, 'vectorChunks', 'c00'), { vectors: {} }));
await check('signed out cannot read a chunk', false, () => getDoc(doc(anon, 'vectorChunks', 'c00')));

await env.cleanup();
console.log(fails === 0 ? 'ALL PASSED' : `${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
