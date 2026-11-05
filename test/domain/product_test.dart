import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Product product({
    String status = 'active',
    String? winnerId,
    DateTime? endsAt,
  }) {
    return Product(
      id: 'p1',
      sellerId: 'seller-1',
      name: 'Vintage Bike',
      description: 'desc',
      minBidPrice: '100',
      date: '2030-12-31',
      imageUrl: '',
      status: status,
      winnerId: winnerId,
      endsAt: endsAt ?? DateTime.now().add(const Duration(days: 1)),
    );
  }

  group('Product result', () {
    test('active auction is neither closed nor won', () {
      final p = product();
      expect(p.isClosed, isFalse);
      expect(p.isWonBy('bidder-1'), isFalse);
    });

    test('expired but unsettled auction is not closed yet', () {
      final p = product(
        endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(p.isActive, isFalse);
      expect(p.isClosed, isFalse);
      expect(p.isWonBy('bidder-1'), isFalse);
    });

    test('closed auction is won only by winnerId', () {
      final p = product(status: 'ended', winnerId: 'bidder-1');
      expect(p.isClosed, isTrue);
      expect(p.isWonBy('bidder-1'), isTrue);
      expect(p.isWonBy('bidder-2'), isFalse);
      expect(p.isWonBy(null), isFalse);
    });

    test('closed auction with no bids has no winner', () {
      final p = product(status: 'ended');
      expect(p.isWonBy(null), isFalse);
      expect(p.isWonBy('bidder-1'), isFalse);
    });
  });
}
