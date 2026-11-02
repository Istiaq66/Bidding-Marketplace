import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import { notifyUsers } from './notify';

const REGION = 'us-central1';

interface BidDoc {
  'Bidder Id': string;
  'Bid Amount': number;
  'Product Id': string;
}

/**
 * Fan-out notifications when a new bid is created.
 *
 * - Notifies the seller with `bid_placed`.
 * - Notifies the previous high bidder with `outbid`.
 *
 * Notification ids are keyed by the bid id, so a retried trigger doesn't
 * notify twice.
 */
export const onBidCreate = onDocumentCreated(
  { document: 'bids/{bidId}', region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const bidId = event.params.bidId;
    const bid = snap.data() as BidDoc;
    const productId = bid['Product Id'];
    const bidderId = bid['Bidder Id'];
    const amount = bid['Bid Amount'];

    if (!productId || !bidderId) {
      logger.warn('onBidCreate: malformed bid', { id: bidId });
      return;
    }

    const db = getFirestore();
    const productSnap = await db.collection('products').doc(productId).get();
    if (!productSnap.exists) {
      logger.warn(`onBidCreate: product ${productId} missing`);
      return;
    }

    const product = productSnap.data() as Record<string, unknown>;
    const sellerId = (product['User Id'] as string | undefined) ?? '';
    const base = {
      productId,
      productName: (product['Product Name'] as string | undefined) ?? '',
      productImage: (product['Image Url'] as string | undefined) ?? '',
      amount,
    };

    const previous = await previousBidder(db, bidId, productId);
    const results = await Promise.allSettled([
      sellerId && sellerId !== bidderId
        ? notifyUsers(db, [sellerId], bidId, { ...base, type: 'bid_placed' })
        : Promise.resolve(0),
      previous && previous !== bidderId
        ? notifyUsers(db, [previous], bidId, { ...base, type: 'outbid' })
        : Promise.resolve(0),
    ]);
    const failure = results.find((r) => r.status === 'rejected');
    // Surface the failure in logs. Triggers are delivered at-least-once, and
    // any redelivery skips notifications that were already written.
    if (failure) throw (failure as PromiseRejectedResult).reason;
  },
);

/**
 * Bidder of the bid this one replaced as the high bid. Bids are stored as
 * `{productId}_{n}` (enforced by the security rules), so that's bid n-1.
 * Legacy auto-id bids fall back to the second-highest bid by amount.
 */
async function previousBidder(
  db: Firestore,
  bidId: string,
  productId: string,
): Promise<string | null> {
  const prefix = `${productId}_`;
  const n = bidId.startsWith(prefix) ? Number(bidId.slice(prefix.length)) : NaN;
  if (Number.isInteger(n)) {
    if (n <= 1) return null;
    const prev = await db.collection('bids').doc(`${prefix}${n - 1}`).get();
    if (prev.exists) return (prev.get('Bidder Id') as string | undefined) ?? null;
  }

  const topTwo = await db
    .collection('bids')
    .where('Product Id', '==', productId)
    .orderBy('Bid Amount', 'desc')
    .limit(2)
    .get();
  if (topTwo.size < 2) return null;
  return (topTwo.docs[1].get('Bidder Id') as string | undefined) ?? null;
}
