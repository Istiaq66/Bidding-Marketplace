import 'package:app/providers/theme_provider.dart';
import 'package:flutter/material.dart';

extension ScaffoldMessengerExt on BuildContext {
  void showSuccess(String message) {
    final colorToken = ThemeProvider.of(this).colorToken;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorToken.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showError(String message) {
    final colorToken = ThemeProvider.of(this).colorToken;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorToken.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showInfo(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}