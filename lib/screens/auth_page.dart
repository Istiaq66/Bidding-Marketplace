import 'package:app/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'navigation_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: AuthRepository.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const NavigationPage();
          }
          return const LoginRegister();
        },
      ),
    );
  }
}