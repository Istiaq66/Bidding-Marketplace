import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImageHolder extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double width;

  const CustomImageHolder({super.key, required this.imageUrl, this.height = 200, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: ThemeProvider.of(context, listen: false).colorToken.surface,
        child: Icon(
          Icons.image_outlined,
          size: 50,
          color:
              ThemeProvider.of(context, listen: false).colorToken.surfaceVariant,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
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
    );
  }
}