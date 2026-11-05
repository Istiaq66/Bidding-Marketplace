import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

/// The four sort options Home's filter sheet offers. Sorting is applied
/// server-side (see `ProductRepository.fetchPage` / `ProductSort`); 'All' and
/// 'Newest First' both map to [ProductSort.newest].
const homeFilterOptions = [
  'All',
  'Price: Low to High',
  'Price: High to Low',
  'Newest First',
];

/// Simple text-search dialog. Calls [onSearch] with the entered text, or
/// `''` if the user taps Clear.
void showHomeSearchDialog(
  BuildContext context, {
  required String initialQuery,
  required ValueChanged<String> onSearch,
}) {
  final colorToken = ThemeProvider.of(context).colorToken;

  showDialog(
    context: context,
    builder: (context) {
      String tempSearch = initialQuery;
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
              onSearch('');
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
              onSearch(tempSearch);
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

/// Bottom sheet for picking a sort option. Calls [onSelected] with the
/// chosen option; the sheet pops itself first.
void showHomeFilterSheet(
  BuildContext context, {
  required String selectedFilter,
  required ValueChanged<String> onSelected,
}) {
  final colorToken = ThemeProvider.of(context).colorToken;
  final icons = {
    'All': Icons.apps,
    'Price: Low to High': Icons.arrow_upward,
    'Price: High to Low': Icons.arrow_downward,
    'Newest First': Icons.new_releases,
  };

  showModalBottomSheet(
    context: context,
    backgroundColor: colorToken.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (context) => Padding(
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
              for (final option in homeFilterOptions)
                _FilterOptionTile(
                  title: option,
                  icon: icons[option]!,
                  isSelected: selectedFilter == option,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(option);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
  );
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

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
      trailing:
          isSelected ? Icon(Icons.check, color: colorToken.primary) : null,
      onTap: onTap,
    );
  }
}
