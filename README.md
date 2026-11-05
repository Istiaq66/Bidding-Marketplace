# Bidding Marketplace

Cross-platform Flutter auction app. Users register, list items with images, place
bids, manage a watchlist, follow sellers, and get push/in-app notifications on
bids, outbids, and auction results.

## Tech Stack

- Flutter (version pinned in `.fvmrc`) / Dart 3
- Material 3 with custom light/dark theme tokens (`lib/core/theme`)
- State: `provider` 6.x
- Auth: Firebase Auth (email/password) + Google Sign-In
- Data: Cloud Firestore, secured by `firestore.rules` (tested in `firestore-rules-tests/`)
- Backend logic: Firebase Cloud Functions (`functions/`) — auction close, bid/follow
  notifications, FCM push, signed image-upload URLs
- Image storage: Supabase Storage, uploaded via signed URLs issued by a Cloud
  Function (see `docs/decisions/0001-supabase-storage.md`)
- Push: Firebase Cloud Messaging + `flutter_local_notifications`
- Local prefs: `shared_preferences` (theme persistence)

## Project Layout

Feature-first; see `ARCHITECTURE.md` for the full dependency rules.

```
lib/
  core/        Cross-cutting: theme, services (FCM, Supabase storage), shared widgets, utils
  features/
    auth/          Sign-in / sign-up
    auctions/      Listings: browse, search, create, edit, product details
    bids/          Placing bids, bid history
    watchlist/     Saved auctions
    notifications/ In-app notification feed
    profile/       Profile, settings, following, account deletion
    shell/         Bottom-nav container
    support/       Static privacy / help screens
  main.dart    App entry point
```

Firestore collections: `users` (+ `users/{uid}/private/profile`), `products`, `bids`,
`watchlist`, `follows`, `notifications/{uid}/items`.

## Setup

1. Install Flutter via [FVM](https://fvm.app/) (reads the version from `.fvmrc`), or
   any Flutter install matching `.fvmrc`.
2. `flutter pub get`
3. Configure Firebase for Android and iOS (see https://firebase.flutter.dev/docs/overview):
   - Add `android/app/google-services.json`
   - Add `ios/Runner/GoogleService-Info.plist`
   - These files are gitignored — request them from a project admin.
4. Replace the Google Sign-In `serverClientId` in
   `lib/features/auth/data/auth_repository.dart` with your own OAuth client ID.
5. Configure Supabase Storage (product/profile images — see
   `docs/decisions/0001-supabase-storage.md`):
   - Copy `supabase.example.json` to `supabase.json` and fill in your project URL +
     anon key. `supabase.json` is gitignored.
   - Apply the bucket config and policies: in the Supabase SQL editor run
     `supabase/policies.sql` (or `supabase db execute --file supabase/policies.sql`).
   - Uploads/deletes are signed by the `createImageUploadUrl` / `deleteImage` Cloud
     Functions — see `functions/README.md` for the service-role key setup.
6. Deploy Cloud Functions and Firestore rules (`functions/README.md`) — needed for
   auction closing, notifications, and image upload to work.
7. `flutter run --dart-define-from-file=supabase.json` (the `--dart-define-from-file`
   flag is required for every `run`/`build`; without it the app asserts on missing
   Supabase config).

## Testing

- `flutter test` — widget/unit tests.
- `firestore-rules-tests/` — Firestore security rules tests against the emulator
  (`npm test`, needs Java 21+). See that folder's `package.json`.
- `functions/test/` — Cloud Functions lifecycle tests against the emulator
  (`npm test` from `functions/`).

CI (`.github/workflows/ci.yml`) runs all three on every push/PR.

## Android Notes

- Application id: `com.bidplace.app`.
- Multidex is enabled in `android/app/build.gradle` (`multiDexEnabled true`) —
  required because Firebase pushes the method count past the 64k limit.

## Status

Active development. See `PROMPT.md` for the historical v1.1 engineering plan.
