import 'package:app/models/watchlist_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistRepository {
  WatchlistRepository._();

  static final CollectionReference<Map<String, dynamic>> _watchlist =
      FirebaseFirestore.instance.collection('watchlist');

  static Query<Map<String, dynamic>> _userProductQuery(String userId, String productId) {
    return _watchlist
        .where('User Id', isEqualTo: userId)
        .where('Product Id', isEqualTo: productId);
  }

  static Future<bool> isWatched(String userId, String productId) async {
    final snap = await _userProductQuery(userId, productId).get();
    return snap.docs.isNotEmpty;
  }

  static Future<void> add(String userId, String productId) async {
    await _watchlist.add({
      'User Id': userId,
      'Product Id': productId,
      'Added At': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeByUserAndProduct(String userId, String productId) async {
    final snap = await _userProductQuery(userId, productId).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> deleteById(String id) async {
    await _watchlist.doc(id).delete();
  }

  static Stream<List<WatchlistEntry>> watchByUser(String userId) {
    return _watchlist
        .where('User Id', isEqualTo: userId)
        .orderBy('Added At', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WatchlistEntry.fromFirestore).toList());
  }
}