import 'dart:async';
import 'package:app/core/widgets/custom_image_holder.dart';
import 'package:app/features/bids/domain/bid.dart';
import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/bids/data/bid_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/watchlist/data/watchlist_repository.dart';
import 'package:app/features/profile/data/follow_repository.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:app/core/utils/share.dart';
import 'package:flutter/material.dart';

class ProductDetails extends StatefulWidget {
  final String docId;

  const ProductDetails({super.key, required this.docId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final _bidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isWatchlisted = false;
  Product? _product;
  StreamSubscription<Product?>? _productSub;

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
    _bidController.dispose();
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
      if (_isWatchlisted) {
        await WatchlistRepository.removeByUserAndProduct(userId, widget.docId);
        _showSuccessSnackbar('Removed from watchlist');
      } else {
        await WatchlistRepository.add(userId, widget.docId);
        _showSuccessSnackbar('Added to watchlist');
      }
      if (!mounted) return;
      setState(() => _isWatchlisted = !_isWatchlisted);
    } catch (_) {
      _showErrorSnackbar('Failed to update watchlist');
    }
  }

  Future<void> _placeBid(Product product) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = AuthRepository.currentUserId;
    if (userId == null) {
      _showErrorSnackbar('Please login to place a bid');
      return;
    }

    final bidAmount = double.tryParse(_bidController.text.trim()) ?? 0;

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);

    try {
      await BidRepository.place(
        productId: widget.docId,
        bidderId: userId,
        amount: bidAmount,
      );
      _showSuccessSnackbar('Bid placed successfully!');
      _bidController.clear();
      navigator.pop();
    } on Exception catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBidDialog(Product product) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorToken.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Place Your Bid',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current bid: \$${product.currentBid.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.bidCount == 0
                    ? 'First bid must clear the start price.'
                    : 'Min next bid: \$${product.nextMinBid.toStringAsFixed(2)} '
                        '(\$${product.minIncrement.toStringAsFixed(2)} increment)',
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bidController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
                decoration: InputDecoration(
                  labelText: 'Your Bid Amount',
                  prefixIcon:
                      Icon(Icons.attach_money, color: colorToken.primary),
                  labelStyle: TextStyle(
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                  filled: true,
                  fillColor: colorToken.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorToken.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter bid amount';
                  }
                  final bid = double.tryParse(value);
                  if (bid == null) return 'Enter a valid number';
                  if (bid <= product.currentBid) {
                    return 'Bid must be > \$${product.currentBid.toStringAsFixed(2)}';
                  }
                  if (product.bidCount > 0 && bid < product.nextMinBid) {
                    return 'Bid must be ≥ \$${product.nextMinBid.toStringAsFixed(2)}';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _bidController.clear();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _placeBid(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Place Bid',
                    style: TextStyle(fontFamily: 'SourceSans3'),
                  ),
          ),
        ],
      ),
    );
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
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: colorToken.surface,
              leading: IconButton(
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
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorToken.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isWatchlisted ? Icons.favorite : Icons.favorite_border,
                        color: _isWatchlisted
                            ? colorToken.error
                            : colorToken.textPrimary,
                      ),
                    ),
                    onPressed: _toggleWatchlist,
                  ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorToken.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share, color: colorToken.textPrimary),
                  ),
                  onPressed: () => ShareUtil.shareAuction(
                    productId: widget.docId,
                    productName: _product?.name,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: product.imageUrl.isNotEmpty
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
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auction ended badge
                    if (!product.isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorToken.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_clock,
                                size: 16, color: colorToken.error),
                            const SizedBox(width: 6),
                            Text(
                              'Auction Ended',
                              style: TextStyle(
                                color: colorToken.error,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SourceSans3',
                              ),
                            ),
                          ],
                        ),
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

                    // Price and Date Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorToken.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorToken.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.bidCount > 0
                                    ? 'Current Bid'
                                    : 'Starting Bid',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorToken.textSecondary,
                                  fontFamily: 'SourceSans3',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: colorToken.success,
                                    size: 24,
                                  ),
                                  Text(
                                    product.currentBid.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: colorToken.textPrimary,
                                      fontFamily: 'SourceSans3',
                                    ),
                                  ),
                                ],
                              ),
                              if (product.bidCount > 0)
                                Text(
                                  '${product.bidCount} bid${product.bidCount == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorToken.textSecondary,
                                    fontFamily: 'SourceSans3',
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Ends On',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorToken.textSecondary,
                                  fontFamily: 'SourceSans3',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: colorToken.textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.date,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorToken.textPrimary,
                                      fontFamily: 'SourceSans3',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (!isOwnProduct &&
                        currentUserId != null &&
                        product.sellerId.isNotEmpty) ...[
                      _sellerCard(product, colorToken, currentUserId),
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
                    _buildBidsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          isOwnProduct ? null : _buildBottomBar(product, colorToken),
    );
  }

  Widget _sellerCard(Product product, colorToken, String currentUserId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorToken.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorToken.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorToken.surfaceVariant,
            backgroundImage: product.sellerPhoto.isNotEmpty
                ? NetworkImage(product.sellerPhoto)
                : null,
            child: product.sellerPhoto.isEmpty
                ? Icon(Icons.person, color: colorToken.textSecondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seller',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.sellerName.isNotEmpty
                      ? product.sellerName
                      : 'Unknown seller',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<bool>(
            stream: FollowRepository.watchIsFollowing(
                currentUserId, product.sellerId),
            builder: (context, snap) {
              final following = snap.data ?? false;
              return OutlinedButton.icon(
                onPressed: () => _toggleFollow(
                    currentUserId, product.sellerId, following),
                icon: Icon(
                  following ? Icons.check : Icons.add,
                  size: 18,
                  color:
                      following ? colorToken.textSecondary : colorToken.primary,
                ),
                label: Text(
                  following ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: following
                        ? colorToken.textSecondary
                        : colorToken.primary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color:
                        following ? colorToken.divider : colorToken.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow(
      String followerId, String sellerId, bool following) async {
    try {
      if (following) {
        await FollowRepository.unfollow(followerId, sellerId);
      } else {
        await FollowRepository.follow(followerId, sellerId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update follow: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBottomBar(Product product, colorToken) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorToken.surface,
        boxShadow: [
          BoxShadow(
            color: colorToken.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed:
                product.isActive ? () => _showBidDialog(product) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: product.isActive
                  ? Colors.black
                  : colorToken.surfaceVariant,
              foregroundColor: product.isActive
                  ? Colors.white
                  : colorToken.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              product.isActive ? 'Place Bid' : 'Auction Ended',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidsList() {
    final colorToken = ThemeProvider.of(context).colorToken;

    return StreamBuilder<List<Bid>>(
      stream: BidRepository.watchByProduct(widget.docId),
      builder: (context, snapshot) {
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
          final isOwner =
              AuthRepository.currentUserId == _product?.sellerId;
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
            final bidAmount =
                (double.tryParse(bid.amount.toString()) ?? 0)
                    .toStringAsFixed(2);
            final bidTime = bid.bidTime;

            return Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: index == 0
                    ? colorToken.success.withValues(alpha: 0.1)
                    : colorToken.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? colorToken.success
                          : colorToken.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      index == 0 ? Icons.emoji_events : Icons.person,
                      color: index == 0
                          ? Colors.white
                          : colorToken.textSecondary,
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
                              '\$$bidAmount',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorToken.textPrimary,
                                fontFamily: 'SourceSans3',
                              ),
                            ),
                            if (index == 0) ...[
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
                                child: const Text(
                                  'Leading',
                                  style: TextStyle(
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
                          bidTime,
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