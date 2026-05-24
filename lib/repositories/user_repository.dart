import 'dart:io';
import 'package:app/models/app_user.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserRepository {
  UserRepository._();

  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

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

  static Future<String> uploadProfileImage(String uid, File image) async {
    final fileName = 'profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('profile_images/$fileName');
    final snapshot = await ref.putFile(image);
    return snapshot.ref.getDownloadURL();
  }
}