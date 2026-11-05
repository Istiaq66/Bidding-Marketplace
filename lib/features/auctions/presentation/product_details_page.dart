import 'dart:async';
import 'package:bidding_marketplace/core/widgets/custom_image_holder.dart';
import 'package:bidding_marketplace/features/bids/domain/bid.dart';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:bidding_marketplace/features/auctions/presentation/bid_dialog.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/auction_result_banner.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/bid_list.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/product_bottom_bar.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/product_price_card.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/seller_card.dart';
import 'package:bidding_marketplace/features/auth/data/auth_repository.dart';
import 'package:bidding_marketplace/features/bids/data/bid_repository.dart';
import 'package:bidding_marketplace/features/auctions/data/product_repository.dart';
import 'package:bidding_marketplace/features/watchlist/data/watchlist_repository.dart';
import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/core/utils/share.dart';
import 'package:flutter/material.dart';

class ProductDetails extends StatefulWidget {
  final String docId;

  const ProductDetails({super.key, required this.docId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isWatchlisted = false;
  Product? _product;
  StreamSubscription<Product?>? _productSub;

  // Created once, not in build(): every new bid rebuilds this page via the
  // product stream, and a fresh stream there would re-subscribe and flash a
  // spinner in BidList.
  late final Stream<List<Bid>> _bidsStream = BidRepository.watchByProduct(
    widget.docId,
  );

  @override
  void initState() {
    super.initState();
    _productSub = ProductRepository.watchById(widget.docId).listen((p) {
      if (mounted) setState(() => _product = p);
    });
    _checkWatchlistStatus();
  }

  @override
  void dispose() {
    _productSub?.cancel();
    super.dispose();
  }

  Future<void> _checkWatchlistStatus() async {
    final userId = AuthRepository.currentUserId;
    if (userId == null) return;
    try {
      final watched = await WatchlistRepository.isWatched(userId, widget.docId);
      if (!mounted) return;
      setState(() => _isWatchlisted = watched);
    } catch (_) {}
  }

  Future<void> _toggleWatchlist() async {
    final userId = AuthRepository.currentUserId;
    if (userId == null) {
      _showErrorSnackbar('Please login to add to watchlist');
      return;
    }
    try {
      final wasWatchlisted = _isWatchlisted;
      if (wasWatchlisted) {
        await WatchlistRepository.removeByUserAndProduct(userId, widget.docId);
      } else {
        await WatchlistRepository.add(userId, widget.docId);
      }
      if (!mounted) return;
      setState(() => _isWatchlisted = !wasWatchlisted);
      _showSuccessSnackbar(
        wasWatchlisted ? 'Removed from watchlist' : 'Added to watchlist',
      );
    } catch (_) {
      if (mounted) _showErrorSnackbar('Failed to update watchlist');
    }
  }

  Future<void> _showBidDialog(Product product) async {
    if (AuthRepository.currentUserId == null) {
      _showErrorSnackbar('Please login to place a bid');
      return;
    }
    final placed = await showDialog<bool>(
      context: context,
      builder: (_) => BidDialog(initialProduct: product),
    );
    if (placed == true && mounted) {
      _showSuccessSnackbar('Bid placed successfully!');
    }
  }

  void _showSuccessSnackbar(String message) {
    final colorToken = ThemeProvider.of(context).colorToken;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorToken.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    final colorToken = ThemeProvider.of(context).colorToken;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorToken.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final product = _product;

    if (product == null) {
      return Scaffold(
        backgroundColor: colorToken.background,
        appBar: AppBar(
          backgroundColor: colorToken.surface,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colorToken.primary),
        ),
      );
    }

    final currentUserId = AuthRepository.currentUserId;
    final isOwnProduct = currentUserId == product.sellerId;

    return Scaffold(
      backgroundColor: colorToken.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildImageAppBar(colorToken, product, isOwnProduct),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auction result banner (winner / seller) or ended badge
                    if (!product.isActive)
                      AuctionResultBanner(
                        product: product,
                        currentUserId: currentUserId,
                      ),

                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorToken.textPrimary,
                        fontFamily: 'SourceSans3',
                      ),
                    ),

                    const SizedBox(height: 16),

                    ProductPriceCard(product: product),

                    const SizedBox(height: 24),

                    if (!isOwnProduct &&
                        currentUserId != null &&
                        product.sellerId.isNotEmpty) ...[
                      SellerCard(
                        product: product,
                        currentUserId: currentUserId,
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorToken.textPrimary,
                        fontFamily: 'SourceSans3',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: colorToken.textSecondary,
                        fontFamily: 'SourceSans3',
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Recent Bids',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorToken.textPrimary,
                        fontFamily: 'SourceSans3',
                      ),
                    ),
                    BidList(
                      bidsStream: _bidsStream,
                      isOwner: currentUserId == product.sellerId,
                      isClosed: product.isClosed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          isOwnProduct
              ? null
              : ProductBottomBar(
                product: product,
                isWinner: product.isWonBy(currentUserId),
                onPlaceBid: () => _showBidDialog(product),
              ),
    );
  }

  Widget _buildImageAppBar(
    ColorToken colorToken,
    Product product,
    bool isOwnProduct,
  ) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: colorToken.surface,
      leading: IconButton(
        tooltip: 'Back',
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorToken.surface.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: colorToken.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!isOwnProduct)
          IconButton(
            tooltip:
                _isWatchlisted ? 'Remove from watchlist' : 'Add to watchlist',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorToken.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isWatchlisted ? Icons.favorite : Icons.favorite_border,
                color:
                    _isWatchlisted ? colorToken.error : colorToken.textPrimary,
              ),
            ),
            onPressed: _toggleWatchlist,
          ),
        IconButton(
          tooltip: 'Share',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorToken.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.share, color: colorToken.textPrimary),
          ),
          onPressed:
              () => ShareUtil.shareAuction(
                productId: widget.docId,
                productName: _product?.name,
              ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background:
            product.imageUrl.isNotEmpty
                ? CustomImageHolder(
                  imageUrl: product.imageUrl,
                  height: double.infinity,
                  width: double.infinity,
                )
                : Container(
                  color: colorToken.surfaceVariant,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: colorToken.textSecondary,
                  ),
                ),
      ),
    );
  }
}
