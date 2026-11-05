import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/minimalistic_product_card.dart';
import 'package:flutter/material.dart';

/// Home's main content area: loading / error / empty states, or the
/// paginated product grid.
class HomeResultsView extends StatelessWidget {
  const HomeResultsView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.allProductsEmpty,
    required this.products,
    required this.myBidProductIds,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;

  /// Whether the unfiltered result set is empty (vs. just the search filter
  /// matching nothing), so the right empty-state message shows.
  final bool allProductsEmpty;
  final List<Product> products;
  final Set<String> myBidProductIds;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorToken.primary),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorToken.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: TextStyle(color: colorToken.primary)),
            ),
          ],
        ),
      );
    }

    if (allProductsEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: colorToken.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No auctions available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new items',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorToken.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return MinimalisticProductCard(
                name: product.name,
                minPrice: product.currentBid.toStringAsFixed(2),
                imageUrl: product.imageUrl,
                description: product.description,
                docId: product.id,
                hasBid: myBidProductIds.contains(product.id),
              );
            }, childCount: products.length),
          ),
        ),
        SliverToBoxAdapter(
          child:
              isLoadingMore
                  ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colorToken.primary,
                      ),
                    ),
                  )
                  : hasMore
                  ? const SizedBox(height: 80)
                  : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'All ${products.length} items loaded',
                        style: TextStyle(
                          color: colorToken.textSecondary,
                          fontFamily: 'SourceSans3',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}
