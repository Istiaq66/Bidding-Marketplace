import 'package:app/models/bid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BidRepository {
  BidRepository._();

  static final CollectionReference<Map<String, dynamic>> _bids =
      FirebaseFirestore.instance.collection('bids');

  static Future<void> place({
    required String productId,
    required String bidderId,
    required String amount,
  }) async {
    await _bids.add({
      'Bidder Id': bidderId,
      'Product Id': productId,
      'Bid Amount': amount,
      'Bid Time': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      'Created At': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Bid>> watchByProduct(String productId, {int limit = 5}) {
    return _bids
        .where('Product Id', isEqualTo: productId)
        .orderBy('Created At', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Bid.fromFirestore).toList());
  }

  static Stream<List<Bid>> watchByBidder(String bidderId) {
    return _bids
        .where('Bidder Id', isEqualTo: bidderId)
        .orderBy('Bid Time', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bid.fromFirestore).toList());
  }
}