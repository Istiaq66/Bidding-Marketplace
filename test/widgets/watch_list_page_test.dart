import 'package:app/core/theme/theme_provider.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/watchlist/data/watchlist_repository.dart';
import 'package:app/features/watchlist/presentation/watch_list_page.dart';
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

  testWidgets('renders empty state when no watchlist entries', (tester) async {
    final fake = FakeFirebaseFirestore();
    WatchlistRepository.firestoreForTesting = fake;
    AuthRepository.authForTesting = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1', email: 'a@example.com'),
    );

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(const WatchList(), prefs));
    await tester.pumpAndSettle();

    expect(find.text('No items in watchlist'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}
