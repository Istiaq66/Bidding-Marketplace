import 'package:bidding_marketplace/features/notifications/domain/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  NotificationRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _items(String uid) {
    return _db.collection('notifications').doc(uid).collection('items');
  }

  /// Newest [limit] notifications.
  static Stream<List<AppNotification>> watchByUser(
    String uid, {
    int limit = 50,
  }) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList());
  }

  /// Unread count, capped at 100 (the badge shows "99+" beyond that) so a
  /// large backlog isn't streamed just to count it.
  static Stream<int> watchUnreadCount(String uid) {
    return _items(uid)
        .where('read', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<void> markRead(String uid, String id) async {
    await _items(uid).doc(id).update({'read': true});
  }

  /// Marks every unread notification read, in batches of 500 writes.
  static Future<void> markAllRead(String uid) async {
    while (true) {
      final unread =
          await _items(uid).where('read', isEqualTo: false).limit(500).get();
      if (unread.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      if (unread.docs.length < 500) return;
    }
  }
}
