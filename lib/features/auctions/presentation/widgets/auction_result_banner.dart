import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/core/utils/money.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:flutter/material.dart';

/// Banner shown above the fold once an auction is past its end time:
/// a win/sale/no-bids result once the server has settled it, or a plain
/// "Auction Ended" badge while that's still pending.
class AuctionResultBanner extends StatelessWidget {
  const AuctionResultBanner({
    super.key,
    required this.product,
    required this.currentUserId,
  });

  final Product product;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final amount = formatMoney(product.currentBid);
    final isSeller = currentUserId == product.sellerId;

    if (product.isWonBy(currentUserId)) {
      return _ResultCard(
        colorToken: colorToken,
        color: colorToken.bidWon,
        icon: Icons.emoji_events,
        title: 'You won this auction!',
        subtitle: 'Winning bid: $amount',
      );
    }

    if (isSeller && product.isClosed) {
      final sold = product.winnerId != null;
      return _ResultCard(
        colorToken: colorToken,
        color: sold ? colorToken.bidWon : colorToken.textSecondary,
        icon: sold ? Icons.sell : Icons.do_not_disturb_alt,
        title: sold ? 'Sold for $amount' : 'Ended with no bids',
        subtitle:
            sold
                ? 'The winning bidder has been notified.'
                : 'Nobody placed a bid on this auction.',
      );
    }

    // Past endsAt but the server hasn't settled the winner yet.
    final label =
        product.isClosed ? 'Auction Ended' : 'Auction Ended · finalizing';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorToken.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock, size: 16, color: colorToken.error),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorToken.error,
              fontWeight: FontWeight.bold,
              fontFamily: 'SourceSans3',
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.colorToken,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ColorToken colorToken;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
