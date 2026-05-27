import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Wraps image picking, client-side compression, and Firebase Storage upload
/// for product photos. Replaces the old "paste an image URL" flow so every
/// stored image is a real `https` download URL with a token (no more broken
/// images from arbitrary/expired third-party links).
///
/// Storage layout: `product_images/{uid}/{id}.jpg`.
class StorageService {
  StorageService._();

  static FirebaseStorage _storage = FirebaseStorage.instance;
  static ImagePicker _picker = ImagePicker();

  @visibleForTesting
  static set storageForTesting(FirebaseStorage storage) => _storage = storage;

  @visibleForTesting
  static set pickerForTesting(ImagePicker picker) => _picker = picker;

  @visibleForTesting
  static void resetForTesting() {
    _storage = FirebaseStorage.instance;
    _picker = ImagePicker();
  }

  /// Opens the camera or gallery. Returns null if the user cancels.
  static Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 90,
    );
  }

  /// Compresses [file] and uploads it to `product_images/{uid}/{id}.jpg`.
  /// Returns the public `https` download URL.
  static Future<String> uploadProductImage({
    required String uid,
    required XFile file,
    String? id,
  }) async {
    final bytes = await _compress(file);
    final name = '${id ?? DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref('product_images/$uid/$name');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Deletes a previously uploaded image by its download URL. Silently ignores
  /// URLs that are not Storage references or are already gone.
  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Not a Storage URL (legacy pasted link) or already deleted — ignore.
    }
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