import 'package:app/features/watchlist/data/watchlist_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    WatchlistRepository.firestoreForTesting = fake;
  });

  test('add → isWatched returns true', () async {
    await WatchlistRepository.add('user-1', 'product-A');
    expect(await WatchlistRepository.isWatched('user-1', 'product-A'), isTrue);
  });

  test('isWatched returns false when pair absent', () async {
    expect(await WatchlistRepository.isWatched('user-1', 'product-A'), isFalse);
  });

  test('removeByUserAndProduct deletes the entry', () async {
    await WatchlistRepository.add('user-1', 'product-A');
    await WatchlistRepository.removeByUserAndProduct('user-1', 'product-A');
    expect(await WatchlistRepository.isWatched('user-1', 'product-A'), isFalse);
  });

  test('deleteAllByUser drops every entry for that user only', () async {
    await WatchlistRepository.add('user-1', 'p1');
    await WatchlistRepository.add('user-1', 'p2');
    await WatchlistRepository.add('user-2', 'p1');

    await WatchlistRepository.deleteAllByUser('user-1');

    final remaining = await fake.collection('watchlist').get();
    expect(remaining.docs.length, 1);
    expect(remaining.docs.first.data()['User Id'], 'user-2');
  });

  test('watchByUser streams only entries for that user', () async {
    await WatchlistRepository.add('user-1', 'p1');
    await WatchlistRepository.add('user-2', 'p9');
    await WatchlistRepository.add('user-1', 'p2');

    final entries = await WatchlistRepository.watchByUser('user-1').first;
    expect(entries.length, 2);
  });
}
