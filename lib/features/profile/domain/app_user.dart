import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String? name;
  final String? email;
  final String? photo;
  final String? profileImage;
  final String? phone;
  final String? bio;
  final String? address;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.photo,
    this.profileImage,
    this.phone,
    this.bio,
    this.address,
  });

  /// Builds a user from the public `users/{uid}` doc. Pass the owner's
  /// `private/profile` data as [private] to fill contact fields; without it
  /// they fall back to legacy values still on the public doc (pre-migration).
  factory AppUser.fromFirestore(
    DocumentSnapshot snapshot, {
    Map<String, dynamic>? private,
  }) {
    final data = (snapshot.data() as Map<String, dynamic>? ?? const {});
    final priv = private ?? const <String, dynamic>{};
    String? privateField(String key) => (priv[key] ?? data[key]) as String?;
    return AppUser(
      id: snapshot.id,
      name: data['name'] as String?,
      email: privateField('email'),
      photo: data['photo'] as String?,
      profileImage: data['profileImage'] as String?,
      phone: privateField('phone'),
      bio: data['bio'] as String?,
      address: privateField('address'),
    );
  }

  String get displayImage {
    if (profileImage != null && profileImage!.isNotEmpty) return profileImage!;
    if (photo != null && photo!.isNotEmpty) return photo!;
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (photo != null) 'photo': photo,
      if (profileImage != null) 'profileImage': profileImage,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      if (address != null) 'address': address,
    };
  }
}
