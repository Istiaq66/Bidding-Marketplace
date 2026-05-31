import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> backfillProducts() async {
  final db = FirebaseFirestore.instance;
  final productsSnap = await db.collection('products').get();

  var updated = 0;
  var skipped = 0;

  for (final doc in productsSnap.docs) {
    final data = doc.data();

    // Already migrated — skip.
    if (data.containsKey('bidCount') &&
        data.containsKey('status') &&
        data.containsKey('nameLower') &&
        data.containsKey('endsAt')) {
      skipped++;
      continue;
    }

    final dateStr = (data['Date'] as String?) ?? '';
    Timestamp? endsAt;
    try {
      final parsed = DateTime.parse(dateStr);
      endsAt = Timestamp.fromDate(
        DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59),
      );
    } catch (_) {}

    final minBidStr = (data['Minimum Bid Price'] ?? '0').toString();
    final minPrice = double.tryParse(minBidStr) ?? 0;
    final name = (data['Product Name'] ?? '') as String;

    // Count existing bids and find the highest to set currentBid accurately.
    final bidsSnap =
        await db
            .collection('bids')
            .where('Product Id', isEqualTo: doc.id)
            .orderBy('Bid Amount', descending: true)
            .get();

    final bidCount = bidsSnap.docs.length;
    final highestBidDoc = bidCount > 0 ? bidsSnap.docs.first.data() : null;
    final currentBid =
        highestBidDoc != null
            ? (highestBidDoc['Bid Amount'] as num?)?.toDouble() ?? minPrice
            : minPrice;
    final highestBidderId =
        highestBidDoc != null ? highestBidDoc['Bidder Id'] as String? : null;

    // Determine status from endsAt; Cloud Functions will correct later.
    final now = DateTime.now();
    final status =
        (endsAt != null && endsAt.toDate().isBefore(now)) ? 'ended' : 'active';

    final updates = <String, dynamic>{
      if (!data.containsKey('nameLower')) 'nameLower': name.toLowerCase(),
      if (!data.containsKey('endsAt') && endsAt != null) 'endsAt': endsAt,
      if (!data.containsKey('currentBid')) 'currentBid': currentBid,
      if (!data.containsKey('bidCount')) 'bidCount': bidCount,
      if (!data.containsKey('highestBidderId') && highestBidderId != null)
        'highestBidderId': highestBidderId,
      if (!data.containsKey('status')) 'status': status,
      if (!data.containsKey('winnerId')) 'winnerId': null,
      if (!data.containsKey('sellerName')) 'sellerName': '',
      if (!data.containsKey('sellerPhoto')) 'sellerPhoto': '',
      if (!data.containsKey('createdAt'))
        'createdAt': FieldValue.serverTimestamp(),
    };

    if (updates.isEmpty) {
      skipped++;
      continue;
    }

    await doc.reference.update(updates);
    updated++;
  }

  // ignore: avoid_print
  print('Backfill complete: $updated updated, $skipped skipped');
}
