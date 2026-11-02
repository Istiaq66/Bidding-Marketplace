import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { defineSecret, defineString } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';
import { StorageClient } from '@supabase/storage-js';

const REGION = 'us-central1';
const BUCKET = 'product_images';

/** e.g. `https://<ref>.supabase.co`. Set in functions/.env. */
const SUPABASE_URL = defineString('SUPABASE_URL');
/** Service-role key; never shipped to clients. `firebase functions:secrets:set`. */
const SUPABASE_SERVICE_ROLE_KEY = defineSecret('SUPABASE_SERVICE_ROLE_KEY');

/** File names the app uses: `{id}.jpg` for products, `avatar.jpg`. */
const FILE_NAME = /^[A-Za-z0-9_-]{1,64}\.jpg$/;

function storage(): StorageClient {
  const key = SUPABASE_SERVICE_ROLE_KEY.value();
  return new StorageClient(`${SUPABASE_URL.value()}/storage/v1`, {
    apikey: key,
    Authorization: `Bearer ${key}`,
  });
}

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to upload images.');
  }
  return auth.uid;
}

/**
 * Issues a one-minute signed upload URL for `product_images/{uid}/{name}`.
 * The bucket has no anon write policy, so this is the only way to upload:
 * a user can only ever write inside their own folder. Bucket-level limits
 * (5 MB, image MIME types) still apply to the upload itself.
 */
export const createImageUploadUrl = onCall(
  { region: REGION, secrets: [SUPABASE_SERVICE_ROLE_KEY] },
  async (req) => {
    const uid = requireUid(req.auth);
    const name = (req.data as { name?: unknown } | undefined)?.name;
    if (typeof name !== 'string' || !FILE_NAME.test(name)) {
      throw new HttpsError('invalid-argument', 'Invalid file name.');
    }

    const path = `${uid}/${name}`;
    const { data, error } = await storage()
      .from(BUCKET)
      .createSignedUploadUrl(path, { upsert: true });
    if (error || !data) {
      logger.error(`createImageUploadUrl failed for ${path}`, error);
      throw new HttpsError('internal', 'Could not prepare the upload.');
    }
    return { path, token: data.token };
  },
);

/** Deletes `product_images/{path}` if it lies in the caller's own folder. */
export const deleteImage = onCall(
  { region: REGION, secrets: [SUPABASE_SERVICE_ROLE_KEY] },
  async (req) => {
    const uid = requireUid(req.auth);
    const path = (req.data as { path?: unknown } | undefined)?.path;
    const prefix = `${uid}/`;
    if (
      typeof path !== 'string' ||
      !path.startsWith(prefix) ||
      !FILE_NAME.test(path.slice(prefix.length))
    ) {
      throw new HttpsError('permission-denied', 'Not your image.');
    }

    const { error } = await storage().from(BUCKET).remove([path]);
    if (error) {
      logger.error(`deleteImage failed for ${path}`, error);
      throw new HttpsError('internal', 'Could not delete the image.');
    }
    return { deleted: path };
  },
);
