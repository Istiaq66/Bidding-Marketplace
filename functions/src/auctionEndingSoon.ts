import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import {
  Firestore,
  QueryDocumentSnapshot,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { distinctUserIds, notifyUsers } from './notify';

const REGION = 'us-central1';
const PAGE_SIZE = 100;
const WINDOW_MS = 60 * 60 * 1000; // notify ~1h before close

/**
 * Scheduled sweep that notifies interested users shortly before an auction
 * closes. Runs every 15 minutes; for each active product whose `endsAt` falls
 * within the next hour and that hasn't been flagged yet, notifies every
 * watcher and bidder (except the seller) and sets `endingSoonNotified` so the
 * reminder fires at most once.
 *
 * Pages through the whole window: auctions cluster at 23:59:59, so a single
 * fixed-size page full of already-notified products would starve the rest.
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

    let cursor: QueryDocumentSnapshot | undefined;
    let notified = 0;
    for (;;) {
      let query = db
        .collection('products')
        .where('status', '==', 'active')
        .where('endsAt', '>', now)
        .where('endsAt', '<=', soon)
        .orderBy('endsAt')
        .limit(PAGE_SIZE);
      if (cursor) query = query.startAfter(cursor);

      const snap = await query.get();
      if (snap.empty) break;
      cursor = snap.docs[snap.docs.length - 1];

      for (const doc of snap.docs) {
        const data = doc.data() as Record<string, unknown>;
        if (data['endingSoonNotified'] === true) continue;
        try {
          await notifyEndingSoon(db, doc.id, data);
          notified++;
        } catch (err) {
          logger.error(`auctionEndingSoon failed for ${doc.id}`, err);
        }
      }
      if (snap.size < PAGE_SIZE) break;
    }

    if (notified > 0) logger.info(`auctionEndingSoon: notified ${notified} auction(s)`);
  },
);

async function notifyEndingSoon(
  db: Firestore,
  productId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const sellerId = (data['User Id'] as string | undefined) ?? '';

  const [watchers, bidders] = await Promise.all([
    distinctUserIds(db, 'watchlist', 'Product Id', productId, 'User Id'),
    distinctUserIds(db, 'bids', 'Product Id', productId, 'Bidder Id'),
  ]);
  const recipients = new Set([...watchers, ...bidders]);
  if (sellerId) recipients.delete(sellerId);

  await notifyUsers(db, recipients, productId, {
    type: 'auction_ending_soon',
    productId,
    productName: (data['Product Name'] as string | undefined) ?? '',
    productImage: (data['Image Url'] as string | undefined) ?? '',
  });

  // Flag even when there were no recipients so we don't re-scan it every run.
  await db
    .collection('products')
    .doc(productId)
    .update({ endingSoonNotified: true });
}
