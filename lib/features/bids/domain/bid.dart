import 'package:cloud_firestore/cloud_firestore.dart';

class Bid {
  final String id;
  final String bidderId;
  final String productId;
  final String amount;
  final String bidTime;
  final DateTime? createdAt;

  const Bid({
    required this.id,
    required this.bidderId,
    required this.productId,
    required this.amount,
    required this.bidTime,
    this.createdAt,
  });

  factory Bid.fromFirestore(DocumentSnapshot snapshot) {
    final data = (snapshot.data() as Map<String, dynamic>? ?? const {});
    final created = data['Created At'];
    return Bid(
      id: snapshot.id,
      bidderId: (data['Bidder Id'] ?? '') as String,
      productId: (data['Product Id'] ?? '') as String,
      amount: (data['Bid Amount'] ?? '0').toString(),
      bidTime: (data['Bid Time'] ?? '') as String,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Bidder Id': bidderId,
      'Product Id': productId,
      'Bid Amount': amount,
      'Bid Time': bidTime,
      'Created At': FieldValue.serverTimestamp(),
    };
  }
}
