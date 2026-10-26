// Fills the dataset startups with SAMPLE people so every team member has a
// full public profile (publicProfiles/{id}).
//
// WHAT IT TOUCHES (and nothing else):
//   1. NEW documents in `publicProfiles` (sample people only; id starts with
//      "seed-"; isSample: true).
//   2. The `teamMembers` list of dataset startups (founderId ==
//      "crunchbase-dataset"): people already in it get a `uid`; startups with
//      no team get a founder and 0-3 team members.
//   It never changes any other field of a startup, never touches startups made
//   by real accounts, `users`, `investors`, requests or interests.
//
// USAGE
//   node seed_team.mjs <service-account.json>            (dry run: writes nothing)
//   node seed_team.mjs <service-account.json> --write    (really writes)
//
// Before writing, the original teamMembers of every startup it changes are
// saved to backups/. cleanup.mjs restores them and removes the sample profiles.

import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const keyPath = process.argv[2];
const WRITE = process.argv.includes('--write');
if (!keyPath) {
  console.log('Usage: node seed_team.mjs <service-account.json> [--write]');
  process.exit(1);
}
initializeApp({ credential: cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = getFirestore();

// ----------------------------------------------------------------- helpers
function hash(str) {
  let h = 2166136261;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const pick = (r, list) => list[Math.floor(r() * list.length)];

const SECTOR_LABELS = {
  healthtech: 'HealthTech', fintech: 'Fintech', edtech: 'EdTech', ecommerce: 'E-commerce',
  logistics: 'Logistics', agritech: 'AgriTech', proptech: 'PropTech', cleantech: 'CleanTech',
  tourism: 'Tourism', saas: 'SaaS', ai: 'AI', cybersecurity: 'Cybersecurity', gaming: 'Gaming',
  media: 'Media', foodtech: 'FoodTech', mobility: 'Mobility', retail: 'Retail', energy: 'Energy',
  insurtech: 'InsurTech', legaltech: 'LegalTech', hr_tech: 'HR Tech', biotech: 'Biotech',
  manufacturing: 'Manufacturing', sports: 'Sports',
};
const ALL_SECTORS = Object.values(SECTOR_LABELS);
const sectorLabel = (v) => SECTOR_LABELS[v] || null;
const cityLabel = (v) =>
  !v || v === 'other' ? '' : v.split('_').map((w) => w[0].toUpperCase() + w.slice(1)).join(' ');
const SAUDI_CITIES = ['Riyadh', 'Jeddah', 'Dammam', 'Al Khobar', 'Makkah', 'Madinah', 'Abha', 'Tabuk',
  'Buraydah', 'Hail', 'Jazan', 'Najran', 'Al Ahsa', 'Taif', 'Yanbu', 'Dhahran', 'Al Jubail'];

// ---------------------------------------------------------- the sample pool
// Saudi names only: every sample founder / team member is Saudi.
const GROUPS = [
  { weight: 50, male: ['Abdullah', 'Faisal', 'Khalid', 'Saud', 'Turki', 'Nawaf', 'Mansour', 'Fahad', 'Salman', 'Rayan', 'Bandar', 'Majed', 'Yazeed', 'Talal', 'Sultan', 'Omar', 'Hamad', 'Ibrahim', 'Mishari', 'Abdulaziz', 'Nasser', 'Waleed', 'Meshal', 'Badr'],
    female: ['Noura', 'Lama', 'Reem', 'Haifa', 'Sarah', 'Maha', 'Dana', 'Hessa', 'Jawaher', 'Ghada', 'Rawan', 'Layan', 'Shahad', 'Joud', 'Amal', 'Latifa', 'Bayan', 'Dalal', 'Wejdan', 'Asma', 'Munira', 'Abeer'],
    last: ['Alharbi', 'Alotaibi', 'Alqahtani', 'Alghamdi', 'Alzahrani', 'Aldossari', 'Alshehri', 'Almutairi', 'Alsubaie', 'Alshammari', 'Alamri', 'Alharthi', 'Alrashed', 'Alfaraj', 'Alsaif', 'Alhajri', 'Alkhaldi', 'Alnasser', 'Alsalem', 'Alanazi', 'Alyami', 'Albalawi'] },
];
const FOUNDER_TITLES = ['Founder & CEO', 'Co-founder & CEO', 'Founder', 'CEO', 'Co-founder'];
const TEAM_ROLES = [
  ['CTO', 'Leads engineering and the technical roadmap.'],
  ['COO', 'Runs day-to-day operations and partnerships.'],
  ['CFO', 'Looks after finance, budgeting and fundraising.'],
  ['CMO', 'Leads marketing, brand and customer acquisition.'],
  ['Head of Product', 'Owns the product vision and the roadmap.'],
  ['Head of Growth', 'Drives user growth and retention.'],
  ['Lead Engineer', 'Builds and ships the core platform.'],
  ['Product Designer', 'Designs the product experience and the brand.'],
  ['Operations Manager', 'Keeps delivery, suppliers and logistics running.'],
  ['Head of Sales', 'Builds the sales pipeline and key accounts.'],
  ['Data Lead', 'Leads analytics, data pipelines and insights.'],
  ['Legal & Compliance Lead', 'Handles contracts, licences and compliance.'],
];
const PRIOR = ['a regional bank', 'a global consulting firm', 'a large telecom company', 'an e-commerce marketplace',
  'a government innovation programme', 'two early-stage startups', 'a hospital group', 'a logistics company',
  'a university research lab', 'a venture studio', 'a retail chain', 'a software house'];
const FOCUS = ['building products people use every day', 'turning ideas into reliable services',
  'growing teams and customers across the Kingdom', 'making technology simple for everyone',
  'working with partners across the region', 'solving real problems with data'];

function makePool(size) {
  const r = rng(20261026);
  const pool = [];
  const used = new Set();
  const total = GROUPS.reduce((s, g) => s + g.weight, 0);
  while (pool.length < size) {
    let x = r() * total, g = GROUPS[0];
    for (const c of GROUPS) { if ((x -= c.weight) < 0) { g = c; break; } }
    const female = r() < 0.4;
    const name = `${pick(r, female ? g.female : g.male)} ${pick(r, g.last)}`;
    if (used.has(name)) continue;
    used.add(name);
    const i = pool.length;
    const isFounder = i < 120; // 120 founders, the rest team members
    const sectors = [...new Set([pick(r, ALL_SECTORS), pick(r, ALL_SECTORS), pick(r, ALL_SECTORS)])].slice(0, 1 + Math.floor(r() * 3));
    const years = 4 + Math.floor(r() * 16);
    const [teamRole, teamLine] = pick(r, TEAM_ROLES);
    const role = isFounder ? pick(r, FOUNDER_TITLES) : teamRole;
    const city = pick(r, SAUDI_CITIES);
    const bio = isFounder
      ? `${role} with ${years} years in ${sectors[0]}. Previously worked at ${pick(r, PRIOR)}. Passionate about ${pick(r, FOCUS)}. Based in ${city}.`
      : `${teamRole} with ${years} years of experience in ${sectors[0]}, after time at ${pick(r, PRIOR)}. ${teamLine} Based in ${city}.`;
    pool.push({
      id: `seed-pool-${String(i + 1).padStart(3, '0')}`,
      name, role, isFounder, sectors, city, bio,
      contribution: isFounder ? `Sets the vision and leads the company in ${sectors[0]}.` : teamLine,
      // Contact: private for everybody, except four people used to test it.
      emailPublic: false, phonePublic: false,
      startups: [],
    });
  }
  // Four founders to test the Contact section (the app always shows the
  // profile; only these expose an e-mail / phone, each on its own).
  const contact = (p, email, phone) => {
    if (email) { p.emailPublic = true; p.email = `${p.name.toLowerCase().replace(/[^a-z]+/g, '.')}@example.com`; }
    if (phone) { p.phonePublic = true; p.phone = `5${String(10000000 + (hash(p.name) % 89999999))}`.slice(0, 9); }
  };
  contact(pool[0], true, false); // e-mail only
  contact(pool[1], false, true); // phone only
  contact(pool[2], true, true); // both
  return pool;
}

// ---------------------------------------------------------------- the plan
const snap = await db.collection('startups').get();
const startups = snap.docs
  .map((d) => ({ id: d.id, ...d.data() }))
  .filter((s) => s.founderId === 'crunchbase-dataset') // real accounts' startups are NEVER touched
  .sort((a, b) => a.id.localeCompare(b.id));

const pool = makePool(250);
const founders = pool.filter((p) => p.isFounder);
const members = pool.filter((p) => !p.isFounder);
const profiles = new Map(); // id -> profile doc
const updates = new Map(); // startup id -> new teamMembers
const original = new Map(); // startup id -> old teamMembers

const sentence = (text) => {
  const t = String(text || '').replace(/\s+/g, ' ').trim();
  if (!t) return '';
  const m = t.match(/^(.{20,220}?[.!?])(\s|$)/);
  return (m ? m[1] : t.slice(0, 200)).trim();
};

let existingPeople = 0, filledStartups = 0, keptStartups = 0;
for (const s of startups) {
  const team = Array.isArray(s.teamMembers) ? s.teamMembers : [];
  const sector = sectorLabel(s.sector);
  const city = cityLabel(s.location);
  const desc = sentence(s.description || s.oneLinePitch);
  const r = rng(hash(s.id));
  let out;
  if (team.length) {
    // People already there: keep every field, add the link to a profile.
    keptStartups++;
    let founderSeen = false;
    out = team.map((m, i) => {
      existingPeople++;
      const role = String(m.role || '');
      const isFounder = !founderSeen && /founder|ceo/i.test(role);
      if (isFounder) founderSeen = true;
      const coFounder = !isFounder && /co-?founder/i.test(role);
      const id = `seed-${s.id}-${i}`;
      const kind = isFounder ? 'founder' : coFounder ? 'coFounder' : 'member';
      profiles.set(id, {
        fullName: m.fullName || m.name || 'Team member',
        role: 'founder',
        city,
        bio: [`${role || 'Team member'} at ${s.name}.`, desc].filter(Boolean).join(' '),
        sectorsOfInterest: sector ? [sector] : [],
        emailPublic: false, phonePublic: false,
        startups: [{ id: s.id, name: s.name, role: kind }],
        isSample: true,
      });
      return {
        ...m,
        contribution: m.contribution ?? m.shortBio ?? '',
        coFounder, invited: false, isFounder, email: m.email ?? '', uid: id,
      };
    });
  } else {
    filledStartups++;
    out = [];
    const taken = new Set();
    const choose = (list, salt) => {
      for (let k = 0; k < list.length; k++) {
        const p = list[(hash(s.id + salt) + k) % list.length];
        if (!taken.has(p.id) && p.startups.length < 30) { taken.add(p.id); return p; }
      }
      return null;
    };
    const f = choose(founders, 'f');
    if (f) {
      f.startups.push({ id: s.id, name: s.name, role: 'founder' });
      out.push({ fullName: f.name, email: '', role: f.role, contribution: f.contribution, coFounder: false, invited: false, isFounder: true, uid: f.id });
    }
    const n = Math.floor(r() * 4); // 0-3 team members
    for (let i = 0; i < n; i++) {
      const p = choose(members, `m${i}`);
      if (!p) continue;
      const co = r() < 0.35;
      p.startups.push({ id: s.id, name: s.name, role: co ? 'coFounder' : 'member' });
      out.push({ fullName: p.name, email: '', role: p.role, contribution: p.contribution, coFounder: co, invited: false, isFounder: false, uid: p.id });
    }
  }
  original.set(s.id, team);
  updates.set(s.id, out);
}
for (const p of pool) {
  if (!p.startups.length) continue;
  profiles.set(p.id, {
    fullName: p.name, role: 'founder', city: p.city, bio: p.bio, sectorsOfInterest: p.sectors,
    emailPublic: p.emailPublic, phonePublic: p.phonePublic,
    ...(p.emailPublic ? { email: p.email } : {}),
    ...(p.phonePublic ? { phone: p.phone } : {}),
    startups: p.startups, isSample: true,
  });
}

// ------------------------------------------------------------- safety checks
let problems = 0;
for (const [id] of updates) {
  const s = startups.find((x) => x.id === id);
  if (s.founderId !== 'crunchbase-dataset') { console.log('REFUSED: not a dataset startup', id); problems++; }
}
for (const [id, p] of profiles) {
  if (!id.startsWith('seed-') || p.isSample !== true) { console.log('REFUSED: bad profile id', id); problems++; }
  if (p.email && !p.emailPublic) { console.log('REFUSED: private e-mail in', id); problems++; }
  if (p.phone && !p.phonePublic) { console.log('REFUSED: private phone in', id); problems++; }
  if ((p.startups || []).length > 30) { console.log('REFUSED: >30 startups', id); problems++; }
}
const existingProfiles = await db.collection('publicProfiles').get();
const clash = existingProfiles.docs.filter((d) => profiles.has(d.id));
if (clash.length) { console.log('REFUSED: profile ids already exist:', clash.length); problems++; }

// ------------------------------------------------------------------- report
const withPool = [...updates.values()].filter((t) => t.some((m) => String(m.uid).startsWith('seed-pool'))).length;
console.log(JSON.stringify({
  datasetStartups: startups.length,
  realAccountStartupsLeftAlone: snap.size - startups.length,
  startupsKeepingTheirTeam: keptStartups,
  existingPeopleGettingAProfile: existingPeople,
  startupsGettingANewTeam: filledStartups,
  startupsUsingSamplePool: withPool,
  samplePoolSize: pool.length,
  profilesToCreate: profiles.size,
  startupWritesToTeamMembersOnly: updates.size,
  mode: WRITE ? 'WRITE' : 'DRY RUN (nothing is written)',
}, null, 2));
const sampleIds = [startups.find((s) => (s.teamMembers || []).length)?.id, startups.find((s) => !(s.teamMembers || []).length)?.id].filter(Boolean);
for (const id of sampleIds) {
  const s = startups.find((x) => x.id === id);
  console.log(`\n--- ${s.name} (${id}) ---`);
  console.log('before:', JSON.stringify((s.teamMembers || []).map((m) => `${m.fullName} (${m.role})`)));
  console.log('after: ', JSON.stringify(updates.get(id).map((m) => `${m.fullName} (${m.role})${m.isFounder ? ' [founder]' : m.coFounder ? ' [co-founder]' : ''}`)));
}
console.log('\nContact test people:');
for (const p of pool.slice(0, 3)) console.log(' ', p.name, '| email public:', p.emailPublic, '| phone public:', p.phonePublic);

if (problems) { console.log(`\n${problems} problem(s): nothing written.`); process.exit(2); }
if (!WRITE) { console.log('\nDry run only. Run again with --write to apply.'); process.exit(0); }

// -------------------------------------------------------------------- write
const backupDir = path.join(here, 'backups');
fs.mkdirSync(backupDir, { recursive: true });
const backupFile = path.join(backupDir, `teams_before_${Date.now()}.json`);
fs.writeFileSync(backupFile, JSON.stringify(Object.fromEntries(original), null, 1));
console.log('\nBackup of the original teams:', backupFile);

let ops = 0;
let batch = db.batch();
const flush = async () => { if (ops) { await batch.commit(); batch = db.batch(); ops = 0; } };
for (const [id, p] of profiles) {
  batch.create(db.collection('publicProfiles').doc(id), { ...p, updatedAt: FieldValue.serverTimestamp() });
  if (++ops >= 400) await flush();
}
for (const [id, team] of updates) {
  // ONLY the team list is written: update() leaves every other field alone.
  batch.update(db.collection('startups').doc(id), { teamMembers: team });
  if (++ops >= 400) await flush();
}
await flush();
console.log('Done. Profiles created:', profiles.size, '| startups updated:', updates.size);
