# Bidding Marketplace

Cross-platform Flutter auction app. Users register, list items with images, place bids, manage a watchlist, and view their auctions and bid history.

## Tech Stack

- Flutter 3.7+ / Dart 3
- Material 3 with custom light/dark theme tokens
- State: `provider` 6.x
- Auth: Firebase Auth (email/password) + Google Sign-In
- Data: Cloud Firestore
- Storage: Firebase Storage (product and profile images)
- Local prefs: `shared_preferences` (theme persistence)

## Project Layout

```
lib/
  components/    Shared widgets (buttons, text fields, image holder)
  screens/       App screens (auth, home, dashboard, profile, product details, etc.)
  services/      Firebase wrappers (auth, user bootstrap, auction creation)
  providers/     Provider-based state (theme)
  util/          Design tokens (colors)
  main.dart      App entry point
```

Firestore collections: `users`, `products`, `bids`, `watchlist`.

## Setup

1. Install Flutter `>= 3.7.0`.
2. `flutter pub get`
3. Configure Firebase for Android and iOS (see https://firebase.flutter.dev/docs/overview):
   - Add `android/app/google-services.json`
   - Add `ios/Runner/GoogleService-Info.plist`
   - These files are gitignored — request them from a project admin.
4. Replace the Google Sign-In `serverClientId` in `lib/services/auth_service.dart` with your own OAuth client ID.
5. `flutter run`

## Android Notes

Multidex is enabled in `android/app/build.gradle` (`multiDexEnabled true`) — required because Firebase pushes the method count past the 64k limit.

## Status

Active development. See `PROMPT.md` for the engineering plan and phased PR sequence.