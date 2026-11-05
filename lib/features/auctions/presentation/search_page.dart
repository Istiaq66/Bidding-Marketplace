import 'dart:async';
import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:bidding_marketplace/features/auctions/data/product_repository.dart';
import 'package:bidding_marketplace/features/auctions/presentation/product_details_page.dart';
import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:bidding_marketplace/core/utils/money.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Product> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _hasSearched = false;
        _searchError = null;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      List<Product> results;
      String? error;
      try {
        results = await ProductRepository.search(query);
      } catch (_) {
        results = [];
        error = 'Search failed. Check your connection and try again.';
      }
      // Drop responses for a query the user has since changed.
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _results = results;
        _searchError = error;
        _isSearching = false;
        _hasSearched = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        backgroundColor: colorToken.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: TextStyle(
            color: colorToken.textPrimary,
            fontFamily: 'SourceSans3',
          ),
          decoration: InputDecoration(
            hintText: 'Search auctions...',
            hintStyle: TextStyle(
              color: colorToken.textTertiary,
              fontFamily: 'SourceSans3',
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear search',
              icon: Icon(Icons.close, color: colorToken.textSecondary),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(colorToken),
    );
  }

  Widget _buildBody(colorToken) {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: colorToken.primary),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 72, color: colorToken.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Search for auctions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a product name above',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      );
    }

    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 72, color: colorToken.error),
              const SizedBox(height: 16),
              Text(
                _searchError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              TextButton(
                onPressed: () => _onChanged(_controller.text),
                child: Text(
                  'Retry',
                  style: TextStyle(color: colorToken.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: colorToken.textSecondary),
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
              'Try a different search term',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        return _buildResultTile(context, product, colorToken);
      },
    );
  }

  Widget _buildResultTile(BuildContext context, Product product, colorToken) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    errorBuilder:
                        (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: colorToken.surfaceVariant,
                          child: Icon(
                            Icons.shopping_bag,
                            color: colorToken.textSecondary,
                          ),
                        ),
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
            fontFamily: 'SourceSans3',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.bidCount > 0
                  ? 'Current bid: ${formatMoney(product.currentBid)}'
                  : 'Starting at: ${formatMoney(product.currentBid)}',
              style: TextStyle(
                color: colorToken.success,
                fontWeight: FontWeight.w600,
                fontFamily: 'SourceSans3',
              ),
            ),
            Row(
              children: [
                Icon(
                  product.isActive
                      ? Icons.radio_button_on
                      : Icons.radio_button_off,
                  size: 12,
                  color:
                      product.isActive ? colorToken.success : colorToken.error,
                ),
                const SizedBox(width: 4),
                Text(
                  product.isActive ? 'Active • Ends ${product.date}' : 'Ended',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorToken.textSecondary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: colorToken.textSecondary),
        isThreeLine: true,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetails(docId: product.id),
              ),
            ),
      ),
    );
  }
}
