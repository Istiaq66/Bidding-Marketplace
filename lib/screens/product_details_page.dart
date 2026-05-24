import 'package:app/models/bid.dart';
import 'package:app/models/product.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:app/repositories/bid_repository.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/repositories/watchlist_repository.dart';
import 'package:app/providers/theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _checkWatchlistStatus();
  }

  Future<void> _checkWatchlistStatus() async {
    final userId = AuthRepository.currentUserId;
    if (userId == null) return;

    try {
      final watched = await WatchlistRepository.isWatched(userId, widget.docId);
      if (!mounted) return;
      setState(() => _isWatchlisted = watched);
    } catch (_) {
      // ignored — UI just shows un-watchlisted state
    }
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

  Future<void> _placeBid(String minBidPrice) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = AuthRepository.currentUserId;
    if (userId == null) {
      _showErrorSnackbar('Please login to place a bid');
      return;
    }

    final bidAmount = double.tryParse(_bidController.text.trim()) ?? 0;
    final minPrice = double.tryParse(minBidPrice) ?? 0;

    if (bidAmount <= minPrice) {
      _showErrorSnackbar('Bid must be higher than minimum price');
      return;
    }

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);

    try {
      await BidRepository.place(
        productId: widget.docId,
        bidderId: userId,
        amount: _bidController.text.trim(),
      );

      _showSuccessSnackbar('Bid placed successfully!');
      _bidController.clear();
      navigator.pop();
    } catch (_) {
      _showErrorSnackbar('Failed to place bid');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBidDialog(String minBidPrice) {
    final colorToken = ThemeProvider.of(context).colorToken;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorToken.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                'Minimum bid: \$$minBidPrice',
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
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
                  prefixIcon: Icon(Icons.attach_money, color: colorToken.primary),
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
                    return 'Please enter your bid amount';
                  }
                  final bid = double.tryParse(value);
                  if (bid == null) {
                    return 'Please enter a valid number';
                  }
                  final minPrice = double.tryParse(minBidPrice) ?? 0;
                  if (bid <= minPrice) {
                    return 'Bid must be higher than \$$minBidPrice';
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
            onPressed: _isLoading ? null : () => _placeBid(minBidPrice),
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
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      body: FutureBuilder<Product?>(
        future: ProductRepository.getById(widget.docId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorToken.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorToken.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Product not found',
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

          final product = snapshot.data!;
          final imageUrl = product.imageUrl;
          final productName = product.name;
          final description = product.description;
          final minBidPrice = product.minBidPrice;
          final endDate = product.date;
          final sellerId = product.sellerId;

          final currentUserId = AuthRepository.currentUserId;
          final isOwnProduct = currentUserId == sellerId;

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: colorToken.surface,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorToken.surface.withValues(alpha:0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: colorToken.textPrimary,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (!isOwnProduct)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorToken.surface.withValues(alpha:0.9),
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
                        color: colorToken.surface.withValues(alpha:0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.share,
                        color: colorToken.textPrimary,
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share — coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty && imageUrl != ''
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: colorToken.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: colorToken.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: colorToken.surfaceVariant,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: colorToken.textSecondary,
                        ),
                      );
                    },
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

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        productName,
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Minimum Bid',
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
                                          minBidPrice,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: colorToken.textPrimary,
                                            fontFamily: 'SourceSans3',
                                          ),
                                        ),
                                      ],
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
                                          endDate,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Section
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
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: colorToken.textSecondary,
                          fontFamily: 'SourceSans3',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bids Section
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
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Product?>(
        future: ProductRepository.getById(widget.docId),
        builder: (context, snapshot) {
          final product = snapshot.data;
          if (product == null) return const SizedBox();

          final minBidPrice = product.minBidPrice;
          final sellerId = product.sellerId;
          final currentUserId = AuthRepository.currentUserId;
          final isOwnProduct = currentUserId == sellerId;

          if (isOwnProduct) return const SizedBox();

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
                  onPressed: () => _showBidDialog(minBidPrice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Place Bid',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final bid = bids[index];
            final bidAmount = bid.amount;
            final bidTime = bid.bidTime;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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