import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';
/// Full-screen “Itinerary” loading state while the AI generates the trip.
/// Route: [AppRoutes.loading] (itinerary generation flow).
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const int _navItinerary = 1;

  late AnimationController _progressController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == _navItinerary) return;
    if (index == 0 || index == 2) {
      NavigationUtils.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<TripPlannerBloc, TripPlannerState>(
      listener: (context, state) {
        if (state is TripPlannerSuccess) {
          NavigationUtils.pushReplacementNamed(
            context,
            AppRoutes.tripAnalysisSuccess,
          );
        }
        if (state is TripPlannerFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: scheme.error,
            ),
          );
        }
      },
      buildWhen: (previous, current) =>
          current is TripPlannerLoading || current is TripPlannerFailure,
      builder: (context, state) {
        final isFailure = state is TripPlannerFailure;

        return Scaffold(
          body: SafeArea(
            child: isFailure
                ? _FailureBody(onBack: () => NavigationUtils.pop(context))
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.sp4,
                            AppTheme.sp3,
                            AppTheme.sp4,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LoadingHeader(scheme: scheme, theme: theme),
                              const SizedBox(height: AppTheme.sp8),
                              _AnalyzingRing(
                                progress: _progressController,
                                pulse: _pulseController,
                                scheme: scheme,
                              ),
                              const SizedBox(height: AppTheme.sp6),
                              Text(
                                'Analyzing your perfect trip...',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: AppTheme.sp3),
                              Text(
                                'Our AI is curating hidden gems and optimizing '
                                'routes for your unique style.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: AppTheme.sp8),
                              _TaskCardActive(
                                scheme: scheme,
                                theme: theme,
                                progress: _progressController,
                              ),
                              const SizedBox(height: AppTheme.sp3),
                              _TaskCardLocked(
                                scheme: scheme,
                                theme: theme,
                                icon: Icons.bed_rounded,
                                title: 'Sourcing Boutique Accommodations',
                              ),
                              const SizedBox(height: AppTheme.sp3),
                              _TaskCardLocked(
                                scheme: scheme,
                                theme: theme,
                                icon: Icons.restaurant_rounded,
                                title: 'Curating Culinary Experiences',
                              ),
                              const SizedBox(height: AppTheme.sp8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: isFailure
              ? null
              : _LoadingBottomNav(
                  selectedIndex: _navItinerary,
                  onTap: _onBottomNavTap,
                ),
        );
      },
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sp8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: scheme.error,
            ),
            const SizedBox(height: AppTheme.sp4),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.sp6),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader({
    required this.scheme,
    required this.theme,
  });

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp4,
        vertical: AppTheme.sp3,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow:
            isDark ? AppTheme.darkCardShadow : AppTheme.lightCardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: AppTheme.sp2),
          Text(
            'TripPlanner',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {},
            icon: Icon(
              Icons.search_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 17,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingRing extends StatelessWidget {
  const _AnalyzingRing({
    required this.progress,
    required this.pulse,
    required this.scheme,
  });

  final Animation<double> progress;
  final Animation<double> pulse;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([progress, pulse]),
      builder: (context, _) {
        final t = (math.sin(progress.value * math.pi * 2) + 1) / 2;
        final ringValue = 0.18 + t * 0.72;
        final scale = 0.92 + pulse.value * 0.08;

        return Center(
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 168,
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: ringValue,
                      strokeWidth: 3.5,
                      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.25),
                      color: scheme.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerLow,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaskCardActive extends StatelessWidget {
  const _TaskCardActive({
    required this.scheme,
    required this.theme,
    required this.progress,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final bar = 0.35 + (math.sin(progress.value * math.pi * 2) + 1) / 2 * 0.4;
        return Container(
          padding: const EdgeInsets.all(AppTheme.sp4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: scheme.primaryContainer, width: 1.5),
            boxShadow: AppTheme.lightAquaGlow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.map_rounded,
                  color: scheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT TASK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sp1),
                    Text(
                      'Mapping Geographic Preferences',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.sp2),
              SizedBox(
                width: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: bar,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCardLocked extends StatelessWidget {
  const _TaskCardLocked({
    required this.scheme,
    required this.theme,
    required this.icon,
    required this.title,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest,
            ),
            child: Icon(
              icon,
              color: scheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.sp3),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

/// Matches home [NavigationBar] order: Explore, Itinerary, Expenses, Profile.
class _LoadingBottomNav extends StatelessWidget {
  const _LoadingBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
    (Icons.event_note_outlined, Icons.event_note_rounded, 'Itinerary'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      destinations: _items
          .map(
            (e) => NavigationDestination(
              icon: Icon(e.$1),
              selectedIcon: Icon(e.$2),
              label: e.$3,
            ),
          )
          .toList(),
    );
  }
}
