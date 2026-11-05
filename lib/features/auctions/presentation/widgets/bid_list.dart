import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/core/utils/money.dart';
import 'package:bidding_marketplace/core/widgets/load_error.dart';
import 'package:bidding_marketplace/features/bids/domain/bid.dart';
import 'package:flutter/material.dart';

/// The "Recent Bids" list on the product details page: top bid highlighted
/// as Leading (while the auction runs) or Winner (once it's closed).
class BidList extends StatelessWidget {
  const BidList({
    super.key,
    required this.bidsStream,
    required this.isOwner,
    required this.isClosed,
  });

  final Stream<List<Bid>> bidsStream;
  final bool isOwner;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return StreamBuilder<List<Bid>>(
      stream: bidsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const LoadError();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: colorToken.primary),
            ),
          );
        }

        final bids = snapshot.data ?? const <Bid>[];
        if (bids.isEmpty) {
          if (isOwner) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorToken.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No bids yet. Be the first to bid!',
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final bid = bids[index];
            final amount = double.tryParse(bid.amount.toString()) ?? 0;
            final isTop = index == 0;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isTop
                        ? colorToken.success.withValues(alpha: 0.1)
                        : colorToken.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isTop
                              ? colorToken.success
                              : colorToken.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTop ? Icons.emoji_events : Icons.person,
                      color: isTop ? Colors.white : colorToken.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              formatMoney(amount),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorToken.textPrimary,
                                fontFamily: 'SourceSans3',
                              ),
                            ),
                            if (isTop) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorToken.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isClosed ? 'Winner' : 'Leading',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SourceSans3',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bid.bidTime,
                          style: TextStyle(
                            fontSize: 12,
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
          },
        );
      },
    );
  }
}
