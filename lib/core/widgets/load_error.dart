import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

/// Shown when a stream or future fails, so a permission or network error
/// doesn't masquerade as an empty list or an endless spinner.
class LoadError extends StatelessWidget {
  const LoadError({
    super.key,
    this.message = "Couldn't load this. Check your connection and try again.",
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorToken.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
