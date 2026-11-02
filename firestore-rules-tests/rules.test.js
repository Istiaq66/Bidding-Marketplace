// Security-rules tests for ../firestore.rules. Run with `npm test` (starts the
// Firestore emulator via `firebase emulators:exec`).
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const SELLER = 'seller1';
const ALICE = 'alice';
const BOB = 'bob';
const PRODUCT = 'p1';
const IMG = `https://abc123.supabase.co/storage/v1/object/public/product_images/${SELLER}/x.jpg?v=1`;

let env;

const days = (n) => Timestamp.fromMillis(Date.now() + n * 86400000);
const db = (uid) => env.authenticatedContext(uid).firestore();

/** Fields a freshly listed product carries (mirrors ProductRepository.create). */
function newProduct(overrides = {}) {
  return {
    'User Id': SELLER,
    'Product Name': 'Bike',
    'Product Description': 'desc',
    'Minimum Bid Price': '100',
    Date: '2030-01-01',
    'Image Url': IMG,
    nameLower: 'bike',
    endsAt: days(7),
    currentBid: 100,
    bidCount: 0,
    minIncrement: 5,
    status: 'active',
    winnerId: null,
    sellerName: 'Seller',
    sellerPhoto: '',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

/** Seeds a product directly, bypassing rules. */
async function seedProduct(data = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'products', PRODUCT), {
      ...newProduct(),
      createdAt: Timestamp.now(),
      ...data,
    });
  });
}

/** Mirrors BidRepository.place: bid doc + product update in one transaction. */
function placeBid(uid, amount, { bidId, productUpdate } = {}) {
  const fs = db(uid);
  return runTransaction(fs, async (tx) => {
    const ref = doc(fs, 'products', PRODUCT);
    const snap = await tx.get(ref);
    const count = (snap.data().bidCount ?? 0) + 1;
    tx.set(doc(fs, 'bids', bidId ?? `${PRODUCT}_${count}`), {
      'Bidder Id': uid,
      'Product Id': PRODUCT,
      'Bid Amount': amount,
      'Bid Time': '2030-01-01 10:00',
      'Created At': serverTimestamp(),
    });
    tx.update(ref, {
      currentBid: amount,
      bidCount: count,
      highestBidderId: uid,
      ...productUpdate,
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-bidding',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

describe('products: create', () => {
  test('seller can list a valid product', async () => {
    await assertSucceeds(setDoc(doc(db(SELLER), 'products', 'new'), newProduct()));
  });

  test('cannot list for another user', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'products', 'new'), newProduct()));
  });

  for (const [name, patch] of [
    ['already ended', { status: 'ended' }],
    ['pre-set winner', { winnerId: ALICE }],
    ['fake bid count', { bidCount: 3 }],
    ['pre-set high bidder', { highestBidderId: ALICE }],
    ['missing endsAt', { endsAt: null }],
    ['endsAt in the past', { endsAt: days(-1) }],
    ['endsAt years away', { endsAt: days(3650) }],
    ['foreign image url', { 'Image Url': 'https://evil.example/x.jpg' }],
    ['image in another user folder', {
      'Image Url': IMG.replace(`/${SELLER}/`, `/${ALICE}/`),
    }],
    ['zero increment', { minIncrement: 0 }],
    ['unknown field', { hacked: true }],
  ]) {
    test(`rejects ${name}`, async () => {
      await assertFails(
        setDoc(doc(db(SELLER), 'products', 'new'), newProduct(patch)),
      );
    });
  }
});

describe('products: seller update', () => {
  test('seller cannot set winner / status / bid fields', async () => {
    await seedProduct({ bidCount: 2, currentBid: 150, highestBidderId: ALICE });
    const ref = doc(db(SELLER), 'products', PRODUCT);
    await assertFails(updateDoc(ref, { winnerId: BOB }));
    await assertFails(updateDoc(ref, { status: 'ended' }));
    await assertFails(updateDoc(ref, { bidCount: 0 }));
    await assertFails(updateDoc(ref, { currentBid: 1, highestBidderId: BOB }));
  });

  test('seller can edit while there are no bids', async () => {
    await seedProduct();
    await assertSucceeds(
      updateDoc(doc(db(SELLER), 'products', PRODUCT), {
        'Product Description': 'new',
        endsAt: days(10),
        currentBid: 120,
        'Minimum Bid Price': '120',
      }),
    );
  });

  test('seller cannot edit once bids exist', async () => {
    await seedProduct({ bidCount: 1, currentBid: 110, highestBidderId: ALICE });
    await assertFails(
      updateDoc(doc(db(SELLER), 'products', PRODUCT), {
        'Product Description': 'new',
      }),
    );
  });

  test('seller cannot rename via nameLower or edit to a past end date', async () => {
    await seedProduct();
    const ref = doc(db(SELLER), 'products', PRODUCT);
    await assertFails(updateDoc(ref, { nameLower: 'spam' }));
    await assertFails(updateDoc(ref, { endsAt: days(-1) }));
  });

  test('delete only without bids', async () => {
    await seedProduct({ bidCount: 1, currentBid: 110, highestBidderId: ALICE });
    await assertFails(deleteDoc(doc(db(SELLER), 'products', PRODUCT)));
    await seedProduct();
    await assertFails(deleteDoc(doc(db(ALICE), 'products', PRODUCT)));
    await assertSucceeds(deleteDoc(doc(db(SELLER), 'products', PRODUCT)));
  });
});

describe('bids', () => {
  test('valid first bid succeeds', async () => {
    await seedProduct();
    await assertSucceeds(placeBid(ALICE, 101));
  });

  test('outbid must clear the increment', async () => {
    await seedProduct();
    await assertSucceeds(placeBid(ALICE, 101));
    await assertFails(placeBid(BOB, 104)); // < 101 + 5
    await assertSucceeds(placeBid(BOB, 106));
  });

  test('first bid must exceed the start price', async () => {
    await seedProduct();
    await assertFails(placeBid(ALICE, 100));
  });

  test('seller cannot bid on own auction', async () => {
    await seedProduct();
    await assertFails(placeBid(SELLER, 200));
  });

  test('cannot bid on an ended auction', async () => {
    await seedProduct({ endsAt: Timestamp.fromMillis(Date.now() - 1000) });
    await assertFails(placeBid(ALICE, 200));
    await seedProduct({ status: 'ended' });
    await assertFails(placeBid(ALICE, 200));
  });

  test('bid doc alone (no product update) is rejected', async () => {
    await seedProduct();
    await assertFails(
      setDoc(doc(db(ALICE), 'bids', `${PRODUCT}_1`), {
        'Bidder Id': ALICE,
        'Product Id': PRODUCT,
        'Bid Amount': 1e12,
        'Bid Time': 'x',
        'Created At': serverTimestamp(),
      }),
    );
  });

  test('product price bump without a bid doc is rejected', async () => {
    await seedProduct();
    await assertFails(
      updateDoc(doc(db(ALICE), 'products', PRODUCT), {
        currentBid: 1e15,
        bidCount: 1,
        highestBidderId: ALICE,
      }),
    );
  });

  test('bid amount must match the new product price', async () => {
    await seedProduct();
    await assertFails(placeBid(ALICE, 101, { productUpdate: { currentBid: 500 } }));
  });

  test('cannot name someone else as high bidder', async () => {
    await seedProduct();
    await assertFails(
      placeBid(ALICE, 101, { productUpdate: { highestBidderId: BOB } }),
    );
  });

  test('bid id must follow {productId}_{bidCount}', async () => {
    await seedProduct();
    await assertFails(placeBid(ALICE, 101, { bidId: 'random' }));
  });

  test('bids for a nonexistent product are rejected', async () => {
    await assertFails(
      setDoc(doc(db(ALICE), 'bids', 'nope_1'), {
        'Bidder Id': ALICE,
        'Product Id': 'nope',
        'Bid Amount': 5,
        'Bid Time': 'x',
        'Created At': serverTimestamp(),
      }),
    );
  });
});

describe('notifications', () => {
  const seedNotif = () =>
    env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'notifications', ALICE, 'items', 'n1'), {
        type: 'auction_won',
        read: false,
      }),
    );

  test('owner can mark read and delete', async () => {
    await seedNotif();
    const ref = doc(db(ALICE), 'notifications', ALICE, 'items', 'n1');
    await assertSucceeds(updateDoc(ref, { read: true }));
    await assertSucceeds(deleteDoc(ref));
  });

  test('owner cannot change other fields or create', async () => {
    await seedNotif();
    const ref = doc(db(ALICE), 'notifications', ALICE, 'items', 'n1');
    await assertFails(updateDoc(ref, { type: 'outbid' }));
    await assertFails(
      setDoc(doc(db(ALICE), 'notifications', ALICE, 'items', 'n2'), { read: false }),
    );
  });

  test('others cannot read or touch them', async () => {
    await seedNotif();
    const ref = doc(db(BOB), 'notifications', ALICE, 'items', 'n1');
    await assertFails(getDoc(ref));
    await assertFails(updateDoc(ref, { read: true }));
  });
});

describe('follows', () => {
  const follow = (uid, id, sellerId) =>
    setDoc(doc(db(uid), 'follows', id), {
      followerId: uid,
      sellerId,
      createdAt: serverTimestamp(),
    });

  test('follow with canonical id', async () => {
    await assertSucceeds(follow(ALICE, `${ALICE}_${SELLER}`, SELLER));
  });

  test('rejects mismatched id or self-follow', async () => {
    await assertFails(follow(ALICE, 'whatever', SELLER));
    await assertFails(follow(ALICE, `${ALICE}_${ALICE}`, ALICE));
  });
});

describe('users: public profile', () => {
  test('owner can create and update public fields; others can read', async () => {
    const ref = doc(db(ALICE), 'users', ALICE);
    await assertSucceeds(setDoc(ref, { userId: ALICE, name: 'A', photo: null }));
    await assertSucceeds(setDoc(ref, { bio: 'hi' }, { merge: true }));
    await assertSucceeds(getDoc(doc(db(BOB), 'users', ALICE)));
  });

  test('private fields cannot be written to the public doc', async () => {
    const ref = doc(db(ALICE), 'users', ALICE);
    await assertFails(setDoc(ref, { userId: ALICE, email: 'a@x' }));
    await setDoc(ref, { userId: ALICE, name: 'A' });
    await assertFails(setDoc(ref, { phone: '1' }, { merge: true }));
    await assertFails(setDoc(ref, { fcmTokens: ['t'] }, { merge: true }));
  });

  test('cannot write another user or unknown fields', async () => {
    await assertFails(setDoc(doc(db(BOB), 'users', ALICE), { name: 'x' }));
    await assertFails(setDoc(doc(db(ALICE), 'users', ALICE), { isAdmin: true }));
  });

  test('owner can strip legacy private fields (migration)', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'users', ALICE), {
        userId: ALICE,
        name: 'A',
        email: 'a@x',
        fcmTokens: ['t'],
      }),
    );
    const ref = doc(db(ALICE), 'users', ALICE);
    // Can't update other fields while legacy private fields remain.
    await assertFails(updateDoc(ref, { bio: 'hi' }));
    await assertSucceeds(
      updateDoc(ref, { email: deleteField(), fcmTokens: deleteField() }),
    );
    await assertSucceeds(updateDoc(ref, { bio: 'hi' }));
  });
});

describe('users: private profile', () => {
  const priv = (uid, owner = uid) => doc(db(uid), 'users', owner, 'private', 'profile');

  test('owner can read and write contact, tokens, prefs', async () => {
    await assertSucceeds(
      setDoc(priv(ALICE), {
        email: 'a@x',
        phone: '1',
        address: 'street',
        fcmTokens: ['t1'],
        notificationPrefs: { outbid: false },
      }),
    );
    await assertSucceeds(getDoc(priv(ALICE)));
    await assertSucceeds(deleteDoc(priv(ALICE)));
  });

  test('other users cannot read or write it', async () => {
    await setDoc(priv(ALICE), { email: 'a@x', fcmTokens: ['t1'] });
    await assertFails(getDoc(priv(BOB, ALICE)));
    await assertFails(setDoc(priv(BOB, ALICE), { email: 'evil' }, { merge: true }));
  });

  test('only the profile doc, known keys, capped tokens', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'users', ALICE, 'private', 'other'), { email: 'a' }));
    await assertFails(setDoc(priv(ALICE), { isAdmin: true }));
    const tokens = Array.from({ length: 11 }, (_, i) => `t${i}`);
    await assertFails(setDoc(priv(ALICE), { fcmTokens: tokens }));
  });
});
