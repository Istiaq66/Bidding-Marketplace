import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/shell/presentation/navigation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: AuthRepository.authStateChanges,
        builder: (context, snapshot) {
          // Firebase restores the session asynchronously; without this a
          // signed-in user sees the login screen flash on every cold start.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const NavigationPage();
          }
          return const LoginRegister();
        },
      ),
    );
  }
}
