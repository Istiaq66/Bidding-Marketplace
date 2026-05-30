# ADR 0001: Use Supabase Storage for product/profile images instead of Firebase Storage

- **Status:** Accepted
- **Date:** 2026-05-30
- **Context PR:** "Migrate image storage from Firebase to Supabase" (`db28a6b`)

## Context

The v1.1 plan (`PROMPT.md` §3) specifies Firebase Storage for the image-upload
feature that replaces the legacy URL-paste flow. `firebase_storage` was listed in
§1 as an authorized dependency.

During implementation we hit a blocker: **Firebase Storage now requires the paid
Blaze (pay-as-you-go) billing plan** to provision a bucket. The project runs on
the free Spark plan, so a Storage bucket could not be created without attaching a
billing account. Auth, Firestore, Cloud Functions, and FCM all remain on Firebase.

## Decision

Use **Supabase Storage** for product and profile images. Everything else stays on
Firebase. Implementation: `lib/core/services/storage_service.dart`.

- Bucket: `product_images` (public).
- Path layout: `{uid}/{id}.jpg` for products, `{uid}/avatar.jpg` for profiles —
  `{uid}` first so uid-based RLS works.
- Upload returns a public `https` URL written into the same legacy
  `Image Url` field, so existing documents and `cached_network_image` keep working
  with no auth header.
- Client-side compress (`flutter_image_compress`, long edge ~1600px, q80) before
  upload — unchanged from the plan.

## Why this over the plan's Firebase Storage

- **No billing requirement.** Supabase Storage has a usable free tier; Firebase
  Storage does not without Blaze.
- **Public URL is plain `https` with no token/query auth**, so the existing
  `cached_network_image` render path and the legacy `Image Url` field need no
  changes. Firebase download URLs carry a `?token=` and tie reads to Storage rules.
- Picker + compression layer (`image_picker`, `flutter_image_compress`) is
  storage-agnostic and matches the plan verbatim.

## Consequences

- **`supabase_flutter` is a new top-level dependency not in `PROMPT.md` §1.** This
  ADR is the record of that deviation; §1's authorized list should be treated as
  amended by this decision.
- **Security model differs from the plan — and is weaker.** The plan's
  `storage.rules` (size cap, `contentType` check, uid path match) do not apply.
  Crucially, **the app uses Firebase Auth and talks to Supabase with the anon key
  only — it never signs into Supabase.** So in Supabase RLS `auth.uid()` is always
  NULL and the `{uid}` path segment is a Firebase uid Supabase cannot verify.
  Per-user write isolation is therefore **not enforceable** on the Supabase side:
  uploads run as the `anon` role and any holder of the anon key can
  write/overwrite/delete any path in `product_images`. The only server-side
  boundaries are the **bucket-level size cap (5 MB) and MIME allowlist**. This is an
  accepted residual risk for v1.1. The policy SQL is committed at
  `supabase/policies.sql`.
  - **Hardening path (future):** either (a) wire Supabase third-party auth to verify
    the Firebase JWT so `auth.uid()` is populated, then switch to owner-scoped
    policies on `(storage.foldername(name))[1]`; or (b) route uploads through a
    Cloud/edge function that signs them with the service-role key and lock the
    bucket to no anon write.
- **Two storage providers to operate.** Account-deletion orphan cleanup
  (`PROMPT.md` DoD §4) must call `StorageService.deleteByUrl`, which targets
  Supabase, not Firebase.
- **`firebase deploy --only storage` is not used.** Drop it from any deploy
  scripts/CI; it has no effect here.
- **Bucket reads are public.** The plan's "auth-only read, document why" option is
  not taken — product photos are public by nature, and a public bucket is the
  simplest path that keeps the legacy URL field renderable. Revisit if private
  media is ever needed.

## Secret handling

The Supabase URL + anon key are injected at build time via `--dart-define`
(`String.fromEnvironment` in `lib/main.dart`), not committed inline. Local config
lives in the gitignored `supabase.json`; `supabase.example.json` is the template.
Build/run with `--dart-define-from-file=supabase.json`. The anon key is a public
client key — RLS / bucket config is the real boundary (see security model above).

> Note: the prior inline anon key remains in git history (commits `db28a6b`..`HEAD`).
> Since it is a public anon key and the bucket is intentionally public-read, rotation
> is optional; rotate in the Supabase dashboard if desired.