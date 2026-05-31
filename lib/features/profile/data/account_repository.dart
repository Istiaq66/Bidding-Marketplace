import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/bids/data/bid_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/watchlist/data/watchlist_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Account-level operations that span multiple collections. Account deletion
/// in particular needs to cascade across `users`, `products`, `bids`,
/// `watchlist`, and finally Firebase Auth.
class AccountRepository {
  AccountRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Re-authenticates the current user with their email/password.
  ///
  /// Firebase requires a fresh credential for sensitive operations such as
  /// `delete()`. Surfaces a user-readable [Exception] on failure.
  static Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw Exception('No password-backed account is currently signed in.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /// Re-authenticates the current user via the Google provider. Triggers a
  /// fresh Google sign-in to obtain a current ID token.
  static Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in.');
    }
    final account = await GoogleSignIn.instance.authenticate();
    final auth = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /// Returns the provider IDs (e.g. `password`, `google.com`) attached to the
  /// signed-in user, used to decide which reauth flow to surface.
  static List<String> currentUserProviders() {
    final user = _auth.currentUser;
    if (user == null) return const [];
    return user.providerData.map((p) => p.providerId).toList();
  }

  /// Cascades deletion of all data owned by the current user, then deletes
  /// the Firebase Auth account itself.
  ///
  /// Assumes the caller has just re-authenticated. Deletion order:
  ///   1. `watchlist` entries
  ///   2. `products` (only docs with `bidCount == 0`)
  ///   3. `bids` (best-effort; rules currently block delete)
  ///   4. `users/{uid}`
  ///   5. `FirebaseAuth.currentUser.delete()`
  ///
  /// If Firestore writes fail mid-way the auth account is left intact so the
  /// caller can retry without orphaning the user record.
  static Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (user == null || uid == null) {
      throw Exception('No user is currently signed in.');
    }

    await WatchlistRepository.deleteAllByUser(uid);
    await ProductRepository.deleteAllByUser(uid);
    await BidRepository.deleteAllByBidder(uid);
    await _db.collection('users').doc(uid).delete();

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }

    // Sign out from the Google session too, so the next launch lands on the
    // login screen cleanly.
    try {
      await AuthRepository.signOut();
    } catch (_) {}
  }

  static String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'requires-recent-login':
        return 'For security, please sign in again before deleting your account.';
      case 'user-mismatch':
        return 'The credential does not match the signed-in account.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}
