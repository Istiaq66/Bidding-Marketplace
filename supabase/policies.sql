-- Supabase Storage configuration for the `product_images` bucket.
--
-- Replaces the former Firebase `storage.rules` (removed). See
-- docs/decisions/0001-supabase-storage.md for why image storage runs on Supabase.
--
-- Apply via the Supabase SQL editor (Dashboard -> SQL) or the Supabase CLI:
--   supabase db execute --file supabase/policies.sql
-- Re-running is safe: bucket upsert + drop-then-create policies are idempotent.
--
-- =====================================================================
-- SECURITY MODEL — READ THIS
-- =====================================================================
-- The app authenticates with FIREBASE Auth and only holds the public ANON key,
-- so Supabase cannot tell users apart (auth.uid() is always NULL). The anon
-- role therefore gets NO access to storage.objects:
--
--   * Uploads: the `createImageUploadUrl` Cloud Function verifies the Firebase
--     ID token and, with the service-role key, signs a one-minute upload URL
--     for `{firebase uid}/{name}`. The app PUTs the bytes to that URL.
--   * Deletes: the `deleteImage` Cloud Function removes a path only if it is
--     inside the caller's `{uid}/` folder.
--   * Reads: the bucket is public, so `/object/public/...` URLs work without
--     any SELECT policy. Leaving SELECT out also blocks anon `list()`, which
--     would otherwise enumerate every user's files.
--
-- Signed uploads still respect the bucket's size cap and MIME allowlist.
-- See functions/src/storage.ts.
-- =====================================================================

-- ---------------------------------------------------------------------------
-- Bucket: public read, 5 MB cap, images only.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product_images',
  'product_images',
  true,                                   -- public read (public marketplace photos)
  5242880,                                -- 5 * 1024 * 1024
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public             = excluded.public,
  file_size_limit    = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- Remove the old anon policies (read/list, insert, update, delete). With no
-- policy granting anon access, RLS denies every direct anon request; the
-- service role used by the Cloud Functions bypasses RLS.
-- ---------------------------------------------------------------------------
drop policy if exists "product_images read"   on storage.objects;
drop policy if exists "product_images insert" on storage.objects;
drop policy if exists "product_images update" on storage.objects;
drop policy if exists "product_images delete" on storage.objects;
