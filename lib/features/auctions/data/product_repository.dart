import 'package:app/features/auctions/domain/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductRepository {
  ProductRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

  static Future<DocumentReference<Map<String, dynamic>>> create({
    required String sellerId,
    required String name,
    required String description,
    required String minBidPrice,
    required String date,
    required String imageUrl,
    num minIncrement = 1,
  }) async {
    // Fetch seller info for denormalization
    final sellerSnap = await _db.collection('users').doc(sellerId).get();
    final sellerData = sellerSnap.data() ?? {};
    final sellerName = (sellerData['name'] as String?) ?? '';
    final sellerPhoto = (sellerData['profileImage'] as String?) ??
        (sellerData['photo'] as String?) ??
        '';

    // Compute endsAt at 23:59:59 local time on the selected date
    Timestamp? endsAt;
    try {
      final parsed = DateTime.parse(date);
      endsAt = Timestamp.fromDate(
        DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59),
      );
    } catch (_) {}

    final minPrice = double.tryParse(minBidPrice) ?? 0;

    return _products.add({
      'User Id': sellerId,
      'Product Name': name,
      'Product Description': description,
      'Minimum Bid Price': minBidPrice,
      'Date': date,
      'Image Url': imageUrl,
      'nameLower': name.toLowerCase(),
      'endsAt': endsAt,
      'currentBid': minPrice,
      'bidCount': 0,
      'minIncrement': minIncrement,
      'status': 'active',
      'winnerId': null,
      'sellerName': sellerName,
      'sellerPhoto': sellerPhoto,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Product>> watchAll() {
    return _products.snapshots().map(
          (snap) => snap.docs.map(Product.fromFirestore).toList(),
        );
  }

  static Stream<List<Product>> watchActive() {
    return _products
        .where('status', isEqualTo: 'active')
        .orderBy('endsAt')
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromFirestore).toList());
  }

  static Future<List<Product>> getAll() async {
    final snap = await _products.get();
    return snap.docs.map(Product.fromFirestore).toList();
  }

  static Stream<List<Product>> watchByUser(String userId) {
    return _products
        .where('User Id', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromFirestore).toList());
  }

  static Stream<List<Product>> watchRecentByUser(
      String userId, {
      int limit = 3,
    }) {
    return _products
        .where('User Id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromFirestore).toList());
  }

  static Future<int> countWonByUser(String userId) async {
    final snap = await _products.where('winnerId', isEqualTo: userId).count().get();
    return snap.count ?? 0;
  }

  static Future<Product?> getById(String id) async {
    final snap = await _products.doc(id).get();
    if (!snap.exists) return null;
    return Product.fromFirestore(snap);
  }

  static Stream<Product?> watchById(String id) {
    return _products.doc(id).snapshots().map(
          (snap) => snap.exists ? Product.fromFirestore(snap) : null,
        );
  }

  static Future<void> deleteById(String id) async {
    await _products.doc(id).delete();
  }

  /// Updates the editable fields on a product. The transaction asserts the
  /// auction has not yet received any bids — matching the security rule that
  /// only allows this update when `bidCount == 0`.
  static Future<void> updateEditable({
    required String id,
    required String description,
    required String date,
    required String minBidPrice,
    String? imageUrl,
    num? minIncrement,
  }) async {
    final ref = _products.doc(id);
    final minPrice = double.tryParse(minBidPrice) ?? 0;

    Timestamp? endsAt;
    try {
      final parsed = DateTime.parse(date);
      endsAt = Timestamp.fromDate(
        DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59),
      );
    } catch (_) {}

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Auction not found');
      final data = snap.data()!;
      final bidCount = (data['bidCount'] as int?) ?? 0;
      if (bidCount > 0) {
        throw Exception('Cannot edit an auction that has bids');
      }

      tx.update(ref, {
        'Product Description': description,
        'Date': date,
        'Minimum Bid Price': minBidPrice,
        if (endsAt != null) 'endsAt': endsAt,
        'currentBid': minPrice,
        if (imageUrl != null) 'Image Url': imageUrl,
        if (minIncrement != null) 'minIncrement': minIncrement,
      });
    });
  }

  /// Deletes every product owned by [userId] whose `bidCount` is zero.
  /// Returns the number of products deleted.
  static Future<int> deleteAllByUser(String userId) async {
    final snap =
        await _products.where('User Id', isEqualTo: userId).get();
    int deleted = 0;
    for (final doc in snap.docs) {
      final bidCount = (doc.data()['bidCount'] as int?) ?? 0;
      if (bidCount == 0) {
        await doc.reference.delete();
        deleted++;
      }
    }
    return deleted;
  }

  /// Prefix-query search on `nameLower`. Falls back to client-side contains
  /// for legacy docs that haven't been backfilled yet.
  static Future<List<Product>> search(String query, {int limit = 20}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final snap = await _products
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q')
        .limit(limit)
        .get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.map(Product.fromFirestore).toList();
    }

    // Fallback for docs without nameLower (pre-backfill)
    final fallback = await _products.limit(100).get();
    return fallback.docs
        .map(Product.fromFirestore)
        .where((p) => p.name.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  /// Fetches a page of products for infinite-scroll pagination.
  /// Returns the products and the cursor snapshot for the next page.
  static Future<(List<Product>, QueryDocumentSnapshot<Map<String, dynamic>>?)>
      fetchPage({
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    var q = _products.limit(limit);
    if (after != null) q = q.startAfterDocument(after);
    final snap = await q.get();
    final products = snap.docs.map(Product.fromFirestore).toList();
    final cursor = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (products, cursor);
  }
}