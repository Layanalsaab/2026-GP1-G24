// Replays every write the Flutter app makes (build/rules_parity.json, made by
// test/audit/rules_parity_export_test.dart) against the real firestore.rules.
// Every write must be ALLOWED: a refusal means the app and the rules disagree
// (a field, a pick-list value or a length limit).
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  setDoc, updateDoc, deleteDoc, doc, writeBatch, serverTimestamp, arrayUnion,
  arrayRemove, deleteField, Timestamp,
} from 'firebase/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const rules = fs.readFileSync(path.join(here, '..', '..', 'firestore.rules'), 'utf8');
const log = JSON.parse(fs.readFileSync(path.join(here, '..', '..', 'build', 'rules_parity.json'), 'utf8'));
const env = await initializeTestEnvironment({
  projectId: 'demo-parity',
  firestore: { rules, host: '127.0.0.1', port: 8080 },
});

function decode(v) {
  if (Array.isArray(v)) return v.map(decode);
  if (v && typeof v === 'object') {
    const keys = Object.keys(v);
    if (keys.length === 1) {
      const k = keys[0];
      if (k === '$ts') return serverTimestamp();
      if (k === '$del') return deleteField();
      if (k === '$union') return arrayUnion(...v[k].map(decode));
      if (k === '$remove') return arrayRemove(...v[k].map(decode));
      if (k === '$date') return Timestamp.fromDate(new Date(v[k]));
    }
    return Object.fromEntries(keys.map((k) => [k, decode(v[k])]));
  }
  return v;
}

const dbOf = (e) => env.authenticatedContext(e.uid, { email: e.email, email_verified: e.verified }).firestore();
// Collections may be sub-collection paths ("startups/x/fundingRounds").
const refOf = (db, e) => doc(db, ...e.collection.split('/'), e.id);

let writes = 0;
const failures = [];
async function run(e, fn) {
  writes++;
  try { await fn(); } catch (err) {
    failures.push({ scenario: e.scenario, op: e.op, path: `${e.collection}/${e.id}`, as: e.uid, why: String(err.message ?? err).split('\n')[0], keys: Object.keys(e.data ?? {}) });
  }
}

for (let i = 0; i < log.length; i++) {
  const e = log[i];
  if (e.batch) {
    const group = [e];
    while (i + 1 < log.length && log[i + 1].batch === e.batch) group.push(log[++i]);
    const db = dbOf(e);
    const b = writeBatch(db);
    for (const w of group) {
      const ref = refOf(db, w);
      if (w.op === 'set') b.set(ref, decode(w.data));
      else if (w.op === 'update') b.update(ref, decode(w.data));
      else b.delete(ref);
    }
    await run(e, () => b.commit());
    continue;
  }
  const db = dbOf(e);
  const ref = refOf(db, e);
  if (e.op === 'set') await run(e, () => setDoc(ref, decode(e.data), e.merge ? { merge: true } : undefined));
  else if (e.op === 'update') await run(e, () => updateDoc(ref, decode(e.data)));
  else await run(e, () => deleteDoc(ref));
}

console.log(`${writes} writes replayed against firestore.rules.`);
if (failures.length === 0) {
  console.log('PASS: every write the app makes is accepted by the rules.');
} else {
  const seen = new Set();
  for (const f of failures) {
    const k = `${f.scenario}|${f.path}|${f.op}`;
    if (seen.has(k)) continue;
    seen.add(k);
    console.log(`FAIL [${f.scenario}] ${f.op} ${f.path} as ${f.as}: ${f.why}`);
  }
  console.log(`${failures.length} write(s) refused.`);
}
await env.cleanup();
process.exit(failures.length ? 1 : 0);
