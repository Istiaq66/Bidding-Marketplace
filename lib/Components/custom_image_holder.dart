import 'package:app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImageHolder extends StatelessWidget {
  final String imageUrl;

  const CustomImageHolder({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      // Placeholder while loading
      placeholder: (context, url) => Container(
        color: ThemeProvider.of(context, listen: false).colorToken.surface,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      // Error widget if image fails to load
      errorWidget: (context, url, error) => Container(
        color: ThemeProvider.of(context, listen: false).colorToken.surface,
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: ThemeProvider.of(context, listen: false).colorToken.surfaceVariant,
        ),
      ),
      // Fit image
      fit: BoxFit.cover,
      // Fade in animation
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 500),
      // Image dimensions
      width: double.infinity,
      height: 200,
    );
  }
}