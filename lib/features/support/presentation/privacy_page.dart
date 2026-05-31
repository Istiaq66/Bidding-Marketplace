import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        backgroundColor: colorToken.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Data we collect', colorToken),
            _body(
              'We store your email, display name, and any profile image you upload so you can sign in and be identified on auctions and bids. Your bid history and watchlist are kept while your account is active.',
              colorToken,
            ),
            const SizedBox(height: 16),
            _heading('How we use your data', colorToken),
            _body(
              'We use your data only to run the auction marketplace — showing your listings to buyers, attributing your bids, and notifying you about auction outcomes. We do not sell your data.',
              colorToken,
            ),
            const SizedBox(height: 16),
            _heading('Authentication', colorToken),
            _body(
              'Email/password and Google Sign-In are handled by Firebase Authentication. Your password is never stored on our servers.',
              colorToken,
            ),
            const SizedBox(height: 16),
            _heading('Deleting your account', colorToken),
            _body(
              'Account deletion is coming in a future release. In the interim, contact support to request data removal.',
              colorToken,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String text, ColorToken colorToken) {
    return Text(
      text,
      style: TextStyle(
        color: colorToken.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'SourceSans3',
      ),
    );
  }

  Widget _body(String text, ColorToken colorToken) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(
          color: colorToken.textSecondary,
          fontSize: 14,
          height: 1.5,
          fontFamily: 'SourceSans3',
        ),
      ),
    );
  }
}
