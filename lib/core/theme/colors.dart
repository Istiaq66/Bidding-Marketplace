import 'package:flutter/material.dart';

class AppColors {
  // Neutral Greys - Light minimalistic background like screenshot
  static const Color neutral050 = Color(0xFFF5F5F5); // Light grey background
  static const Color neutral100 = Color(0xFFEEEEEE); // Input field background
  static const Color neutral200 = Color(0xFFE0E0E0); // Divider
  static const Color neutral300 = Color(0xFFBDBDBD); // Border
  static const Color neutral400 = Color(0xFF9E9E9E); // Placeholder text
  static const Color neutral500 = Color(
    0xFF757575,
  ); // Secondary text "Forgot Password?"
  static const Color neutral600 = Color(0xFF616161); // Grey text
  static const Color neutral700 = Color(0xFF424242); // Dark grey
  static const Color neutral800 = Color(0xFF212121); // Almost black text
  static const Color neutral900 = Color(0xFF000000); // Pure black

  // Gavel colors from screenshot
  static const Color gavelGrey = Color(0xFF5F6C7B); // Dark grey of gavel handle
  static const Color gavelTeal = Color(0xFF8BC8C3); // Light teal of gavel head

  // Button - Pure black like "Sign In" button in screenshot
  static const Color black = Color(0xFF000000);

  // Link color - Blue "Register Now" text
  static const Color blue667eea = Color(0xFF3B82F6); // Blue for links
  static const Color purple764ba2 = Color(
    0xFF8B5CF6,
  ); // Keep for gradient if needed

  // Status Colors (Muted)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Auction specific colors (Muted)
  static const Color bidActive = Color(0xFF8BC8C3);
  static const Color bidWon = Color(0xFF10B981);
  static const Color bidLost = Color(0xFF757575);
  static const Color watchlist = Color(0xFFF59E0B);
}
