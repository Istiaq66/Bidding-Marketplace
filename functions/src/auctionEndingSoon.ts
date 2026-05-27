import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { sendPush } from './push';

const REGION = 'us-central1';
const BATCH_LIMIT = 50;
const WINDOW_MS = 60 * 60 * 1000; // notify ~1h before close

/**
 * Scheduled sweep that notifies interested users shortly before an auction
 * closes. Runs every 15 minutes; for each active product whose `endsAt` falls
 * within the next hour and that hasn't been flagged yet, notifies every
 * watcher and bidder (except the seller) and sets `endingSoonNotified` so the
 * reminder fires at most once.
 */
export const auctionEndingSoon = onSchedule(
  {
    schedule: 'every 15 minutes',
    region: REGION,
    timeoutSeconds: 300,
    memory: '256MiB',
  },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const soon = Timestamp.fromMillis(Date.now() + WINDOW_MS);

    const snap = await db
      .collection('products')
      .where('status', '==', 'active')
      .where('endsAt', '>', now)
      .where('endsAt', '<=', soon)
      .limit(BATCH_LIMIT)
      .get();

    if (snap.empty) {
      logger.debug('auctionEndingSoon: nothing closing soon');
      return;
    }

    for (const doc of snap.docs) {
      const data = doc.data() as Record<string, unknown>;
      if (data['endingSoonNotified'] === true) continue;
      try {
        await notifyEndingSoon(db, doc.id, data);
      } catch (err) {
        logger.error(`auctionEndingSoon failed for ${doc.id}`, err);
      }
    }
  },
);

async function notifyEndingSoon(
  db: Firestore,
  productId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const sellerId = (data['User Id'] as string | undefined) ?? '';
  const productName = (data['Product Name'] as string | undefined) ?? '';
  const productImage = (data['Image Url'] as string | undefined) ?? '';

  const recipients = new Set<string>();

  const watchers = await db
    .collection('watchlist')
    .where('Product Id', '==', productId)
    .get();
  watchers.forEach((d) => {
    const uid = d.data()['User Id'] as string | undefined;
    if (uid) recipients.add(uid);
  });

  const bidders = await db
    .collection('bids')
    .where('Product Id', '==', productId)
    .get();
  bidders.forEach((d) => {
    const uid = d.data()['Bidder Id'] as string | undefined;
    if (uid) recipients.add(uid);
  });

  if (sellerId) recipients.delete(sellerId);

  const batch = db.batch();
  for (const uid of recipients) {
    const ref = db
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .doc();
    batch.set(ref, {
      type: 'auction_ending_soon',
      productId,
      productName,
      productImage,
      amount: null,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  // Flag even when there were no recipients so we don't re-scan it every run.
  batch.update(db.collection('products').doc(productId), {
    endingSoonNotified: true,
  });

  await batch.commit();

  await Promise.all(
    [...recipients].map((uid) =>
      sendPush(db, uid, 'auction_ending_soon', productName, productId),
    ),
  );
}