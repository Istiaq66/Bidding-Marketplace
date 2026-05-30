import 'package:app/core/theme/theme_provider.dart';
import 'package:app/core/widgets/user_avatar.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/auctions/presentation/home.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/profile/data/follow_repository.dart';
import 'package:app/features/profile/data/user_repository.dart';
import 'package:app/features/profile/domain/app_user.dart';
import 'package:flutter/material.dart';

/// Public read-only view of a seller: their photo, name, bio, follower count,
/// a follow/unfollow action, and the auctions they have listed.
class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key, required this.sellerId});

  final String sellerId;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context, listen: true).colorToken;
    final currentUserId = AuthRepository.currentUserId;
    final isSelf = currentUserId == sellerId;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: Text(
          'Profile',
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<AppUser?>(
              stream: UserRepository.watchById(sellerId),
              builder: (context, snap) {
                final seller = snap.data;
                return _header(
                  context,
                  colorToken,
                  seller,
                  currentUserId,
                  isSelf,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Auctions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
            ),
            _auctions(context, colorToken),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    ColorToken colorToken,
    AppUser? seller,
    String? currentUserId,
    bool isSelf,
  ) {
    final name = (seller?.name != null && seller!.name!.isNotEmpty)
        ? seller.name!
        : 'Unknown seller';

    return Container(
      width: double.infinity,
      color: colorToken.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          UserAvatar(imageUrl: seller?.displayImage ?? '', radius: 50),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorToken.textPrimary,
              fontFamily: 'SourceSans3',
            ),
          ),
          if (seller?.bio != null && seller!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              seller.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorToken.textSecondary,
              ),
            ),
          ],
          if (seller?.address != null && seller!.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: colorToken.textTertiary),
                const SizedBox(width: 4),
                Text(
                  seller.address!,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorToken.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FutureBuilder<int>(
            future: FollowRepository.countFollowers(sellerId),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Text(
                '$count follower${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorToken.textSecondary,
                ),
              );
            },
          ),
          if (!isSelf && currentUserId != null) ...[
            const SizedBox(height: 16),
            _followButton(context, colorToken, currentUserId),
          ],
        ],
      ),
    );
  }

  Widget _followButton(
    BuildContext context,
    ColorToken colorToken,
    String currentUserId,
  ) {
    return StreamBuilder<bool>(
      stream: FollowRepository.watchIsFollowing(currentUserId, sellerId),
      builder: (context, snap) {
        final following = snap.data ?? false;
        return SizedBox(
          width: double.infinity,
          child: following
              ? OutlinedButton.icon(
                  onPressed: () =>
                      FollowRepository.unfollow(currentUserId, sellerId),
                  icon: Icon(Icons.check, color: colorToken.textSecondary),
                  label: Text(
                    'Following',
                    style: TextStyle(color: colorToken.textSecondary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: colorToken.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () =>
                      FollowRepository.follow(currentUserId, sellerId),
                  icon: const Icon(Icons.add),
                  label: const Text('Follow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorToken.primary,
                    foregroundColor: colorToken.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
        );
      },
    );
  }

  Widget _auctions(BuildContext context, ColorToken colorToken) {
    return StreamBuilder<List<Product>>(
      stream: ProductRepository.watchByUser(sellerId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: colorToken.primary),
            ),
          );
        }
        final products = snap.data ?? const [];
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No auctions listed yet.',
                style: TextStyle(color: colorToken.textSecondary),
              ),
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return MinimalisticProductCard(
              name: product.name,
              minPrice: product.currentBid.toStringAsFixed(2),
              imageUrl: product.imageUrl,
              description: product.description,
              docId: product.id,
            );
          },
        );
      },
    );
  }
}