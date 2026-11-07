import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(JSON.parse(readFileSync(process.argv[2], 'utf8'))) });
const snap = await admin.firestore().collection('startups').select('founderId', 'isPublic').get();
let dataset = 0, real = 0, realPublic = 0, datasetPublic = 0;
snap.forEach((d) => {
  const x = d.data();
  if (x.founderId === 'crunchbase-dataset') { dataset++; if (x.isPublic) datasetPublic++; }
  else { real++; if (x.isPublic) realPublic++; }
});
console.log(JSON.stringify({ total: snap.size, dataset, datasetPublic, real, realPublic }));
