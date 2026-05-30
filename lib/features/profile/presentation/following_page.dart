import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/profile/data/follow_repository.dart';
import 'package:app/features/profile/data/user_repository.dart';
import 'package:app/features/profile/domain/app_user.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:app/core/widgets/user_avatar.dart';
import 'package:app/features/profile/presentation/seller_profile_page.dart';
import 'package:flutter/material.dart';

/// Lists the sellers the current user follows, with an Unfollow action.
class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context, listen: true).colorToken;
    final uid = AuthRepository.currentUserId;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: Text(
          'Following',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'SourceSans3',
          ),
        ),
        backgroundColor: colorToken.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? _emptyState(colorToken, 'Sign in to see who you follow')
          : StreamBuilder<List<String>>(
              stream: FollowRepository.watchFollowingSellerIds(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorToken.primary),
                  );
                }
                final sellerIds = snap.data ?? const [];
                if (sellerIds.isEmpty) {
                  return _emptyState(
                    colorToken,
                    'You are not following anyone yet.\nFollow a seller to get notified about their new auctions.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sellerIds.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colorToken.divider,
                    indent: 72,
                  ),
                  itemBuilder: (context, index) => _SellerTile(
                    followerId: uid,
                    sellerId: sellerIds[index],
                    colorToken: colorToken,
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyState(ColorToken colorToken, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: colorToken.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
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

class _SellerTile extends StatelessWidget {
  const _SellerTile({
    required this.followerId,
    required this.sellerId,
    required this.colorToken,
  });

  final String followerId;
  final String sellerId;
  final ColorToken colorToken;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: UserRepository.getById(sellerId),
      builder: (context, snap) {
        final seller = snap.data;
        final name = (seller?.name != null && seller!.name!.isNotEmpty)
            ? seller.name!
            : 'Unknown seller';
        final image = seller?.displayImage ?? '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerProfilePage(sellerId: sellerId),
            ),
          ),
          leading: UserAvatar(imageUrl: image, radius: 24),
          title: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorToken.textPrimary,
            ),
          ),
          subtitle: seller?.email != null && seller!.email!.isNotEmpty
              ? Text(
                  seller.email!,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorToken.textSecondary,
                  ),
                )
              : null,
          trailing: OutlinedButton(
            onPressed: () => _confirmUnfollow(context, name),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorToken.textSecondary,
              side: BorderSide(color: colorToken.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Following'),
          ),
        );
      },
    );
  }

  Future<void> _confirmUnfollow(BuildContext context, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorToken.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Unfollow $name?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorToken.textPrimary,
          ),
        ),
        content: Text(
          "You'll stop getting notifications about their new auctions.",
          style: TextStyle(color: colorToken.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorToken.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorToken.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Unfollow', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await FollowRepository.unfollow(followerId, sellerId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to unfollow: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}