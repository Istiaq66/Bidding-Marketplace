import 'package:bidding_marketplace/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

/// Search box + filter button, plus the active-filter chip row, at the top
/// of Home.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onTapSearch,
    required this.onTapFilter,
    required this.onClearSearch,
    required this.onClearFilter,
  });

  final String searchQuery;
  final String selectedFilter;
  final VoidCallback onTapSearch;
  final VoidCallback onTapFilter;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: colorToken.surface,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTapSearch,
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
                          searchQuery.isEmpty
                              ? 'Search auctions...'
                              : searchQuery,
                          style: TextStyle(
                            color:
                                searchQuery.isEmpty
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
                onTap: onTapFilter,
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
        if (searchQuery.isNotEmpty || selectedFilter != 'All')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorToken.surface,
            child: Wrap(
              spacing: 8,
              children: [
                if (searchQuery.isNotEmpty)
                  Chip(
                    label: Text(
                      'Search: $searchQuery',
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
                    onDeleted: onClearSearch,
                    backgroundColor: colorToken.surfaceVariant,
                  ),
                if (selectedFilter != 'All')
                  Chip(
                    label: Text(
                      selectedFilter,
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
                    onDeleted: onClearFilter,
                    backgroundColor: colorToken.surfaceVariant,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
