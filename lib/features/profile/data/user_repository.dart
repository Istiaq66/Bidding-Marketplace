import 'package:bidding_marketplace/features/profile/domain/app_user.dart';
import 'package:bidding_marketplace/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// User profiles are split in two documents:
///   - `users/{uid}`: public profile (name, photo, bio), readable by any
///     signed-in user.
///   - `users/{uid}/private/profile`: contact details, FCM tokens and
///     notification prefs, readable only by the owner (and Cloud Functions).
class UserRepository {
  UserRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static DocumentReference<Map<String, dynamic>> _private(String uid) =>
      _users.doc(uid).collection('private').doc('profile');

  /// Keys older app versions wrote on the public doc that now belong in the
  /// private doc.
  static const _privateKeys = [
    'email',
    'phone',
    'address',
    'fcmTokens',
    'notificationPrefs',
  ];

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

  static Future<void> ensureUserDocument() async {
    final user = AuthRepository.currentUser;
    if (user == null) return;
    final doc = _users.doc(user.uid);
    final snap = await doc.get();
    if (snap.exists) {
      await migrateLegacyPrivateFields(user.uid);
      return;
    }
    final batch = _db.batch();
    batch.set(doc, {
      'userId': user.uid,
      'name': user.displayName,
      'photo': user.photoURL,
    });
    batch.set(_private(user.uid), {
      'email': user.email,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Moves private fields left on the public doc by older app versions into
  /// the private doc. No-op once migrated.
  @visibleForTesting
  static Future<void> migrateLegacyPrivateFields(String uid) async {
    final ref = _users.doc(uid);
    final data = (await ref.get()).data();
    if (data == null) return;

    final legacy = {
      for (final key in _privateKeys)
        if (data.containsKey(key)) key: data[key],
    };
    if (legacy.isEmpty) return;

    final tokens = legacy['fcmTokens'];
    if (tokens is List) legacy['fcmTokens'] = FieldValue.arrayUnion(tokens);

    final batch = _db.batch();
    batch.set(_private(uid), legacy, SetOptions(merge: true));
    batch.update(ref, {
      for (final key in legacy.keys) key: FieldValue.delete(),
    });
    await batch.commit();
  }

  /// Public profile of any user. Contact fields are not included.
  static Future<AppUser?> getById(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  /// The signed-in user's full profile, public and private fields merged.
  /// Only works for the owner: rules deny reading another user's private doc.
  static Future<AppUser?> getOwnProfile(String uid) async {
    final results = await Future.wait([
      _users.doc(uid).get(),
      _private(uid).get(),
    ]);
    if (!results[0].exists) return null;
    return AppUser.fromFirestore(results[0], private: results[1].data());
  }

  static Stream<AppUser?> watchById(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? AppUser.fromFirestore(snap) : null);
  }

  static Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String bio,
    required String address,
    String? profileImageUrl,
  }) async {
    final batch = _db.batch();
    batch.set(_users.doc(uid), {
      'name': name,
      'bio': bio,
      'profileImage': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_private(uid), {
      'email': email,
      'phone': phone,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Registers an FCM device token for push delivery. Stored as an array so a
  /// user can receive pushes on multiple devices.
  static Future<void> addFcmToken(String uid, String token) async {
    await _private(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Removes an FCM token (logout / token invalidation).
  static Future<void> removeFcmToken(String uid, String token) async {
    await _private(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  /// Persists the per-category push mute preferences. Keys:
  /// `sellerUpdates`, `outbid`, `endingSoon`, `newAuction`, `results`.
  static Future<void> updateNotificationPrefs(
    String uid,
    Map<String, bool> prefs,
  ) async {
    await _private(
      uid,
    ).set({'notificationPrefs': prefs}, SetOptions(merge: true));
  }

  /// Streams the raw notification preference map (empty when unset → all on).
  static Stream<Map<String, bool>> watchNotificationPrefs(String uid) {
    return _private(uid).snapshots().map((snap) {
      final data = snap.data();
      final raw = data?['notificationPrefs'];
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v == true));
      }
      return <String, bool>{};
    });
  }

  /// Deletes both profile docs. Used by account deletion.
  static Future<void> deleteProfile(String uid) async {
    final batch = _db.batch();
    batch.delete(_private(uid));
    batch.delete(_users.doc(uid));
    await batch.commit();
  }
}
