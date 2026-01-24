import 'package:app/Screens/dashboard.dart';
import 'package:app/Screens/home.dart';
import 'package:app/Screens/profile.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int index = 0;

  final screens = [
    const Home(),
    const Dashboard(),
    const Profile(),
  ];

  // Get dynamic AppBar based on current page
  PreferredSizeWidget _getAppBar(BuildContext context, int currentIndex) {
    final colorToken = ThemeProvider.of(context, listen: true).colorToken;

    switch (currentIndex) {
      case 0: // Home
        return AppBar(
          backgroundColor: colorToken.surface,
          elevation: 0,
          title: Text(
            'Home',
            style: TextStyle(
              color: colorToken.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'SourceSans3',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: colorToken.textPrimary),
              onPressed: () {
                // Navigate to search
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: colorToken.textPrimary),
              onPressed: () {
                // Navigate to notifications
              },
            ),
            const SizedBox(width: 8),
          ],
        );

      case 1: // Dashboard
        return AppBar(
          backgroundColor: colorToken.surface,
          elevation: 0,
          title: Text(
            'My Dashboard',
            style: TextStyle(
              color: colorToken.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'SourceSans3',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list, color: colorToken.textPrimary),
              onPressed: () {
                _showFilterBottomSheet(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: colorToken.textPrimary),
              onPressed: () {
                _showDashboardOptionsMenu(context);
              },
            ),
            const SizedBox(width: 8),
          ],
        );

      case 2: // Profile
        final themeProvider = ThemeProvider.of(context, listen: true);
        return AppBar(
          backgroundColor: colorToken.surface,
          elevation: 0,
          title: Text(
            'Profile',
            style: TextStyle(
              color: colorToken.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'SourceSans3',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isLightTheme ? Icons.dark_mode : Icons.light_mode,
                color: colorToken.textPrimary,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: 'Toggle theme',
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: colorToken.textPrimary),
              onPressed: () {
                _showProfileSettingsMenu(context);
              },
            ),
            const SizedBox(width: 8),
          ],
        );

      default:
        return AppBar();
    }
  }

  // Dashboard Filter Bottom Sheet
  void _showFilterBottomSheet(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorToken.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorToken.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Filter By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterOption(context, 'All Auctions', true),
            _buildFilterOption(context, 'Active Only', false),
            _buildFilterOption(context, 'Ending Soon', false),
            _buildFilterOption(context, 'My Bids', false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String title, bool isSelected) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: colorToken.textPrimary,
          fontFamily: 'SourceSans3',
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: colorToken.primary) : null,
      onTap: () {
        Navigator.pop(context);
        // Apply filter
      },
    );
  }

  // Dashboard Options Menu
  void _showDashboardOptionsMenu(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorToken.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorToken.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.refresh, color: colorToken.textPrimary),
              title: Text(
                'Refresh',
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Refresh data
              },
            ),
            ListTile(
              leading: Icon(Icons.sort, color: colorToken.textPrimary),
              title: Text(
                'Sort By',
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Show sort options
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: colorToken.textPrimary),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Profile Settings Menu
  void _showProfileSettingsMenu(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorToken.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorToken.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit, color: colorToken.textPrimary),
              title: Text(
                'Edit Profile',
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit profile
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_outline, color: colorToken.textPrimary),
              title: Text(
                'Privacy & Security',
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to privacy settings
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: colorToken.textPrimary),
              title: Text(
                'Help & Support',
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Navigate to help
              },
            ),
            const SizedBox(height: 8),
            Divider(color: colorToken.divider, height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: colorToken.error),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: colorToken.error,
                  fontFamily: 'SourceSans3',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorToken.surface,
        title: Text(
          'Logout',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontFamily: 'SourceSans3',
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: colorToken.textSecondary,
            fontFamily: 'SourceSans3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement logout
              // AuthService.signOut();
              // Navigate to login
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: colorToken.error,
                fontWeight: FontWeight.bold,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        final colorToken = theme.colorToken;

        return Scaffold(
          backgroundColor: colorToken.background,
          appBar: _getAppBar(context, index), // Dynamic AppBar
          body: screens[index],
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: colorToken.surface,
              indicatorColor: colorToken.primary.withOpacity(0.1),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorToken.primary,
                    fontFamily: 'SourceSans3',
                  );
                }
                return TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                    color: colorToken.primary,
                    size: 24,
                  );
                }
                return IconThemeData(
                  color: colorToken.textSecondary,
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (index) => setState(() {
                this.index = index;
              }),
              elevation: 0,
              backgroundColor: colorToken.surface,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                  selectedIcon: Icon(Icons.home),
                ),
                NavigationDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  label: 'Dashboard',
                  selectedIcon: Icon(Icons.dashboard),
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_2_outlined),
                  label: 'Profile',
                  selectedIcon: Icon(Icons.person),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}