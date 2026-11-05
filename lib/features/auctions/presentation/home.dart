import 'dart:async';

import 'package:bidding_marketplace/features/auctions/domain/product.dart';
import 'package:bidding_marketplace/features/auctions/data/product_repository.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/home_dialogs.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/home_results_view.dart';
import 'package:bidding_marketplace/features/auctions/presentation/widgets/home_search_bar.dart';
import 'package:bidding_marketplace/features/bids/data/bid_repository.dart';
import 'package:bidding_marketplace/features/auth/data/auth_repository.dart';
import 'package:bidding_marketplace/features/profile/data/user_repository.dart';
import 'package:bidding_marketplace/core/theme/theme_provider.dart';
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
  // Bumped on every first-page load (refresh / sort change) so responses
  // from an older request can't overwrite newer results.
  int _loadGeneration = 0;

  Set<String> _myBidProductIds = {};
  StreamSubscription<Set<String>>? _bidSub;

  @override
  void initState() {
    super.initState();
    UserRepository.ensureUserDocument();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
    final uid = AuthRepository.currentUserId;
    if (uid != null) {
      _bidSub = BidRepository.watchBidProductIds(uid).listen((ids) {
        if (mounted) setState(() => _myBidProductIds = ids);
      });
    }
  }

  @override
  void dispose() {
    _bidSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  ProductSort get _sort {
    switch (_selectedFilter) {
      case 'Price: Low to High':
        return ProductSort.priceLowToHigh;
      case 'Price: High to Low':
        return ProductSort.priceHighToLow;
      default: // 'All' and 'Newest First'
        return ProductSort.newest;
    }
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _error = null;
      _products = [];
      _cursor = null;
      _hasMore = true;
    });
    try {
      final (products, cursor) = await ProductRepository.fetchPage(
        limit: _pageSize,
        after: null,
        sort: _sort,
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _products = products;
        _cursor = cursor;
        _hasMore = products.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _cursor == null) return;
    final generation = _loadGeneration;
    setState(() => _isLoadingMore = true);
    try {
      final (products, cursor) = await ProductRepository.fetchPage(
        limit: _pageSize,
        after: _cursor,
        sort: _sort,
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _products.addAll(products);
        _cursor = cursor;
        _hasMore = products.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFirstPage();
  }

  // Sort order is applied server-side in fetchPage (see _sort). Only the search
  // text is filtered client-side, over the currently-loaded pages.
  List<Product> _filterAndSortProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    final q = _searchQuery.toLowerCase();
    return products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Container(
      color: colorToken.background,
      child: Column(
        children: [
          HomeSearchBar(
            searchQuery: _searchQuery,
            selectedFilter: _selectedFilter,
            onTapSearch:
                () => showHomeSearchDialog(
                  context,
                  initialQuery: _searchQuery,
                  onSearch: (q) => setState(() => _searchQuery = q),
                ),
            onTapFilter:
                () => showHomeFilterSheet(
                  context,
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) {
                    if (filter == _selectedFilter) return;
                    setState(() => _selectedFilter = filter);
                    _loadFirstPage(); // re-query with the new server-side order
                  },
                ),
            onClearSearch: () => setState(() => _searchQuery = ''),
            onClearFilter: () => setState(() => _selectedFilter = 'All'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: colorToken.primary,
              child: HomeResultsView(
                isLoading: _isLoading,
                error: _error,
                allProductsEmpty: _products.isEmpty,
                products: _filterAndSortProducts(_products),
                myBidProductIds: _myBidProductIds,
                hasMore: _hasMore,
                isLoadingMore: _isLoadingMore,
                scrollController: _scrollController,
                onRetry: _loadFirstPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
