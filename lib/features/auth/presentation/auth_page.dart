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
          if (snapshot.hasData) {
            return const NavigationPage();
          }
          return const LoginRegister();
        },
      ),
    );
  }
}
