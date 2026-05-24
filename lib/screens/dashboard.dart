import 'package:app/models/bid.dart';
import 'package:app/models/product.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:app/repositories/bid_repository.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/screens/add_new_item.dart';
import 'package:app/screens/product_details_page.dart';
import 'package:app/providers/theme_provider.dart';
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
              stream: userId == null
                  ? const Stream.empty()
                  : ProductRepository.watchByUser(userId),
              builder: (context, productSnapshot) {
                return StreamBuilder<List<Bid>>(
                  stream: userId == null
                      ? const Stream.empty()
                      : BidRepository.watchByBidder(userId),
                  builder: (context, bidSnapshot) {
                    final products = productSnapshot.data ?? const <Product>[];
                    final bids = bidSnapshot.data ?? const <Bid>[];
                    final totalAuctions = products.length;
                    final totalBids = bids.length;
                    final activeAuctions = products.where((p) => p.isActive).length;

                    return Row(
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
            _buildRecentActivity(context),

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
              stream: userId == null
                  ? const Stream.empty()
                  : ProductRepository.watchRecentByUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colorToken.primary),
                  );
                }

                final products = snapshot.data ?? const <Product>[];
                if (products.isEmpty) {
                  return _buildEmptyState(
                    context,
                    'No auctions yet',
                    'Create your first auction to get started',
                  );
                }

                return Column(
                  children: products.map((p) => _buildAuctionCard(context, p)).toList(),
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

  Widget _buildRecentActivity(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Card(
      elevation: 2,
      color: colorToken.cardBackground,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder:
            (context, index) => Divider(height: 1, color: colorToken.divider),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colorToken.primary.withValues(alpha: 0.1),
              child: Icon(Icons.notifications, color: colorToken.primary),
            ),
            title: Text(
              'New bid on your item',
              style: TextStyle(color: colorToken.textPrimary),
            ),
            subtitle: Text(
              '2 hours ago',
              style: TextStyle(color: colorToken.textSecondary),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorToken.textSecondary,
            ),
          );
        },
      ),
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
            MaterialPageRoute(builder: (_) => ProductDetails(docId: product.id)),
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
