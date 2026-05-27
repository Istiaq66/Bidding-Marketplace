import 'package:app/features/profile/domain/app_user.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  UserRepository._();

  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @visibleForTesting
  static set firestoreForTesting(FirebaseFirestore db) => _db = db;

  @visibleForTesting
  static void resetForTesting() => _db = FirebaseFirestore.instance;

  static Future<void> ensureUserDocument() async {
    final user = AuthRepository.currentUser;
    if (user == null) return;
    final doc = _users.doc(user.uid);
    final snap = await doc.get();
    if (snap.exists) return;
    await doc.set({
      'userId': user.uid,
      'name': user.displayName,
      'email': user.email,
      'photo': user.photoURL,
    });
  }

  static Future<AppUser?> getById(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  static Stream<AppUser?> watchById(String uid) {
    return _users.doc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromFirestore(snap) : null,
        );
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
    await _users.doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'address': address,
      'profileImage': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Registers an FCM device token for push delivery. Stored as an array so a
  /// user can receive pushes on multiple devices.
  static Future<void> addFcmToken(String uid, String token) async {
    await _users.doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Removes an FCM token (logout / token invalidation).
  static Future<void> removeFcmToken(String uid, String token) async {
    await _users.doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  /// Persists the per-category push mute preferences. Keys:
  /// `sellerUpdates`, `outbid`, `endingSoon`, `newAuction`, `results`.
  static Future<void> updateNotificationPrefs(
    String uid,
    Map<String, bool> prefs,
  ) async {
    await _users.doc(uid).set({
      'notificationPrefs': prefs,
    }, SetOptions(merge: true));
  }

  /// Streams the raw notification preference map (empty when unset → all on).
  static Stream<Map<String, bool>> watchNotificationPrefs(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      final raw = data?['notificationPrefs'];
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v == true));
      }
      return <String, bool>{};
    });
  }
}