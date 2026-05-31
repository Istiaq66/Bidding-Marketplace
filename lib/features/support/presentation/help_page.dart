import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = <_Faq>[
    _Faq(
      question: 'How do I create an auction?',
      answer:
          'Open the Dashboard tab and tap "Create Auction". Add a photo, name, description, minimum bid, and end date.',
    ),
    _Faq(
      question: 'How do bids work?',
      answer:
          'Open an auction from Home and tap "Place Bid". Your bid must be higher than the current minimum bid. The highest bid at the auction end date wins.',
    ),
    _Faq(
      question: 'Can I edit or cancel an auction?',
      answer:
          'You can delete your auction from the My Auctions screen. Editing existing auctions is coming soon.',
    ),
    _Faq(
      question: 'Where can I see items I am watching?',
      answer: 'Open the Profile tab and tap "Watchlist".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        backgroundColor: colorToken.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._faqs.map((f) => _faqTile(f, colorToken)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorToken.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still need help?',
                  style: TextStyle(
                    color: colorToken.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reach us at support@biddingmarketplace.example.',
                  style: TextStyle(
                    color: colorToken.textSecondary,
                    fontSize: 14,
                    fontFamily: 'SourceSans3',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqTile(_Faq faq, ColorToken colorToken) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorToken.cardBackground,
      child: ExpansionTile(
        iconColor: colorToken.textPrimary,
        collapsedIconColor: colorToken.textSecondary,
        title: Text(
          faq.question,
          style: TextStyle(
            color: colorToken.textPrimary,
            fontWeight: FontWeight.w600,
            fontFamily: 'SourceSans3',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: TextStyle(
                color: colorToken.textSecondary,
                height: 1.5,
                fontFamily: 'SourceSans3',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq({required this.question, required this.answer});
}
