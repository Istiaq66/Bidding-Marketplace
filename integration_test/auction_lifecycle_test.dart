// Integration test for the end-to-end auction lifecycle. This test must run
// against the Firebase Local Emulator Suite — `firebase emulators:start` —
// because it exercises Firestore + Auth round-trips.
//
// Run with:
//   firebase emulators:start --only auth,firestore &
//   flutter test integration_test/auction_lifecycle_test.dart
//
// The Cloud Function `endAuction` is *not* invoked by this test; we simulate
// its behaviour ("forced clock") by writing the closing transaction
// directly. The repository-layer transactional bid path and the seller
// notification fan-out remain real.

import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/bids/data/bid_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore db;
  late FirebaseAuth auth;

  setUpAll(() async {
    await Firebase.initializeApp();

    db = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;

    // Point at the emulator. Idempotent; safe to call repeatedly.
    db.useFirestoreEmulator('127.0.0.1', 8080);
    await auth.useAuthEmulator('127.0.0.1', 9099);

    AuthRepository.authForTesting = auth;
  });

  testWidgets('anon user creates auction, places bid, auction is closed',
      (tester) async {
    final seller = await auth.signInAnonymously();
    final sellerId = seller.user!.uid;

    // Seller writes the product directly (bypassing image upload).
    final productRef = await db.collection('products').add({
      'User Id': sellerId,
      'Product Name': 'IT Test Item',
      'Product Description': 'integration',
      'Minimum Bid Price': '50',
      'Date': '2099-12-31',
      'Image Url': '',
      'nameLower': 'it test item',
      'endsAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 5)),
      ),
      'currentBid': 50,
      'bidCount': 0,
      'status': 'active',
      'winnerId': null,
      'sellerName': 'tester',
      'sellerPhoto': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Switch to a second anon user (the bidder).
    await auth.signOut();
    final bidder = await auth.signInAnonymously();
    final bidderId = bidder.user!.uid;
    expect(bidderId, isNot(sellerId));

    await BidRepository.place(
      productId: productRef.id,
      bidderId: bidderId,
      amount: 75,
    );

    // "Forced clock": simulate endAuction by closing the auction now.
    final topBid = await db
        .collection('bids')
        .where('Product Id', isEqualTo: productRef.id)
        .orderBy('Bid Amount', descending: true)
        .limit(1)
        .get();
    final winnerId =
        topBid.docs.isEmpty ? null : topBid.docs.first.data()['Bidder Id'];

    await productRef.update({
      'status': 'ended',
      'winnerId': winnerId,
      'endedAt': FieldValue.serverTimestamp(),
    });

    final closed = (await productRef.get()).data()!;
    expect(closed['status'], 'ended');
    expect(closed['winnerId'], bidderId);
    expect(closed['currentBid'], 75);
    expect(closed['bidCount'], 1);

    await auth.signOut();
  });
}