import 'package:bidding_marketplace/features/bids/data/bid_repository.dart';
import 'package:bidding_marketplace/features/notifications/data/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    BidRepository.firestoreForTesting = fake;
    NotificationRepository.firestoreForTesting = fake;
  });

  test('watchByProduct returns the top bids, highest first', () async {
    for (final amount in [110, 150, 120, 130, 140, 160]) {
      await fake.collection('bids').add({
        'Product Id': 'p1',
        'Bidder Id': 'b$amount',
        'Bid Amount': amount,
      });
    }
    await fake.collection('bids').add({
      'Product Id': 'other',
      'Bidder Id': 'x',
      'Bid Amount': 999,
    });

    final bids = await BidRepository.watchByProduct('p1', limit: 3).first;
    expect(bids.map((b) => b.amount), ['160', '150', '140']);
  });

  test('watchRecentByBidder returns the newest bids first', () async {
    for (var i = 1; i <= 7; i++) {
      await fake.collection('bids').add({
        'Product Id': 'p$i',
        'Bidder Id': 'me',
        'Bid Amount': i,
        'Created At': Timestamp.fromMillisecondsSinceEpoch(i * 1000),
      });
    }
    final bids = await BidRepository.watchRecentByBidder('me', limit: 5).first;
    expect(bids.map((b) => b.productId), ['p7', 'p6', 'p5', 'p4', 'p3']);
  });

  test('place uses the {productId}_{bidCount} bid id', () async {
    await fake.collection('products').doc('p1').set({
      'User Id': 'seller',
      'currentBid': 100,
      'bidCount': 2,
      'minIncrement': 1,
      'status': 'active',
      'endsAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
    });
    await BidRepository.place(productId: 'p1', bidderId: 'me', amount: 105);
    expect((await fake.collection('bids').doc('p1_3').get()).exists, isTrue);
    expect(
      (await fake.collection('products').doc('p1').get()).data()!['bidCount'],
      3,
    );
  });

  test('markAllRead clears every unread notification', () async {
    final items = fake.collection('notifications').doc('u').collection('items');
    for (var i = 0; i < 3; i++) {
      await items.add({'read': false, 'createdAt': Timestamp.now()});
    }
    await items.add({'read': true, 'createdAt': Timestamp.now()});

    await NotificationRepository.markAllRead('u');

    final unread = await items.where('read', isEqualTo: false).get();
    expect(unread.docs, isEmpty);
  });
}
