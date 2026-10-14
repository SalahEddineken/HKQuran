#!/usr/bin/env node
/**
 * Noor Quran - Firebase Cloud Firestore Database Uploader
 * Uploads all 114 Surahs, 6,236 Ayahs, 30 Juzs, and Metadata to Firebase.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const PROJECT_ID = 'studio-5996533553-9d4ec';
const ROOT_DIR = path.resolve(__dirname, '..');
const ASSETS_DIR = path.join(ROOT_DIR, 'assets', 'quran');
const SURAHS_DIR = path.join(ASSETS_DIR, 'surahs');

function getAuthToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error('Firebase credentials not found at ' + configPath);
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config?.tokens?.access_token;
  if (!token) {
    throw new Error('No access_token found in firebase-tools.json');
  }
  return token;
}

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val) ? { integerValue: val.toString() } : { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (Array.isArray(val)) return { arrayValue: { values: val.map(toFirestoreValue) } };
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      if (v !== undefined) fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function writeDocument(token, docPath, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${docPath}`;
  const fields = toFirestoreValue(data).mapValue.fields;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ fields })
  });
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Write failed for ${docPath} (${res.status}): ${errText}`);
  }
  return res.json();
}

async function batchWrite(token, writes) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:batchWrite`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ writes })
  });
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`batchWrite failed (${res.status}): ${errText}`);
  }
  return res.json();
}

async function main() {
  console.log('========================================================');
  console.log('🚀 NOOR QURAN - FIREBASE CLOUD FIRESTORE UPLOADER');
  console.log(`Target Project: ${PROJECT_ID}`);
  console.log('========================================================\n');

  const token = getAuthToken();
  console.log('✓ Firebase authentication token obtained.');

  // 1. Upload 30 Juzs
  console.log('\n[1/4] Uploading 30 Juzs metadata...');
  const juzsPath = path.join(ASSETS_DIR, 'juzs.json');
  const juzs = JSON.parse(fs.readFileSync(juzsPath, 'utf8'));
  for (const juz of juzs) {
    await writeDocument(token, `juzs/${juz.number}`, juz);
  }
  console.log(`✓ Uploaded ${juzs.length} Juzs to 'juzs' collection.`);

  // 2. Upload Surahs Catalog to Metadata
  console.log('\n[2/4] Uploading Surahs metadata catalog...');
  const surahsMetaPath = path.join(ASSETS_DIR, 'surahs.json');
  const surahsMeta = JSON.parse(fs.readFileSync(surahsMetaPath, 'utf8'));
  await writeDocument(token, 'metadata/surahs', { list: surahsMeta });
  await writeDocument(token, 'metadata/app_info', {
    name: 'Noor',
    version: '1.0.0',
    totalSurahs: 114,
    totalVerses: 6236,
    totalJuzs: 30,
    updatedAt: new Date().toISOString()
  });
  console.log(`✓ Uploaded catalog with ${surahsMeta.length} surahs to 'metadata'.`);

  // 3. Upload 114 Surahs with complete embedded verses
  console.log('\n[3/4] Uploading 114 Surahs (including all verses array for instant fetch)...');
  let totalVersesCount = 0;
  const allVersesForSubcollection = [];

  for (let sNum = 1; sNum <= 114; sNum++) {
    const meta = surahsMeta.find(s => s.n === sNum) || { n: sNum, id: sNum };
    const versesFilePath = path.join(SURAHS_DIR, `${sNum}.json`);
    const verses = JSON.parse(fs.readFileSync(versesFilePath, 'utf8'));
    totalVersesCount += verses.length;

    const surahDoc = {
      ...meta,
      ayahsCount: verses.length,
      verses: verses
    };

    await writeDocument(token, `surahs/${sNum}`, surahDoc);
    process.stdout.write(`\r  Surah ${sNum}/114 (${meta.ar || ''} - ${meta.en || ''}) uploaded (${verses.length} verses)`);

    for (const v of verses) {
      allVersesForSubcollection.push({
        surahNum: sNum,
        ayahNum: v.n,
        verseData: v
      });
    }
  }
  console.log(`\n✓ All 114 Surahs successfully uploaded to 'surahs' collection!`);

  // 4. Upload individual Ayahs to subcollections: surahs/{surahId}/verses/{ayahNum}
  console.log(`\n[4/4] Uploading ${allVersesForSubcollection.length} individual Ayahs to subcollections in batches...`);
  const BATCH_SIZE = 150;
  let batchIndex = 0;
  const totalBatches = Math.ceil(allVersesForSubcollection.length / BATCH_SIZE);

  for (let i = 0; i < allVersesForSubcollection.length; i += BATCH_SIZE) {
    batchIndex++;
    const slice = allVersesForSubcollection.slice(i, i + BATCH_SIZE);
    const writes = slice.map(item => {
      const docFullName = `projects/${PROJECT_ID}/databases/(default)/documents/surahs/${item.surahNum}/verses/${item.ayahNum}`;
      return {
        update: {
          name: docFullName,
          fields: toFirestoreValue(item.verseData).mapValue.fields
        }
      };
    });

    await batchWrite(token, writes);
    process.stdout.write(`\r  Batch ${batchIndex}/${totalBatches} (${Math.min(i + BATCH_SIZE, allVersesForSubcollection.length)}/${allVersesForSubcollection.length} verses written)`);
  }
  console.log(`\n✓ All ${allVersesForSubcollection.length} Ayahs uploaded to subcollections!`);

  console.log('\n========================================================');
  console.log('🎉 UPLOAD COMPLETE!');
  console.log(`Total Surahs: 114`);
  console.log(`Total Juzs: 30`);
  console.log(`Total Verses: ${totalVersesCount}`);
  console.log(`Firestore Database: https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
  console.log('========================================================\n');
}

main().catch(err => {
  console.error('\n❌ Fatal Error during upload:', err);
  process.exit(1);
});
