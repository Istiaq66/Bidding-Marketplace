import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps image picking, client-side compression, and Supabase Storage upload
/// for product photos. Bucket must exist and be public so [uploadProductImage]
/// can return a public `https` URL that the app can render via
/// `cached_network_image` without extra auth.
///
/// Storage layout: bucket `product_images`, path `{uid}/{id}.jpg`.
class StorageService {
  StorageService._();

  static const String _bucket = 'product_images';

  static SupabaseClient get _client => Supabase.instance.client;
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static ImagePicker _picker = ImagePicker();

  @visibleForTesting
  static set pickerForTesting(ImagePicker picker) => _picker = picker;

  @visibleForTesting
  static void resetForTesting() {
    _picker = ImagePicker();
  }

  /// Opens the camera or gallery. Returns null if the user cancels.
  static Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source, maxWidth: 2000, imageQuality: 90);
  }

  /// Compresses [file] and uploads it to `product_images/{uid}/{id}.jpg`,
  /// where `{uid}` is the signed-in user. Returns the public `https` URL.
  static Future<String> uploadProductImage({
    required XFile file,
    String? id,
  }) async {
    final bytes = await _compress(file);
    return _upload('${id ?? DateTime.now().millisecondsSinceEpoch}.jpg', bytes);
  }

  /// Compresses [file] and uploads it to `product_images/{uid}/avatar.jpg`.
  /// Reuses the public product bucket so no extra bucket setup is needed.
  /// Returns the public `https` URL.
  static Future<String> uploadProfileImage({required XFile file}) async {
    final bytes = await _compress(file);
    return _upload('avatar.jpg', bytes);
  }

  /// The bucket has no anon write access. The `createImageUploadUrl` Cloud
  /// Function verifies the Firebase user and signs an upload for
  /// `{uid}/{name}` with the Supabase service-role key; the bytes then go
  /// straight to Supabase with that one-minute token.
  static Future<String> _upload(String name, Uint8List bytes) async {
    final result = await _functions
        .httpsCallable('createImageUploadUrl')
        .call<Object?>({'name': name});
    final data = Map<String, dynamic>.from(result.data as Map);
    final path = data['path'] as String;

    await _client.storage
        .from(_bucket)
        .uploadBinaryToSignedUrl(
          path,
          data['token'] as String,
          bytes,
          const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return _bustCache(_client.storage.from(_bucket).getPublicUrl(path));
  }

  /// Appends a version query param so an overwritten image (same storage path,
  /// hence same base URL) yields a fresh URL. Without this, `upsert: true`
  /// re-uploads return an identical URL, and both `cached_network_image` (keyed
  /// by URL) and the Supabase CDN keep serving the stale image.
  static String _bustCache(String url) =>
      '$url?v=${DateTime.now().millisecondsSinceEpoch}';

  /// Deletes a previously uploaded image by its public URL. Silently ignores
  /// URLs that are not Supabase Storage references or are already gone.
  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    final path = _pathFromPublicUrl(url);
    if (path == null) return;
    try {
      // Deletes go through the `deleteImage` Cloud Function, which only
      // removes files in the caller's own folder.
      await _functions.httpsCallable('deleteImage').call<Object?>({
        'path': path,
      });
    } catch (_) {
      // Already deleted or transient error — ignore.
    }
  }

  /// Public URL format:
  /// `https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>`
  /// Returns `<path>` if [url] matches our bucket, else null.
  static String? _pathFromPublicUrl(String url) {
    const marker = '/object/public/$_bucket/';
    final i = url.indexOf(marker);
    if (i == -1) return null;
    var path = url.substring(i + marker.length);
    // Strip the cache-busting query (`?v=...`) appended by _bustCache.
    final q = path.indexOf('?');
    if (q != -1) path = path.substring(0, q);
    return Uri.decodeComponent(path);
  }

  /// Caps the long edge near 1600px at quality 80 (~target < 500 KB). Falls
  /// back to the raw bytes if the platform plugin can't compress.
  static Future<Uint8List> _compress(XFile file) async {
    final out = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    return out ?? await file.readAsBytes();
  }
}
