import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';

/// Shown after trip generation succeeds — same visual language as the analyzing
/// screen, with completed tasks and a path to the full itinerary.
class TripAnalysisSuccessScreen extends StatelessWidget {
  const TripAnalysisSuccessScreen({super.key});

  static const int _navItinerary = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<TripPlannerBloc, TripPlannerState>(
      builder: (context, state) {
        if (state is! TripPlannerSuccess) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.sp6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No trip data here.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.sp4),
                    FilledButton(
                      onPressed: () => NavigationUtils.pushReplacementNamed(
                        context,
                        AppRoutes.home,
                      ),
                      child: const Text('Back to home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = state.data;
        final summary = (data.summary != null && data.summary!.trim().isNotEmpty)
            ? data.summary!.trim()
            : 'Your personalized itinerary is ready. Open the full plan to explore every stop.';

        return Scaffold(
          backgroundColor: scheme.surface,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.surface,
                  scheme.surfaceContainerLow,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.sp4,
                        AppTheme.sp3,
                        AppTheme.sp4,
                        AppTheme.sp4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SuccessHeader(scheme: scheme, theme: theme),
                          const SizedBox(height: AppTheme.sp8),
                          _SuccessRing(scheme: scheme),
                          const SizedBox(height: AppTheme.sp6),
                          Text(
                            'Your perfect trip is ready',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppTheme.sp3),
                          Text(
                            summary,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          if (data.city != null) ...[
                            const SizedBox(height: AppTheme.sp4),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppTheme.sp2,
                              runSpacing: AppTheme.sp2,
                              children: [
                                _MetaChip(
                                  icon: Icons.place_rounded,
                                  label: data.city!,
                                  scheme: scheme,
                                  theme: theme,
                                ),
                                if (data.days != null)
                                  _MetaChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: '${data.days} days',
                                    scheme: scheme,
                                    theme: theme,
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppTheme.sp8),
                          _CompletedTaskCard(
                            scheme: scheme,
                            theme: theme,
                            icon: Icons.map_rounded,
                            title: 'Mapping Geographic Preferences',
                          ),
                          const SizedBox(height: AppTheme.sp3),
                          _CompletedTaskCard(
                            scheme: scheme,
                            theme: theme,
                            icon: Icons.bed_rounded,
                            title: 'Sourcing Boutique Accommodations',
                          ),
                          const SizedBox(height: AppTheme.sp3),
                          _CompletedTaskCard(
                            scheme: scheme,
                            theme: theme,
                            icon: Icons.restaurant_rounded,
                            title: 'Curating Culinary Experiences',
                          ),
                          const SizedBox(height: AppTheme.sp6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                              gradient: theme.brightness == Brightness.dark
                                  ? AppTheme.darkPrimaryButtonGradient
                                  : AppTheme.lightPrimaryButtonGradient,
                              boxShadow: theme.brightness == Brightness.dark
                                  ? AppTheme.darkPrimaryGlow
                                  : AppTheme.lightAquaGlow,
                            ),
                            child: FilledButton(
                              onPressed: () {
                                NavigationUtils.pushReplacementNamed(
                                  context,
                                  AppRoutes.tripResult,
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_rounded, size: 22),
                                  SizedBox(width: AppTheme.sp2),
                                  Text('View full itinerary'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.sp4),
                        ],
                      ),
                    ),
                  ),
                  _SuccessBottomNav(
                    selectedIndex: _navItinerary,
                    onTap: (index) {
                      if (index == _navItinerary) return;
                      NavigationUtils.pushReplacementNamed(
                        context,
                        AppRoutes.home,
                      );
                    },
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

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({
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

class _SuccessRing extends StatelessWidget {
  const _SuccessRing({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 168,
        height: 168,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: 1,
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
                color: scheme.surfaceContainerLowest,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 28,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 36,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({
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
        border: Border.all(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
        ),
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
              color: scheme.primary,
            ),
            child: Icon(
              icon,
              color: scheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.sp3),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 26,
            color: scheme.primary,
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp3,
        vertical: AppTheme.sp1,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Explore · Itinerary · Expenses (matches reference — Itinerary active).
class _SuccessBottomNav extends StatelessWidget {
  const _SuccessBottomNav({
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
