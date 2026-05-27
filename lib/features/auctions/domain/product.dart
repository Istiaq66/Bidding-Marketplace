import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String minBidPrice;
  final String date;
  final String imageUrl;
  final String nameLower;
  final DateTime? endsAt;
  final num currentBid;
  final int bidCount;
  final String status;
  final String? winnerId;
  final String? highestBidderId;
  final String sellerName;
  final String sellerPhoto;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.minBidPrice,
    required this.date,
    required this.imageUrl,
    this.nameLower = '',
    this.endsAt,
    this.currentBid = 0,
    this.bidCount = 0,
    this.status = 'active',
    this.winnerId,
    this.highestBidderId,
    this.sellerName = '',
    this.sellerPhoto = '',
    this.createdAt,
  });

  factory Product.fromFirestore(DocumentSnapshot snapshot) {
    final data = (snapshot.data() as Map<String, dynamic>? ?? const {});
    final endsAtRaw = data['endsAt'];
    final createdAtRaw = data['createdAt'];
    final minBidPrice = (data['Minimum Bid Price'] ?? '0').toString();
    return Product(
      id: snapshot.id,
      sellerId: (data['User Id'] ?? '') as String,
      name: (data['Product Name'] ?? 'Unknown') as String,
      description: (data['Product Description'] ?? '') as String,
      minBidPrice: minBidPrice,
      date: (data['Date'] ?? '') as String,
      imageUrl: (data['Image Url'] ?? '') as String,
      nameLower: (data['nameLower'] as String?) ?? '',
      endsAt: endsAtRaw is Timestamp ? endsAtRaw.toDate() : null,
      currentBid: (data['currentBid'] as num?) ?? double.tryParse(minBidPrice) ?? 0,
      bidCount: (data['bidCount'] as int?) ?? 0,
      status: (data['status'] as String?) ?? 'active',
      winnerId: data['winnerId'] as String?,
      highestBidderId: data['highestBidderId'] as String?,
      sellerName: (data['sellerName'] as String?) ?? '',
      sellerPhoto: (data['sellerPhoto'] as String?) ?? '',
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'User Id': sellerId,
        'Product Name': name,
        'Product Description': description,
        'Minimum Bid Price': minBidPrice,
        'Date': date,
        'Image Url': imageUrl,
        'nameLower': nameLower,
        if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
        'currentBid': currentBid,
        'bidCount': bidCount,
        'status': status,
        'winnerId': winnerId,
        'highestBidderId': highestBidderId,
        'sellerName': sellerName,
        'sellerPhoto': sellerPhoto,
      };

  bool get isActive {
    if (status != 'active') return false;
    if (endsAt != null) return endsAt!.isAfter(DateTime.now());
    // Fallback for legacy docs without endsAt Timestamp
    if (date.isEmpty) return false;
    try {
      return DateTime.parse(date).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}