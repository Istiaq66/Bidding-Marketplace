import 'package:app/models/watchlist_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WatchlistRepository {
  WatchlistRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _watchlist =>
      _db.collection('watchlist');

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

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

  static Future<void> deleteAllByUser(String userId) async {
    final snap =
        await _watchlist.where('User Id', isEqualTo: userId).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  static Stream<List<WatchlistEntry>> watchByUser(String userId) {
    return _watchlist
        .where('User Id', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(WatchlistEntry.fromFirestore).toList()
            ..sort((a, b) {
              final ac = a.addedAt;
              final bc = b.addedAt;
              if (ac == null && bc == null) return 0;
              if (ac == null) return 1;
              if (bc == null) return -1;
              return bc.compareTo(ac);
            });
          return list;
        });
  }

  static Future<int> countByUser(String userId) async {
    final snap = await _watchlist.where('User Id', isEqualTo: userId).count().get();
    return snap.count ?? 0;
  }
}