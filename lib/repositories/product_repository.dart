import 'dart:io';
import 'package:app/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class ProductRepository {
  ProductRepository._();

  static final CollectionReference<Map<String, dynamic>> _products =
      FirebaseFirestore.instance.collection('products');

  static Future<DocumentReference<Map<String, dynamic>>> create({
    required String sellerId,
    required String name,
    required String description,
    required String minBidPrice,
    required String date,
    required File image,
  }) async {
    final fileName = p.basename(image.path);
    final ref = FirebaseStorage.instance.ref().child('files/$fileName');
    final snapshot = await ref.putFile(image);
    final imageUrl = await snapshot.ref.getDownloadURL();

    return _products.add({
      'User Id': sellerId,
      'Product Name': name,
      'Product Description': description,
      'Minimum Bid Price': minBidPrice,
      'Date': date,
      'Image Url': imageUrl,
    });
  }

  static Stream<List<Product>> watchAll() {
    return _products.snapshots().map(
          (snap) => snap.docs.map(Product.fromFirestore).toList(),
        );
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

  static Stream<List<Product>> watchRecentByUser(String userId, {int limit = 3}) {
    return _products
        .where('User Id', isEqualTo: userId)
        .orderBy('Date', descending: true)
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
}