import 'dart:io';
import 'package:app/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class ProductRepository {
  ProductRepository._();

  static final _db = FirebaseFirestore.instance;
  static final CollectionReference<Map<String, dynamic>> _products =
      _db.collection('products');

  static Future<DocumentReference<Map<String, dynamic>>> create({
    required String sellerId,
    required String name,
    required String description,
    required String minBidPrice,
    required String date,
    required File image,
  }) async {
    // Fetch seller info for denormalization
    final sellerSnap = await _db.collection('users').doc(sellerId).get();
    final sellerData = sellerSnap.data() ?? {};
    final sellerName = (sellerData['name'] as String?) ?? '';
    final sellerPhoto = (sellerData['profileImage'] as String?) ??
        (sellerData['photo'] as String?) ??
        '';

    // Upload image
    final fileName = p.basename(image.path);
    final ref = FirebaseStorage.instance.ref().child('files/$fileName');
    final snapshot = await ref.putFile(image);
    final imageUrl = await snapshot.ref.getDownloadURL();

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