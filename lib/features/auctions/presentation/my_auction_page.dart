import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/auctions/presentation/add_new_item.dart';
import 'package:app/features/auctions/presentation/edit_auction_page.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class MyAuctionsPage extends StatelessWidget {
  const MyAuctionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = AuthRepository.currentUserId;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: Text(
          'My Auctions',
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
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colorToken.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewItem()),
              );
            },
            tooltip: 'Create Auction',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: colorToken.surface,
              child: TabBar(
                indicatorColor: colorToken.primary,
                labelColor: colorToken.primary,
                unselectedLabelColor: colorToken.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'SourceSans3',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                  fontFamily: 'SourceSans3',
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'All'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildAuctionsList(context, 'active', userId: userId),
                  _buildAuctionsList(context, 'completed', userId: userId),
                  _buildAuctionsList(context, 'all', userId: userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionsList(BuildContext context, String filter, {String? userId}) {
    final colorToken = ThemeProvider.of(context).colorToken;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Product>>(
      stream: ProductRepository.watchByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorToken.primary),
          );
        }

        final all = snapshot.data ?? const <Product>[];
        if (all.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: colorToken.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No auctions found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first auction to get started',
                  style: TextStyle(
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewItem()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create Auction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final products = all.where((p) {
          if (filter == 'all') return true;
          if (filter == 'active') return p.isActive;
          return !p.isActive;
        }).toList();

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_off,
                  size: 64,
                  color: colorToken.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No $filter auctions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildAuctionItem(context, products[index]),
        );
      },
    );
  }

  Widget _buildAuctionItem(BuildContext context, Product product) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final themeProvider = ThemeProvider.of(context);
    final imageUrl = product.imageUrl;
    final productName = product.name;
    final description = product.description;
    final minBidPrice = product.minBidPrice;
    final date = product.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: themeProvider.isLightTheme
          ? colorToken.surface
          : colorToken.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorToken.divider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty && imageUrl != ''
                ? Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: themeProvider.isLightTheme
                      ? colorToken.surfaceVariant
                      : colorToken.background,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      color: colorToken.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stack) {
                return Container(
                  height: 200,
                  color: themeProvider.isLightTheme
                      ? colorToken.surfaceVariant
                      : colorToken.background,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: colorToken.textSecondary,
                  ),
                );
              },
            )
                : Container(
              height: 200,
              color: themeProvider.isLightTheme
                  ? colorToken.surfaceVariant
                  : colorToken.background,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: colorToken.textSecondary,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 20, color: colorToken.success),
                    Text(
                      'Starting Bid: \$$minBidPrice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorToken.textPrimary,
                        fontFamily: 'SourceSans3',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: colorToken.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Ends: $date',
                      style: TextStyle(
                        color: colorToken.textSecondary,
                        fontFamily: 'SourceSans3',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: product.bidCount == 0
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditAuctionPage(product: product),
                                  ),
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Auctions with bids cannot be edited',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorToken.primary,
                          side: BorderSide(color: colorToken.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _deleteAuction(context, product.id);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorToken.error,
                          side: BorderSide(color: colorToken.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAuction(BuildContext context, String docId) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorToken.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Auction',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontFamily: 'SourceSans3',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this auction? This action cannot be undone.',
          style: TextStyle(
            color: colorToken.textSecondary,
            fontFamily: 'SourceSans3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await ProductRepository.deleteById(docId);
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Auction deleted successfully'),
                  backgroundColor: colorToken.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: colorToken.error,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}