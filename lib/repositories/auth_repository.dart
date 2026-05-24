import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository._();

  static const String _googleServerClientId =
      '122106600540-359hu91sqgrthmeq10746vic85uouq6a.apps.googleusercontent.com';

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static String? get currentUserId => _auth.currentUser?.uid;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize(serverClientId: _googleServerClientId);
    final GoogleSignInAccount gUser = await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication gAuth = gUser.authentication;
    final credential = GoogleAuthProvider.credential(idToken: gAuth.idToken);
    return _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}