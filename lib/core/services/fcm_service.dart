import 'dart:async';

import 'package:bidding_marketplace/features/profile/data/user_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wires Firebase Cloud Messaging into the app:
///   - requests notification permission,
///   - registers/unregisters the device token under
///     `users/{uid}/private/profile.fcmTokens` (owner-only),
///   - shows foreground messages via a local notification channel,
///   - routes notification taps to the relevant product.
///
/// Navigation is delegated to [onOpenProduct] (set by the app layer) so this
/// `core` service never imports a feature screen.
class FcmService {
  FcmService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Set by the app layer: given a productId, open its details screen.
  static void Function(String productId)? onOpenProduct;

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'auction_default',
    'Auction notifications',
    description: 'Bids, outbids, results, and auctions ending soon.',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSub;

  /// One-time setup. Call after `Firebase.initializeApp()`.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Local notifications (Android channel + tap handler for foreground pushes).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final productId = response.payload;
        if (productId != null && productId.isNotEmpty) {
          onOpenProduct?.call(productId);
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Show foreground messages as a local notification.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tap handling: warm start and cold start.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  /// Requests permission, fetches the token, stores it, and keeps it fresh.
  static Future<void> registerToken(String uid) async {
    await FirebaseMessaging.instance.requestPermission();
    // One listener at a time, bound to the current user: re-registering
    // (NavigationPage is rebuilt per login) must not stack listeners, and a
    // refresh after logout must not write to the previous account.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      UserRepository.addFcmToken(uid, t);
    });

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await UserRepository.addFcmToken(uid, token);
  }

  /// Removes this device's token on logout / account deletion.
  static Future<void> unregisterToken(String uid) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await UserRepository.removeFcmToken(uid, token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Best-effort; never block logout on token cleanup.
    }
  }

  static void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['productId'] as String?,
    );
  }

  static void _handleTap(RemoteMessage message) {
    final productId = message.data['productId'] as String?;
    if (productId != null && productId.isNotEmpty) {
      onOpenProduct?.call(productId);
    }
  }
}
