import 'package:app/components/custom_image_holder.dart';
import 'package:app/models/product.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:app/repositories/user_repository.dart';
import 'package:app/screens/product_details_page.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  List<Product> _products = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    UserRepository.ensureUserDocument();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _products = [];
      _cursor = null;
      _hasMore = true;
    });
    try {
      final (products, cursor) =
          await ProductRepository.fetchPage(limit: _pageSize, after: null);
      setState(() {
        _products = products;
        _cursor = cursor;
        _hasMore = products.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _cursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final (products, cursor) = await ProductRepository.fetchPage(
        limit: _pageSize,
        after: _cursor,
      );
      setState(() {
        _products.addAll(products);
        _cursor = cursor;
        _hasMore = products.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFirstPage();
  }

  void _showSearchDialog() {
    final colorToken = ThemeProvider.of(context).colorToken;

    showDialog(
      context: context,
      builder: (context) {
        String tempSearch = _searchQuery;
        return AlertDialog(
          backgroundColor: colorToken.surface,
          title: Text(
            'Search Auctions',
            style: TextStyle(
              color: colorToken.textPrimary,
              fontFamily: 'SourceSans3',
            ),
          ),
          content: TextField(
            autofocus: true,
            onChanged: (value) => tempSearch = value,
            style: TextStyle(
              color: colorToken.textPrimary,
              fontFamily: 'SourceSans3',
            ),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: TextStyle(
                color: colorToken.textTertiary,
                fontFamily: 'SourceSans3',
              ),
              prefixIcon: Icon(Icons.search, color: colorToken.textSecondary),
              filled: true,
              fillColor: colorToken.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: Text(
                'Clear',
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = tempSearch);
                Navigator.pop(context);
              },
              child: Text(
                'Search',
                style: TextStyle(
                  color: colorToken.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SourceSans3',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFilterSheet() {
    final colorToken = ThemeProvider.of(context).colorToken;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorToken.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorToken.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('All', Icons.apps),
            _buildFilterOption('Price: Low to High', Icons.arrow_upward),
            _buildFilterOption('Price: High to Low', Icons.arrow_downward),
            _buildFilterOption('Newest First', Icons.new_releases),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final isSelected = _selectedFilter == title;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorToken.primary : colorToken.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colorToken.primary : colorToken.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'SourceSans3',
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: colorToken.primary) : null,
      onTap: () {
        setState(() => _selectedFilter = title);
        Navigator.pop(context);
      },
    );
  }

  List<Product> _filterAndSortProducts(List<Product> products) {
    var filtered = products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_selectedFilter) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.currentBid.compareTo(b.currentBid));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.currentBid.compareTo(a.currentBid));
        break;
      case 'Newest First':
        filtered = filtered.reversed.toList();
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Container(
      color: colorToken.background,
      child: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colorToken.surface,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showSearchDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colorToken.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: colorToken.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Search auctions...'
                                : _searchQuery,
                            style: TextStyle(
                              color: _searchQuery.isEmpty
                                  ? colorToken.textTertiary
                                  : colorToken.textPrimary,
                              fontFamily: 'SourceSans3',
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorToken.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune,
                        color: colorToken.textPrimary, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Chips
          if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorToken.surface,
              child: Wrap(
                spacing: 8,
                children: [
                  if (_searchQuery.isNotEmpty)
                    Chip(
                      label: Text(
                        'Search: $_searchQuery',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorToken.textPrimary,
                          fontFamily: 'SourceSans3',
                        ),
                      ),
                      deleteIcon: Icon(Icons.close,
                          size: 16, color: colorToken.textSecondary),
                      onDeleted: () => setState(() => _searchQuery = ''),
                      backgroundColor: colorToken.surfaceVariant,
                    ),
                  if (_selectedFilter != 'All')
                    Chip(
                      label: Text(
                        _selectedFilter,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorToken.textPrimary,
                          fontFamily: 'SourceSans3',
                        ),
                      ),
                      deleteIcon: Icon(Icons.close,
                          size: 16, color: colorToken.textSecondary),
                      onDeleted: () =>
                          setState(() => _selectedFilter = 'All'),
                      backgroundColor: colorToken.surfaceVariant,
                    ),
                ],
              ),
            ),

          // Products Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: colorToken.primary,
              child: _buildBody(colorToken),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(colorToken) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorToken.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorToken.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadFirstPage,
              child: Text('Retry',
                  style: TextStyle(color: colorToken.primary)),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: colorToken.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No auctions available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new items',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filterAndSortProducts(_products);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorToken.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = filtered[index];
                return MinimalisticProductCard(
                  name: product.name,
                  minPrice: product.currentBid.toStringAsFixed(2),
                  imageUrl: product.imageUrl,
                  description: product.description,
                  docId: product.id,
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _isLoadingMore
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: colorToken.primary),
                  ),
                )
              : _hasMore
                  ? const SizedBox(height: 80)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'All ${filtered.length} items loaded',
                          style: TextStyle(
                            color: colorToken.textSecondary,
                            fontFamily: 'SourceSans3',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class MinimalisticProductCard extends StatelessWidget {
  final String name;
  final String minPrice;
  final String imageUrl;
  final String docId;
  final String? description;

  const MinimalisticProductCard({
    super.key,
    required this.name,
    required this.minPrice,
    required this.imageUrl,
    required this.docId,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final themeProvider = ThemeProvider.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(docId: docId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.isLightTheme
              ? colorToken.surface
              : colorToken.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isLightTheme
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty && imageUrl != ''
                        ? CustomImageHolder(imageUrl: imageUrl)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorToken.surfaceVariant,
                                  colorToken.surface,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 40,
                                color: colorToken.textSecondary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorToken.textPrimary,
                        fontFamily: 'SourceSans3',
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorToken.textSecondary,
                            fontFamily: 'SourceSans3',
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorToken.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorToken.textSecondary,
                              fontFamily: 'SourceSans3',
                            ),
                          ),
                          Flexible(
                            child: Text(
                              minPrice,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorToken.textSecondary,
                                fontFamily: 'SourceSans3',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}