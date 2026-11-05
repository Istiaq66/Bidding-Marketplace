import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/features/auctions/data/product_repository.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:bidding_marketplace/features/auctions/presentation/bid_dialog.dart';
import 'package:bidding_marketplace/features/auth/data/auth_repository.dart';
import 'package:bidding_marketplace/features/bids/data/bid_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore fake;
  late DocumentReference<Map<String, dynamic>> productRef;
  bool? result;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fake = FakeFirebaseFirestore();
    ProductRepository.firestoreForTesting = fake;
    BidRepository.firestoreForTesting = fake;
    AuthRepository.authForTesting = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'bidder'),
    );
    productRef = fake.collection('products').doc('p1');
    await productRef.set({
      'User Id': 'seller',
      'Product Name': 'Bike',
      'Minimum Bid Price': '100',
      'Date': '2030-01-01',
      'currentBid': 100,
      'bidCount': 1,
      'minIncrement': 5,
      'highestBidderId': 'someone',
      'status': 'active',
      'endsAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
    });
    result = null;
  });

  Future<void> openDialog(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final product = Product.fromFirestore(await productRef.get());
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(prefs),
        child: MaterialApp(
          home: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => BidDialog(initialProduct: product),
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('enforces the minimum increment', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), '102');
    await tester.tap(find.text('Place Bid'));
    await tester.pumpAndSettle();
    expect(find.text('Bid must be ≥ \$105.00'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('validates against bids that land while open', (tester) async {
    await openDialog(tester);
    await productRef.update({'currentBid': 200, 'bidCount': 2});
    await tester.pumpAndSettle();
    expect(find.text('Current bid: \$200.00'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '150');
    await tester.tap(find.text('Place Bid'));
    await tester.pumpAndSettle();
    expect(find.text('Bid must be > \$200.00'), findsOneWidget);
  });

  testWidgets('places a valid bid and closes', (tester) async {
    await openDialog(tester);
    await tester.enterText(find.byType(TextFormField), '110');
    await tester.tap(find.text('Place Bid'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(BidDialog), findsNothing);
    final product = (await productRef.get()).data()!;
    expect(product['currentBid'], 110);
    expect(product['highestBidderId'], 'bidder');
    expect((await fake.collection('bids').doc('p1_2').get()).exists, isTrue);
  });
}
