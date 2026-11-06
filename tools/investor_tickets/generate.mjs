// Builds the new values for the DATASET investors (isDataset == true). Writes
// nothing to Firebase.
//
// WHAT IT MAKES (for the 104 dataset investors only; app investors are skipped)
//   1. investmentsCount   the real "Number of Investments" from the Crunchbase
//                         file, put in the app's options (0, 1–3, 4–6, 7–9, 10+)
//   2. ticketSize         assumed typical ticket size (score + spread)
//   3. tickets            sample tickets for half of them; about 70% are made to
//                         fit a real raising startup, the rest are left free
//
// INPUT
//   output/investors_backup.json and output/startups.json (export_investors.mjs)
//   the Crunchbase investors file (matched by CB Rank (Investor) = crunchbaseRank)
//
// OUTPUT
//   output/plan.json            what upload.mjs writes
//   output/investors_new.csv    every step for every investor (for the report)
//   output/tickets.csv          every ticket, and which startups it fits
//
// USAGE
//   node generate.mjs <crunchbase-investors.csv>
//
// Random draws use mulberry32: seed 2026 for step 2 and 2027 for step 3
// (separate, so the steps don't share the same numbers). Running it again
// gives exactly the same result.

import fs from 'fs';

const [cbPath] = process.argv.slice(2);
if (!cbPath) {
  console.log('node generate.mjs <crunchbase-investors.csv>');
  process.exit(1);
}

const SEED = 2026;

// small seeded random generator (mulberry32), returns 0 <= x < 1
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// picks a key from { key: chance } with a draw r (chances add up to 1)
function pick(table, r) {
  let acc = 0;
  for (const [k, p] of Object.entries(table)) {
    acc += p;
    if (r < acc) return k;
  }
  return Object.keys(table).at(-1);
}

// csv with quoted fields (commas, quotes and new lines inside quotes)
function readCsv(text) {
  const rows = [];
  let row = [];
  let cell = '';
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (c === '"') quoted = false;
      else cell += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(cell); cell = ''; }
    else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(cell); rows.push(row); row = []; cell = '';
    } else cell += c;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  const [head, ...rest] = rows.filter((r) => r.some((x) => x.trim()));
  const names = head.map((h) => h.replace(/^﻿/, '').trim());
  return rest.map((r) => Object.fromEntries(names.map((n, i) => [n, (r[i] ?? '').trim()])));
}

const BANDS = ['Under SAR 100K', 'SAR 100K – 500K', 'SAR 500K – 1M', 'SAR 1M – 5M', 'Over SAR 5M'];

// ---- step 1: investmentsCount (real number -> the app's option) ----
const countOption = (n) => (n === 0 ? '0' : n <= 3 ? '1–3' : n <= 6 ? '4–6' : n <= 9 ? '7–9' : '10+');

// ---- step 2: ticketSize ----
const STAGE_POINTS = { 'Pre-seed': 0, 'Seed': 1, 'Series A': 2, 'Series B': 3, 'Series C': 3 };
const COUNT_POINTS = { '0': 0, '1–3': 0, '4–6': 1, '7–9': 1, '10+': 2 };
// score -> centre band (index in BANDS), from the published ranges per angel type
//   0   first-time angel        $5K–25K    -> Under SAR 100K
//   1-2 individual angel        $25K–100K  -> SAR 100K – 500K
//   3   super angel             $100K–500K -> SAR 500K – 1M
//   4+  family office / top     $500K–2M+  -> SAR 1M – 5M
const CENTRE = { 0: 0, 1: 1, 2: 1, 3: 2, 4: 3 };
// 60% centre band, 20% one lower, 20% one higher
const SPREAD = { '-1': 0.2, '0': 0.6, '1': 0.2 };

// ---- step 3: tickets ----
const SHARE_WITH_TICKETS = 0.5;
const HOW_MANY = { 1: 0.3, 2: 0.45, 3: 0.25 };
const FIT_A_STARTUP = 0.7;
const STATUS = { open: 0.85, closed: 0.15 };
// amount limits for a ticket, per band (SAR)
const LIMITS = [
  [25000, 100000],
  [100000, 500000],
  [500000, 1000000],
  [1000000, 5000000],
  [5000000, 10000000],
];
// lib/recommender/knowledge_filter.dart: investor label -> startup stored value
const SECTOR_VALUE = {
  HealthTech: 'healthtech', Fintech: 'fintech', EdTech: 'edtech', 'E-commerce': 'ecommerce',
  Logistics: 'logistics', AgriTech: 'agritech', PropTech: 'proptech', CleanTech: 'cleantech',
  Tourism: 'tourism', SaaS: 'saas', AI: 'ai', Cybersecurity: 'cybersecurity', Gaming: 'gaming',
  Media: 'media', FoodTech: 'foodtech', Mobility: 'mobility', Retail: 'retail', Energy: 'energy',
  InsurTech: 'insurtech', LegalTech: 'legaltech', 'HR Tech': 'hr_tech', Biotech: 'biotech',
  Manufacturing: 'manufacturing', Sports: 'sports', Other: 'other',
};
const STAGE_VALUE = {
  'Pre-seed': 'pre_seed', Seed: 'seed', 'Series A': 'series_a', 'Series B': 'series_b',
  'Series C': 'series_c', Other: 'other',
};

const roundTo = (n) => {
  const step = n < 100000 ? 5000 : n < 1000000 ? 25000 : n < 5000000 ? 100000 : 250000;
  return Math.round(n / step) * step;
};
const roundDown = (n) => {
  const step = n < 100000 ? 5000 : n < 1000000 ? 25000 : n < 5000000 ? 100000 : 250000;
  return Math.floor(n / step) * step;
};

const SECTOR_WORD = {
  HealthTech: 'health tech', Fintech: 'fintech', EdTech: 'edtech', 'E-commerce': 'e-commerce',
  Logistics: 'logistics', AgriTech: 'agritech', PropTech: 'proptech', CleanTech: 'clean tech',
  Tourism: 'tourism', SaaS: 'SaaS', AI: 'AI', Cybersecurity: 'cybersecurity', Gaming: 'gaming',
  Media: 'media', FoodTech: 'food tech', Mobility: 'mobility', Retail: 'retail', Energy: 'energy',
  InsurTech: 'insurtech', LegalTech: 'legal tech', 'HR Tech': 'HR tech', Biotech: 'biotech',
  Manufacturing: 'manufacturing', Sports: 'sports', Other: 'new ideas',
};
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

// names people actually give: some about the sector, some about the stage,
// some about the plan, some just casual. "small" names only for small tickets
function nameOptions(t, city) {
  const w = SECTOR_WORD[t.sectors[0]] ?? t.sectors[0];
  const early = t.stages.includes('Pre-seed');
  const small = t.amountMax <= 250000;
  return [
    `${cap(w)} picks`,
    `Early ${w}`,
    `${cap(w)}, one more`,
    `Betting on ${w}`,
    `${cap(w)} this year`,
    `Next ${w} startup`,
    `${w} stuff`,
    `The ${w} one`,
    t.sectors.length > 1 ? `${cap(w)} and ${SECTOR_WORD[t.sectors[1]] ?? t.sectors[1]}` : `Only ${w}`,
    early ? 'Pre-seed punts' : 'Seed round money',
    early ? 'Very early bets' : 'Follow-on money',
    t.stages.some((s) => s.startsWith('Series')) ? 'Growth round' : 'Early stage 2026',
    `${city} founders`,
    small ? 'Small bets 2026' : 'Bigger bet this year',
    'Next angel deal',
    'Founder I believe in',
    'Second check',
    'Side portfolio',
    'Saudi founders fund',
    'Long-term hold',
    small ? 'Learning bets' : 'Serious one',
    'Q1 plan',
    'This year’s budget',
    'One good team',
  ];
}

// ---- run ----
const all = JSON.parse(fs.readFileSync('output/investors_backup.json', 'utf8'));
const dataset = all.filter((d) => d.data.isDataset === true).sort((a, b) => a.id.localeCompare(b.id));
console.log(`Dataset investors: ${dataset.length} (skipped ${all.length - dataset.length} app investors)`);

const rank = (v) => Number(String(v ?? '').replace(/,/g, ''));
const crunchbase = new Map(readCsv(fs.readFileSync(cbPath, 'utf8')).map((r) => [rank(r['CB Rank (Investor)']), r]));
const missing = dataset.filter((d) => !crunchbase.has(rank(d.data.crunchbaseRank)));
if (missing.length) {
  console.log(`Stopped: ${missing.length} investor(s) not in the Crunchbase file:`);
  for (const d of missing) console.log(`  ${d.id} ${d.data.fullName} (rank ${d.data.crunchbaseRank})`);
  process.exit(1);
}

// raising startups (public, looking for funding, with an amount)
const startups = JSON.parse(fs.readFileSync('output/startups.json', 'utf8'))
  .map(({ id, data }) => ({
    id,
    name: data.name ?? '',
    sector: data.sector,
    stage: data.stage,
    need: Math.max(0, (data.fundingRequirement ?? 0) - (data.raisedInRound ?? 0)),
    raising: data.isPublic === true && (data.lookingFor ?? []).includes('funding') && (data.fundingRequirement ?? 0) > 0,
  }))
  .filter((s) => s.raising && s.need > 0);
console.log(`Raising startups: ${startups.length}`);

// a ticket fits a startup: same main sector and stage, and its minimum is
// not more than what the round still needs
const fits = (t, s) =>
  t.sectors.some((x) => SECTOR_VALUE[x] === s.sector) &&
  t.stages.some((x) => STAGE_VALUE[x] === s.stage) &&
  t.amountMin <= s.need;

const r2 = rng(SEED);
const r3 = rng(SEED + 1);

const rows = [];
const updates = [];
for (const { id, data } of dataset) {
  // step 1
  const cb = crunchbase.get(rank(data.crunchbaseRank));
  const realCount = Number(cb['Number of Investments'] || 0);
  const newCount = countOption(realCount);

  // step 2
  const stages = data.preferredStages ?? [];
  const stagePts = Math.max(0, ...stages.map((s) => STAGE_POINTS[s] ?? 0));
  const countPts = COUNT_POINTS[newCount] ?? 0;
  const leadPts = data.hasLedRound === true ? 1 : 0;
  const score = stagePts + countPts + leadPts;
  const centre = CENTRE[Math.min(score, 4)];
  const r = r2();
  const move = Number(pick(SPREAD, r));
  const band = Math.max(0, Math.min(BANDS.length - 1, centre + move));

  updates.push({ id, investmentsCount: newCount, ticketSize: BANDS[band] });
  rows.push({
    id, fullName: data.fullName ?? '', crunchbaseName: cb['Organization/Person Name'],
    stages: stages.join(' | '),
    realInvestments: realCount, oldInvestmentsCount: data.investmentsCount ?? '', newInvestmentsCount: newCount,
    hasLedRound: data.hasLedRound === true, stagePts, countPts, leadPts, score,
    centreBand: BANDS[centre], spreadDraw: r.toFixed(3), move,
    oldTicketSize: data.ticketSize ?? '', newTicketSize: BANDS[band], band,
    sectors: data.preferredSectors ?? [], stageList: stages, city: data.city ?? 'Riyadh',
  });
}

// step 3: shuffle the investors with the seed, the first half get tickets
const order = rows.map((x) => x.id);
for (let i = order.length - 1; i > 0; i--) {
  const j = Math.floor(r3() * (i + 1));
  [order[i], order[j]] = [order[j], order[i]];
}
const withTickets = new Set(order.slice(0, Math.round(rows.length * SHARE_WITH_TICKETS)));

const takeSome = (list, n, must) => {
  const out = must ? [must] : [];
  const copy = list.filter((x) => x !== must);
  while (out.length < n && copy.length) out.push(copy.splice(Math.floor(r3() * copy.length), 1)[0]);
  // keep the app's order
  return list.filter((x) => out.includes(x));
};
const labelOf = (map, value) => Object.keys(map).find((k) => map[k] === value);

const tickets = [];
const start = Date.UTC(2026, 0, 1);
const end = Date.UTC(2026, 10, 1);
let aimed = 0;
let noStartup = 0;
for (const row of rows) {
  if (!withTickets.has(row.id)) continue;
  const n = Number(pick(HOW_MANY, r3()));
  const used = new Set();
  const [lo, hi] = LIMITS[row.band];
  for (let k = 1; k <= n; k++) {
    // a startup this investor could back with a ticket from their own band
    let target = null;
    if (r3() < FIT_A_STARTUP) {
      aimed++;
      const options = startups.filter((s) =>
        row.sectors.some((x) => SECTOR_VALUE[x] === s.sector) &&
        row.stageList.some((x) => STAGE_VALUE[x] === s.stage) &&
        s.need >= lo);
      if (options.length) target = options[Math.floor(r3() * options.length)];
      else noStartup++;
    }
    const sectorCount = row.sectors.length > 1 && r3() < 0.5 ? 2 : 1;
    const stageCount = row.stageList.length > 1 && r3() < 0.5 ? 2 : 1;
    const t = {
      sectors: takeSome(row.sectors, sectorCount, target && labelOf(SECTOR_VALUE, target.sector)),
      stages: takeSome(row.stageList, stageCount, target && labelOf(STAGE_VALUE, target.stage)),
    };
    // amount inside the investor's typical band; a ticket made for a startup
    // starts at or below what that round still needs
    const top = target ? Math.min(hi, target.need) : hi;
    const min = Math.max(lo, roundDown(lo + r3() * 0.6 * (top - lo)));
    let max = roundTo(min + (0.3 + r3() * 0.7) * (hi - min));
    if (max <= min) max = roundTo(min * 1.5);
    t.amountMin = min;
    t.amountMax = max;
    const names = nameOptions(t, row.city).filter((x) => !used.has(x));
    const name = names[Math.floor(r3() * names.length)];
    used.add(name);
    tickets.push({
      id: `${row.id}-T${k}`,
      investorId: row.id,
      name,
      sectors: t.sectors,
      stages: t.stages,
      amountMin: min,
      amountMax: max,
      status: pick(STATUS, r3()),
      startupId: null,
      createdAt: new Date(start + r3() * (end - start)).toISOString(),
      isSample: true,
    });
  }
}

// which startups each ticket fits in the end (made for one or not)
const fitList = new Map(tickets.map((t) => [t.id, startups.filter((s) => fits(t, s))]));

fs.writeFileSync('output/plan.json', JSON.stringify({ seeds: [SEED, SEED + 1], updates, tickets }, null, 2));

const csv = (cols, list) => {
  const cell = (v) => {
    const s = Array.isArray(v) ? v.join(' | ') : String(v ?? '');
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return '﻿' + [cols.join(','), ...list.map((x) => cols.map((c) => cell(x[c])).join(','))].join('\n');
};
fs.writeFileSync('output/investors_new.csv', csv(['id', 'fullName', 'crunchbaseName', 'stages',
  'realInvestments', 'oldInvestmentsCount', 'newInvestmentsCount', 'hasLedRound', 'stagePts',
  'countPts', 'leadPts', 'score', 'centreBand', 'spreadDraw', 'move', 'oldTicketSize',
  'newTicketSize'], rows));
fs.writeFileSync('output/tickets.csv', csv(['id', 'investorId', 'name', 'sectors', 'stages',
  'amountMin', 'amountMax', 'status', 'createdAt', 'fitsStartups', 'fitsCount'],
  tickets.map((t) => ({ ...t, fitsStartups: fitList.get(t.id).map((s) => s.name), fitsCount: fitList.get(t.id).length }))));

// summary
const count = (list, f) => list.reduce((m, x) => ((m[f(x)] = (m[f(x)] ?? 0) + 1), m), {});
console.log('\ninvestmentsCount:', count(updates, (u) => u.investmentsCount));
console.log('score:', count(rows, (x) => Math.min(x.score, 4)));
console.log('ticketSize:');
for (const b of BANDS) console.log(`  ${b}: ${updates.filter((u) => u.ticketSize === b).length}`);
console.log(`\nInvestors with tickets: ${withTickets.size} of ${rows.length}`);
console.log('tickets per investor:', count([...withTickets], (id) => tickets.filter((t) => t.investorId === id).length));
console.log(`tickets: ${tickets.length}`, count(tickets, (t) => t.status));
const fitting = tickets.filter((t) => fitList.get(t.id).length > 0).length;
console.log(`made for a startup: ${aimed - noStartup} (no startup fitted for ${noStartup})`);
console.log(`fit at least one raising startup: ${fitting} of ${tickets.length} (${Math.round((fitting / tickets.length) * 100)}%)`);
console.log('\nSaved output/plan.json, output/investors_new.csv and output/tickets.csv');
