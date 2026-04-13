import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/trip_pill_top_bar.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';
import '../models/generate_trip_response_model.dart';
import 'gallery_screen.dart';
import '../widgets/place_category_visual.dart';
import '../widgets/place_image.dart';
import 'place_detail_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS  (self-contained, no AppTheme)
// ─────────────────────────────────────────────

abstract final class _T {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s6 = 24;
  static const double s8 = 32;

  static const double rSm = 8;
  static const double rMd = 14;
  static const double rLg = 20;
  static const double rFull = 50;

  static List<BoxShadow> lightCard = const [
    BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 3)),
  ];
  static List<BoxShadow> darkCard = const [
    BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 3)),
  ];

  static List<BoxShadow> primaryGlow(Color c) => [
    BoxShadow(
      color: c.withOpacity(0.35),
      blurRadius: 22,
      offset: const Offset(0, 6),
    ),
  ];
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────

String _formatBudget(int n) {
  if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(1)}Cr';
  if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)}K';
  return '₹$n';
}

String _footerLabel(GenerateTripResponseModel data) {
  final g = data.generatedAt;
  return (g != null && g.isNotEmpty)
      ? 'Plan updated · Editable anytime'
      : 'Plan generated · Editable anytime';
}

TripDayPlanModel? _dayContainingPlace(
  List<TripDayPlanModel> days,
  PlaceModel target,
) {
  for (final d in days) {
    for (final p in d.places) {
      if (identical(p, target)) return d;
      final a = p.name ?? '';
      final b = target.name ?? '';
      if (a.isNotEmpty && a == b) return d;
    }
  }
  return null;
}

String _badgeLabel(String title) {
  final t = title.trim();
  if (t.length <= 18) return t.toUpperCase();
  return '${t.substring(0, 15)}…'.toUpperCase();
}

// ─────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────

class TripResultScreen extends StatelessWidget {
  const TripResultScreen({super.key, this.showPillTopBar = true});

  /// When false (e.g. inside [TripDashboardScreen]), the shell provides the bar.
  final bool showPillTopBar;

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
            body: const Center(
              child: Text('No trip data. Plan a trip from the home screen.'),
            ),
          );
        }
        return _TripPlanContent(
          data: state.data,
          showPillTopBar: showPillTopBar,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  CONTENT SHELL
// ─────────────────────────────────────────────

class _TripPlanContent extends StatefulWidget {
  const _TripPlanContent({
    required this.data,
    required this.showPillTopBar,
  });
  final GenerateTripResponseModel data;
  final bool showPillTopBar;

  @override
  State<_TripPlanContent> createState() => _TripPlanContentState();
}

class _TripPlanContentState extends State<_TripPlanContent>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final allPlaces = data.tripPlan.expand((d) => d.places).toList();

    final heroImageUrl = allPlaces
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .map((p) => p.imageUrl!)
        .firstOrNull;

    final highlights = allPlaces
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .take(8)
        .toList();
    final galleryImages = allPlaces
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .map((p) => p.imageUrl!)
        .toSet()
        .toList();

    final city = data.city ?? 'Your destination';
    final budgetLabel = data.expenses?.total != null
        ? _formatBudget(data.expenses!.total!)
        : '—';

    final shellTopGap = !widget.showPillTopBar ? 8.0 + 52.0 : 0.0;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (widget.showPillTopBar)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(_T.s4, _T.s3, _T.s4, 0),
                    child: TripPillTopBar(
                      showSearch: true,
                      onSearch: () {},
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: SizedBox(height: shellTopGap)),

              // ── HERO CARD ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(_T.s4),
                  child: _HeroCard(
                    city: city,
                    summary: data.summary,
                    heroImageUrl: heroImageUrl,
                    days: data.days ?? 0,
                    persons: data.persons ?? 0,
                    budgetLabel: budgetLabel,
                    theme: theme,
                    scheme: scheme,
                  ),
                ),
              ),

              // ── TRIP HIGHLIGHTS HEADER ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_T.s4, 0, _T.s4, _T.s2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trip Highlights',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: _T.s1),
                            Text(
                              'The must-see moments of your journey',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  GalleryScreen(imageUrls: galleryImages),
                            ),
                          );
                        },
                        child: Text(
                          'Explore\nGallery',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── HIGHLIGHTS GALLERY ─────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 215,
                  child: highlights.isEmpty
                      ? Center(
                          child: Text(
                            'Places will appear here when available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _T.s4,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: highlights.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: _T.s3),
                          itemBuilder: (ctx, i) => _HighlightCard(
                            place: highlights[i],
                            city: data.city,
                            day: _dayContainingPlace(data.tripPlan, highlights[i]),
                            theme: theme,
                            scheme: scheme,
                          ),
                        ),
                ),
              ),

              // ── ITINERARY PREVIEW HEADER ───────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _T.s4,
                    _T.s6,
                    _T.s4,
                    _T.s2,
                  ),
                  child: Text(
                    'Itinerary Preview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // ── DAY CARDS ─────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final isLast = i == data.tripPlan.length - 1;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      _T.s4,
                      0,
                      _T.s4,
                      isLast ? 0 : _T.s3,
                    ),
                    child: _DayCard(
                      day: data.tripPlan[i],
                      index: i,
                      city: data.city,
                      theme: theme,
                      scheme: scheme,
                    ),
                  );
                }, childCount: data.tripPlan.length),
              ),

              // ── FOOTER CTA ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _T.s4,
                    _T.s6,
                    _T.s4,
                    _T.s2,
                  ),
                  child: _FooterSection(
                    data: data,
                    theme: theme,
                    scheme: scheme,
                    onViewFullPlan: () => NavigationUtils.pushNamed(
                      context,
                      AppRoutes.viewFullPlan,
                    ),
                    onExpenses: () => NavigationUtils.pushNamed(
                      context,
                      AppRoutes.expenseDetail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}

// ─────────────────────────────────────────────
//  HERO CARD
// ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.city,
    required this.summary,
    required this.heroImageUrl,
    required this.days,
    required this.persons,
    required this.budgetLabel,
    required this.theme,
    required this.scheme,
  });

  final String city;
  final String? summary;
  final String? heroImageUrl;
  final int days;
  final int persons;
  final String budgetLabel;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final desc = (summary != null && summary!.trim().isNotEmpty)
        ? summary!.trim()
        : 'Your personalized route blends must-see sights with local gems.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Stack(
        children: [
          // Background image
          SizedBox(
            height: 320,
            width: double.infinity,
            child: heroImageUrl != null
                ? PlaceImage(imageUrl: heroImageUrl!, fit: BoxFit.cover)
                : ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 64,
                      color: scheme.onSurfaceVariant.withOpacity(0.35),
                    ),
                  ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
          ),

          // "Ready for departure" badge
          Positioned(
            left: _T.s4,
            right: _T.s4,
            top: _T.s4,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _T.s3,
                  vertical: _T.s1 + 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(_T.rFull),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4FE86B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'READY FOR DEPARTURE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom content
          Positioned(
            left: _T.s4,
            right: _T.s4,
            bottom: _T.s4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(text: 'Trip plan ready: '),
                      TextSpan(
                        text: city,
                        style: TextStyle(
                          color: scheme.primaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _T.s2),
                Text(
                  desc,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: _T.s4),
                Row(
                  children: [
                    Expanded(
                      child: _HeroChip(icon: Icons.place_rounded, label: city),
                    ),
                    const SizedBox(width: _T.s2),
                    Expanded(
                      child: _HeroChip(
                        icon: Icons.calendar_today_rounded,
                        label: days > 0 ? '$days Days' : '—',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _T.s2),
                Row(
                  children: [
                    Expanded(
                      child: _HeroChip(
                        icon: Icons.people_alt_rounded,
                        label: persons > 0
                            ? '$persons Person${persons == 1 ? '' : 's'}'
                            : '—',
                      ),
                    ),
                    const SizedBox(width: _T.s2),
                    Expanded(
                      child: _HeroChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: budgetLabel,
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _T.s3, vertical: _T.s2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(_T.rSm),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HIGHLIGHT CARD
// ─────────────────────────────────────────────

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.place,
    this.city,
    this.day,
    required this.theme,
    required this.scheme,
  });

  final PlaceModel place;
  final String? city;
  final TripDayPlanModel? day;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final name = place.name ?? 'Place';
    final sub = (place.category != null && place.category!.isNotEmpty)
        ? place.category!
        : 'Highlight';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlaceDetailScreen(
                place: place,
                city: city,
                day: day,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(_T.rMd),
        child: SizedBox(
          width: 158,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(_T.rMd),
                child: Stack(
                  children: [
                    PlaceImage(
                      imageUrl: place.imageUrl!,
                      height: 118,
                      width: 158,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: 15,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _T.s2),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DAY CARD
// ─────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.index,
    this.city,
    required this.theme,
    required this.scheme,
  });

  final TripDayPlanModel day;
  final int index;
  final String? city;
  final ThemeData theme;
  final ColorScheme scheme;

  static const _icons = [
    Icons.bolt_rounded,
    Icons.account_balance_rounded,
    Icons.park_rounded,
    Icons.camera_alt_rounded,
    Icons.restaurant_rounded,
    Icons.directions_walk_rounded,
  ];

  static List<({PlaceModel? place, String text})> _previewLines(
      TripDayPlanModel day) {
    final out = <({PlaceModel? place, String text})>[];
    for (final p in day.places) {
      if (out.length >= 3) break;
      final label = (p.name ?? p.description ?? '').trim();
      if (label.isEmpty) continue;
      out.add((place: p, text: label));
    }
    if (out.isEmpty &&
        day.description != null &&
        day.description!.trim().isNotEmpty) {
      for (final raw in day.description!.split(RegExp(r'[.\n]'))) {
        if (out.length >= 3) break;
        final line = raw.trim();
        if (line.isEmpty) continue;
        out.add((place: null, text: line));
      }
    }
    while (out.length < 3) {
      out.add((place: null, text: 'Explore local highlights'));
    }
    return out.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final n = day.day ?? (index + 1);
    final title = day.theme ?? 'Day $n';
    final icon = _icons[index % _icons.length];

    final previewLines = _previewLines(day);

    PlaceModel? primaryPlace;
    for (final p in day.places) {
      if ((p.name ?? p.description ?? '').trim().isNotEmpty) {
        primaryPlace = p;
        break;
      }
    }
    final Widget trailingIcon;
    if (primaryPlace != null) {
      final catStyle =
          placeCategoryStyle(primaryPlace.category ?? '');
      if (catStyle.imageAsset != null) {
        trailingIcon = Image.asset(
          catStyle.imageAsset!,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        );
      } else {
        trailingIcon = Icon(icon, color: scheme.primary, size: 26);
      }
    } else {
      trailingIcon = Icon(icon, color: scheme.primary, size: 26);
    }

    return Container(
      padding: const EdgeInsets.all(_T.s4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_T.rMd),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY ${n.toString().padLeft(2, '0')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: _T.s1),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              trailingIcon,
            ],
          ),
          const SizedBox(height: _T.s3),
          ...previewLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: _T.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Expanded(
                    child: line.place != null
                        ? GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PlaceDetailScreen(
                                    place: line.place!,
                                    city: city,
                                    day: day,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              line.text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    scheme.primary.withOpacity(0.4),
                              ),
                            ),
                          )
                        : Text(
                            line.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _T.s2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: _T.s3,
              vertical: _T.s1,
            ),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(_T.rFull),
            ),
            child: Text(
              _badgeLabel(title),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FOOTER SECTION
// ─────────────────────────────────────────────

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.data,
    required this.theme,
    required this.scheme,
    required this.onViewFullPlan,
    required this.onExpenses,
  });

  final GenerateTripResponseModel data;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onViewFullPlan;
  final VoidCallback onExpenses;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        // Gradient CTA
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_T.rFull),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0095E8), const Color(0xFF00C2F0)]
                  : [const Color(0xFF0077CC), const Color(0xFF00B4E6)],
            ),
            boxShadow: _T.primaryGlow(scheme.primary),
          ),
          child: FilledButton(
            onPressed: onViewFullPlan,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'View full plan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: _T.s3),

        Text(
          _footerLabel(data),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: _T.s2),

        TextButton.icon(
          onPressed: onExpenses,
          icon: Icon(
            Icons.receipt_long_rounded,
            size: 17,
            color: scheme.primary,
          ),
          label: Text(
            'Day-wise expense breakdown',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: _T.s8),
      ],
    );
  }
}
