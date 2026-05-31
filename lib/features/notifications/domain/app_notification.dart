import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  bidPlaced,
  outbid,
  auctionWon,
  auctionLost,
  auctionEndedSeller,
  auctionEndingSoon,
  newAuction,
  unknown,
}

NotificationType _parseType(String? raw) {
  switch (raw) {
    case 'bid_placed':
      return NotificationType.bidPlaced;
    case 'outbid':
      return NotificationType.outbid;
    case 'auction_won':
      return NotificationType.auctionWon;
    case 'auction_lost':
      return NotificationType.auctionLost;
    case 'auction_ended_seller':
      return NotificationType.auctionEndedSeller;
    case 'auction_ending_soon':
      return NotificationType.auctionEndingSoon;
    case 'new_auction':
      return NotificationType.newAuction;
    default:
      return NotificationType.unknown;
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String productId;
  final String productName;
  final String productImage;
  final String? amount;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.read,
    this.amount,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot snapshot) {
    final data = (snapshot.data() as Map<String, dynamic>? ?? const {});
    final created = data['createdAt'];
    return AppNotification(
      id: snapshot.id,
      type: _parseType(data['type'] as String?),
      productId: (data['productId'] ?? '') as String,
      productName: (data['productName'] ?? '') as String,
      productImage: (data['productImage'] ?? '') as String,
      amount: data['amount']?.toString(),
      read: (data['read'] ?? false) as bool,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
