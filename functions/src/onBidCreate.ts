import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { sendPush } from './push';

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
 * - Notifies the previous high bidder (second-highest bid right now) with
 *   `outbid`.
 */
export const onBidCreate = onDocumentCreated(
  { document: 'bids/{bidId}', region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const bid = snap.data() as BidDoc;
    const productId = bid['Product Id'];
    const bidderId = bid['Bidder Id'];
    const amount = bid['Bid Amount'];

    if (!productId || !bidderId) {
      logger.warn('onBidCreate: malformed bid', { id: snap.id });
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
    const productName = (product['Product Name'] as string | undefined) ?? '';
    const productImage = (product['Image Url'] as string | undefined) ?? '';

    const writes: Promise<unknown>[] = [];

    if (sellerId && sellerId !== bidderId) {
      const ref = db
        .collection('notifications')
        .doc(sellerId)
        .collection('items')
        .doc();
      writes.push(
        ref.set({
          type: 'bid_placed',
          productId,
          productName,
          productImage,
          amount,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        }),
      );
      writes.push(
        sendPush(db, sellerId, 'bid_placed', productName, productId, amount),
      );
    }

    // Find the previous high bidder: order all bids on this product by amount
    // desc; the new bid sits at index 0, the previous high sits at index 1.
    const topTwo = await db
      .collection('bids')
      .where('Product Id', '==', productId)
      .orderBy('Bid Amount', 'desc')
      .limit(2)
      .get();

    if (topTwo.size === 2) {
      const previous = topTwo.docs[1].data() as BidDoc;
      const prevBidder = previous['Bidder Id'];
      if (prevBidder && prevBidder !== bidderId) {
        const ref = db
          .collection('notifications')
          .doc(prevBidder)
          .collection('items')
          .doc();
        writes.push(
          ref.set({
            type: 'outbid',
            productId,
            productName,
            productImage,
            amount,
            read: false,
            createdAt: FieldValue.serverTimestamp(),
          }),
        );
        writes.push(
          sendPush(db, prevBidder, 'outbid', productName, productId, amount),
        );
      }
    }

    await Promise.all(writes);
  },
);
