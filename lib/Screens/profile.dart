import 'package:app/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Profile extends StatelessWidget {
  Profile({super.key});

  final user = FirebaseAuth.instance.currentUser;

  // Sign user out method
  Future<void> signUserOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context, listen: true);
    final colorToken = theme.colorToken;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: theme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorToken.onPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          // Theme toggle button
                          IconButton(
                            onPressed: () {
                              theme.toggleTheme();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                theme.isLightTheme
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: colorToken.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Navigate to settings
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.settings,
                                color: colorToken.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Profile Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorToken.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorToken.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with status
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: theme.primaryGradient,
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                user?.photoURL ?? 'https://via.placeholder.com/150',
                              ),
                              radius: 50,
                              backgroundColor: colorToken.surfaceVariant,
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colorToken.success,
                                border: Border.all(
                                    color: colorToken.cardBackground,
                                    width: 3
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // User Info
                      Text(
                        user?.displayName ?? 'Auction Enthusiast',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorToken.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Premium Bidder',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorToken.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: colorToken.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.email ?? 'No Email',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorToken.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Auction Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('23', 'Items Won', colorToken),
                          _buildStatItem('47', 'Active Bids', colorToken),
                          _buildStatItem('156', 'Watchlist', colorToken),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to edit profile
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorToken.primary,
                                foregroundColor: colorToken.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Share profile
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorToken.buttonSecondary,
                                foregroundColor: colorToken.onButtonSecondary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Icon(Icons.share),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Menu Items
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorToken.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorToken.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        icon: Icons.gavel,
                        title: 'My Bids',
                        subtitle: 'Track your bidding activity',
                        iconColor: colorToken.warning,
                        iconBg: theme.getStatusBackgroundColor('bidding'),
                        colorToken: colorToken,
                        onTap: () {
                          // Navigate to my bids
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite,
                        title: 'Watchlist',
                        subtitle: 'Items you\'re watching',
                        iconColor: colorToken.error,
                        iconBg: theme.getStatusBackgroundColor('watching'),
                        colorToken: colorToken,
                        onTap: () {
                          // Navigate to watchlist
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        title: 'Auction History',
                        subtitle: 'Your completed auctions',
                        iconColor: colorToken.bidActive,
                        iconBg: theme.getStatusBackgroundColor('active'),
                        colorToken: colorToken,
                        onTap: () {
                          // Navigate to history
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.payment,
                        title: 'Payment Methods',
                        subtitle: 'Manage your payment options',
                        iconColor: colorToken.success,
                        iconBg: theme.getStatusBackgroundColor('won'),
                        colorToken: colorToken,
                        onTap: () {
                          // Navigate to payment
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help with auctions',
                        iconColor: colorToken.info,
                        iconBg: colorToken.info.withOpacity(0.1),
                        colorToken: colorToken,
                        onTap: () {
                          // Navigate to help
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        iconColor: colorToken.error,
                        iconBg: theme.getStatusBackgroundColor('lost'),
                        colorToken: colorToken,
                        onTap: () {
                          _showLogoutDialog(context, colorToken);
                        },
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label, ColorToken colorToken) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorToken.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorToken.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBg,
    required ColorToken colorToken,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorToken.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: colorToken.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: colorToken.textTertiary,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: colorToken.divider,
            indent: 72,
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, ColorToken colorToken) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorToken.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorToken.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: TextStyle(
              color: colorToken.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorToken.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                signUserOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorToken.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}