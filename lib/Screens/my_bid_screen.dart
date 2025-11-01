
import 'package:app/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyAuctions extends StatelessWidget {
  final String userId;

  const MyAuctions({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: ThemeProvider.of(context).primaryGradient,
            ),
            child: TabBar(
              indicatorColor: colorToken.onPrimary,
              labelColor: colorToken.onPrimary,
              unselectedLabelColor: colorToken.onPrimary.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'All'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAuctionsList(context, 'active'),
                _buildAuctionsList(context, 'completed'),
                _buildAuctionsList(context, 'all'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionsList(BuildContext context, String filter) {
    final colorToken = ThemeProvider.of(context).colorToken;

    Query query = FirebaseFirestore.instance
        .collection('products')
        .where('User Id', isEqualTo: userId);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorToken.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: colorToken.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No auctions found',
                  style: TextStyle(color: colorToken.textPrimary),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to create auction
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Auction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorToken.primary,
                    foregroundColor: colorToken.onPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          if (filter == 'all') return true;

          final date = doc['Date'] as String;
          final auctionDate = DateFormat('yyyy-MM-dd').parse(date);
          final isActive = auctionDate.isAfter(DateTime.now());

          return filter == 'active' ? isActive : !isActive;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No $filter auctions',
              style: TextStyle(color: colorToken.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildAuctionItem(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildAuctionItem(BuildContext context, String docId, Map<String, dynamic> data) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final imageUrl = data['Image Url'] ?? '';
    final productName = data['Product Name'] ?? 'Unknown';
    final description = data['Product Description'] ?? '';
    final minBidPrice = data['Minimum Bid Price'] ?? '0';
    final date = data['Date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      color: colorToken.cardBackground,
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return Container(
                  height: 200,
                  color: colorToken.surfaceVariant,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: colorToken.textSecondary,
                  ),
                );
              },
            )
                : Container(
              height: 200,
              color: colorToken.surfaceVariant,
              child: Icon(
                Icons.shopping_bag,
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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: colorToken.textSecondary),
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
                      style: TextStyle(color: colorToken.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Edit auction
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorToken.primary,
                          side: BorderSide(color: colorToken.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _deleteAuction(context, docId);
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorToken.error,
                          side: BorderSide(color: colorToken.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // View details
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorToken.primary,
                          foregroundColor: colorToken.onPrimary,
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
        title: Text('Delete Auction', style: TextStyle(color: colorToken.textPrimary)),
        content: Text(
          'Are you sure you want to delete this auction? This action cannot be undone.',
          style: TextStyle(color: colorToken.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorToken.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Auction deleted successfully'),
                  backgroundColor: colorToken.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: colorToken.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}