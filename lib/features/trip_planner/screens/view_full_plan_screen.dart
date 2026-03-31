import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';
import '../models/generate_trip_response_model.dart';
import '../widgets/place_image.dart';

// ─────────────────────────────────────────────
//  ROOT SCREEN (BLoC-wired)
// ─────────────────────────────────────────────

class ViewFullPlanScreen extends StatelessWidget {
  const ViewFullPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerBloc, TripPlannerState>(
      buildWhen: (prev, curr) => curr is TripPlannerSuccess,
      builder: (context, state) {
        if (state is! TripPlannerSuccess) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => NavigationUtils.pop(context),
              ),
            ),
            body: const Center(child: Text('No trip plan found.')),
          );
        }
        return _ViewFullPlanContent(data: state.data);
      },
    );
  }
}

// ─────────────────────────────────────────────
//  STATEFUL CONTENT
// ─────────────────────────────────────────────

class _ViewFullPlanContent extends StatefulWidget {
  const _ViewFullPlanContent({required this.data});
  final GenerateTripResponseModel data;

  @override
  State<_ViewFullPlanContent> createState() => _ViewFullPlanContentState();
}

class _ViewFullPlanContentState extends State<_ViewFullPlanContent> {
  int _expandedIndex = 0;
  int _selectedNav = 1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // First available place image as hero background
    final heroImageUrl = data.tripPlan
        .expand((d) => d.places)
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .map((p) => p.imageUrl!)
        .firstOrNull;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          // ── SCROLLABLE BODY ───────────────────
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── HERO IMAGE + FLOATING TOP BAR ──
                SliverToBoxAdapter(
                  child: _HeroWithTopBar(
                    heroImageUrl: heroImageUrl,
                    theme: theme,
                    scheme: scheme,
                    isDark: isDark,
                    onBack: () => NavigationUtils.pop(context),
                  ),
                ),

                // ── CITY INFO (badge + name + summary) ──
                SliverToBoxAdapter(
                  child: _CityInfoSection(
                    city: data.city ?? 'Your Destination',
                    summary: data.summary,
                    theme: theme,
                    scheme: scheme,
                  ),
                ),

                // ── DAY PLAN CARDS ──────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final day = data.tripPlan[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DayPlanCard(
                          day: day,
                          isExpanded: _expandedIndex == i,
                          onTap: () => setState(() => _expandedIndex = i),
                          theme: theme,
                          scheme: scheme,
                        ),
                      );
                    }, childCount: data.tripPlan.length),
                  ),
                ),

                // ── WEATHER CARD ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _WeatherCard(
                      city: data.city ?? '',
                      theme: theme,
                      scheme: scheme,
                    ),
                  ),
                ),

                // ── TRAVEL GUIDE CARD ───────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: _TravelGuideCard(
                      city: data.city ?? 'your destination',
                      theme: theme,
                      scheme: scheme,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM NAVIGATION BAR ─────────────
          NavigationBar(
            selectedIndex: _selectedNav,
            onDestinationSelected: (i) {
              setState(() => _selectedNav = i);
              if (i == 0) {
                NavigationUtils.pushReplacementNamed(context, AppRoutes.home);
              }
              if (i == 2) {
                NavigationUtils.pushNamed(context, AppRoutes.expenseDetail);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Itinerary',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Expenses',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HERO IMAGE + FLOATING TOP BAR
//  Full-width image at top; pill top bar floats
//  over it using a Stack.
// ─────────────────────────────────────────────

class _HeroWithTopBar extends StatelessWidget {
  const _HeroWithTopBar({
    required this.heroImageUrl,
    required this.theme,
    required this.scheme,
    required this.isDark,
    required this.onBack,
  });

  final String? heroImageUrl;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // ── FULL-WIDTH HERO IMAGE ──────────────
          Positioned.fill(
            child: heroImageUrl != null && heroImageUrl!.isNotEmpty
                ? PlaceImage(imageUrl: heroImageUrl!, fit: BoxFit.cover)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withOpacity(0.7),
                          scheme.primaryContainer,
                        ],
                      ),
                    ),
                  ),
          ),

          // ── BOTTOM FADE (image → surface) ──────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, scheme.surface],
                ),
              ),
            ),
          ),

          // ── FLOATING PILL TOP BAR ──────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161E28).withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: onBack,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: scheme.onSurface,
                    ),
                  ),
                  // Logo + brand
                  Icon(
                    Icons.flight_takeoff_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    AppConstants.topTittle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 17,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CITY INFO SECTION
//  Badge · Large city name · Summary text
// ─────────────────────────────────────────────

class _CityInfoSection extends StatelessWidget {
  const _CityInfoSection({
    required this.city,
    required this.summary,
    required this.theme,
    required this.scheme,
  });

  final String city;
  final String? summary;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: scheme.primary.withOpacity(0.25)),
            ),
            child: Text(
              'SUMMER EXPEDITION 2024',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // City name — large & bold
          Text(
            city,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),

          // Summary
          if (summary != null && summary!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary!.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DAY PLAN CARD  (accordion)
// ─────────────────────────────────────────────

class _DayPlanCard extends StatelessWidget {
  const _DayPlanCard({
    required this.day,
    required this.isExpanded,
    required this.onTap,
    required this.theme,
    required this.scheme,
  });

  final TripDayPlanModel day;
  final bool isExpanded;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme scheme;

  String get _subtitle {
    final parts = <String>[];
    if (day.description != null && day.description!.trim().isNotEmpty) {
      final first = day.description!
          .trim()
          .split(RegExp(r'[.\n]'))
          .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
      if (first.trim().isNotEmpty) parts.add(first.trim());
    }
    final stopCount = day.places.length;
    parts.add('$stopCount Stop${stopCount == 1 ? '' : 's'}');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final dayNum = (day.day ?? 0).toString().padLeft(2, '0');
    final title = day.theme ?? 'Day ${day.day}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? scheme.primary.withOpacity(0.22)
              : scheme.outlineVariant.withOpacity(0.45),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ROW ───────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day number
                    Text(
                      dayNum,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isExpanded
                            ? scheme.primary
                            : scheme.onSurface.withOpacity(0.25),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          if (_subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Chevron icon
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                // ── EXPANDED PLACE ROWS ──────────
                if (isExpanded && day.places.isNotEmpty) ...[
                  Divider(
                    height: 22,
                    thickness: 0.6,
                    color: scheme.outlineVariant.withOpacity(0.45),
                  ),
                  ...day.places
                      .take(3)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (e) => _PlaceRow(
                          place: e.value,
                          index: e.key,
                          theme: theme,
                          scheme: scheme,
                          isLast:
                              e.key ==
                              (day.places.length > 3
                                  ? 2
                                  : day.places.length - 1),
                        ),
                      ),
                  if (day.places.length > 3) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '+ ${day.places.length - 3} more stops',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PLACE ROW  (inside expanded day card)
//  Layout: dot + connector | thumbnail | text
// ─────────────────────────────────────────────

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.index,
    required this.theme,
    required this.scheme,
    required this.isLast,
  });

  final PlaceModel place;
  final int index;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isLast;

  String get _timeLabel {
    if (place.openingHours != null && place.openingHours!.isNotEmpty) {
      return place.openingHours!;
    }
    if (place.bestTime != null && place.bestTime!.isNotEmpty) {
      return place.bestTime!;
    }
    if (place.duration != null && place.duration! > 0) {
      return '${place.duration} min';
    }
    const times = ['09:00 AM', '11:00 AM', '01:30 PM', '03:30 PM', '06:00 PM'];
    return times[index % times.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = place.name ?? 'Place';
    final desc = place.description ?? place.category ?? '';
    final hasImage = place.imageUrl != null && place.imageUrl!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TIMELINE INDICATOR ───────────────
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                    border: Border.all(
                      color: scheme.primary.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 62,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── PLACE THUMBNAIL ──────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 62,
              width: 62,
              child: hasImage
                  ? PlaceImage(imageUrl: place.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.place_rounded,
                        color: scheme.primary,
                        size: 26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // ── PLACE INFO ───────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                // Time label
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _timeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WEATHER CARD
// ─────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.city,
    required this.theme,
    required this.scheme,
  });

  final String city;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Weather Forecast',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Perfect conditions for outdoor exploration. '
            'Mild temperatures with clear skies expected all week.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Temp + sun icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '24°C',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${city.toUpperCase()}, JP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              // Sun icon with warm glow
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  size: 32,
                  color: Color(0xFFE8A000),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TRAVEL GUIDE CARD
// ─────────────────────────────────────────────

class _TravelGuideCard extends StatelessWidget {
  const _TravelGuideCard({
    required this.city,
    required this.theme,
    required this.scheme,
  });

  final String city;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        // Dark teal matching the design
        color: const Color(0xFF17395A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          // Icon with frosted circle
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            'Travel Guide',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle using city name
          Text(
            'Download the offline ${city.isNotEmpty ? city : 'destination'} '
            'navigation pack.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.78),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF17395A),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: 0.1,
                ),
              ),
              child: const Text('Download Pack'),
            ),
          ),
        ],
      ),
    );
  }
}
