import 'package:app/models/watchlist_entry.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:app/repositories/watchlist_repository.dart';
import 'package:flutter/material.dart';

class WatchList extends StatelessWidget {
  const WatchList({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = AuthRepository.currentUserId;

    return Scaffold(
      body: StreamBuilder<List<WatchlistEntry>>(
        stream: userId == null
            ? const Stream.empty()
            : WatchlistRepository.watchByUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorToken.primary),
            );
          }

          final entries = snapshot.data ?? const <WatchlistEntry>[];
          if (entries.isEmpty) {
            return Container(
              color: colorToken.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: colorToken.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No items in watchlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorToken.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Save items you're interested in",
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
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _buildWatchlistItem(context, entries[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistItem(BuildContext context, WatchlistEntry entry) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorToken.cardBackground,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: colorToken.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.shopping_bag, size: 28, color: colorToken.textSecondary),
        ),
        title: Text(
          'Product Name',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorToken.textPrimary,
          ),
        ),
        subtitle: Text(
          '\$100 • Ends in 2 days',
          style: TextStyle(color: colorToken.textSecondary),
        ),
        trailing: IconButton(
          icon: Icon(Icons.favorite, color: colorToken.watchlist),
          onPressed: () {
            WatchlistRepository.deleteById(entry.id);
          },
        ),
        onTap: () {
          // PR5 — push ProductDetails by joining entry.productId
        },
      ),
    );
  }
}