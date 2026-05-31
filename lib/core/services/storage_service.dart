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

  /// Compresses [file] and uploads it to `product_images/{uid}/{id}.jpg`.
  /// Returns the public `https` URL.
  static Future<String> uploadProductImage({
    required String uid,
    required XFile file,
    String? id,
  }) async {
    final bytes = await _compress(file);
    final name = '${id ?? DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$uid/$name';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return _bustCache(_client.storage.from(_bucket).getPublicUrl(path));
  }

  /// Compresses [file] and uploads it to `product_images/{uid}/avatar.jpg`.
  /// Reuses the public product bucket so no extra bucket setup is needed.
  /// Keeps `{uid}` as the first path segment to satisfy uid-based RLS.
  /// Returns the public `https` URL.
  static Future<String> uploadProfileImage({
    required String uid,
    required XFile file,
  }) async {
    final bytes = await _compress(file);
    final path = '$uid/avatar.jpg';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
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
      await _client.storage.from(_bucket).remove([path]);
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
