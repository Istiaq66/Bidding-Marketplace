import 'package:app/models/bid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BidRepository {
  BidRepository._();

  static final _db = FirebaseFirestore.instance;
  static final CollectionReference<Map<String, dynamic>> _bids =
      _db.collection('bids');

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
        .orderBy('Bid Amount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Bid.fromFirestore).toList());
  }

  static Stream<List<Bid>> watchByBidder(String bidderId) {
    return _bids
        .where('Bidder Id', isEqualTo: bidderId)
        .orderBy('Created At', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bid.fromFirestore).toList());
  }

  static Stream<List<Bid>> watchRecentByBidder(
    String bidderId, {
    int limit = 5,
  }) {
    return _bids
        .where('Bidder Id', isEqualTo: bidderId)
        .orderBy('Created At', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Bid.fromFirestore).toList());
  }
}