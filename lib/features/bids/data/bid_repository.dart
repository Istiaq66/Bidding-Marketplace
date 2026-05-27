import 'package:app/features/bids/domain/bid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class BidRepository {
  BidRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _bids =>
      _db.collection('bids');

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

  /// Places a bid inside a Firestore transaction.
  ///
  /// Throws [Exception] with a user-readable message on:
  /// - product not found
  /// - auction not active or already ended
  /// - bidder == seller
  /// - amount not strictly greater than currentBid
  static Future<void> place({
    required String productId,
    required String bidderId,
    required double amount,
  }) async {
    final productRef = _db.collection('products').doc(productId);
    final bidRef = _bids.doc();

    await _db.runTransaction((tx) async {
      final productSnap = await tx.get(productRef);
      if (!productSnap.exists) throw Exception('Product not found');

      final data = productSnap.data()!;
      final status = (data['status'] as String?) ?? 'active';
      final sellerId = (data['User Id'] as String?) ?? '';
      final endsAtRaw = data['endsAt'];

      if (status != 'active') throw Exception('Auction is not active');

      if (endsAtRaw is Timestamp &&
          endsAtRaw.toDate().isBefore(DateTime.now())) {
        throw Exception('Auction has ended');
      }

      if (bidderId == sellerId) {
        throw Exception('Cannot bid on your own auction');
      }

      final minBidStr = (data['Minimum Bid Price'] ?? '0').toString();
      final currentBid =
          (data['currentBid'] as num?) ?? double.tryParse(minBidStr) ?? 0;

      if (amount <= currentBid) {
        throw Exception(
          'Bid must be higher than current bid of \$${currentBid.toStringAsFixed(2)}',
        );
      }

      tx.set(bidRef, {
        'Bidder Id': bidderId,
        'Product Id': productId,
        'Bid Amount': amount,
        'Bid Time': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        'Created At': FieldValue.serverTimestamp(),
      });

      tx.update(productRef, {
        'currentBid': amount,
        'bidCount': FieldValue.increment(1),
        'highestBidderId': bidderId,
      });
    });
  }

  static Stream<List<Bid>> watchByProduct(String productId, {int limit = 5}) {
    return _bids
        .where('Product Id', isEqualTo: productId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(Bid.fromFirestore).toList()
            ..sort((a, b) {
              final ad = double.tryParse(a.amount) ?? 0;
              final bd = double.tryParse(b.amount) ?? 0;
              return bd.compareTo(ad);
            });
          return list.take(limit).toList();
        });
  }

  static Stream<List<Bid>> watchByBidder(String bidderId) {
    return _bids
        .where('Bidder Id', isEqualTo: bidderId)
        .snapshots()
        .map((snap) => _sortByCreatedDesc(snap.docs.map(Bid.fromFirestore).toList()));
  }

  static Stream<List<Bid>> watchRecentByBidder(
    String bidderId, {
    int limit = 5,
  }) {
    return _bids
        .where('Bidder Id', isEqualTo: bidderId)
        .snapshots()
        .map((snap) {
          final list = _sortByCreatedDesc(snap.docs.map(Bid.fromFirestore).toList());
          return list.take(limit).toList();
        });
  }

  static List<Bid> _sortByCreatedDesc(List<Bid> list) {
    list.sort((a, b) {
      final ac = a.createdAt;
      final bc = b.createdAt;
      if (ac == null && bc == null) return 0;
      if (ac == null) return 1;
      if (bc == null) return -1;
      return bc.compareTo(ac);
    });
    return list;
  }

  static Future<int> countByBidder(String bidderId) async {
    final snap = await _bids.where('Bidder Id', isEqualTo: bidderId).count().get();
    return snap.count ?? 0;
  }

  /// Best-effort delete of every bid placed by [bidderId]. Security rules
  /// block bid deletion (`allow update, delete: if false`) — this exists so
  /// that, when rules are later relaxed for the account-deletion path, the
  /// repository already has the entry point.
  static Future<int> deleteAllByBidder(String bidderId) async {
    final snap = await _bids.where('Bidder Id', isEqualTo: bidderId).get();
    int deleted = 0;
    for (final doc in snap.docs) {
      try {
        await doc.reference.delete();
        deleted++;
      } catch (_) {}
    }
    return deleted;
  }
}