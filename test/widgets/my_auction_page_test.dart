import 'package:app/providers/theme_provider.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/screens/my_auction_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, SharedPreferences prefs) {
  return ChangeNotifierProvider<ThemeProvider>(
    create: (_) => ThemeProvider(prefs),
    child: MaterialApp(home: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows empty state when user has no auctions', (tester) async {
    final fake = FakeFirebaseFirestore();
    ProductRepository.firestoreForTesting = fake;
    AuthRepository.authForTesting = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1'),
    );

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const MyAuctionsPage(), prefs));
    await tester.pumpAndSettle();

    expect(find.text('No auctions found'), findsOneWidget);
  });

  testWidgets('renders auctions when user has products', (tester) async {
    final fake = FakeFirebaseFirestore();
    ProductRepository.firestoreForTesting = fake;
    AuthRepository.authForTesting = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'seller-1'),
    );

    await fake.collection('products').add({
      'User Id': 'seller-1',
      'Product Name': 'Painting',
      'Product Description': 'an oil painting',
      'Minimum Bid Price': '50',
      'Date': '2030-12-31',
      'Image Url': '',
      'currentBid': 50,
      'bidCount': 0,
      'status': 'active',
      'endsAt': Timestamp.fromDate(DateTime(2030, 12, 31)),
    });

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const MyAuctionsPage(), prefs));
    await tester.pumpAndSettle();

    expect(find.text('Painting'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}