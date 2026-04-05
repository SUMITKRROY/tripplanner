import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _timelineDuration = Duration(seconds: 5);
  late final AnimationController _timelineController;
  late final Animation<double> _arrowRotationTurns;
  late final Animation<double> _portalExpansion;
  late final Animation<double> _whiteCoverOpacity;
  late final Animation<double> _messageOpacity;

  @override
  void initState() {
    super.initState();

    _timelineController = AnimationController(
      vsync: this,
      duration: _timelineDuration,
    );
    _arrowRotationTurns = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOutSine),
      ),
    );
    _portalExpansion = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOutCubicEmphasized),
      ),
    );
    _whiteCoverOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.8, 0.88, curve: Curves.easeOut),
      ),
    );
    _messageOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: const Interval(0.82, 0.94, curve: Curves.easeOutCubic),
      ),
    );

    _timelineController.addStatusListener(_onTimelineStatus);
    _timelineController.forward();
  }

  void _navigateToHomeWithCenterReveal() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        settings: const RouteSettings(name: AppRoutes.home),
        transitionDuration: const Duration(milliseconds: 1000),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          final scaleTween = Tween<double>(begin: 0.94, end: 1.0).chain(
            CurveTween(curve: curve),
          );
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          );
          return ScaleTransition(
            alignment: Alignment.center,
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timelineController.removeStatusListener(_onTimelineStatus);
    _timelineController.dispose();
    super.dispose();
  }

  void _onTimelineStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _navigateToHomeWithCenterReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _timelineController,
        builder: (context, _) {
          final timeline = _timelineController.value;
          final glowPulse = (timeline <= 0.4)
              ? (0.4 + 0.6 * Curves.easeOutCubic.transform(timeline / 0.4))
              : 1.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(context),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHigh.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.25 + 0.25 * glowPulse),
                              blurRadius: 16 + 28 * glowPulse,
                              spreadRadius: 1 + 6 * glowPulse,
                            ),
                          ],
                        ),
                        child: RotationTransition(
                          turns: _arrowRotationTurns,
                          child: Icon(
                            Icons.navigation_rounded,
                            size: 50,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: textTheme.displaySmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'YOUR JOURNEY BEGINS',
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.9),
                          letterSpacing: 3.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _PortalExpansionPainter(
                          progress: _portalExpansion.value,
                          color: colors.surface,
                        ),
                      ),
                      Opacity(
                        opacity: _whiteCoverOpacity.value,
                        child: ColoredBox(color: colors.surfaceBright),
                      ),
                      Center(
                        child: Opacity(
                          opacity: _messageOpacity.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'find your best',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    colors.primary,
                                    colors.tertiary,
                                    colors.primaryContainer,
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'destination',
                                  style: textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.surface,
                colors.surfaceContainer,
                colors.surfaceContainerHigh,
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: _HorizonPainter(
            baseColor: colors.surfaceContainerHighest,
            ridgeColor: colors.primary.withValues(alpha: 0.34),
            mistColor: colors.surfaceBright.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _PortalExpansionPainter extends CustomPainter {
  const _PortalExpansionPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final radius = lerpDouble(52, maxRadius * 1.08, progress)!;
    final paint = Paint()..color = color.withValues(alpha: 0.96);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PortalExpansionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _HorizonPainter extends CustomPainter {
  const _HorizonPainter({
    required this.baseColor,
    required this.ridgeColor,
    required this.mistColor,
  });

  final Color baseColor;
  final Color ridgeColor;
  final Color mistColor;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.62;

    final mountainBack = Paint()
      ..color = baseColor.withValues(alpha: 0.9);
    final backPath = Path()
      ..moveTo(0, horizonY + 40)
      ..lineTo(size.width * 0.18, horizonY - 20)
      ..lineTo(size.width * 0.34, horizonY + 24)
      ..lineTo(size.width * 0.54, horizonY - 36)
      ..lineTo(size.width * 0.76, horizonY + 28)
      ..lineTo(size.width, horizonY - 10)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backPath, mountainBack);

    final mountainFront = Paint()
      ..color = ridgeColor.withValues(alpha: 0.88);
    final frontPath = Path()
      ..moveTo(0, horizonY + 90)
      ..lineTo(size.width * 0.12, horizonY + 10)
      ..lineTo(size.width * 0.28, horizonY + 70)
      ..lineTo(size.width * 0.44, horizonY - 12)
      ..lineTo(size.width * 0.62, horizonY + 76)
      ..lineTo(size.width * 0.78, horizonY + 18)
      ..lineTo(size.width, horizonY + 96)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontPath, mountainFront);

    final mist = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          mistColor,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, horizonY - 40, size.width, 220));
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 40, size.width, 220),
      mist,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
