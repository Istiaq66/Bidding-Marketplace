import 'package:app/core/theme/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular user avatar that degrades gracefully: shows a person icon when the
/// URL is empty OR fails to decode (e.g. a non-image URL stored on the user).
/// Use everywhere a user/seller photo is rendered so a bad URL never throws an
/// "Invalid image data" image-codec exception.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.imageUrl, this.radius = 24});

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context, listen: false).colorToken;
    final diameter = radius * 2;

    Widget fallback() =>
        Icon(Icons.person, size: radius, color: colorToken.textSecondary);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorToken.surfaceVariant,
      child: ClipOval(
        child:
            imageUrl.isEmpty
                ? fallback()
                : CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => fallback(),
                  errorWidget: (_, __, ___) => fallback(),
                ),
      ),
    );
  }
}
