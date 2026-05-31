import 'package:app/core/theme/theme_provider.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/profile/data/user_repository.dart';
import 'package:flutter/material.dart';

/// Per-category push notification toggles. Stored on `users/{uid}` under
/// `notificationPrefs`; an absent key means the category is enabled. Cloud
/// Functions skip the push (but still write the in-app row) when a category is
/// set to `false`.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  static const _categories = <(String, String, String)>[
    (
      'sellerUpdates',
      'Bids on my auctions',
      'When someone bids or an auction of mine ends',
    ),
    ('outbid', 'Outbid alerts', "When you've been outbid"),
    ('endingSoon', 'Ending soon', 'Reminders before watched auctions close'),
    ('newAuction', 'Followed sellers', 'New auctions from sellers you follow'),
    ('results', 'Auction results', 'When you win or lose an auction'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final uid = AuthRepository.currentUserId;

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
          'Notifications',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
      ),
      body:
          uid == null
              ? Center(
                child: Text(
                  'Sign in to manage notifications',
                  style: TextStyle(color: colorToken.textSecondary),
                ),
              )
              : StreamBuilder<Map<String, bool>>(
                stream: UserRepository.watchNotificationPrefs(uid),
                builder: (context, snapshot) {
                  final prefs = snapshot.data ?? const <String, bool>{};
                  return ListView(
                    children: [
                      for (final (key, title, subtitle) in _categories)
                        SwitchListTile(
                          value: prefs[key] ?? true,
                          activeColor: colorToken.primary,
                          title: Text(
                            title,
                            style: TextStyle(
                              color: colorToken.textPrimary,
                              fontFamily: 'SourceSans3',
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: TextStyle(
                              color: colorToken.textSecondary,
                              fontSize: 12,
                              fontFamily: 'SourceSans3',
                            ),
                          ),
                          onChanged: (value) {
                            final updated = Map<String, bool>.from(prefs)
                              ..[key] = value;
                            UserRepository.updateNotificationPrefs(
                              uid,
                              updated,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
    );
  }
}
