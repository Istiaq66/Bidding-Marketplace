// Auction lifecycle tests against the Firestore emulator. Run from functions/:
//   npm test
// (builds, then runs this file under `firebase emulators:exec`).
const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'demo-bidding';
const fns = require('../lib/index.js');
const db = getFirestore();

const ago = (ms) => Timestamp.fromMillis(Date.now() - ms);
const ahead = (ms) => Timestamp.fromMillis(Date.now() + ms);

async function clear() {
  for (const name of ['products', 'bids', 'watchlist', 'follows', 'notifications', 'users']) {
    await db.recursiveDelete(db.collection(name));
  }
}

async function items(uid) {
  const snap = await db.collection('notifications').doc(uid).collection('items').get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

function product(overrides = {}) {
  return {
    'User Id': 'seller',
    'Product Name': 'Bike',
    'Image Url': '',
    status: 'active',
    endsAt: ago(1000),
    currentBid: 100,
    bidCount: 0,
    ...overrides,
  };
}

async function bid(productId, n, bidder, amount) {
  await db.collection('bids').doc(`${productId}_${n}`).set({
    'Bidder Id': bidder,
    'Product Id': productId,
    'Bid Amount': amount,
  });
}

beforeEach(clear);

test('endAuction settles winner from product and notifies each party once', async () => {
  await db.collection('products').doc('p1').set(
    product({ currentBid: 130, bidCount: 3, highestBidderId: 'bob' }),
  );
  await bid('p1', 1, 'alice', 110);
  await bid('p1', 2, 'carol', 120);
  await bid('p1', 3, 'bob', 130);
  // Not expired yet: must stay open.
  await db.collection('products').doc('p2').set(product({ endsAt: ahead(60_000) }));

  await fns.endAuction.run({});
  await fns.endAuction.run({}); // second run must not duplicate anything

  const p1 = (await db.collection('products').doc('p1').get()).data();
  assert.equal(p1.status, 'ended');
  assert.equal(p1.winnerId, 'bob');
  assert.equal(p1.resultsNotified, true);
  assert.equal((await db.collection('products').doc('p2').get()).data().status, 'active');

  assert.deepEqual((await items('bob')).map((n) => n.type), ['auction_won']);
  assert.equal((await items('bob'))[0].amount, 130);
  assert.deepEqual((await items('seller')).map((n) => n.type), ['auction_ended_seller']);
  assert.deepEqual((await items('alice')).map((n) => n.type), ['auction_lost']);
  assert.deepEqual((await items('carol')).map((n) => n.type), ['auction_lost']);
});

test('endAuction with no bids closes without a winner', async () => {
  await db.collection('products').doc('p1').set(product());
  await fns.endAuction.run({});
  const p1 = (await db.collection('products').doc('p1').get()).data();
  assert.equal(p1.status, 'ended');
  assert.equal(p1.winnerId, null);
  const seller = await items('seller');
  assert.equal(seller.length, 1);
  assert.equal(seller[0].amount, null);
});

test('endAuction handles more bidders than one batch allows', async () => {
  const n = 600;
  await db.collection('products').doc('big').set(
    product({ currentBid: 100 + n, bidCount: n, highestBidderId: `u${n}` }),
  );
  const writer = db.bulkWriter();
  for (let i = 1; i <= n; i++) {
    writer.set(db.collection('bids').doc(`big_${i}`), {
      'Bidder Id': `u${i}`,
      'Product Id': 'big',
      'Bid Amount': 100 + i,
    });
  }
  await writer.close();

  await fns.endAuction.run({});

  const big = (await db.collection('products').doc('big').get()).data();
  assert.equal(big.status, 'ended');
  assert.equal(big.resultsNotified, true);
  assert.equal((await items(`u${n}`))[0].type, 'auction_won');
  assert.equal((await items('u1'))[0].type, 'auction_lost');
});

test('endAuction retries notifications left pending', async () => {
  await db.collection('products').doc('p1').set(
    product({ status: 'ended', winnerId: 'bob', currentBid: 150, resultsNotified: false }),
  );
  await fns.endAuction.run({});
  assert.equal((await items('bob'))[0].type, 'auction_won');
  assert.equal((await db.collection('products').doc('p1').get()).data().resultsNotified, true);
});

test('auctionEndingSoon notifies watchers and bidders once, past a full page', async () => {
  // 150 already-notified auctions ending sooner than the one that needs it.
  const writer = db.bulkWriter();
  for (let i = 0; i < 150; i++) {
    writer.set(db.collection('products').doc(`done${i}`), product({
      endsAt: ahead(60_000 + i), endingSoonNotified: true,
    }));
  }
  await writer.close();
  await db.collection('products').doc('p1').set(product({ endsAt: ahead(30 * 60_000) }));
  await db.collection('watchlist').add({ 'User Id': 'watcher', 'Product Id': 'p1' });
  await db.collection('watchlist').add({ 'User Id': 'seller', 'Product Id': 'p1' });
  await bid('p1', 1, 'alice', 110);

  await fns.auctionEndingSoon.run({});
  await fns.auctionEndingSoon.run({});

  assert.deepEqual((await items('watcher')).map((n) => n.type), ['auction_ending_soon']);
  assert.deepEqual((await items('alice')).map((n) => n.type), ['auction_ending_soon']);
  assert.equal((await items('seller')).length, 0);
  assert.equal((await db.collection('products').doc('p1').get()).data().endingSoonNotified, true);
});

test('onBidCreate notifies seller and the previous bidder, idempotently', async () => {
  await db.collection('products').doc('p1').set(product({ endsAt: ahead(60_000) }));
  await bid('p1', 1, 'alice', 110);
  await bid('p1', 2, 'bob', 120);
  const snap = await db.collection('bids').doc('p1_2').get();
  const event = { params: { bidId: 'p1_2' }, data: snap };

  await fns.onBidCreate.run(event);
  await fns.onBidCreate.run(event); // redelivery

  assert.deepEqual((await items('alice')).map((n) => n.type), ['outbid']);
  assert.deepEqual((await items('seller')).map((n) => n.type), ['bid_placed']);
  assert.equal((await items('bob')).length, 0);
});

test('onAuctionCreate notifies followers except the seller', async () => {
  await db.collection('follows').doc('f1_seller').set({ followerId: 'f1', sellerId: 'seller' });
  await db.collection('follows').doc('f2_seller').set({ followerId: 'f2', sellerId: 'seller' });
  await db.collection('products').doc('p1').set(product({ endsAt: ahead(60_000) }));
  const snap = await db.collection('products').doc('p1').get();

  await fns.onAuctionCreate.run({ params: { productId: 'p1' }, data: snap });

  assert.deepEqual((await items('f1')).map((n) => n.type), ['new_auction']);
  assert.deepEqual((await items('f2')).map((n) => n.type), ['new_auction']);
});
