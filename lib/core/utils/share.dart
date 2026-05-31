import 'package:share_plus/share_plus.dart';

/// Centralised share entry points. The deep-link host is a placeholder until
/// `app_links` is wired up on Android/iOS — clicking the link will not open
/// the app yet, but it's stable enough to round-trip through any sharing
/// surface (SMS, email, Slack, etc.).
class ShareUtil {
  ShareUtil._();

  // TODO(deeplinks): replace once Android intent filters / iOS Universal
  // Links are configured. Bundle id: `com.example.app` (see android/app
  // build.gradle and ios/Runner/Info.plist before flipping this domain on).
  static const String _baseUrl = 'https://bidding-marketplace.app';

  static Future<void> shareAuction({
    required String productId,
    String? productName,
  }) async {
    final url = '$_baseUrl/auction/$productId';
    final name =
        (productName == null || productName.isEmpty)
            ? 'an auction'
            : '"$productName"';
    await Share.share(
      'Check out $name on Bidding Marketplace: $url',
      subject: 'Bidding Marketplace',
    );
  }

  static Future<void> shareProfile({String? userName}) async {
    final name = (userName == null || userName.isEmpty) ? 'me' : userName;
    await Share.share(
      'Follow $name on Bidding Marketplace: $_baseUrl',
      subject: 'Bidding Marketplace',
    );
  }

  /// GitHub releases page — always resolves to the newest published release,
  /// so the link stays current without code changes per release.
  static const String _releasesUrl =
      'https://github.com/Istiaq66/Bidding-Marketplace/releases/latest';

  static Future<void> shareApp() async {
    await Share.share(
      'Get Bidding Marketplace: $_releasesUrl',
      subject: 'Bidding Marketplace',
    );
  }
}
