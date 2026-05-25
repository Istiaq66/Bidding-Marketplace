# Cloud Functions — Bidding Marketplace

TypeScript Cloud Functions powering the auction lifecycle, bid fan-out, and
search-index sync.

## Functions

| Name             | Trigger                                  | Purpose                                                                                              |
| ---------------- | ---------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `endAuction`     | Schedule — every 5 minutes               | Closes products where `status == 'active'` and `endsAt <= now`. Sets `winnerId`, notifies both parties. |
| `onBidCreate`    | Firestore `bids/{bidId}` onCreate        | Notifies the seller (`bid_placed`) and the previous high bidder (`outbid`).                          |
| `onAuctionWrite` | Firestore `products/{productId}` onWrite | Keeps `nameLower` (lowercased `Product Name`) in sync for prefix search. Idempotent.                 |

All functions deploy to `us-central1`. Change the `REGION` constant in each
`src/*.ts` to relocate.

## Prerequisites

- Node 20 LTS (`node -v`).
- Firebase CLI ≥ 13: `npm install -g firebase-tools`.
- Authenticated: `firebase login`.
- Project selected from repo root: `firebase use --add` (creates `.firebaserc`, gitignored intentionally — pick the project per environment).

## Install

```sh
cd functions
npm install
```

## Build

```sh
npm run build
```

Compiles `src/*.ts` → `lib/*.js`. The deploy step runs this automatically via
the `predeploy` hook in `firebase.json`.

## Local emulator

From the **repo root**:

```sh
firebase emulators:start --only functions,firestore
```

Or, equivalently, from `functions/`:

```sh
npm run serve
```

Scheduled functions do not auto-fire in the emulator. Invoke `endAuction`
manually:

```sh
cd functions
npm run shell
# inside the shell:
endAuction()
```

## Deploy

From the **repo root** (so `firebase.json` is picked up):

```sh
firebase deploy --only functions
```

Single function:

```sh
firebase deploy --only functions:endAuction
```

Rules + indexes + functions together:

```sh
firebase deploy --only firestore,functions
```

First-ever deploy may prompt to enable the Cloud Scheduler, Pub/Sub, and
Eventarc APIs — accept.

## Logs

```sh
firebase functions:log
firebase functions:log --only endAuction
```

## Schema assumptions

These functions read the schema defined in `../PROMPT.md` §2 and
`../firestore.rules`:

- `products/{id}`: `User Id`, `Product Name`, `Image Url`, `status`, `endsAt`
  (Timestamp), `nameLower`.
- `bids/{id}`: `Bidder Id`, `Product Id`, `Bid Amount` (number).
- `notifications/{uid}/items/{id}`: written by these functions; clients have
  read-only access per rules.

## Notes

- `endAuction` resolves the top bid **outside** the transaction (Firestore
  admin transactions can't run `orderBy`/`limit` queries) and re-reads the
  product **inside** the transaction; if the state has shifted (status no
  longer `active`, or `endsAt` extended), the close is skipped.
- `onAuctionWrite` performs a single `update({ nameLower })`. The early-exit
  when `current === expected` prevents infinite recursion on its own writes.
- Defensive client-side check already exists in
  `lib/screens/product_details_page.dart` — the Bid button is disabled when
  `product.isActive` is false. `endAuction` is the server-authoritative
  close.