import 'package:app/features/notifications/data/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    NotificationRepository.firestoreForTesting = fake;
  });

CollectionReference<Map<String, dynamic>> itemsRef(String uid) {
    return fake.collection('notifications').doc(uid).collection('items');
  }

  Future<void> seed(String uid, {required bool read, String type = 'outbid'}) {
    return itemsRef(uid).add({
      'type': type,
      'productId': 'p1',
      'productName': 'Item',
      'productImage': '',
      'amount': 100,
      'read': read,
      'createdAt': Timestamp.now(),
    });
  }

  test('watchByUser returns items ordered by createdAt desc', () async {
    await itemsRef('u').add({
      'type': 'outbid',
      'productId': 'p1',
      'productName': 'Old',
      'productImage': '',
      'read': false,
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(hours: 1)),
      ),
    });
    await itemsRef('u').add({
      'type': 'auction_won',
      'productId': 'p2',
      'productName': 'New',
      'productImage': '',
      'read': false,
      'createdAt': Timestamp.now(),
    });

    final items = await NotificationRepository.watchByUser('u').first;
    expect(items.length, 2);
    expect(items.first.productName, 'New');
  });

  test('watchUnreadCount reflects only read==false items', () async {
    await seed('u', read: false);
    await seed('u', read: true);
    await seed('u', read: false);

    final count = await NotificationRepository.watchUnreadCount('u').first;
    expect(count, 2);
  });

  test('markRead flips read to true', () async {
    final ref = await itemsRef('u').add({
      'type': 'outbid',
      'productId': 'p',
      'productName': 'n',
      'productImage': '',
      'read': false,
      'createdAt': Timestamp.now(),
    });

    await NotificationRepository.markRead('u', ref.id);
    final after = (await ref.get()).data()!;
    expect(after['read'], isTrue);
  });
}