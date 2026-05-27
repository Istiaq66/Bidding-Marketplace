import 'package:app/features/bids/data/bid_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bid-amount validator lives inside the `_showBidDialog` form in
/// [ProductDetails], but the substantive logic — "bid must be strictly
/// greater than currentBid, and the auction must still be active" — is
/// enforced authoritatively in [BidRepository.place]. Driving that path
/// exercises the same validator without standing up the full screen, which
/// would otherwise need Firebase, ThemeProvider, route observers, and a
/// streamed product image.
void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    BidRepository.firestoreForTesting = fake;
  });

  Future<DocumentReference<Map<String, dynamic>>> seed({
    double currentBid = 100,
  }) async {
    return fake.collection('products').add({
      'User Id': 'seller',
      'Product Name': 'Test',
      'Minimum Bid Price': '100',
      'Date': '2030-01-01',
      'currentBid': currentBid,
      'bidCount': 0,
      'status': 'active',
      'endsAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 1)),
      ),
    });
  }

  test('bid equal to currentBid is rejected', () async {
    final product = await seed(currentBid: 100);
    expect(
      () => BidRepository.place(
        productId: product.id,
        bidderId: 'bidder',
        amount: 100,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Bid must be higher'),
        ),
      ),
    );
  });

  test('bid strictly greater than currentBid is accepted', () async {
    final product = await seed(currentBid: 100);
    await BidRepository.place(
      productId: product.id,
      bidderId: 'bidder',
      amount: 101,
    );
    final after = (await product.get()).data()!;
    expect(after['currentBid'], 101);
  });
}