import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String minBidPrice;
  final String date;
  final String imageUrl;

  const Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.minBidPrice,
    required this.date,
    required this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot snapshot) {
    final data = (snapshot.data() as Map<String, dynamic>? ?? const {});
    return Product(
      id: snapshot.id,
      sellerId: (data['User Id'] ?? '') as String,
      name: (data['Product Name'] ?? 'Unknown') as String,
      description: (data['Product Description'] ?? '') as String,
      minBidPrice: (data['Minimum Bid Price'] ?? '0').toString(),
      date: (data['Date'] ?? '') as String,
      imageUrl: (data['Image Url'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'User Id': sellerId,
      'Product Name': name,
      'Product Description': description,
      'Minimum Bid Price': minBidPrice,
      'Date': date,
      'Image Url': imageUrl,
    };
  }

  DateTime? get endsAt {
    if (date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  bool get isActive {
    final ends = endsAt;
    if (ends == null) return false;
    return ends.isAfter(DateTime.now());
  }
}