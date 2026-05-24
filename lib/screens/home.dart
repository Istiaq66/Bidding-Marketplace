import 'package:app/components/custom_image_holder.dart';
import 'package:app/screens/product_details_page.dart';
import 'package:app/services/new_user.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    NewUser().checkUserExistence();
    super.initState();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });
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
      trailing: isSelected
          ? Icon(Icons.check, color: colorToken.primary)
          : null,
      onTap: () {
        setState(() => _selectedFilter = title);
        Navigator.pop(context);
      },
    );
  }

  List<DocumentSnapshot> _filterAndSortProducts(List<DocumentSnapshot> docs) {
    // Filter by search query
    var filtered = docs.where((doc) {
      if (_searchQuery.isEmpty) return true;
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['Product Name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort based on selected filter
    switch (_selectedFilter) {
      case 'Price: Low to High':
        filtered.sort((a, b) {
          final aPrice = double.tryParse((a.data() as Map)['Minimum Bid Price'] ?? '0') ?? 0;
          final bPrice = double.tryParse((b.data() as Map)['Minimum Bid Price'] ?? '0') ?? 0;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) {
          final aPrice = double.tryParse((a.data() as Map)['Minimum Bid Price'] ?? '0') ?? 0;
          final bPrice = double.tryParse((b.data() as Map)['Minimum Bid Price'] ?? '0') ?? 0;
          return bPrice.compareTo(aPrice);
        });
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
                // Search Bar
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
                          Icon(
                            Icons.search,
                            color: colorToken.textSecondary,
                            size: 20,
                          ),
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
                // Filter Button
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorToken.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: colorToken.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Chip
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
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: colorToken.textSecondary,
                      ),
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
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: colorToken.textSecondary,
                      ),
                      onDeleted: () => setState(() => _selectedFilter = 'All'),
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
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('products').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorToken.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
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
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorToken.textPrimary,
                              fontFamily: 'SourceSans3',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: TextStyle(
                              color: colorToken.textSecondary,
                              fontFamily: 'SourceSans3',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: colorToken.textSecondary,
                          ),
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

                  final filteredDocs = _filterAndSortProducts(snapshot.data!.docs);

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: colorToken.textSecondary,
                          ),
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

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final documentData = doc.data() as Map<String, dynamic>;

                      return MinimalisticProductCard(
                        name: documentData['Product Name'] ?? 'Unknown',
                        minPrice: documentData['Minimum Bid Price'] ?? '0',
                        imageUrl: documentData['Image Url'] ?? '',
                        description: documentData['Product Description'] ?? '',
                        docId: doc.id,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MinimalisticProductCard extends StatelessWidget {
  final String name;
  final String minPrice;
  final String imageUrl;
  final String docId;
  final String? description; // Added optional description

  const MinimalisticProductCard({
    Key? key,
    required this.name,
    required this.minPrice,
    required this.imageUrl,
    required this.docId,
    this.description, // Optional parameter
  }) : super(key: key);

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
          borderRadius: BorderRadius.circular(16), // Increased radius for softer look
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
            // Image Section
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
                          color: colorToken.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),

                  // Subtle gradient overlay at bottom
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
                            Colors.black.withValues(alpha:0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              flex: 4, // Increased content area
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
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

                    // Product Description (if available)
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