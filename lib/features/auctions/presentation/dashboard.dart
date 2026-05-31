import 'package:app/features/bids/domain/bid.dart';
import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/bids/data/bid_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/auctions/presentation/add_new_item.dart';
import 'package:app/features/auctions/presentation/product_details_page.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  final VoidCallback? onBrowse;

  const Dashboard({super.key, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context, listen: false);
    final colorToken = themeProvider.colorToken;
    final userId = AuthRepository.currentUserId;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<Product>>(
              stream:
                  userId == null
                      ? const Stream.empty()
                      : ProductRepository.watchByUser(userId),
              builder: (context, productSnapshot) {
                return StreamBuilder<List<Bid>>(
                  stream:
                      userId == null
                          ? const Stream.empty()
                          : BidRepository.watchByBidder(userId),
                  builder: (context, bidSnapshot) {
                    final products = productSnapshot.data ?? const <Product>[];
                    final bids = bidSnapshot.data ?? const <Bid>[];
                    final totalAuctions = products.length;
                    final totalBids = bids.length;
                    final activeAuctions =
                        products.where((p) => p.isActive).length;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'My Auctions',
                              totalAuctions.toString(),
                              Icons.shopping_bag,
                              colorToken.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Active',
                              activeAuctions.toString(),
                              Icons.trending_up,
                              colorToken.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'My Bids',
                              totalBids.toString(),
                              Icons.gavel,
                              colorToken.warning,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Create Auction',
                    Icons.add_circle,
                    colorToken.primary,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewItem(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Browse Items',
                    Icons.search,
                    colorToken.info,
                    () => onBrowse?.call(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentActivity(context, userId),

            const SizedBox(height: 24),

            // Active Auctions Section
            Text(
              'My Active Auctions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Product>>(
              stream:
                  userId == null
                      ? const Stream.empty()
                      : ProductRepository.watchByUser(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildEmptyState(
                    context,
                    'Could not load auctions',
                    '${snapshot.error}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorToken.primary),
                  );
                }

                final active =
                    (snapshot.data ?? const <Product>[])
                        .where((p) => p.isActive)
                        .toList()
                      ..sort((a, b) {
                        final ad = a.createdAt;
                        final bd = b.createdAt;
                        if (ad == null && bd == null) return 0;
                        if (ad == null) return 1; // nulls last
                        if (bd == null) return -1;
                        return bd.compareTo(ad); // newest first
                      });
                final products = active.take(3).toList();
                if (products.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'No active auctions',
                    'Create an auction to see it here',
                  );
                }

                return Column(
                  children:
                      products
                          .map((p) => _buildAuctionCard(context, p))
                          .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Card(
      elevation: 2,
      color: colorToken.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: colorToken.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Card(
      elevation: 2,
      color: colorToken.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorToken.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, String? userId) {
    final colorToken = ThemeProvider.of(context).colorToken;

    if (userId == null) {
      return _buildEmptyState(
        context,
        'Not signed in',
        'Sign in to see your recent activity',
      );
    }

    return StreamBuilder<List<Bid>>(
      stream: BidRepository.watchRecentByBidder(userId, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorToken.primary),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            context,
            'Failed to load activity',
            '${snapshot.error}',
          );
        }

        final bids = snapshot.data ?? const <Bid>[];
        if (bids.isEmpty) {
          return _buildEmptyState(
            context,
            'No recent activity',
            'Your bid history will appear here',
          );
        }

        return Card(
          elevation: 2,
          color: colorToken.cardBackground,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bids.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: colorToken.divider),
            itemBuilder: (context, index) {
              final bid = bids[index];
              return FutureBuilder<Product?>(
                future:
                    bid.productId.isEmpty
                        ? Future.value(null)
                        : ProductRepository.getById(bid.productId),
                builder: (context, productSnapshot) {
                  final product = productSnapshot.data;
                  final amount = (double.tryParse(bid.amount.toString()) ?? 0)
                      .toStringAsFixed(2);
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          product != null && product.imageUrl.isNotEmpty
                              ? Image.network(
                                product.imageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      width: 44,
                                      height: 44,
                                      color: colorToken.surfaceVariant,
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: colorToken.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                              )
                              : Container(
                                width: 44,
                                height: 44,
                                color: colorToken.surfaceVariant,
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: colorToken.textSecondary,
                                  size: 20,
                                ),
                              ),
                    ),
                    title: Text(
                      product?.name ?? 'Loading...',
                      style: TextStyle(
                        color: colorToken.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Bid \$$amount • ${bid.bidTime}',
                      style: TextStyle(
                        color: colorToken.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorToken.textSecondary,
                    ),
                    onTap: () {
                      if (bid.productId.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetails(docId: bid.productId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAuctionCard(BuildContext context, Product product) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final imageUrl = product.imageUrl;
    final productName = product.name;
    final minBidPrice = product.minBidPrice;
    final date = product.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: colorToken.cardBackground,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              imageUrl.isNotEmpty
                  ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: colorToken.surfaceVariant,
                        child: Icon(
                          Icons.image_not_supported,
                          color: colorToken.textSecondary,
                        ),
                      );
                    },
                  )
                  : Container(
                    width: 60,
                    height: 60,
                    color: colorToken.surfaceVariant,
                    child: Icon(
                      Icons.shopping_bag,
                      color: colorToken.textSecondary,
                    ),
                  ),
        ),
        title: Text(
          productName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorToken.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Starting Bid: \$$minBidPrice',
              style: TextStyle(color: colorToken.textSecondary),
            ),
            Text(
              'Ends: $date',
              style: TextStyle(fontSize: 12, color: colorToken.textTertiary),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: colorToken.textSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetails(docId: product.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Row(
      children: [
        Expanded(
          child: Card(
            color: colorToken.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: colorToken.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorToken.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(color: colorToken.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
