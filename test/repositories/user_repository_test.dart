import 'package:app/features/profile/data/user_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    UserRepository.firestoreForTesting = fake;
  });

  Future<Map<String, dynamic>> publicDoc(String uid) async =>
      (await fake.collection('users').doc(uid).get()).data()!;

  Future<Map<String, dynamic>?> privateDoc(String uid) async =>
      (await fake
              .collection('users')
              .doc(uid)
              .collection('private')
              .doc('profile')
              .get())
          .data();

  test('getById returns null when no doc', () async {
    expect(await UserRepository.getById('uid-1'), isNull);
  });

  test('getById hydrates public fields only', () async {
    await fake.collection('users').doc('uid-1').set({
      'userId': 'uid-1',
      'name': 'Alice',
      'bio': 'hi',
    });
    await fake
        .collection('users')
        .doc('uid-1')
        .collection('private')
        .doc('profile')
        .set({'email': 'a@example.com'});

    final user = await UserRepository.getById('uid-1');
    expect(user!.name, 'Alice');
    expect(user.bio, 'hi');
    expect(user.email, isNull);
  });

  test('getOwnProfile merges private fields', () async {
    await fake.collection('users').doc('uid-1').set({'name': 'Alice'});
    await fake
        .collection('users')
        .doc('uid-1')
        .collection('private')
        .doc('profile')
        .set({'email': 'a@example.com', 'phone': '555'});

    final user = await UserRepository.getOwnProfile('uid-1');
    expect(user!.name, 'Alice');
    expect(user.email, 'a@example.com');
    expect(user.phone, '555');
  });

  test('updateProfile splits public and private fields', () async {
    await fake.collection('users').doc('uid-1').set({
      'userId': 'uid-1',
      'name': 'Old',
    });

    await UserRepository.updateProfile(
      uid: 'uid-1',
      name: 'New',
      email: 'new@example.com',
      phone: '555',
      bio: 'hi',
      address: 'street',
    );

    final pub = await publicDoc('uid-1');
    expect(pub['name'], 'New');
    expect(pub['bio'], 'hi');
    expect(pub['userId'], 'uid-1');
    expect(pub.containsKey('email'), isFalse);
    expect(pub.containsKey('phone'), isFalse);
    expect(pub.containsKey('address'), isFalse);

    final priv = (await privateDoc('uid-1'))!;
    expect(priv['email'], 'new@example.com');
    expect(priv['phone'], '555');
    expect(priv['address'], 'street');
  });

  test('FCM tokens and prefs are stored privately', () async {
    await UserRepository.addFcmToken('uid-1', 't1');
    await UserRepository.addFcmToken('uid-1', 't2');
    await UserRepository.removeFcmToken('uid-1', 't1');
    await UserRepository.updateNotificationPrefs('uid-1', {'outbid': false});

    final priv = (await privateDoc('uid-1'))!;
    expect(priv['fcmTokens'], ['t2']);
    expect(priv['notificationPrefs'], {'outbid': false});
    expect(await UserRepository.watchNotificationPrefs('uid-1').first, {
      'outbid': false,
    });
  });

  test(
    'migrateLegacyPrivateFields moves private keys off the public doc',
    () async {
      await fake.collection('users').doc('uid-1').set({
        'userId': 'uid-1',
        'name': 'Alice',
        'email': 'a@example.com',
        'address': 'street',
        'fcmTokens': ['old'],
      });
      await UserRepository.addFcmToken('uid-1', 'new');

      await UserRepository.migrateLegacyPrivateFields('uid-1');

      final pub = await publicDoc('uid-1');
      expect(pub.keys.toSet(), {'userId', 'name'});
      final priv = (await privateDoc('uid-1'))!;
      expect(priv['email'], 'a@example.com');
      expect(priv['address'], 'street');
      expect(priv['fcmTokens'], containsAll(['old', 'new']));

      // Second run is a no-op.
      await UserRepository.migrateLegacyPrivateFields('uid-1');
      expect((await publicDoc('uid-1')).keys.toSet(), {'userId', 'name'});
    },
  );

  test('deleteProfile removes both docs', () async {
    await fake.collection('users').doc('uid-1').set({'name': 'A'});
    await UserRepository.addFcmToken('uid-1', 't');
    await UserRepository.deleteProfile('uid-1');
    expect((await fake.collection('users').doc('uid-1').get()).exists, isFalse);
    expect(await privateDoc('uid-1'), isNull);
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
