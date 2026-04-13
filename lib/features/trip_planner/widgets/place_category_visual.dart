import 'package:flutter/material.dart';

/// Bundled category marker images under `assets/images/`.
abstract final class PlaceCategoryImages {
  static const temple = 'assets/images/temple.png';
  static const park = 'assets/images/park.png';
  static const shopping = 'assets/images/shopping_cart.png';
}

/// Visual style for a place category (accent colors + emoji and/or PNG).
class PlaceCategoryStyle {
  final String emoji;
  final Color color;
  final Color bg;
  /// When set, prefer this asset over [emoji] in UI and custom markers.
  final String? imageAsset;

  const PlaceCategoryStyle(
    this.emoji,
    this.color,
    this.bg, {
    this.imageAsset,
  });
}

PlaceCategoryStyle placeCategoryStyle(String category) {
  final c = category.toLowerCase();

  if (c.contains('temple') ||
      c.contains('mandir') ||
      c.contains('shrine') ||
      c.contains('church') ||
      c.contains('mosque') ||
      c.contains('religious') ||
      c.contains('spiritual')) {
    return const PlaceCategoryStyle(
      '🛕',
      Color(0xFFFF6B35),
      Color(0xFFFFF0E8),
      imageAsset: PlaceCategoryImages.temple,
    );
  }
  if (c.contains('park') ||
      c.contains('garden') ||
      c.contains('nature') ||
      c.contains('forest') ||
      c.contains('wildlife') ||
      c.contains('sanctuary')) {
    return const PlaceCategoryStyle(
      '🌿',
      Color(0xFF22C55E),
      Color(0xFFE8FAF0),
      imageAsset: PlaceCategoryImages.park,
    );
  }
  if (c.contains('restaurant') ||
      c.contains('food') ||
      c.contains('cafe') ||
      c.contains('eat') ||
      c.contains('culinary') ||
      c.contains('dining')) {
    return const PlaceCategoryStyle('🍽️', Color(0xFFE53935), Color(0xFFFFF0F0));
  }
  if (c.contains('museum') ||
      c.contains('gallery') ||
      c.contains('art') ||
      c.contains('heritage') ||
      c.contains('historic')) {
    return const PlaceCategoryStyle('🏛️', Color(0xFF7C3AED), Color(0xFFF3F0FF));
  }
  if (c.contains('mall') ||
      c.contains('shop') ||
      c.contains('market') ||
      c.contains('bazaar') ||
      c.contains('shopping')) {
    return const PlaceCategoryStyle(
      '🛍️',
      Color(0xFFEC4899),
      Color(0xFFFFF0F8),
      imageAsset: PlaceCategoryImages.shopping,
    );
  }
  if (c.contains('beach') ||
      c.contains('lake') ||
      c.contains('river') ||
      c.contains('waterfall') ||
      c.contains('water')) {
    return const PlaceCategoryStyle('🏖️', Color(0xFF0EA5E9), Color(0xFFE8F7FF));
  }
  if (c.contains('fort') ||
      c.contains('palace') ||
      c.contains('castle') ||
      c.contains('monument')) {
    return const PlaceCategoryStyle('🏰', Color(0xFFF59E0B), Color(0xFFFFFBE8));
  }
  if (c.contains('hotel') ||
      c.contains('resort') ||
      c.contains('stay') ||
      c.contains('accommodation')) {
    return const PlaceCategoryStyle('🏨', Color(0xFF6366F1), Color(0xFFF0F0FF));
  }
  if (c.contains('airport') ||
      c.contains('station') ||
      c.contains('transport')) {
    return const PlaceCategoryStyle('🚉', Color(0xFF64748B), Color(0xFFF1F5F9));
  }
  if (c.contains('viewpoint') ||
      c.contains('hill') ||
      c.contains('mountain') ||
      c.contains('trek')) {
    return const PlaceCategoryStyle('🏔️', Color(0xFF0891B2), Color(0xFFE0F7FF));
  }
  return const PlaceCategoryStyle('📍', Color(0xFF14B8A6), Color(0xFFE8FDFB));
}

/// Category badge: PNG when [style.imageAsset] is set, otherwise emoji.
class PlaceCategoryGlyph extends StatelessWidget {
  final PlaceCategoryStyle style;
  final double size;

  const PlaceCategoryGlyph({
    super.key,
    required this.style,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final path = style.imageAsset;
    if (path != null) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }
    return Text(
      style.emoji,
      style: TextStyle(fontSize: size),
      textAlign: TextAlign.center,
    );
  }
}
