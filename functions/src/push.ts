import { getMessaging } from 'firebase-admin/messaging';
import { FieldValue, Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

/** Maps a notification type to the user's `notificationPrefs` mute key. */
const PREF_KEY: Record<string, string> = {
  bid_placed: 'sellerUpdates',
  auction_ended_seller: 'sellerUpdates',
  outbid: 'outbid',
  auction_ending_soon: 'endingSoon',
  new_auction: 'newAuction',
  auction_won: 'results',
  auction_lost: 'results',
};

/** Builds the user-facing title/body for a push of the given type. */
export function pushContent(
  type: string,
  productName: string,
  amount?: number | null,
): { title: string; body: string } {
  const amt = amount != null ? ` ($${amount})` : '';
  switch (type) {
    case 'bid_placed':
      return { title: 'New bid', body: `New bid on ${productName}${amt}` };
    case 'outbid':
      return { title: "You've been outbid", body: `Someone outbid you on ${productName}${amt}` };
    case 'auction_won':
      return { title: 'You won! 🎉', body: `You won ${productName}${amt}` };
    case 'auction_lost':
      return { title: 'Auction ended', body: `${productName} ended — you didn't win this time` };
    case 'auction_ended_seller':
      return { title: 'Your auction ended', body: `${productName} has ended` };
    case 'auction_ending_soon':
      return { title: 'Ending soon', body: `${productName} is closing within the hour` };
    case 'new_auction':
      return { title: 'New auction', body: `A seller you follow listed ${productName}` };
    default:
      return { title: 'Auction update', body: productName };
  }
}

/**
 * Sends an FCM push to a user's registered devices, honouring their
 * per-category mute preference, and prunes any tokens the FCM service reports
 * as no longer valid. No-ops when the user has no tokens or has muted the
 * category — the in-app notification doc is written separately by the caller.
 */
export async function sendPush(
  db: Firestore,
  uid: string,
  type: string,
  productName: string,
  productId: string,
  amount?: number | null,
): Promise<void> {
  if (!uid) return;
  // Tokens and prefs live in the owner-only `users/{uid}/private/profile`.
  // Users not yet migrated by the app still have them on `users/{uid}`.
  const userRef = db.collection('users').doc(uid);
  const privateRef = userRef.collection('private').doc('profile');
  const [userSnap, privateSnap] = await Promise.all([
    userRef.get(),
    privateRef.get(),
  ]);
  if (!userSnap.exists && !privateSnap.exists) return;

  const legacy = (userSnap.data() ?? {}) as Record<string, unknown>;
  const priv = (privateSnap.data() ?? {}) as Record<string, unknown>;

  const prefs = ((priv['notificationPrefs'] ?? legacy['notificationPrefs']) ??
    {}) as Record<string, unknown>;
  const key = PREF_KEY[type];
  if (key && prefs[key] === false) return; // muted

  const privateTokens = (priv['fcmTokens'] as string[] | undefined) ?? [];
  const legacyTokens = (legacy['fcmTokens'] as string[] | undefined) ?? [];
  // FCM multicast accepts at most 500 tokens.
  const tokens = [...new Set([...privateTokens, ...legacyTokens])].slice(0, 500);
  if (tokens.length === 0) return;

  const { title, body } = pushContent(type, productName, amount);

  try {
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { type, productId: productId ?? '' },
      android: { priority: 'high' },
    });

    const invalid: string[] = [];
    res.responses.forEach((r, i) => {
      const code = r.error?.code;
      if (
        !r.success &&
        (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token')
      ) {
        invalid.push(tokens[i]);
      }
    });

    if (invalid.length > 0) {
      const prune = { fcmTokens: FieldValue.arrayRemove(...invalid) };
      await Promise.all([
        privateSnap.exists ? privateRef.update(prune) : null,
        legacyTokens.length > 0 ? userRef.update(prune) : null,
      ]);
    }
  } catch (err) {
    logger.error(`sendPush failed for ${uid}`, err);
  }
}