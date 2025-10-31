import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
   static final FirebaseAuth _auth = FirebaseAuth.instance;

   static signInWithGoogle() async {
    //begin interactive sign in process
     await GoogleSignIn.instance.initialize(serverClientId: '122106600540-359hu91sqgrthmeq10746vic85uouq6a.apps.googleusercontent.com');
     final GoogleSignInAccount gUser = await GoogleSignIn.instance.authenticate();
     // Obtain auth details from request
     final GoogleSignInAuthentication gAuth = gUser.authentication;
    // create  a new credential for user
     final credential = GoogleAuthProvider.credential(
       idToken: gAuth.idToken,
     );
    // finally, let's sign in
    return await _auth.signInWithCredential(credential);
  }

   static Future<UserCredential?> signInWithEmail({
     required String email,
     required String password,
   }) async {
     try {
       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
         email: email,
         password: password,
       );
       return userCredential;
     } on FirebaseAuthException catch (e) {
       if (e.code == 'user-not-found') {
         throw Exception('No user found for that email.');
       } else if (e.code == 'wrong-password') {
         throw Exception('Wrong password provided.');
       } else if (e.code == 'invalid-email') {
         throw Exception('Invalid email address.');
       } else {
         throw Exception('An error occurred: ${e.message}');
       }
     } catch (e) {
       throw Exception('An error occurred: $e');
     }
   }

   // Sign up with email and password
   static Future<UserCredential?> signUpWithEmail({
     required String email,
     required String password,
   }) async {
     try {
       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
         email: email,
         password: password,
       );
       return userCredential;
     } on FirebaseAuthException catch (e) {
       if (e.code == 'weak-password') {
         throw Exception('The password provided is too weak.');
       } else if (e.code == 'email-already-in-use') {
         throw Exception('An account already exists for that email.');
       } else if (e.code == 'invalid-email') {
         throw Exception('Invalid email address.');
       } else {
         throw Exception('An error occurred: ${e.message}');
       }
     } catch (e) {
       throw Exception('An error occurred: $e');
     }
   }

   // Sign out
   static Future<void> signOut() async {
     await _auth.signOut();
     await GoogleSignIn.instance.signOut();
   }

   // Get current user
   static User? getCurrentUser() {
     return _auth.currentUser;
   }

   static Future<void> resetPassword(String email) async {
     try {
       await _auth.sendPasswordResetEmail(email: email);
     } on FirebaseAuthException catch (e) {
       if (e.code == 'user-not-found') {
         throw Exception('No user found for that email.');
       } else {
         throw Exception('An error occurred: ${e.message}');
       }
     }
   }
}
