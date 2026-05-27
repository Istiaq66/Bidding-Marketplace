# Push Notifications Setup (FCM)

The app delivers push notifications via Firebase Cloud Messaging. In-app
notification docs (`notifications/{uid}/items`) are always written; a matching
FCM push is sent in addition, gated by the user's `notificationPrefs`.

## How it works

- **Client** (`lib/core/services/fcm_service.dart`)
  - Requests permission, fetches the device token, stores it under
    `users/{uid}.fcmTokens` (array — multi-device), refreshes on rotation, and
    removes it on logout / account deletion.
  - Foreground messages are shown via `flutter_local_notifications`
    (Android channel `auction_default`).
  - Tapping a notification (foreground, background, or cold start) routes to
    `ProductDetails` using the global navigator key and the `productId` data
    payload.
- **Server** (`functions/src/push.ts`)
  - `sendPush(db, uid, type, productName, productId, amount?)` reads the user's
    tokens + prefs, skips muted categories, sends `sendEachForMulticast`, and
    prunes tokens reported as `not-registered` / `invalid`.
  - Called from `onBidCreate`, `endAuction`, `auctionEndingSoon`,
    `onAuctionCreate`.

## Notification preference keys (`users/{uid}.notificationPrefs`)

| Key             | Covers                                            |
|-----------------|---------------------------------------------------|
| `sellerUpdates` | `bid_placed`, `auction_ended_seller`              |
| `outbid`        | `outbid`                                           |
| `endingSoon`    | `auction_ending_soon`                              |
| `newAuction`    | `new_auction`                                      |
| `results`       | `auction_won`, `auction_lost`                      |

Absent key = enabled. Edited in **Settings → Notifications**.

## Android

- `POST_NOTIFICATIONS` permission and the default channel meta-data are already
  in `android/app/src/main/AndroidManifest.xml`.
- No extra steps — FCM works with the committed `google-services.json`.

## iOS (required before push works on iОS)

1. In the Apple Developer portal, create an **APNs Auth Key** (.p8) and upload
   it to Firebase Console → Project Settings → Cloud Messaging.
2. Add `GoogleService-Info.plist` to `ios/Runner/` (gitignored — do not commit).
3. In Xcode, enable capabilities on the Runner target:
   - **Push Notifications**
   - **Background Modes** → *Remote notifications*.
4. Ensure the bundle id matches the Firebase iOS app.

## Deploy

```bash
cd functions && npm run deploy   # or: firebase deploy --only functions
```

The scheduled `auctionEndingSoon` and `endAuction` functions appear in the
Firebase console once deployed.