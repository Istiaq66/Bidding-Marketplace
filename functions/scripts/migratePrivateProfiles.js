/* eslint-disable no-console */
// One-off migration: moves private fields (email, phone, address, fcmTokens,
// notificationPrefs) from the public `users/{uid}` doc into the owner-only
// `users/{uid}/private/profile` doc. The app does the same per user on login
// (UserRepository.migrateLegacyPrivateFields); this covers users who never
// open the new version.
//
// Usage (from functions/, with Admin credentials, e.g.
// GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json):
//   node scripts/migratePrivateProfiles.js            # dry run
//   node scripts/migratePrivateProfiles.js --apply    # write changes
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');

const PRIVATE_KEYS = ['email', 'phone', 'address', 'fcmTokens', 'notificationPrefs'];
const apply = process.argv.includes('--apply');

async function main() {
  initializeApp({ credential: applicationDefault() });
  const db = getFirestore();
  const users = await db.collection('users').get();

  let migrated = 0;
  let writer = db.bulkWriter();
  for (const doc of users.docs) {
    const data = doc.data();
    const legacy = {};
    for (const key of PRIVATE_KEYS) {
      if (key in data) legacy[key] = data[key];
    }
    if (Object.keys(legacy).length === 0) continue;

    migrated++;
    console.log(`${apply ? 'migrating' : 'would migrate'} ${doc.id}: ${Object.keys(legacy).join(', ')}`);
    if (!apply) continue;

    if (Array.isArray(legacy.fcmTokens)) {
      legacy.fcmTokens = FieldValue.arrayUnion(...legacy.fcmTokens);
    }
    const removals = Object.fromEntries(
      Object.keys(legacy).map((k) => [k, FieldValue.delete()]),
    );
    writer.set(doc.ref.collection('private').doc('profile'), legacy, { merge: true });
    writer.update(doc.ref, removals);
  }
  await writer.close();
  console.log(`${users.size} users scanned, ${migrated} ${apply ? 'migrated' : 'to migrate (dry run, pass --apply)'}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
