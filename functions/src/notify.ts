import { FieldValue, Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { sendPush } from './push';

export interface NotificationContent {
  type: string;
  productId: string;
  productName: string;
  productImage: string;
  amount?: number | null;
}

const ALREADY_EXISTS = 6; // gRPC status code
const PUSH_CONCURRENCY = 25;

/**
 * Writes one in-app notification per recipient (`notifications/{uid}/items`)
 * and sends a push to each recipient whose notification was newly created.
 *
 * Doc ids are `{type}_{eventKey}` and written with `create()`, so a retried
 * trigger or a re-run sweep never duplicates a notification or its push.
 * Uses BulkWriter, so the recipient count isn't capped by the 500-write
 * batch limit.
 *
 * Throws after attempting everything if any write failed, so the caller can
 * retry; already-delivered recipients are skipped on the retry.
 */
export async function notifyUsers(
  db: Firestore,
  recipients: Iterable<string>,
  eventKey: string,
  content: NotificationContent,
): Promise<number> {
  const writer = db.bulkWriter();
  writer.onWriteError(
    (err) => err.code !== ALREADY_EXISTS && err.failedAttempts < 5,
  );

  const created: string[] = [];
  let failed = 0;
  const writes: Promise<void>[] = [];

  for (const uid of new Set(recipients)) {
    if (!uid) continue;
    const ref = db
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .doc(`${content.type}_${eventKey}`);
    writes.push(
      writer
        .create(ref, {
          ...content,
          amount: content.amount ?? null,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        })
        .then(() => {
          created.push(uid);
        })
        .catch((err: { code?: number }) => {
          if (err.code === ALREADY_EXISTS) return;
          failed++;
          logger.error(`notifyUsers: write failed for ${uid}`, err);
        }),
    );
  }
  await writer.close();
  await Promise.all(writes);

  for (let i = 0; i < created.length; i += PUSH_CONCURRENCY) {
    await Promise.all(
      created
        .slice(i, i + PUSH_CONCURRENCY)
        .map((uid) =>
          sendPush(
            db,
            uid,
            content.type,
            content.productName,
            content.productId,
            content.amount,
          ),
        ),
    );
  }

  if (failed > 0) {
    throw new Error(`notifyUsers: ${failed} notification write(s) failed`);
  }
  return created.length;
}

/** Distinct values of [field] across docs of [collection] matching productId. */
export async function distinctUserIds(
  db: Firestore,
  collection: string,
  productField: string,
  productId: string,
  userField: string,
): Promise<Set<string>> {
  const snap = await db
    .collection(collection)
    .where(productField, '==', productId)
    .select(userField)
    .get();
  const ids = new Set<string>();
  snap.forEach((d) => {
    const uid = d.get(userField);
    if (typeof uid === 'string' && uid) ids.add(uid);
  });
  return ids;
}
