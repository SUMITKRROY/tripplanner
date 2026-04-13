import 'package:flutter/material.dart';

import '../models/generate_trip_response_model.dart';
import '../widgets/place_category_visual.dart';
import '../widgets/place_image.dart';

/// Full-screen detail for a single [PlaceModel] (itinerary, highlights, full plan).
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.place,
    this.city,
    this.day,
  });

  final PlaceModel place;
  final String? city;
  final TripDayPlanModel? day;

  static String formatDurationMinutes(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cat = place.category ?? '';
    final style = placeCategoryStyle(cat);
    final name = place.name ?? 'Place';
    final hasImage =
        place.imageUrl != null && place.imageUrl!.trim().isNotEmpty;
    final rating = place.rating;
    final ratingLabel =
        rating != null && rating > 0 ? rating.toStringAsFixed(1) : '—';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? 260 : 200,
            pinned: true,
            stretch: true,
            backgroundColor: style.color,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Positioned.fill(
                      child: PlaceImage(
                        imageUrl: place.imageUrl!,
                        width: MediaQuery.sizeOf(context).width,
                        height: 400,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            style.color,
                            style.color.withValues(alpha: 0.75),
                            scheme.primary,
                          ],
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 28,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PlaceCategoryGlyph(style: style, size: 40),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (city != null && city!.isNotEmpty)
                                Text(
                                  city!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (cat.isNotEmpty)
                        Chip(
                          avatar: PlaceCategoryGlyph(style: style, size: 18),
                          label: Text(cat),
                          backgroundColor: style.bg,
                          side: BorderSide(color: style.color.withValues(alpha: 0.35)),
                          labelStyle: TextStyle(
                            color: style.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          padding: const EdgeInsets.only(left: 4),
                        ),
                      if (day != null && (day!.theme ?? '').isNotEmpty)
                        Chip(
                          label: Text(
                            'Day ${day!.day ?? ''} · ${day!.theme}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoTile(
                        icon: Icons.schedule_rounded,
                        label: 'Visit',
                        value: formatDurationMinutes(place.duration),
                        scheme: scheme,
                      ),
                      const SizedBox(width: 10),
                      _InfoTile(
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: ratingLabel,
                        scheme: scheme,
                        iconColor: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 10),
                      _InfoTile(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Best time',
                        value: (place.bestTime != null &&
                                place.bestTime!.trim().isNotEmpty)
                            ? place.bestTime!.trim()
                            : 'Anytime',
                        scheme: scheme,
                        iconColor: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  if (place.openingHours != null &&
                      place.openingHours!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      scheme: scheme,
                      title: 'Opening hours',
                      child: Text(
                        place.openingHours!.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  if (place.description != null &&
                      place.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      scheme: scheme,
                      title: 'About',
                      child: Text(
                        place.description!.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                  if (place.tips != null && place.tips!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              place.tips!.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFFC2410C),
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (day != null && day!.places.length > 1) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Other stops this day',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...day!.places
                        .where((p) => !identical(p, place))
                        .map((p) {
                      final pName = p.name ?? 'Place';
                      final sub = p.category ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => PlaceDetailScreen(
                                    place: p,
                                    city: city,
                                    day: day,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  PlaceCategoryGlyph(
                                    style: placeCategoryStyle(
                                      p.category ?? '',
                                    ),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (sub.isNotEmpty)
                                          Text(
                                            sub,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor ?? scheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.scheme,
    required this.title,
    required this.child,
  });

  final ColorScheme scheme;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
