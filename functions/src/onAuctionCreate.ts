import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { notifyUsers } from './notify';

const REGION = 'us-central1';

/**
 * Fan-out a `new_auction` notification to every follower of the seller when a
 * new product is created. Followers live in `follows/{followerId}_{sellerId}`
 * documents shaped as `{ followerId, sellerId, createdAt }`.
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
    const db = getFirestore();
    const followers = await db
      .collection('follows')
      .where('sellerId', '==', sellerId)
      .select('followerId')
      .get();

    const followerIds = followers.docs
      .map((d) => d.get('followerId') as string | undefined)
      .filter((id): id is string => !!id && id !== sellerId);
    if (followerIds.length === 0) return;

    const sent = await notifyUsers(db, followerIds, productId, {
      type: 'new_auction',
      productId,
      productName: (data['Product Name'] as string | undefined) ?? '',
      productImage: (data['Image Url'] as string | undefined) ?? '',
    });
    logger.info(`onAuctionCreate: notified ${sent} follower(s) of ${sellerId}`);
  },
);
