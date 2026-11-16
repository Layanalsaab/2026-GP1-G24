// Gives every SAMPLE team member (publicProfiles, id "seed-...") a bio of their
// own that says which startup(s) they are in, their role there and their
// interests, and makes every dataset startup have exactly ONE "Founder".
//
// WHAT IT TOUCHES (and nothing else):
//   1. publicProfiles/{seed-...}: `bio`, `sectorsOfInterest`, and the `role`
//      of each entry of `startups` (only when --fix-roles changes it).
//   2. startups/{dataset}: ONLY `teamMembers` (only with --fix-roles).
//   Real accounts' profiles and startups are never touched.
//
// USAGE
//   node rewrite_bios.mjs <service-account.json>                       dry run
//   node rewrite_bios.mjs <service-account.json> --fix-roles           dry run incl. roles
//   node rewrite_bios.mjs <service-account.json> [--fix-roles] --write applies it
//
// Before writing, the original values are saved to backups/.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const keyPath = process.argv[2];
const WRITE = process.argv.includes('--write');
const FIX_ROLES = process.argv.includes('--fix-roles');
if (!keyPath) {
  console.log('Usage: node rewrite_bios.mjs <service-account.json> [--fix-roles] [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

// ----------------------------------------------------------------- helpers
const hash = (str) => {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h >>> 0;
};
const pick = (seed, list) => list[hash(seed) % list.length];

const SECTOR_LABELS = {
  healthtech: 'HealthTech', fintech: 'Fintech', edtech: 'EdTech', ecommerce: 'E-commerce',
  logistics: 'Logistics', agritech: 'AgriTech', proptech: 'PropTech', cleantech: 'CleanTech',
  tourism: 'Tourism', saas: 'SaaS', ai: 'AI', cybersecurity: 'Cybersecurity', gaming: 'Gaming',
  media: 'Media', foodtech: 'FoodTech', mobility: 'Mobility', retail: 'Retail', energy: 'Energy',
  insurtech: 'InsurTech', legaltech: 'LegalTech', hr_tech: 'HR Tech', biotech: 'Biotech',
  manufacturing: 'Manufacturing', sports: 'Sports',
};
const sectorLabel = (v) => SECTOR_LABELS[v] || null;
const PRIOR = ['a regional bank', 'a global consulting firm', 'a large telecom company', 'an e-commerce marketplace',
  'a government innovation programme', 'two early-stage startups', 'a hospital group', 'a logistics company',
  'a university research lab', 'a venture studio', 'a retail chain', 'a software house'];

const sentence = (text) => {
  const t = String(text || '').replace(/\s+/g, ' ').trim();
  if (!t) return '';
  const m = t.match(/^(.{20,200}?[.!?])(\s|$)/);
  const s = (m ? m[1] : t.slice(0, 180).replace(/[\s,;:-]+\S*$/, '')).trim();
  return /[.!?]$/.test(s) ? s : `${s}.`;
};
const list = (items) =>
  items.length <= 1 ? items.join('') : `${items.slice(0, -1).join(', ')} and ${items[items.length - 1]}`;

// ------------------------------------------------------------------- data
const startups = new Map();
for (const d of (await db.collection('startups').get()).docs) {
  const s = { id: d.id, ...d.data() };
  if (s.founderId === 'crunchbase-dataset') startups.set(s.id, s);
}
const profiles = (await db.collection('publicProfiles').get()).docs
  .map((d) => ({ id: d.id, ...d.data() }))
  .filter((p) => p.isSample === true && p.id.startsWith('seed-'));

// ------------------------------------------------- roles: ONE founder each
const roleBackup = {};
const newTeams = new Map();
const FOUNDER_TEXT = { 'Founder': 'Founder', 'CEO': 'Founder & CEO', 'Co-founder': 'Founder', 'Co-founder & CEO': 'Founder & CEO', 'Founder & CEO': 'Founder & CEO' };
let extraFounders = 0, relabelled = 0;
for (const s of startups.values()) {
  const team = s.teamMembers || [];
  const out = team.map((m) => {
    const text = String(m.role || '');
    if (m.isFounder) {
      const t = FOUNDER_TEXT[text] ?? text;
      if (t !== text) relabelled++;
      return { ...m, role: t, coFounder: false };
    }
    if (/founder/i.test(text)) { // a second "Founder": a Co-founder
      extraFounders++;
      return { ...m, role: 'Co-founder', coFounder: true };
    }
    return m;
  });
  if (JSON.stringify(out) !== JSON.stringify(team)) { roleBackup[s.id] = team; newTeams.set(s.id, out); }
}
const teamOf = (id) => (FIX_ROLES && newTeams.get(id)) || startups.get(id)?.teamMembers || [];

// ------------------------------------------------------------------ bios
const kindOf = (m) => (m.isFounder ? 'founder' : m.coFounder ? 'coFounder' : 'member');
const ROLE_PHRASE = {
  founder: (n, t) => pick(n + t, [`Founder of ${n}`, `Founded ${n}`, `${/CEO/.test(t) ? 'Founder and CEO' : 'Founder'} of ${n}`]),
  coFounder: (n) => `Co-founder of ${n}`,
};
const phraseFor = (kind, roleText, name) =>
  kind === 'member' ? `${roleText || 'Team member'} at ${name}` : ROLE_PHRASE[kind](name, roleText);

const interestsLine = (p, sectors) => {
  const who = p.id;
  const years = 4 + (hash(who + 'y') % 15);
  const lead = sectors[0] || 'technology';
  const prior = pick(who + 'p', PRIOR);
  const intro = pick(who + 't', [
    `${years} years in ${lead}, starting out at ${prior}.`,
    `Spent ${years} years in ${lead}, including time at ${prior}.`,
    `Has worked in ${lead} for ${years} years, after ${prior}.`,
    `Brings ${years} years of ${lead} experience, previously at ${prior}.`,
  ]);
  const more = sectors.length > 1
    ? pick(who + 'm', [`Most interested in ${list(sectors)}.`, `Follows ${list(sectors)} closely.`, `Keeps an eye on ${list(sectors)}.`])
    : pick(who + 'm', [
        `Keen on how ${lead} is changing across the Kingdom.`,
        `Always looking for what comes next in ${lead}.`,
        `Follows the ${lead} market closely.`,
        `Enjoys working with early teams in ${lead}.`,
      ]);
  return `${intro} ${more}`;
};

const makeBio = (p) => {
  const mine = (p.startups || [])
    .map((e) => ({ e, s: startups.get(e.id) }))
    .filter((x) => x.s);
  if (!mine.length) return null;
  const parts = mine.map(({ e, s }) => {
    const m = teamOf(s.id).find((x) => x.uid === p.id) || {};
    const kind = FIX_ROLES ? kindOf(m) : e.role;
    return { s, kind, text: String(m.role || ''), name: s.name };
  });
  const order = { founder: 0, coFounder: 1, member: 2 };
  parts.sort((a, b) => order[a.kind] - order[b.kind] || a.name.localeCompare(b.name));
  const named = parts.slice(0, 4);
  const rest = parts.length - named.length;
  // "Founder of A and co-founder of B, and CTO at C."
  // One startup: a few ways to say it. Several: grouped by role, e.g.
  // "Founder of A and B, co-founder of C and CTO at D".
  const groups = [];
  for (const x of named) {
    const key = x.kind === 'member' ? `m:${x.text}` : x.kind;
    let g = groups.find((y) => y.key === key);
    if (!g) groups.push((g = { key, x, names: [] }));
    g.names.push(x.name);
  }
  const phrases = groups.map((g, i) => {
    const names = list(g.names);
    const t = parts.length === 1
      ? phraseFor(g.x.kind, g.x.text, names)
      : g.x.kind === 'founder' ? `Founder of ${names}`
      : g.x.kind === 'coFounder' ? `Co-founder of ${names}`
      : `${g.x.text || 'Team member'} at ${names}`;
    return i === 0 ? t : t.replace(/^(Founder|Co-founder)/, (w) => w.toLowerCase());
  });
  let head = `${list(phrases)}${rest > 0 ? `, and is involved in ${rest} other startup${rest > 1 ? 's' : ''}` : ''}.`;
  const first = parts[0].s;
  const what = sentence(first.description || first.problem || first.solution);
  const sectors = [...new Set(parts.map((x) => sectorLabel(x.s.sector)).filter(Boolean))].slice(0, 3);
  const city = p.city ? ` Based in ${p.city}.` : '';
  return { bio: `${head} ${what} ${interestsLine(p, sectors)}${city}`.replace(/\s+/g, ' ').trim(), sectors };
};

const results = new Map();
for (const p of profiles) {
  const r = makeBio(p);
  if (r) results.set(p.id, r);
}

// make sure no two bios are the same (a short distinguishing clause if so)
const seen = new Map();
for (const [id, r] of results) {
  let bio = r.bio, n = 0;
  while (seen.has(bio)) bio = `${r.bio} ${pick(id + (++n), ['Mentors young founders.', 'Often speaks at startup meetups.', 'Active in the local startup community.', 'Enjoys advising early teams.'])}`.replace(/\s+/g, ' ');
  seen.set(bio, id);
  r.bio = bio;
}

// ------------------------------------------------------------------ report
const changedProfiles = profiles.filter((p) => results.has(p.id));
const oldDup = new Map();
for (const p of profiles) oldDup.set(p.bio, (oldDup.get(p.bio) || 0) + 1);
console.log(JSON.stringify({
  mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)',
  sampleProfiles: profiles.length,
  bioRewritten: changedProfiles.length,
  oldBiosSharedWithSomeoneElse: profiles.filter((p) => oldDup.get(p.bio) > 1).length,
  newBiosDistinct: new Set([...results.values()].map((r) => r.bio)).size,
  fixRoles: FIX_ROLES,
  startupsWhoseTeamChanges: FIX_ROLES ? newTeams.size : 0,
  extraFoundersBecomingCoFounders: FIX_ROLES ? extraFounders : 0,
  founderTitlesRenamed: FIX_ROLES ? relabelled : 0,
}, null, 2));
const show = [
  profiles.find((p) => (p.startups || []).length === 1 && p.startups[0].role === 'founder'),
  profiles.find((p) => p.startups?.[0]?.id === 'PIEHSIP' && p.startups[0].role === 'member'),
  profiles.find((p) => (p.startups || []).length >= 3 && (p.startups || []).length <= 5),
  profiles.find((p) => (p.startups || []).length >= 9),
].filter(Boolean);
for (const p of show) {
  console.log(`\n--- ${p.fullName} (${(p.startups || []).length} startup${p.startups.length > 1 ? 's' : ''}) ---`);
  console.log('before:', p.bio);
  console.log('after: ', results.get(p.id)?.bio);
}

if (!WRITE) { console.log('\nDry run only. Add --write to apply.'); process.exit(0); }

// -------------------------------------------------------------------- write
const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const stamp = Date.now();
fs.writeFileSync(path.join(backupDir, `bios_before_${stamp}.json`), JSON.stringify(Object.fromEntries(
  changedProfiles.map((p) => [p.id, { bio: p.bio, sectorsOfInterest: p.sectorsOfInterest ?? null, startups: p.startups ?? null }])), null, 1));
if (FIX_ROLES) fs.writeFileSync(path.join(backupDir, `teams_before_roles_${stamp}.json`), JSON.stringify(roleBackup, null, 1));
console.log('Backups saved in', backupDir, 'with stamp', stamp);

let ops = 0, batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const p of changedProfiles) {
  const r = results.get(p.id);
  const data = { bio: r.bio, updatedAt: FieldValue.serverTimestamp() };
  if (r.sectors.length) data.sectorsOfInterest = r.sectors;
  if (FIX_ROLES) {
    data.startups = (p.startups || []).map((e) => {
      const m = teamOf(e.id).find((x) => x.uid === p.id);
      return m ? { ...e, role: kindOf(m) } : e;
    });
  }
  batch.update(db.collection('publicProfiles').doc(p.id), data);
  if (++ops >= 400) await flush();
}
if (FIX_ROLES) {
  for (const [id, team] of newTeams) {
    batch.update(db.collection('startups').doc(id), { teamMembers: team });
    if (++ops >= 400) await flush();
  }
}
await flush();
console.log('Done. Profiles updated:', changedProfiles.length, FIX_ROLES ? `| startup teams updated: ${newTeams.size}` : '');
