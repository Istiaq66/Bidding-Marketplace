import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:flutter/material.dart';

/// Current/starting bid on the left, end date on the right.
class ProductPriceCard extends StatelessWidget {
  const ProductPriceCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorToken.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorToken.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.bidCount > 0 ? 'Current Bid' : 'Starting Bid',
                style: TextStyle(
                  fontSize: 14,
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, color: colorToken.success, size: 24),
                  Text(
                    product.currentBid.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                ],
              ),
              if (product.bidCount > 0)
                Text(
                  '${product.bidCount} bid${product.bidCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Ends On',
                style: TextStyle(
                  fontSize: 14,
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: colorToken.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.date,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
