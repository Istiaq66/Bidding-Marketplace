import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewUser {
  
  final existingUser = FirebaseAuth.instance.currentUser;

  // Check if user already exists
  checkUserExistence() async {
    if (existingUser != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(existingUser?.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        // Save user information in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(existingUser?.uid)
            .set({
          'userId': existingUser?.uid,
          'name': existingUser?.displayName,
          'email': existingUser?.email,
          'photo': existingUser?.photoURL
          // Other user information
        });
      }
    }
  }
}
