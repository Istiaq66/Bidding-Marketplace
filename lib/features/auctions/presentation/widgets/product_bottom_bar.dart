import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:flutter/material.dart';

/// Sticky "Place Bid" bar at the bottom of the product details page.
class ProductBottomBar extends StatelessWidget {
  const ProductBottomBar({
    super.key,
    required this.product,
    required this.isWinner,
    required this.onPlaceBid,
  });

  final Product product;
  final bool isWinner;
  final VoidCallback onPlaceBid;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorToken.surface,
        boxShadow: [
          BoxShadow(
            color: colorToken.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: product.isActive ? onPlaceBid : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  product.isActive ? Colors.black : colorToken.surfaceVariant,
              foregroundColor:
                  product.isActive ? Colors.white : colorToken.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              product.isActive
                  ? 'Place Bid'
                  : isWinner
                  ? 'You Won'
                  : 'Auction Ended',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
