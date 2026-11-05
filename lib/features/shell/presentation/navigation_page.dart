import 'dart:async';
import 'package:app/features/auctions/presentation/dashboard.dart';
import 'package:app/features/profile/presentation/edit_profile_page.dart';
import 'package:app/features/support/presentation/help_page.dart';
import 'package:app/features/auctions/presentation/home.dart';
import 'package:app/features/notifications/presentation/notifications_page.dart';
import 'package:app/features/support/presentation/privacy_page.dart';
import 'package:app/features/profile/presentation/profile.dart';
import 'package:app/features/auctions/presentation/search_page.dart';
import 'package:app/features/profile/presentation/settings_page.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/notifications/data/notification_repository.dart';
import 'package:app/core/services/fcm_service.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int index = 0;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;

  @override
  void initState() {
    super.initState();
    final userId = AuthRepository.currentUserId;
    if (userId != null) {
      _unreadSub = NotificationRepository.watchUnreadCount(userId).listen((
        count,
      ) {
        if (mounted) setState(() => _unreadCount = count);
      });
      FcmService.registerToken(userId);
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  // Tabs live in an IndexedStack so switching doesn't throw away Home's
  // loaded pages and scroll position. Each tab is built on first visit and
  // the widget instances are cached, so parent rebuilds (e.g. unread count)
  // don't rebuild them. Profile loads its stats once, so it gets a fresh key
  // on every visit; Dashboard gets one on "Refresh".
  final _visited = <int>{0};
  final Widget _home = const Home();
  late Widget _dashboard = _newDashboard();
  Key _profileKey = UniqueKey();

  Widget _newDashboard() =>
      Dashboard(key: UniqueKey(), onBrowse: () => _selectTab(0));

  Widget _screen(int i) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => _home,
      1 => _dashboard,
      _ => Profile(key: _profileKey),
    };
  }

  void _selectTab(int i) {
    setState(() {
      if (i == 2 && index != 2) _profileKey = UniqueKey();
      index = i;
      _visited.add(i);
    });
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
              tooltip: 'Search',
              icon: Icon(Icons.search, color: colorToken.textPrimary),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchPage()),
                  ),
            ),
            IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(fontSize: 10),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: colorToken.textPrimary,
                ),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  ),
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
              tooltip: 'Filter',
              icon: Icon(Icons.filter_list, color: colorToken.textPrimary),
              onPressed: () {
                _showFilterBottomSheet(context);
              },
            ),
            IconButton(
              tooltip: 'More options',
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
              tooltip: 'Settings',
              icon: Icon(
                Icons.settings_outlined,
                color: colorToken.textPrimary,
              ),
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
      builder:
          (context) => Padding(
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

  Widget _buildFilterOption(
    BuildContext context,
    String title,
    bool isSelected,
  ) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: colorToken.textPrimary,
          fontFamily: 'SourceSans3',
        ),
      ),
      trailing:
          isSelected ? Icon(Icons.check, color: colorToken.primary) : null,
      onTap: () {
        Navigator.pop(context);
        _showComingSoon('Filtering');
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
      builder:
          (context) => SafeArea(
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
                    setState(() => _dashboard = _newDashboard());
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
                    _showComingSoon('Sort options');
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
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
      builder:
          (context) => SafeArea(
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.lock_outline,
                    color: colorToken.textPrimary,
                  ),
                  title: Text(
                    'Privacy & Security',
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: colorToken.textPrimary,
                  ),
                  title: Text(
                    'Help & Support',
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    );
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
      builder:
          (context) => AlertDialog(
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
                onPressed: () async {
                  Navigator.pop(context);
                  final uid = AuthRepository.currentUserId;
                  if (uid != null) await FcmService.unregisterToken(uid);
                  await AuthRepository.signOut();
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
          body: IndexedStack(index: index, children: List.generate(3, _screen)),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: colorToken.surface,
              indicatorColor: colorToken.primary.withValues(alpha: 0.1),
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
                  return IconThemeData(color: colorToken.primary, size: 24);
                }
                return IconThemeData(color: colorToken.textSecondary, size: 24);
              }),
            ),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _selectTab,
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
