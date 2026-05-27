import 'package:app/core/theme/theme_provider.dart';
import 'package:app/features/profile/presentation/delete_account_page.dart';
import 'package:app/features/profile/presentation/notification_settings_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context, listen: true);
    final colorToken = themeProvider.colorToken;

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
          'Settings',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
      ),
      body: ListView(
        children: [
          _sectionHeader('Appearance', colorToken),
          SwitchListTile(
            value: !themeProvider.isLightTheme,
            onChanged: (_) => themeProvider.toggleTheme(),
            title: Text(
              'Dark mode',
              style: TextStyle(color: colorToken.textPrimary, fontFamily: 'SourceSans3'),
            ),
            secondary: Icon(
              themeProvider.isLightTheme ? Icons.light_mode : Icons.dark_mode,
              color: colorToken.textPrimary,
            ),
            activeColor: colorToken.primary,
          ),
          _sectionHeader('Account', colorToken),
          ListTile(
            leading: Icon(Icons.notifications, color: colorToken.textPrimary),
            title: Text(
              'Notifications',
              style: TextStyle(
                  color: colorToken.textPrimary, fontFamily: 'SourceSans3'),
            ),
            trailing:
                Icon(Icons.chevron_right, color: colorToken.textSecondary),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage()),
            ),
          ),
          _comingSoonTile(context, Icons.lock_outline, 'Privacy & Security', colorToken),
          _comingSoonTile(context, Icons.payment, 'Payment methods', colorToken),
          _sectionHeader('Danger zone', colorToken),
          ListTile(
            leading: Icon(Icons.delete_forever, color: colorToken.error),
            title: Text(
              'Delete account',
              style: TextStyle(
                color: colorToken.error,
                fontFamily: 'SourceSans3',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Permanently remove your profile and data',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colorToken.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
              );
            },
          ),
          _sectionHeader('About', colorToken),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorToken.textPrimary),
            title: Text(
              'Version',
              style: TextStyle(color: colorToken.textPrimary, fontFamily: 'SourceSans3'),
            ),
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: colorToken.textSecondary, fontFamily: 'SourceSans3'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, ColorToken colorToken) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: colorToken.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontFamily: 'SourceSans3',
        ),
      ),
    );
  }

  Widget _comingSoonTile(BuildContext context, IconData icon, String title, ColorToken colorToken) {
    return ListTile(
      leading: Icon(icon, color: colorToken.textPrimary),
      title: Text(
        title,
        style: TextStyle(color: colorToken.textPrimary, fontFamily: 'SourceSans3'),
      ),
      trailing: Icon(Icons.chevron_right, color: colorToken.textSecondary),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title — coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}