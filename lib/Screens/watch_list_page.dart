import 'package:app/Services/new_user.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WatchList extends StatelessWidget {

  const WatchList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = NewUser().existingUser?.uid;


    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('watchlist')
            .where('User Id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorToken.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                      'Save items you\'re interested in',
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
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                return _buildWatchlistItem(
                  context,
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistItem(BuildContext context, String docId, Map<String, dynamic> data) {
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
            // Remove from watchlist
            FirebaseFirestore.instance.collection('watchlist').doc(docId).delete();
          },
        ),
        onTap: () {
          // Navigate to product details
        },
      ),
    );
  }
}