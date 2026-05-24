import 'package:app/screens/product_details_page.dart';
import 'package:app/services/new_user.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyBids extends StatelessWidget {
  const MyBids({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = NewUser().existingUser?.uid;


    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bids')
            .where('Bidder Id', isEqualTo: userId)
            .orderBy('Bid Time', descending: true)
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
                    Icon(Icons.gavel, size: 64, color: colorToken.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No bids yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorToken.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start bidding on items you like',
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
                final data = doc.data() as Map<String, dynamic>;

                return _buildBidItem(context, data);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBidItem(BuildContext context, Map<String, dynamic> data) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final productId = data['Product Id'] ?? '';
    final bidAmount = data['Bid Amount'] ?? '0';
    final bidTime = data['Bid Time'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
      builder: (context, productSnapshot) {
        if (!productSnapshot.hasData) {
          return const SizedBox();
        }

        final productData = productSnapshot.data!.data() as Map<String, dynamic>?;
        if (productData == null) {
          return const SizedBox();
        }

        final productName = productData['Product Name'] ?? 'Unknown';
        final imageUrl = productData['Image Url'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: colorToken.cardBackground,
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: colorToken.surfaceVariant,
                    child: Icon(
                      Icons.image_not_supported,
                      color: colorToken.textSecondary,
                    ),
                  );
                },
              )
                  : Container(
                width: 60,
                height: 60,
                color: colorToken.surfaceVariant,
                child: Icon(Icons.shopping_bag, color: colorToken.textSecondary),
              ),
            ),
            title: Text(
              productName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorToken.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Bid: \$$bidAmount',
                  style: TextStyle(
                    color: colorToken.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bidTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorToken.textTertiary,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorToken.bidActive.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, size: 16, color: colorToken.bidActive),
                  const SizedBox(width: 4),
                  Text(
                    'Leading',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorToken.bidActive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              if (productId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetails(docId: productId)),
              );
            },
          ),
        );
      },
    );
  }
}