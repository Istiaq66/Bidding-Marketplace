import 'package:app/models/bid.dart';
import 'package:app/models/product.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:app/repositories/bid_repository.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/screens/product_details_page.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:flutter/material.dart';

class MyBids extends StatelessWidget {
  const MyBids({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = AuthRepository.currentUserId;

    return Scaffold(
      body: StreamBuilder<List<Bid>>(
        stream: userId == null
            ? const Stream.empty()
            : BidRepository.watchByBidder(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorToken.primary),
            );
          }

          final bids = snapshot.data ?? const <Bid>[];
          if (bids.isEmpty) {
            return Container(
              color: colorToken.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gavel, size: 64, color: colorToken.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No bids yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorToken.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start bidding on items you like',
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
              itemCount: bids.length,
              itemBuilder: (context, index) => _buildBidItem(context, bids[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBidItem(BuildContext context, Bid bid) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final productId = bid.productId;
    final bidAmount = bid.amount;
    final bidTime = bid.bidTime;

    return FutureBuilder<Product?>(
      future: productId.isEmpty ? Future.value(null) : ProductRepository.getById(productId),
      builder: (context, productSnapshot) {
        final product = productSnapshot.data;
        if (product == null) {
          return const SizedBox();
        }

        final productName = product.name;
        final imageUrl = product.imageUrl;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: colorToken.cardBackground,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
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
                child: Icon(Icons.shopping_bag, color: colorToken.textSecondary),
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
                  'Your Bid: \$$bidAmount',
                  style: TextStyle(
                    color: colorToken.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bidTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorToken.textTertiary,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorToken.bidActive.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 16, color: colorToken.bidActive),
                  const SizedBox(width: 4),
                  Text(
                    'Leading',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorToken.bidActive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              if (productId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetails(docId: productId)),
              );
            },
          ),
        );
      },
    );
  }
}