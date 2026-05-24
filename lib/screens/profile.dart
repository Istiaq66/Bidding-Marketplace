
import 'package:app/components/custom_image_holder.dart';
import 'package:app/screens/edit_profile_page.dart';
import 'package:app/screens/help_page.dart';
import 'package:app/screens/my_auction_page.dart';
import 'package:app/screens/my_bids_page.dart';
import 'package:app/screens/watch_list_page.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/services/new_user.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final User? user = NewUser().existingUser;
  late String _currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          final profileUrl = data['profileImage'];
          _currentImageUrl = (profileUrl != null && profileUrl.toString().isNotEmpty)
              ? profileUrl
              : null; // fallback to null if empty
        });
      }
    } catch (e) {
       debugPrint('Failed to load profile data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        final colorToken = theme.colorToken;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                      Stack(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: theme.primaryGradient,
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: ClipOval(
                                child: CustomImageHolder(
                                  imageUrl:  _currentImageUrl,
                                  height: 100,
                                  width: 100,
                                ),
                              )
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfilePage(),
                                  ),
                                );
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share — coming soon'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyBids(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.business_center,
                        title: 'My Auctions',
                        subtitle: 'Your all auctions',
                        iconColor: colorToken.bidActive,
                        iconBg: theme.getStatusBackgroundColor('won'),
                        colorToken: colorToken,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyAuctionsPage(),
                            ),
                          );
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WatchList(),
                            ),
                          );
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyAuctionsPage()),
                          );
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment methods — coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help with auctions',
                        iconColor: colorToken.info,
                        iconBg: colorToken.info.withValues(alpha:0.1),
                        colorToken: colorToken,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpPage()),
                          );
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
        );
      }
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
                AuthService.signOut();
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