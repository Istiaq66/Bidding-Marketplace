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
-- The app authenticates with FIREBASE Auth and talks to Supabase using only the
-- public ANON key. It never signs into Supabase, so in Supabase RLS:
--
--   * auth.uid()  is always NULL  (the client is the `anon` role)
--   * the {uid} path segment is a FIREBASE uid that Supabase cannot verify
--
-- Therefore uploads/deletes run as `anon`, and per-user write isolation CANNOT
-- be enforced on the Supabase side with this setup. Any client holding the anon
-- key can write/overwrite/delete any path in this bucket. The only real
-- server-side boundaries are the bucket-level size cap and MIME allowlist below.
--
-- Residual risk accepted for v1.1: a malicious client could overwrite another
-- user's image or upload junk (bounded to 5 MB images). Hardening options, when
-- this matters, are tracked in docs/decisions/0001-supabase-storage.md:
--   (a) Supabase third-party auth: verify the Firebase JWT so auth.uid() is set,
--       then switch the policies below to owner-scoped on (foldername)[1];
--   (b) route uploads through a Cloud Function / edge function that signs them
--       server-side with the service-role key, and lock the bucket to no anon write.
-- =====================================================================

-- ---------------------------------------------------------------------------
-- Bucket: public read, 5 MB cap, images only. The size/MIME limits are the
-- equivalent of the old Firebase rules' `request.resource.size < 5MB` and
-- `contentType.matches('image/.*')`, and are the primary server-side guard.
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
-- RLS policies on storage.objects, scoped to the product_images bucket.
-- Granted to BOTH `anon` and `authenticated` because the app's Supabase client
-- is unauthenticated (see SECURITY MODEL above). bucket_id is the only check we
-- can trust here; size/MIME are enforced at the bucket level.
-- ---------------------------------------------------------------------------

drop policy if exists "product_images read"   on storage.objects;
drop policy if exists "product_images insert" on storage.objects;
drop policy if exists "product_images update" on storage.objects;
drop policy if exists "product_images delete" on storage.objects;

create policy "product_images read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'product_images');

create policy "product_images insert"
  on storage.objects for insert
  to anon, authenticated
  with check (bucket_id = 'product_images');

create policy "product_images update"
  on storage.objects for update
  to anon, authenticated
  using      (bucket_id = 'product_images')
  with check (bucket_id = 'product_images');

create policy "product_images delete"
  on storage.objects for delete
  to anon, authenticated
  using (bucket_id = 'product_images');

-- ---------------------------------------------------------------------------
-- WHEN Firebase JWT verification is wired (option (a) above), replace the
-- insert/update/delete policies with owner-scoped versions, e.g.:
--
--   create policy "product_images owner insert"
--     on storage.objects for insert to authenticated
--     with check (
--       bucket_id = 'product_images'
--       and (storage.foldername(name))[1] = auth.uid()::text
--     );
--
-- and drop the broad anon write policies.
-- ---------------------------------------------------------------------------