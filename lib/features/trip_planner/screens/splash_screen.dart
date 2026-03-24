import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _planeController;
  late Animation<double> _fadeScale;
  late Animation<double> _planeOffset;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeScale = Tween<double>(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: Curves.easeOutCubic),
    ).animate(_fadeController);

    // Plane moves bottom to top – smooth, longer duration
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _planeOffset = Tween<double>(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: Curves.easeOut),
    ).animate(_planeController);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _planeController.forward();
    });

    // When plane reaches top, show next page with slider transition
    _planeController.addStatusListener(_onPlaneStatus);
  }

  void _navigateToHomeWithSlider() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        settings: const RouteSettings(name: AppRoutes.home),
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          final slideTween = Tween(
            begin: const Offset(0.0, 0.08),
            end: Offset.zero,
          ).chain(CurveTween(curve: curve));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(slideTween),
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
    _planeController.removeStatusListener(_onPlaneStatus);
    _fadeController.dispose();
    _planeController.dispose();
    super.dispose();
  }

  void _onPlaneStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _navigateToHomeWithSlider();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _planeOffset,
          builder: (context, child) {
            // Gentle overall fade in last 15% of plane journey
            final endFade = ((_planeOffset.value - 0.85) / 0.15).clamp(0.0, 1.0);
            return Opacity(
              opacity: 1.0 - endFade * 0.95,
              child: child,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(context),
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradientMeshPainter(),
                ),
              ),
              // Title at top center (fades in, then fades out as plane reaches top)
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: Listenable.merge([_fadeScale, _planeOffset]),
                    builder: (context, child) {
                      final fadeIn = _fadeScale.value.clamp(0.0, 1.0);
                      final fadeOut = (1.0 - ((_planeOffset.value - 0.5) / 0.5).clamp(0.0, 1.0));
                      final opacity = fadeIn * fadeOut;
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: 0.85 + 0.15 * _fadeScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.92),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your journey starts here',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
            // Airplane: bottom to top, bigger size
            AnimatedBuilder(
              animation: _planeOffset,
              builder: (context, child) {
                final y = size.height * (1.2 - 1.2 * _planeOffset.value);
                return Positioned(
                  left: 0,
                  right: 0,
                  top: y - 70,
                  child: Center(
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  size: 68,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C5C),
            Color(0xFF1B6B7A),
            Color(0xFF228B8B),
            Color(0xFF2D9D8B),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
    );
  }
}

class _GradientMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.2, 0.3),
        radius: size.longestSide * 0.7,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
