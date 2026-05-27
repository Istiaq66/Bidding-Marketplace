import 'package:app/core/theme/theme_provider.dart';
import 'package:app/features/profile/data/account_repository.dart';
import 'package:flutter/material.dart';

/// Two-step destructive flow:
///   1. Re-authenticate (Google or password, depending on the provider).
///   2. Confirm deletion, then cascade-delete all user data.
///
/// On success the auth state listener routes the user back to the login
/// screen, so this page does not need to navigate anywhere itself.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  bool _isReauthenticated = false;
  bool _isWorking = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isGoogleUser =>
      AccountRepository.currentUserProviders().contains('google.com');

  Future<void> _reauthenticate() async {
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      if (_isGoogleUser) {
        await AccountRepository.reauthenticateWithGoogle();
      } else {
        final pw = _passwordController.text;
        if (pw.isEmpty) {
          throw Exception('Enter your password to continue.');
        }
        await AccountRepository.reauthenticateWithPassword(pw);
      }
      if (!mounted) return;
      setState(() => _isReauthenticated = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently remove your profile, your watchlist, '
          'every auction you created without bids, and every bid you placed. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await AccountRepository.deleteCurrentUser();
      // AuthPage's StreamBuilder will route to login on signOut().
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

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
          'Delete Account',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorToken.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorToken.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colorToken.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deleting your account cannot be undone. Auctions with '
                        'active bids will be left in place so existing bidders '
                        'are not disrupted.',
                        style: TextStyle(
                          color: colorToken.textPrimary,
                          fontFamily: 'SourceSans3',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_isReauthenticated) ..._buildReauthSection(colorToken)
              else ..._buildConfirmSection(colorToken),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: colorToken.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReauthSection(ColorToken colorToken) {
    return [
      Text(
        'Step 1 of 2 — Re-authenticate',
        style: TextStyle(
          color: colorToken.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'SourceSans3',
        ),
      ),
      const SizedBox(height: 12),
      if (_isGoogleUser)
        Text(
          'For security, please re-confirm your Google account before '
          'deleting your data.',
          style: TextStyle(color: colorToken.textSecondary),
        )
      else ...[
        Text(
          'Enter your password to confirm.',
          style: TextStyle(color: colorToken.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: TextStyle(color: colorToken.textPrimary),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: colorToken.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _isWorking ? null : _reauthenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorToken.primary,
          foregroundColor: colorToken.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isWorking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(_isGoogleUser
                ? 'Continue with Google'
                : 'Verify Password'),
      ),
    ];
  }

  List<Widget> _buildConfirmSection(ColorToken colorToken) {
    return [
      Text(
        'Step 2 of 2 — Confirm deletion',
        style: TextStyle(
          color: colorToken.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'SourceSans3',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'You\'re re-authenticated. Tap the button below to permanently '
        'delete your account.',
        style: TextStyle(color: colorToken.textSecondary),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _isWorking ? null : _confirmDelete,
        icon: const Icon(Icons.delete_forever),
        label: const Text('Delete my account'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorToken.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ];
  }
}