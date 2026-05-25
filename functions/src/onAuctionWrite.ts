import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

const REGION = 'us-central1';

/**
 * Mirrors `Product Name` into the lowercased `nameLower` field used for
 * prefix-search queries. Idempotent — returns early when already in sync,
 * which prevents the function from recursing on its own writes.
 */
export const onAuctionWrite = onDocumentWritten(
  { document: 'products/{productId}', region: REGION },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const data = after.data() as Record<string, unknown>;
    const name = (data['Product Name'] as string | undefined) ?? '';
    const expected = name.toLowerCase();
    const current = (data['nameLower'] as string | undefined) ?? '';

    if (current === expected) return;

    await getFirestore()
      .collection('products')
      .doc(event.params.productId)
      .update({ nameLower: expected });
  },
);