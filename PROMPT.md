# Bidding Marketplace — Completion Prompt (Senior Engineer)

You are a senior Flutter engineer taking over a partially built auction/bidding marketplace app. The skeleton, theming, auth, auction creation, bid placement, and watchlist are in place. Your job is to ship a production-quality v1 by fixing broken wiring, completing stubbed features, hardening the Firestore data model, and adding the missing core auction lifecycle. Do not rewrite working code. Do not introduce new state-management libraries (Provider stays). Do not change the design system (`lib/Util/colors.dart`, `lib/providers/theme_provider.dart`).

---

## 1. Tech Baseline (do not change)

- Flutter SDK `>=3.7.0 <4.0.0`, Dart 3.
- State: `provider` 6.x (`ThemeProvider` already wired via `MultiProvider` in `lib/main.dart`).
- Backend: Firebase Core / Auth / Firestore / Storage. Google Sign-In 7.x.
- Persistence: `shared_preferences` for theme only.
- Images: `image_picker` + `cached_network_image`.
- Pubspec name is `app` — keep it (do not rename to `auction_app`); update only README to match.

---

## 2. Current Firestore Schema (audit + harden)

Existing collections and the exact field names already written by the code:

- `users/{uid}`: `userId, name, email, photo, profileImage, phone, bio, address, updatedAt`
- `products/{autoId}`: `User Id, Product Name, Product Description, Minimum Bid Price, Date (yyyy-MM-dd string), Image Url`
- `bids/{autoId}`: `Bidder Id, Product Id, Bid Amount, Bid Time (yyyy-MM-dd HH:mm string), Created At (serverTimestamp)`
- `watchlist/{autoId}`: `User Id, Product Id, Added At (serverTimestamp)`

**Required changes (must be backward-compatible reads):**

1. Add the following fields on `products` write path in `lib/Services/new_auction_item.dart`:
   - `endsAt` (Timestamp, derived from `Date` at 23:59:59 local) — replace string-date comparisons over time, but keep writing `Date` for now.
   - `currentBid` (num, init = `Minimum Bid Price`)
   - `bidCount` (int, init 0)
   - `status` (`active` | `ended` | `cancelled`, init `active`)
   - `winnerId` (string?, init null)
   - `sellerName`, `sellerPhoto` (denormalized from `users` doc at creation)
   - `createdAt` (serverTimestamp)
2. On every successful bid in `lib/Screens/product_details_page.dart::_placeBid`, run a Firestore transaction that:
   - Re-reads the product, asserts `status == 'active'` and `endsAt > now`.
   - Asserts `Bid Amount > currentBid` (not just `> Minimum Bid Price`).
   - Writes the `bids` doc, increments `bidCount`, sets `currentBid` and `highestBidderId` on the product.
   - Rejects bids by the seller on their own product.
3. Add composite indexes (document in `firestore.indexes.json` at repo root):
   - `products` (`status` asc, `endsAt` asc)
   - `bids` (`Product Id` asc, `Bid Amount` desc)
   - `bids` (`Bidder Id` asc, `Created At` desc)
   - `watchlist` (`User Id` asc, `Added At` desc)
4. Ship `firestore.rules` at repo root enforcing:
   - `users/{uid}` writable only by `request.auth.uid == uid`.
   - `products` create requires `User Id == auth.uid`; update only to `status`, `currentBid`, `bidCount`, `winnerId`, `highestBidderId` and only via transaction-equivalent constraints; delete only by owner while `bidCount == 0`.
   - `bids` create requires `Bidder Id == auth.uid`, immutable thereafter.
   - `watchlist` create/delete requires `User Id == auth.uid`.

---

## 3. Bugs to fix (exact file:line)

1. `lib/Screens/navigation_page.dart:395` — logout dialog has `AuthService.signOut()` commented out. Wire it: call `AuthService.signOut()`, then let `AuthPage`'s `StreamBuilder` route back to login. Remove the navigator pop-then-push hack if present.
2. `lib/Screens/login.dart:117` — commented post-registration navigation. Remove the comment and the dead nav; rely on `authStateChanges()` in `AuthPage`.
3. `lib/Screens/bid.dart` and `lib/Components/product_card.dart` — both deprecated by `product_details_page.dart`. Delete both files and the empty `onPressed: () {}` at `bid.dart:104`. Update any imports.
4. `lib/Components/floating_action_button.dart` — unused. Delete.
5. `lib/Screens/watch_list_page.dart:93-112` — hardcoded `"Product Name"` / `"$100 • Ends in 2 days"`. Replace with a real `StreamBuilder` over `watchlist` filtered by `User Id == auth.uid`, joined to `products` via a second fetch (or denormalize product fields onto the watchlist doc on write).
6. `pubspec.yaml:33` — `flutter_lints: ^2.0.0` is stale for Dart 3. Bump to `^4.0.0` and fix any new lints.
7. README — replace boilerplate with real project description; remove `firebase_database` reference (you use Firestore + Storage, not RTDB).

---

## 4. Stubs to complete (exact file:line, each)

Dashboard filter sheet `navigation_page.dart:191` — wire selection to a `DashboardFilter` enum lifted to the `Dashboard` widget via a callback; apply against the `products` stream.

`navigation_page.dart:231` (Refresh) — trigger a `setState` plus re-subscribe; use `liquid_pull_to_refresh` already in pubspec on the Home and Dashboard lists.

`navigation_page.dart:245` (Sort) — bottom sheet with: Newest, Ending Soonest, Highest Bid, Lowest Min Bid. Pipe into the same stream query.

`navigation_page.dart:259, :318, :332` (Settings / Privacy / Help) — create three minimal screens under `lib/Screens/`: `settings_page.dart`, `privacy_page.dart`, `help_page.dart`. Settings hosts theme + notifications + account deletion entrypoint. Privacy is static markdown for now. Help shows FAQ + contact email.

`navigation_page.dart:304` (Edit Profile) — push `EditProfilePage` (already implemented in `lib/Screens/edit_profile_page.dart`).

`home.dart:45` (search icon) and `:131` (browse) — open a dedicated `SearchPage` that runs a Firestore prefix query on a lowercased `nameLower` field (add on write); fall back to client-side `contains` until index backfilled.

`home.dart:51` (notifications icon) — push `NotificationsPage` reading `notifications/{uid}/items` (see §5).

`dashboard.dart:131, :378` — wire to `NavigationPage` Home tab and `ProductDetailsPage(productId: ...)` respectively.

`dashboard.dart:290-304` (hardcoded recent activity) — replace with a `bids` query for the current user ordered by `Created At` desc, limit 5, each row resolving the `products` doc for the image/title.

`product_details_page.dart:375` (share) — use `share_plus` (add to pubspec) to share a deep link `https://<your-domain>/auction/{productId}`. Add `app_links` only if you wire deep links on Android/iOS; otherwise leave a TODO with the bundle ID note.

`profile.dart:196, :290, :301, :312` — share = `share_plus`; history = new `auction_history_page.dart` (closed auctions where user was bidder or seller); payment = stub page that explains "coming soon" and lists Stripe Connect as the planned integration; help routes to the same `help_page.dart`.

`my_auction_page.dart:36, :134` — push `AddNewItem` (already implemented).

`my_auction_page.dart:346` (Edit auction) — push a new `EditAuctionPage` that lets the seller update description, end date, and minimum bid **only when `bidCount == 0`** (enforce in rules too).

`my_bids_page.dart:179` — push `ProductDetailsPage(productId: ...)`.

---

## 5. Missing features to build

### 5.1 Auction lifecycle (highest priority)

- Server-authoritative end: write a Cloud Function in a new top-level `functions/` directory (TypeScript). Implement:
  - `endAuction` — scheduled (every 5 minutes) Firestore query for `products where status == 'active' and endsAt <= now`. For each, run a transaction that:
    - Sets `status = 'ended'`.
    - Reads the top bid (`bids` ordered by `Bid Amount` desc, limit 1) and sets `winnerId`.
    - Writes a `notifications/{userId}/items` doc for both winner and seller.
  - `onBidCreate` — Firestore trigger that creates a `notifications` doc for the seller and the previous high bidder ("outbid").
  - `onAuctionWrite` — keep `nameLower` in sync for search.
- Document deploy: `firebase deploy --only functions`.
- Until functions are deployed, add a defensive client-side check in `product_details_page.dart` that hides the Bid button when `endsAt <= now`.

### 5.2 Notifications (in-app, no FCM in v1)

- Collection `notifications/{uid}/items/{autoId}`: `type` (`bid_placed` | `outbid` | `auction_won` | `auction_lost` | `auction_ended_seller`), `productId`, `productName`, `productImage`, `amount?`, `read` (bool), `createdAt`.
- New screen `lib/Screens/notifications_page.dart`: stream items, mark-as-read on tap, badge unread count on the nav bell.

### 5.3 Search

- Add `nameLower` (lowercased `Product Name`) on product writes (client + backfill function).
- Prefix query: `where('nameLower', isGreaterThanOrEqualTo: q).where('nameLower', isLessThan: q + '').limit(20)`.

### 5.4 Pagination

- All list streams (`Home`, `Dashboard`, `MyAuctions`, `MyBids`, `Watchlist`) move to paged `query.startAfterDocument` with `limit(20)` and infinite scroll.

### 5.5 Account deletion

- In Settings, "Delete account" reauthenticates, then deletes the `users` doc, the user's `products` (only if `bidCount == 0`), the user's `bids`, the user's `watchlist`, and finally `FirebaseAuth.currentUser.delete()`.

---

## 6. Architecture & code quality requirements

- Introduce a `lib/models/` directory with immutable data classes for `Product`, `Bid`, `AppUser`, `WatchlistEntry`, `AppNotification`. Each has `fromFirestore(DocumentSnapshot)` and `toMap()`. Update all screens to consume models, not raw `Map<String, dynamic>`.
- Introduce `lib/repositories/` (one file per collection) wrapping Firestore queries. Screens depend on repositories, not on `FirebaseFirestore.instance` directly. Existing services (`auth_service.dart`, `new_user.dart`, `new_auction_item.dart`) move into this layer and are renamed: `auth_repository.dart`, `user_repository.dart`, `product_repository.dart`, `bid_repository.dart`, `watchlist_repository.dart`, `notification_repository.dart`. Keep one commit per move with no behavior change before refactoring callers.
- Rename top-level directories to lowercase to match Dart conventions: `lib/Screens` → `lib/screens`, `lib/Components` → `lib/components`, `lib/Services` → `lib/services` (becomes `lib/repositories`), `lib/Util` → `lib/util`. Update all imports. Verify on case-sensitive filesystems (CI) — Windows hides this.
- Replace `withOpacity` (deprecated in Flutter 3.27) with `.withValues(alpha: ...)`. Currently used in `navigation_page.dart:425` and elsewhere — sweep the tree.
- Add `analysis_options.yaml` rules: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `avoid_print`, `require_trailing_commas`. Fix all violations.
- Add error and empty states to every list/stream: handle `snapshot.hasError`, `ConnectionState.waiting`, and empty data with a consistent `EmptyState` widget.
- Wrap every Firebase call site with try/catch logging via a single `lib/util/logger.dart`; surface user-visible failures via a `ScaffoldMessenger` extension.

---

## 7. Testing

- Add `test/` with:
  - Unit tests for every repository using `fake_cloud_firestore` and `firebase_auth_mocks`.
  - Widget tests for `LoginRegister`, `ProductDetailsPage` (bid validation), `MyAuctionPage` (delete guard), `WatchListPage` (empty state).
  - One integration test under `integration_test/` that signs in anonymously (test mode), creates a product, places a bid, ends it via a forced clock, and asserts winner.
- Add `flutter test` and `flutter analyze` to CI: ship `.github/workflows/flutter.yml` running on `ubuntu-latest` with the FVM-pinned Flutter version.

---

## 8. Deliverables / definition of done

A reviewer pulling `main` should be able to:

1. `flutter pub get && flutter analyze` — zero errors, zero warnings.
2. `flutter test` — all tests green.
3. `flutter run` on Android emulator — register, log in with Google, create an auction with image, place a bid, get outbid, see notification, watchlist add/remove, dark/light toggle, edit profile, log out from both menu and profile, delete account.
4. Inspect Firestore — no documents with missing required fields; rules deployed; indexes present.
5. `cd functions && npm run deploy` — scheduled `endAuction` visible in Firebase console.

---

## 9. Sequencing (PRs, in order)

1. **PR1 — Hygiene.** Lint bump, dir lowercase rename, `withOpacity` sweep, delete `bid.dart` / `product_card.dart` / `floating_action_button.dart`, fix README, fix `login.dart:117`.
2. **PR2 — Logout + stubbed navigations.** Fix `navigation_page.dart:395` and wire every stub callback to its target screen (Settings/Privacy/Help shells, Edit Profile, AddNewItem from MyAuctions, etc.).
3. **PR3 — Models + repositories.** Introduce `lib/models/` and `lib/repositories/`; migrate screens, no feature changes.
4. **PR4 — Firestore hardening.** Add new product fields, transactional bid placement, rules, indexes, `nameLower` backfill script.
5. **PR5 — Watchlist + MyBids real data.** Wire to repositories; pagination on Home/Dashboard.
6. **PR6 — Search + Notifications screens.** Client-side flows only; notifications doc reads.
7. **PR7 — Cloud Functions.** `endAuction`, `onBidCreate`, `onAuctionWrite`. Deploy guide in `functions/README.md`.
8. **PR8 — Edit auction + account deletion + share.**
9. **PR9 — Tests + CI.**

Each PR must include: rationale in the description, before/after screenshots for any UI change, and a manual QA checklist.

---

## 10. Non-goals (v1)

- Payments / escrow / Stripe Connect.
- Multi-currency.
- Real-time chat between bidder and seller.
- Push notifications (FCM) — add in v1.1.
- Web/desktop builds — Android + iOS only.
- Ratings, disputes, reports.

---

## 11. Constraints

- Do not break existing Firestore documents. New required fields must be either backfilled by a one-shot script (`tools/backfill.dart`) committed in the same PR, or read with defensive defaults.
- Do not log PII. Strip emails from any analytics/logger output.
- Do not commit `google-services.json`, `GoogleService-Info.plist`, or `.env`. Add to `.gitignore` if missing.
- All user-visible strings go through a single `lib/util/strings.dart` constant file to ease later i18n. Do not add `intl`-based localization yet; just centralize.

Begin with PR1. Open each PR against `main`. Stop and ask before introducing any new top-level dependency not listed here.