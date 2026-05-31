import 'package:app/core/widgets/custom_image_holder.dart';
import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/watchlist/domain/watchlist_entry.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/watchlist/data/watchlist_repository.dart';
import 'package:app/features/auctions/presentation/product_details_page.dart';
import 'package:flutter/material.dart';

class WatchList extends StatelessWidget {
  const WatchList({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = AuthRepository.currentUserId;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: const Text('Watchlist'),
        backgroundColor: colorToken.cardBackground,
        foregroundColor: colorToken.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<List<WatchlistEntry>>(
          stream:
              userId == null
                  ? const Stream.empty()
                  : WatchlistRepository.watchByUser(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colorToken.primary),
              );
            }

            if (snapshot.hasError) {
              return Container(
                color: colorToken.background,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Failed to load watchlist: ${snapshot.error}',
                    style: TextStyle(color: colorToken.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final entries = snapshot.data ?? const <WatchlistEntry>[];
            if (entries.isEmpty) {
              return Container(
                color: colorToken.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: colorToken.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items in watchlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorToken.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Save items you're interested in",
                        style: TextStyle(color: colorToken.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              color: colorToken.background,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder:
                    (context, index) =>
                        _buildWatchlistItem(context, entries[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWatchlistItem(BuildContext context, WatchlistEntry entry) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return FutureBuilder<Product?>(
      future:
          entry.productId.isEmpty
              ? Future.value(null)
              : ProductRepository.getById(entry.productId),
      builder: (context, productSnapshot) {
        final product = productSnapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: colorToken.cardBackground,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  product != null && product.imageUrl.isNotEmpty
                      ? CustomImageHolder(
                        imageUrl: product.imageUrl,
                        width: 56,
                        height: 56,
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        color: colorToken.surfaceVariant,
                        child: Icon(
                          Icons.shopping_bag,
                          size: 28,
                          color: colorToken.textSecondary,
                        ),
                      ),
            ),
            title: Text(
              product?.name ?? 'Loading...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                product == null
                    ? Text(
                      '—',
                      style: TextStyle(color: colorToken.textSecondary),
                    )
                    : Text(
                      '\$${product.currentBid.toStringAsFixed(2)} • Ends ${product.date}',
                      style: TextStyle(color: colorToken.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            trailing: IconButton(
              icon: Icon(Icons.favorite, color: colorToken.watchlist),
              onPressed: () => WatchlistRepository.deleteById(entry.id),
            ),
            onTap: () {
              if (entry.productId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetails(docId: entry.productId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
