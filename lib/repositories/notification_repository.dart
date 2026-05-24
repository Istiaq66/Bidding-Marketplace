import 'package:app/models/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository {
  NotificationRepository._();

  static CollectionReference<Map<String, dynamic>> _items(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items');
  }

  static Stream<List<AppNotification>> watchByUser(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList());
  }

  static Stream<int> watchUnreadCount(String uid) {
    return _items(uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<void> markRead(String uid, String id) async {
    await _items(uid).doc(id).update({'read': true});
  }
}