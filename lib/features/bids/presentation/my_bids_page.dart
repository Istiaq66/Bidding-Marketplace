import 'package:app/features/bids/domain/bid.dart';
import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/bids/data/bid_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/auctions/presentation/product_details_page.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class MyBids extends StatefulWidget {
  const MyBids({super.key});

  @override
  State<MyBids> createState() => _MyBidsState();
}

class _MyBidsState extends State<MyBids> {
  final String? userId = AuthRepository.currentUserId;

  // Created once so rebuilds don't re-subscribe; product lookups are cached
  // per id so a list update doesn't refetch every row.
  late final Stream<List<Bid>> _stream =
      userId == null
          ? const Stream.empty()
          : BidRepository.watchByBidder(userId!);
  final _productFutures = <String, Future<Product?>>{};

  Future<Product?> _productFor(String id) =>
      _productFutures.putIfAbsent(id, () => ProductRepository.getById(id));

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: const Text('My Bids'),
        backgroundColor: colorToken.cardBackground,
        foregroundColor: colorToken.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Bid>>(
          stream: _stream,
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
                    'Failed to load bids: ${snapshot.error}',
                    style: TextStyle(color: colorToken.error),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                      Icon(
                        Icons.gavel,
                        size: 64,
                        color: colorToken.textSecondary,
                      ),
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
                itemBuilder:
                    (context, index) =>
                        _buildBidItem(context, bids[index], userId),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBidItem(BuildContext context, Bid bid, String? currentUserId) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final productId = bid.productId;
    final bidAmount = (double.tryParse(bid.amount.toString()) ?? 0)
        .toStringAsFixed(2);
    final bidTime = bid.bidTime;

    return FutureBuilder<Product?>(
      future: productId.isEmpty ? Future.value(null) : _productFor(productId),
      builder: (context, productSnapshot) {
        final product = productSnapshot.data;
        if (product == null) return const SizedBox();

        final (statusLabel, statusIcon, statusColor) = _bidStatus(
          product,
          bid.bidderId,
          colorToken,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: colorToken.cardBackground,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  product.imageUrl.isNotEmpty
                      ? Image.network(
                        product.imageUrl,
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
              product.name,
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
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
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
                MaterialPageRoute(
                  builder: (_) => ProductDetails(docId: productId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Label, icon and color for the status chip on a bid row.
  (String, IconData, Color) _bidStatus(
    Product product,
    String bidderId,
    ColorToken colorToken,
  ) {
    if (product.isClosed) {
      return product.isWonBy(bidderId)
          ? ('Won', Icons.emoji_events, colorToken.bidWon)
          : ('Lost', Icons.cancel_outlined, colorToken.bidLost);
    }
    // Past endsAt; the server sweep hasn't settled the winner yet.
    if (!product.isActive) {
      return ('Ended', Icons.hourglass_bottom, colorToken.textSecondary);
    }
    final isLeading =
        product.highestBidderId != null && product.highestBidderId == bidderId;
    return isLeading
        ? ('Leading', Icons.trending_up, colorToken.bidActive)
        : ('Outbid', Icons.trending_down, colorToken.error);
  }
}
