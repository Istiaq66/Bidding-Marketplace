import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';

const REGION = 'us-central1';
const BATCH_LIMIT = 50;

interface BidDoc {
  'Bidder Id': string;
  'Bid Amount': number;
  'Product Id': string;
}

/**
 * Scheduled sweep that closes expired auctions.
 *
 * Runs every 5 minutes. For each product where `status == 'active'` and
 * `endsAt <= now`, transitions the doc to `status == 'ended'`, sets
 * `winnerId` to the top bidder (if any), and writes notifications for the
 * winner and the seller.
 */
export const endAuction = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: REGION,
    timeoutSeconds: 300,
    memory: '256MiB',
  },
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();

    const expired = await db
      .collection('products')
      .where('status', '==', 'active')
      .where('endsAt', '<=', now)
      .limit(BATCH_LIMIT)
      .get();

    if (expired.empty) {
      logger.debug('endAuction: no expired auctions');
      return;
    }

    logger.info(`endAuction: closing ${expired.size} auction(s)`);

    for (const productSnap of expired.docs) {
      const productId = productSnap.id;
      try {
        await closeAuction(db, productId);
      } catch (err) {
        logger.error(`endAuction failed for ${productId}`, err);
      }
    }
  },
);

async function closeAuction(db: Firestore, productId: string): Promise<void> {
  // Resolve the top bid outside the transaction. Firestore transactions
  // cannot run queries with orderBy/limit, so we read once up front; the
  // transaction re-reads the product and aborts if state has shifted.
  const topBidSnap = await db
    .collection('bids')
    .where('Product Id', '==', productId)
    .orderBy('Bid Amount', 'desc')
    .limit(1)
    .get();

  const topBid = topBidSnap.empty
    ? null
    : (topBidSnap.docs[0].data() as BidDoc);

  const productRef = db.collection('products').doc(productId);

  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(productRef);
    if (!fresh.exists) return;

    const data = fresh.data() as Record<string, unknown>;
    if (data.status !== 'active') return;

    const endsAt = data.endsAt as Timestamp | undefined;
    if (endsAt && endsAt.toMillis() > Date.now()) return;

    const winnerId = topBid?.['Bidder Id'] ?? null;

    tx.update(productRef, {
      status: 'ended',
      winnerId,
      endedAt: FieldValue.serverTimestamp(),
    });

    const sellerId = (data['User Id'] as string | undefined) ?? '';
    const productName = (data['Product Name'] as string | undefined) ?? '';
    const productImage = (data['Image Url'] as string | undefined) ?? '';

    if (sellerId) {
      const sellerNotifRef = db
        .collection('notifications')
        .doc(sellerId)
        .collection('items')
        .doc();
      tx.set(sellerNotifRef, {
        type: 'auction_ended_seller',
        productId,
        productName,
        productImage,
        amount: topBid?.['Bid Amount'] ?? null,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    if (topBid && winnerId) {
      const winnerRef = db
        .collection('notifications')
        .doc(winnerId)
        .collection('items')
        .doc();
      tx.set(winnerRef, {
        type: 'auction_won',
        productId,
        productName,
        productImage,
        amount: topBid['Bid Amount'],
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });
}