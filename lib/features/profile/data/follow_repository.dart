import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tracks which sellers a user follows. Each follow is one document with a
/// deterministic id `{followerId}_{sellerId}` so the pair stays unique and
/// follow/unfollow is idempotent. The `onAuctionCreate` Cloud Function reads
/// this collection to fan out `new_auction` notifications.
class FollowRepository {
  FollowRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _follows =>
      _db.collection('follows');

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

  static String _docId(String followerId, String sellerId) =>
      '${followerId}_$sellerId';

  static Future<void> follow(String followerId, String sellerId) async {
    await _follows.doc(_docId(followerId, sellerId)).set({
      'followerId': followerId,
      'sellerId': sellerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unfollow(String followerId, String sellerId) async {
    await _follows.doc(_docId(followerId, sellerId)).delete();
  }

  static Future<bool> isFollowing(String followerId, String sellerId) async {
    final snap = await _follows.doc(_docId(followerId, sellerId)).get();
    return snap.exists;
  }

  static Stream<bool> watchIsFollowing(String followerId, String sellerId) {
    return _follows
        .doc(_docId(followerId, sellerId))
        .snapshots()
        .map((snap) => snap.exists);
  }

  static Future<int> countFollowers(String sellerId) async {
    final snap =
        await _follows.where('sellerId', isEqualTo: sellerId).count().get();
    return snap.count ?? 0;
  }
}