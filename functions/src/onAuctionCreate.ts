import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { sendPush } from './push';

const REGION = 'us-central1';

/**
 * Fan-out a `new_auction` notification to every follower of the seller when a
 * new product is created. Followers live in `follows/{autoId}` documents
 * shaped as `{ followerId, sellerId, createdAt }`.
 */
export const onAuctionCreate = onDocumentCreated(
  { document: 'products/{productId}', region: REGION },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as Record<string, unknown>;
    const sellerId = (data['User Id'] as string | undefined) ?? '';
    if (!sellerId) return;

    const productId = event.params.productId;
    const productName = (data['Product Name'] as string | undefined) ?? '';
    const productImage = (data['Image Url'] as string | undefined) ?? '';

    const db = getFirestore();
    const followers = await db
      .collection('follows')
      .where('sellerId', '==', sellerId)
      .get();

    if (followers.empty) return;

    const batch = db.batch();
    const followerIds: string[] = [];
    followers.forEach((d) => {
      const followerId = d.data()['followerId'] as string | undefined;
      if (!followerId || followerId === sellerId) return;
      const ref = db
        .collection('notifications')
        .doc(followerId)
        .collection('items')
        .doc();
      batch.set(ref, {
        type: 'new_auction',
        productId,
        productName,
        productImage,
        amount: null,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
      followerIds.push(followerId);
    });

    if (followerIds.length > 0) {
      await batch.commit();
      await Promise.all(
        followerIds.map((id) =>
          sendPush(db, id, 'new_auction', productName, productId),
        ),
      );
      logger.info(
        `onAuctionCreate: notified ${followerIds.length} follower(s) of ${sellerId}`,
      );
    }
  },
);