import 'package:app/repositories/product_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    ProductRepository.firestoreForTesting = fake;
  });

Future<DocumentReference<Map<String, dynamic>>> seed({
    String sellerId = 'seller-1',
    String name = 'Vintage Bike',
    int bidCount = 0,
    String status = 'active',
    double currentBid = 100,
    String date = '2030-12-31',
  }) {
    return fake.collection('products').add({
      'User Id': sellerId,
      'Product Name': name,
      'Product Description': 'desc',
      'Minimum Bid Price': '100',
      'Date': date,
      'Image Url': '',
      'nameLower': name.toLowerCase(),
      'endsAt': Timestamp.fromDate(DateTime.parse(date)),
      'currentBid': currentBid,
      'bidCount': bidCount,
      'status': status,
      'winnerId': null,
      'sellerName': 'Alice',
      'sellerPhoto': '',
      'createdAt': Timestamp.now(),
    });
  }

  test('getById returns Product when doc exists', () async {
    final ref = await seed(name: 'Camera');
    final product = await ProductRepository.getById(ref.id);
    expect(product, isNotNull);
    expect(product!.name, 'Camera');
    expect(product.currentBid, 100);
  });

  test('getById returns null when doc missing', () async {
    final product = await ProductRepository.getById('nope');
    expect(product, isNull);
  });

  test('watchByUser filters by seller id', () async {
    await seed(sellerId: 'a');
    await seed(sellerId: 'a', name: 'Two');
    await seed(sellerId: 'b', name: 'Other');

    final stream = ProductRepository.watchByUser('a');
    final products = await stream.first;
    expect(products.length, 2);
    expect(products.every((p) => p.sellerId == 'a'), isTrue);
  });

  test('deleteById removes the document', () async {
    final ref = await seed();
    await ProductRepository.deleteById(ref.id);
    final snap = await ref.get();
    expect(snap.exists, isFalse);
  });

  group('updateEditable', () {
    test('updates fields when bidCount == 0', () async {
      final ref = await seed();
      await ProductRepository.updateEditable(
        id: ref.id,
        description: 'new desc',
        date: '2031-01-15',
        minBidPrice: '250',
      );
      final after = (await ref.get()).data()!;
      expect(after['Product Description'], 'new desc');
      expect(after['Date'], '2031-01-15');
      expect(after['Minimum Bid Price'], '250');
      expect(after['currentBid'], 250);
    });

    test('throws when bidCount > 0', () async {
      final ref = await seed(bidCount: 3);
      expect(
        () => ProductRepository.updateEditable(
          id: ref.id,
          description: 'x',
          date: '2031-01-15',
          minBidPrice: '999',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when product missing', () async {
      expect(
        () => ProductRepository.updateEditable(
          id: 'ghost',
          description: 'x',
          date: '2031-01-15',
          minBidPrice: '999',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteAllByUser', () {
    test('removes only zero-bid products', () async {
      await seed(sellerId: 'u', bidCount: 0);
      await seed(sellerId: 'u', name: 'Two', bidCount: 0);
      await seed(sellerId: 'u', name: 'Three', bidCount: 5);
      await seed(sellerId: 'other');

      final deleted = await ProductRepository.deleteAllByUser('u');
      expect(deleted, 2);

      final remaining =
          await fake.collection('products').where('User Id', isEqualTo: 'u').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.data()['bidCount'], 5);
    });
  });

  group('search', () {
    test('returns prefix matches via nameLower', () async {
      await seed(name: 'Antique Lamp');
      await seed(name: 'Antique Chair');
      await seed(name: 'Modern Sofa');

      final results = await ProductRepository.search('antique');
      expect(results.length, 2);
      expect(results.every((p) => p.name.toLowerCase().startsWith('antique')),
          isTrue);
    });

    test('falls back to client-side contains when prefix yields nothing',
        () async {
      // Seed a doc without nameLower (legacy).
      await fake.collection('products').add({
        'User Id': 'x',
        'Product Name': 'Old Camera',
        'Product Description': 'd',
        'Minimum Bid Price': '10',
        'Date': '2030-01-01',
        'Image Url': '',
        'currentBid': 10,
        'bidCount': 0,
        'status': 'active',
      });
      final results = await ProductRepository.search('camera');
      expect(results.length, 1);
      expect(results.first.name, 'Old Camera');
    });

    test('empty query returns empty list', () async {
      await seed();
      final results = await ProductRepository.search('');
      expect(results, isEmpty);
    });
  });
}