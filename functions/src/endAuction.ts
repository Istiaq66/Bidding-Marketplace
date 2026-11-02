import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import {
  FieldValue,
  Firestore,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { distinctUserIds, notifyUsers } from './notify';

const REGION = 'us-central1';
const PAGE_SIZE = 50;
/** Stop starting new work after this, leaving headroom under the timeout. */
const TIME_BUDGET_MS = 240_000;

/**
 * Scheduled sweep that closes expired auctions.
 *
 * Runs every 5 minutes. For each product where `status == 'active'` and
 * `endsAt <= now`, a transaction sets `status: 'ended'`, `winnerId` (the
 * product's `highestBidderId`, which the security rules keep consistent with
 * the bids) and `resultsNotified: false`. Notifications for the seller, the
 * winner and every other bidder are then sent, and `resultsNotified` flips to
 * true. Auctions whose notifications failed are retried on the next run.
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
    const started = Date.now();
    const outOfTime = () => Date.now() - started > TIME_BUDGET_MS;

    let closed = 0;
    while (!outOfTime()) {
      const expired = await db
        .collection('products')
        .where('status', '==', 'active')
        .where('endsAt', '<=', Timestamp.now())
        .limit(PAGE_SIZE)
        .get();
      if (expired.empty) break;

      let progress = 0;
      for (const doc of expired.docs) {
        if (outOfTime()) break;
        try {
          if (await closeAuction(db, doc.id)) progress++;
        } catch (err) {
          logger.error(`endAuction: closing ${doc.id} failed`, err);
        }
      }
      closed += progress;
      // Every doc in the page failed: stop rather than spin on them.
      if (progress === 0) break;
    }

    // Retry notifications for auctions closed earlier whose fan-out failed.
    const pending = await db
      .collection('products')
      .where('status', '==', 'ended')
      .where('resultsNotified', '==', false)
      .limit(PAGE_SIZE)
      .get();
    for (const doc of pending.docs) {
      if (outOfTime()) break;
      try {
        await notifyResults(db, doc.id, doc.data());
      } catch (err) {
        logger.error(`endAuction: notifying ${doc.id} failed`, err);
      }
    }

    logger.info(
      `endAuction: closed ${closed}, retried ${pending.size} pending notification(s)`,
    );
  },
);

/** Closes one auction and notifies everyone. Returns false if skipped. */
async function closeAuction(db: Firestore, productId: string): Promise<boolean> {
  const productRef = db.collection('products').doc(productId);

  const closedData = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(productRef);
    if (!fresh.exists) return null;

    const data = fresh.data() as Record<string, unknown>;
    if (data.status !== 'active') return null;

    const endsAt = data.endsAt as Timestamp | undefined;
    if (endsAt && endsAt.toMillis() > Date.now()) return null;

    const winnerId = (data.highestBidderId as string | undefined) ?? null;
    const update = {
      status: 'ended',
      winnerId,
      endedAt: FieldValue.serverTimestamp(),
      resultsNotified: false,
    };
    tx.update(productRef, update);
    return { ...data, ...update };
  });

  if (!closedData) return false;
  await notifyResults(db, productId, closedData);
  return true;
}

/** Sends seller / winner / loser notifications, then marks them sent. */
async function notifyResults(
  db: Firestore,
  productId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const sellerId = (data['User Id'] as string | undefined) ?? '';
  const winnerId = (data.winnerId as string | null | undefined) ?? null;
  const amount = winnerId ? ((data.currentBid as number | undefined) ?? null) : null;
  const base = {
    productId,
    productName: (data['Product Name'] as string | undefined) ?? '',
    productImage: (data['Image Url'] as string | undefined) ?? '',
    amount,
  };

  const bidders = await distinctUserIds(
    db,
    'bids',
    'Product Id',
    productId,
    'Bidder Id',
  );
  const losers = [...bidders].filter((id) => id !== winnerId && id !== sellerId);

  // Run all three so one failure doesn't block the others; rethrow after.
  const results = await Promise.allSettled([
    notifyUsers(db, sellerId ? [sellerId] : [], productId, {
      ...base,
      type: 'auction_ended_seller',
    }),
    notifyUsers(db, winnerId ? [winnerId] : [], productId, {
      ...base,
      type: 'auction_won',
    }),
    notifyUsers(db, losers, productId, { ...base, type: 'auction_lost' }),
  ]);
  const failure = results.find((r) => r.status === 'rejected');
  if (failure) throw (failure as PromiseRejectedResult).reason;

  await db
    .collection('products')
    .doc(productId)
    .update({ resultsNotified: true });
}
