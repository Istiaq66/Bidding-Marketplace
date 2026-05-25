import 'package:app/repositories/auth_repository.dart';
import 'package:app/screens/login.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthRepository.authForTesting = MockFirebaseAuth();
  });

  Widget wrap() => const MaterialApp(home: LoginRegister());

  testWidgets('renders email + password fields and login affordances',
      (tester) async {
    await tester.pumpWidget(wrap());
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Not a member?'), findsOneWidget);
    expect(find.text('Register Now'), findsOneWidget);
  });
}