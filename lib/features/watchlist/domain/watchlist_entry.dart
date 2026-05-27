import 'package:cloud_firestore/cloud_firestore.dart';

class WatchlistEntry {
  final String id;
  final String userId;
  final String productId;
  final DateTime? addedAt;

  const WatchlistEntry({
    required this.id,
    required this.userId,
    required this.productId,
    this.addedAt,
  });

  factory WatchlistEntry.fromFirestore(DocumentSnapshot snapshot) {
    final data = (snapshot.data() as Map<String, dynamic>? ?? const {});
    final added = data['Added At'];
    return WatchlistEntry(
      id: snapshot.id,
      userId: (data['User Id'] ?? '') as String,
      productId: (data['Product Id'] ?? '') as String,
      addedAt: added is Timestamp ? added.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'User Id': userId,
      'Product Id': productId,
      'Added At': FieldValue.serverTimestamp(),
    };
  }
}