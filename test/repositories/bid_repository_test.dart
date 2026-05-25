import 'package:app/repositories/bid_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    BidRepository.firestoreForTesting = fake;
  });

Future<DocumentReference<Map<String, dynamic>>> seedProduct({
    String sellerId = 'seller',
    double currentBid = 100,
    String status = 'active',
    DateTime? endsAt,
  }) {
    final ends = endsAt ?? DateTime.now().add(const Duration(days: 1));
    return fake.collection('products').add({
      'User Id': sellerId,
      'Product Name': 'Item',
      'Minimum Bid Price': '100',
      'Date': '2030-01-01',
      'currentBid': currentBid,
      'bidCount': 0,
      'status': status,
      'endsAt': Timestamp.fromDate(ends),
    });
  }

  group('place', () {
    test('records bid, increments count, updates currentBid', () async {
      final product = await seedProduct();

      await BidRepository.place(
        productId: product.id,
        bidderId: 'bidder-1',
        amount: 150,
      );

      final updated = (await product.get()).data()!;
      expect(updated['currentBid'], 150);
      expect(updated['bidCount'], 1);
      expect(updated['highestBidderId'], 'bidder-1');

      final bids = await fake.collection('bids').get();
      expect(bids.docs.length, 1);
      expect(bids.docs.first.data()['Bid Amount'], 150);
    });

    test('rejects bid <= currentBid', () async {
      final product = await seedProduct(currentBid: 200);
      expect(
        () => BidRepository.place(
          productId: product.id,
          bidderId: 'b',
          amount: 200,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects bid from seller', () async {
      final product = await seedProduct(sellerId: 'seller-x');
      expect(
        () => BidRepository.place(
          productId: product.id,
          bidderId: 'seller-x',
          amount: 999,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects when auction not active', () async {
      final product = await seedProduct(status: 'ended');
      expect(
        () => BidRepository.place(
          productId: product.id,
          bidderId: 'b',
          amount: 999,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects when endsAt is in the past', () async {
      final product = await seedProduct(
        endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(
        () => BidRepository.place(
          productId: product.id,
          bidderId: 'b',
          amount: 999,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects when product missing', () async {
      expect(
        () => BidRepository.place(
          productId: 'missing',
          bidderId: 'b',
          amount: 10,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('deleteAllByBidder removes only matching bids', () async {
    await fake.collection('bids').add({
      'Bidder Id': 'me',
      'Product Id': 'p1',
      'Bid Amount': 10,
    });
    await fake.collection('bids').add({
      'Bidder Id': 'me',
      'Product Id': 'p2',
      'Bid Amount': 20,
    });
    await fake.collection('bids').add({
      'Bidder Id': 'other',
      'Product Id': 'p3',
      'Bid Amount': 30,
    });

    final deleted = await BidRepository.deleteAllByBidder('me');
    expect(deleted, 2);

    final remaining = await fake.collection('bids').get();
    expect(remaining.docs.length, 1);
    expect(remaining.docs.first.data()['Bidder Id'], 'other');
  });
}