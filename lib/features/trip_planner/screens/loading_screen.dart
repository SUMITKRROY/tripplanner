import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';

/// Full-screen sequential loading screen.
/// Three tasks animate in one-by-one: slide-in → ring fills → tick pops.
/// Navigates to [AppRoutes.tripAnalysisSuccess] once animation + BLoC both done.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  // ── Master controller (total 7.8 s split into 3 equal phases) ─────────────
  late final AnimationController _seq;

  bool _animDone = false;
  bool _stateDone = false;

  // ── Per-step animations ───────────────────────────────────────────────────
  // Step 1  → interval 0.00–0.33
  late final Animation<double> _fade1;
  late final Animation<Offset> _slide1;
  late final Animation<double> _ring1;
  late final Animation<double> _tick1;

  // Step 2  → interval 0.33–0.66
  late final Animation<double> _fade2;
  late final Animation<Offset> _slide2;
  late final Animation<double> _ring2;
  late final Animation<double> _tick2;

  // Step 3  → interval 0.66–1.00
  late final Animation<double> _fade3;
  late final Animation<Offset> _slide3;
  late final Animation<double> _ring3;
  late final Animation<double> _tick3;

  // ── Overall UI fade-in ────────────────────────────────────────────────────
  late final Animation<double> _uiFade;

  // ── Helper ────────────────────────────────────────────────────────────────
  CurvedAnimation _interval(double s, double e, Curve c) =>
      CurvedAnimation(parent: _seq, curve: Interval(s, e, curve: c));

  @override
  void initState() {
    super.initState();

    _seq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7800),
    );

    // Overall fade-in
    _uiFade = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.00, 0.06, Curves.easeOut));

    // ── Step 1 ──────────────────────────────────────────────────────────────
    _fade1 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.00, 0.07, Curves.easeOut));
    _slide1 = Tween<Offset>(
      begin: const Offset(0.30, 0),
      end: Offset.zero,
    ).animate(_interval(0.00, 0.10, Curves.easeOutCubic));
    _ring1 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.06, 0.27, Curves.easeInOut));
    _tick1 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.27, 0.33, Curves.elasticOut));

    // ── Step 2 ──────────────────────────────────────────────────────────────
    _fade2 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.33, 0.40, Curves.easeOut));
    _slide2 = Tween<Offset>(
      begin: const Offset(0.30, 0),
      end: Offset.zero,
    ).animate(_interval(0.33, 0.43, Curves.easeOutCubic));
    _ring2 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.39, 0.61, Curves.easeInOut));
    _tick2 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.61, 0.66, Curves.elasticOut));

    // ── Step 3 ──────────────────────────────────────────────────────────────
    _fade3 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.66, 0.73, Curves.easeOut));
    _slide3 = Tween<Offset>(
      begin: const Offset(0.30, 0),
      end: Offset.zero,
    ).animate(_interval(0.66, 0.76, Curves.easeOutCubic));
    _ring3 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.72, 0.94, Curves.easeInOut));
    _tick3 = Tween<double>(begin: 0, end: 1)
        .animate(_interval(0.94, 1.00, Curves.elasticOut));

    _seq.forward();
    _seq.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animDone = true;
        _tryNavigate();
      }
    });
  }

  void _tryNavigate() {
    if (_animDone && _stateDone && mounted) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          // Skips the success screen — goes directly to the itinerary screen.
          // Replace AppRoutes.itinerary with your actual next route if different.
          NavigationUtils.pushReplacementNamed(
            context,
            AppRoutes.tripResult,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _seq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<TripPlannerBloc, TripPlannerState>(
      listener: (ctx, state) {
        if (state is TripPlannerSuccess) {
          _stateDone = true;
          _tryNavigate();
        }
        if (state is TripPlannerFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: scheme.error,
            ),
          );
        }
      },
      builder: (ctx, state) {
        if (state is TripPlannerFailure) {
          return Scaffold(
            body: SafeArea(
              child: _FailureBody(onBack: () => NavigationUtils.pop(context)),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: AnimatedBuilder(
              animation: _uiFade,
              builder: (_, __) => Opacity(
                opacity: _uiFade.value,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────────
                      _LoadingHeader(scheme: scheme, theme: theme),
                      const SizedBox(height: 40),

                      // ── Hero text ──────────────────────────────────────
                      Text(
                        'Crafting your\nperfect trip ✈️',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          height: 1.05,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI is curating hidden gems & optimising your route',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 44),

                      // ── Step cards ─────────────────────────────────────
                      _StepTile(
                        fade: _fade1,
                        slide: _slide1,
                        ring: _ring1,
                        tick: _tick1,
                        stepIndex: 0,
                        seqValue: _seq,
                        icon: Icons.map_rounded,
                        title: 'Mapping Geographic Preferences',
                        subtitle: 'Destinations & optimal routes',
                        scheme: scheme,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _StepTile(
                        fade: _fade2,
                        slide: _slide2,
                        ring: _ring2,
                        tick: _tick2,
                        stepIndex: 1,
                        seqValue: _seq,
                        icon: Icons.bed_rounded,
                        title: 'Sourcing Boutique Accommodations',
                        subtitle: 'Handpicked stays for your style',
                        scheme: scheme,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _StepTile(
                        fade: _fade3,
                        slide: _slide3,
                        ring: _ring3,
                        tick: _tick3,
                        stepIndex: 2,
                        seqValue: _seq,
                        icon: Icons.restaurant_rounded,
                        title: 'Curating Culinary Experiences',
                        subtitle: 'Best local flavors & hidden gems',
                        scheme: scheme,
                        theme: theme,
                      ),

                      const Spacer(),

                      // ── Bottom step dots ────────────────────────────────
                      _StepDots(seq: _seq, scheme: scheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step tile
// ─────────────────────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.fade,
    required this.slide,
    required this.ring,
    required this.tick,
    required this.stepIndex,
    required this.seqValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.scheme,
    required this.theme,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final Animation<double> ring;
  final Animation<double> tick;
  final int stepIndex;
  final Animation<double> seqValue; // used only to know active phase
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([fade, slide, ring, tick]),
      builder: (_, __) {
        final fv = fade.value;
        final rv = ring.value;
        final tv = tick.value;
        final isDone = tv > 0;
        final isActive = rv > 0 && !isDone;

        return FractionalTranslation(
          translation: slide.value,
          child: Opacity(
            opacity: fv,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDone
                    ? scheme.primaryContainer.withValues(alpha: 0.14)
                    : isActive
                    ? scheme.surfaceContainerLow
                    : scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDone
                      ? scheme.primary.withValues(alpha: 0.45)
                      : isActive
                      ? scheme.primary.withValues(alpha: 0.30)
                      : scheme.outlineVariant.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
                    : null,
              ),
              child: Row(
                children: [
                  // ── Ring + centre icon ──────────────────────────────────
                  _RingIndicator(
                    ring: rv,
                    tick: tv,
                    isDone: isDone,
                    isActive: isActive,
                    icon: icon,
                    scheme: scheme,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),

                  // ── Labels ──────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDone || isActive
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right status ────────────────────────────────────────
                  if (isDone)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Transform.scale(
                        scale: tv.clamp(0.0, 1.0),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                      ),
                    )
                  else if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.primary,
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Ring indicator  ( o ……→ O ……→ ✓ )
// ─────────────────────────────────────────────────────────────────────────────

class _RingIndicator extends StatelessWidget {
  const _RingIndicator({
    required this.ring,
    required this.tick,
    required this.isDone,
    required this.isActive,
    required this.icon,
    required this.scheme,
    required this.theme,
  });

  final double ring;
  final double tick;
  final bool isDone;
  final bool isActive;
  final IconData icon;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Progress ring ───────────────────────────────────────────────
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: isDone ? 1.0 : ring,
              strokeWidth: 3,
              backgroundColor: scheme.outlineVariant.withValues(alpha: 0.25),
              color: scheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),

          // ── Inner circle ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? scheme.primary
                  : isActive
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              boxShadow: isDone
                  ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
                  : null,
            ),
          ),

          // ── Centre content: icon → check ─────────────────────────────
          // Task icon (fades out as tick comes in)
          Opacity(
            opacity: (1 - tick).clamp(0.0, 1.0),
            child: Icon(
              icon,
              color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              size: 20,
            ),
          ),

          // Tick (scales + fades in)
          if (isDone)
            Transform.scale(
              scale: tick.clamp(0.0, 1.0),
              child: Icon(
                Icons.check_rounded,
                color: scheme.onPrimary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom step dots  ( ● — — )  ( ✓ ● — )  ( ✓ ✓ ● )
// ─────────────────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.seq, required this.scheme});

  final AnimationController seq;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: seq,
      builder: (_, __) {
        final p = seq.value;
        // active phase: 0 = first third, 1 = second, 2 = third
        final activePhase = p < 0.33 ? 0 : p < 0.66 ? 1 : 2;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = i == activePhase;
            final isDone = i < activePhase;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDone || isActive
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets (header, failure body)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.lightCardShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff_rounded,
              color: scheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'TripPlanner',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person_rounded,
                size: 17, color: scheme.onPrimaryContainer),
          ),
        ],
      ),
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
            Icon(Icons.error_outline_rounded, size: 64, color: scheme.error),
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