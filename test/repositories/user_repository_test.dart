import 'package:app/features/profile/data/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    UserRepository.firestoreForTesting = fake;
  });

test('getById returns null when no doc', () async {
    expect(await UserRepository.getById('uid-1'), isNull);
  });

  test('getById hydrates AppUser from snapshot', () async {
    await fake.collection('users').doc('uid-1').set({
      'userId': 'uid-1',
      'name': 'Alice',
      'email': 'a@example.com',
    });
    final user = await UserRepository.getById('uid-1');
    expect(user, isNotNull);
    expect(user!.name, 'Alice');
    expect(user.email, 'a@example.com');
  });

  test('updateProfile merges new fields into existing doc', () async {
    await fake.collection('users').doc('uid-1').set({
      'userId': 'uid-1',
      'name': 'Old',
      'email': 'old@example.com',
    });

    await UserRepository.updateProfile(
      uid: 'uid-1',
      name: 'New',
      email: 'new@example.com',
      phone: '555',
      bio: 'hi',
      address: 'street',
    );

    final doc = (await fake.collection('users').doc('uid-1').get()).data()!;
    expect(doc['name'], 'New');
    expect(doc['email'], 'new@example.com');
    expect(doc['phone'], '555');
    expect(doc['bio'], 'hi');
    expect(doc['address'], 'street');
    // userId field from earlier set() should remain (merge semantics).
    expect(doc['userId'], 'uid-1');
  });

  test('watchById emits null then doc as it is created', () async {
    final stream = UserRepository.watchById('uid-x');
    final results = <bool>[];
    final sub = stream.listen((u) => results.add(u != null));

    await fake.collection('users').doc('uid-x').set({'name': 'Bob'});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(results, contains(true));
  });
}