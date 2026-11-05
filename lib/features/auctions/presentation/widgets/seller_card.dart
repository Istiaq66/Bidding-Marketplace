import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/core/widgets/user_avatar.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:bidding_marketplace/features/profile/data/follow_repository.dart';
import 'package:bidding_marketplace/features/profile/presentation/seller_profile_page.dart';
import 'package:flutter/material.dart';

/// Seller summary row on the product details page: avatar, name, and a
/// Follow/Following toggle. Owns its own follow-state stream so it survives
/// parent rebuilds without re-subscribing.
class SellerCard extends StatefulWidget {
  const SellerCard({
    super.key,
    required this.product,
    required this.currentUserId,
  });

  final Product product;
  final String currentUserId;

  @override
  State<SellerCard> createState() => _SellerCardState();
}

class _SellerCardState extends State<SellerCard> {
  late final Stream<bool> _followingStream = FollowRepository.watchIsFollowing(
    widget.currentUserId,
    widget.product.sellerId,
  );

  Future<void> _toggleFollow(bool following) async {
    try {
      if (following) {
        await FollowRepository.unfollow(
          widget.currentUserId,
          widget.product.sellerId,
        );
      } else {
        await FollowRepository.follow(
          widget.currentUserId,
          widget.product.sellerId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update follow: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final product = widget.product;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerProfilePage(sellerId: product.sellerId),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorToken.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorToken.divider),
        ),
        child: Row(
          children: [
            UserAvatar(imageUrl: product.sellerPhoto, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorToken.textSecondary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sellerName.isNotEmpty
                        ? product.sellerName
                        : 'Unknown seller',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<bool>(
              stream: _followingStream,
              builder: (context, snap) {
                final following = snap.data ?? false;
                return OutlinedButton.icon(
                  onPressed: () => _toggleFollow(following),
                  icon: Icon(
                    following ? Icons.check : Icons.add,
                    size: 18,
                    color:
                        following
                            ? colorToken.textSecondary
                            : colorToken.primary,
                  ),
                  label: Text(
                    following ? 'Following' : 'Follow',
                    style: TextStyle(
                      color:
                          following
                              ? colorToken.textSecondary
                              : colorToken.primary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          following ? colorToken.divider : colorToken.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
