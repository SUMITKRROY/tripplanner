import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────
//  SplashScreen  —  Golden Compass edition
//  Navigation kept from original.
//  Aesthetic: warm parchment · compass rose · stamp logo
//  · typewriter name · destination chips · progress bar
// ─────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Master timeline (keeps original nav trigger) ───────
  static const Duration _totalDuration = Duration(milliseconds: 6200);
  late final AnimationController _timeline;

  // ── Compass drawing + needle spin ─────────────────────
  late final Animation<double> _compassDraw;   // rose path 0→1
  late final Animation<double> _compassFade;   // rose opacity
  late final Animation<double> _needleSpin;    // angle rad (big→final)
  late final Animation<double> _needleFade;

  // ── Ink-spread rings (ripple on stamp) ────────────────
  late final AnimationController _inkController;
  late final Animation<double>   _inkRing;

  // ── Logo stamp ────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _ringGlow;    // outer glow after stamp

  // ── Destination chips ─────────────────────────────────
  late final Animation<double> _chipsProgress;  // stagger driven

  // ── App name typewriter ───────────────────────────────
  late final Animation<double> _nameProgress;  // 0→1 drives char count
  late final Animation<double> _nameSlide;
  late final Animation<double> _nameFade;

  // ── Tagline + loading bar ─────────────────────────────
  late final Animation<double> _subFade;
  late final Animation<double> _barProgress;
  late final Animation<double> _barFade;

  // ── Ambient pulse (logo glow, grid shimmer) ───────────
  late final AnimationController _pulseCtrl;

  // ── Destination chip data ──────────────────────────────
  static const List<_ChipData> _chips = [
    _ChipData(label: 'Ram Mandir', icon: Icons.architecture,
        relX: 0.5,  relY: 0.10, offsetX: -72),
    _ChipData(label: 'Goa', icon: Icons.beach_access,
        relX: 0.08, relY: 0.40, offsetX:   0),
    _ChipData(label: 'Jaipur', icon: Icons.castle,
        relX: 0.84, relY: 0.34, offsetX: -12),
    _ChipData(label: 'Ladakh', icon: Icons.terrain,
        relX: 0.5,  relY: 0.80, offsetX: -58),
  ];

  // Typewriter state
  int _visibleChars = 0;
  late final String _appName;

  @override
  void initState() {
    super.initState();
    _appName = AppConstants.appName;
    _setupControllers();
    _setupAnimations();
    _timeline.addStatusListener(_onDone);
    _timeline.addListener(_onTick);
    _timeline.forward();
  }

  // ── Controllers ────────────────────────────────────────
  void _setupControllers() {
    _timeline = AnimationController(vsync: this, duration: _totalDuration);

    _inkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  // ── Animations ─────────────────────────────────────────
  void _setupAnimations() {
    // Compass rose
    _compassDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.0, 0.38, curve: Curves.easeInOutCubic)),
    );
    _compassFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.0, 0.14, curve: Curves.easeOut)),
    );

    // Needle — spins from 5π→0.06π
    _needleSpin = Tween<double>(begin: math.pi * 5, end: math.pi * 0.06).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.07, 0.50, curve: Curves.easeOut)),
    );
    _needleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.07, 0.22, curve: Curves.easeOut)),
    );

    // Ink ripple (triggered at logo appear)
    _inkRing = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _inkController, curve: Curves.easeOut),
    );

    // Logo stamp
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.33, 0.52, curve: _ElasticOutCurve())),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.33, 0.43, curve: Curves.easeOut)),
    );
    _ringGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.45, 0.62, curve: Curves.easeOut)),
    );

    // Chips staggered
    _chipsProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.48, 0.80, curve: Curves.easeOut)),
    );

    // App name typewriter + slide
    _nameProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.54, 0.78, curve: Curves.easeInOutCubic)),
    );
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.54, 0.62, curve: Curves.easeOut)),
    );
    _nameSlide = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.54, 0.68, curve: Curves.easeOutCubic)),
    );

    // Tagline + bar
    _subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.68, 0.80, curve: Curves.easeOut)),
    );
    _barFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.60, 0.70, curve: Curves.easeOut)),
    );
    _barProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timeline,
          curve: const Interval(0.60, 0.96, curve: Curves.easeInOutCubic)),
    );
  }

  // ── Typewriter tick ────────────────────────────────────
  bool _inkFired = false;
  void _onTick() {
    final chars = (_nameProgress.value * _appName.length).floor();
    if (chars != _visibleChars) {
      setState(() => _visibleChars = chars);
    }
    // Fire ink ring when logo fully appears
    if (!_inkFired && _logoOpacity.value > 0.85) {
      _inkFired = true;
      _inkController.forward(from: 0);
    }
  }

  // ── Navigation (kept from original) ───────────────────
  void _navigateToHomeWithCenterReveal() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => const HomeScreen(),
        settings: const RouteSettings(name: AppRoutes.home),
        transitionDuration: const Duration(milliseconds: 1000),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          return ScaleTransition(
            alignment: Alignment.center,
            scale: animation.drive(
              Tween<double>(begin: 0.94, end: 1.0)
                  .chain(CurveTween(curve: curve)),
            ),
            child: FadeTransition(
              opacity: animation.drive(
                Tween<double>(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: curve)),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _onDone(AnimationStatus s) {
    if (s == AnimationStatus.completed && mounted) {
      _navigateToHomeWithCenterReveal();
    }
  }

  @override
  void dispose() {
    _timeline
      ..removeStatusListener(_onDone)
      ..removeListener(_onTick)
      ..dispose();
    _inkController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    // Compass centre: 42% down from top
    final compassCY = size.height * 0.42;
    final compassCX = size.width  * 0.50;
    const compassR  = 88.0;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _timeline, _inkController, _pulseCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [

              // 1 ── Themed parchment-style background ─────
              CustomPaint(
                painter: _ParchmentPainter(
                  scheme: scheme,
                  pulseT: _pulseCtrl.value,
                ),
              ),

              // 2 ── Compass rose (draws itself) ────────────
              CustomPaint(
                painter: _CompassPainter(
                  scheme: scheme,
                  progress:  _compassDraw.value,
                  opacity:   _compassFade.value,
                  centerX:   compassCX,
                  centerY:   compassCY,
                  radius:    compassR,
                ),
              ),

              // 3 ── Needle ─────────────────────────────────
              CustomPaint(
                painter: _NeedlePainter(
                  scheme: scheme,
                  angle:   _needleSpin.value,
                  opacity: _needleFade.value,
                  cx: compassCX,
                  cy: compassCY,
                ),
              ),

              // 4 ── Ink ripple rings ────────────────────────
              CustomPaint(
                painter: _InkRingPainter(
                  scheme: scheme,
                  progress: _inkRing.value,
                  cx: compassCX,
                  cy: compassCY,
                ),
              ),

              // 5 ── Destination chips ───────────────────────
              ..._buildChips(context, size),

              // 6 ── Logo (stamp effect) ─────────────────────
              Positioned(
                left: compassCX - 70,
                top:  compassCY - 80,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow ring
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: 158, height: 158,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary
                                      .withValues(alpha: 0.28 + 0.12 * _pulseCtrl.value),
                                  blurRadius: 36 + 16 * _pulseCtrl.value,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Outer ring border
                        Container(
                          width: 152, height: 152,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.primary
                                  .withValues(alpha: 0.45 * _ringGlow.value),
                              width: 2.0,
                            ),
                          ),
                        ),
                        // Custom travel globe (no asset needed)
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => SizedBox(
                            width: 136, height: 136,
                            child: CustomPaint(
                              painter: _TravelGlobePainter(
                                scheme: scheme,
                                pulseT: _pulseCtrl.value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 7 ── App name + tagline ──────────────────────
              Positioned(
                left: 0, right: 0,
                top: compassCY + 90,
                child: Column(
                  children: [

                    // App name (typewriter)
                    Transform.translate(
                      offset: Offset(0, _nameSlide.value),
                      child: Opacity(
                        opacity: _nameFade.value,
                        child: Text(
                          _appName.length > 0
                              ? _appName.substring(0, _visibleChars.clamp(0, _appName.length))
                              : '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    Opacity(
                      opacity: _subFade.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoldDash(color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'YOUR JOURNEY BEGINS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _GoldDash(color: scheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 8 ── Warm loading bar ────────────────────────
              Positioned(
                bottom: 54,
                left: 0, right: 0,
                child: Center(
                  child: Opacity(
                    opacity: _barFade.value,
                    child: _WarmProgressBar(
                      scheme: scheme,
                      progress: _barProgress.value,
                    ),
                  ),
                ),
              ),

              // 9 ── Vignette ────────────────────────────────
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.88,
                      colors: [
                        Colors.transparent,
                        scheme.scrim.withValues(
                          alpha: scheme.brightness == Brightness.dark
                              ? 0.42
                              : 0.10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Chip builder (staggered elastic pop) ──────────────
  List<Widget> _buildChips(BuildContext context, Size size) {
    final scheme = Theme.of(context).colorScheme;
    return _chips.asMap().entries.map((e) {
      final i = e.key;
      final c = e.value;
      final delay = i * 0.12;
      final t = ((_chipsProgress.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      final sc  = _elasticOut(t);
      final op  = (t * 3).clamp(0.0, 1.0);

      return Positioned(
        left: c.relX * size.width + c.offsetX,
        top:  c.relY * size.height - 18,
        child: Opacity(
          opacity: op,
          child: Transform.scale(
            scale: 0.7 + 0.3 * sc,
            child: _DestinationChip(scheme: scheme, data: c),
          ),
        ),
      );
    }).toList();
  }

  static double _elasticOut(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return math.pow(2, -10 * t) *
        math.sin((t * 10 - 0.75) * math.pi * 2 / 3) + 1;
  }
}

// ─────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────

class _GoldDash extends StatelessWidget {
  const _GoldDash({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 20, height: 1.5,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip({required this.scheme, required this.data});
  final ColorScheme scheme;
  final _ChipData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.surface.withValues(alpha: 0.88),
          scheme.surfaceContainerHighest,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            data.icon,
            size: 14,
            color: Color.lerp(scheme.primary, scheme.onSurface, 0.25)!,
          ),
          const SizedBox(width: 5),
          Text(
            data.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmProgressBar extends StatelessWidget {
  const _WarmProgressBar({required this.scheme, required this.progress});
  final ColorScheme scheme;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, height: 2.5,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primaryContainer, scheme.primary],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.35),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Custom Painters
// ─────────────────────────────────────────────────────────

// ── Parchment background ──────────────────────────────────
class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter({required this.scheme, required this.pulseT});
  final ColorScheme scheme;
  final double pulseT;

  @override
  void paint(Canvas canvas, Size size) {
    final top = Color.lerp(scheme.surface, scheme.primary, 0.04)!;
    final mid = scheme.surfaceContainerLow;
    final bottom = scheme.surfaceContainerHigh;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, mid, bottom],
        ).createShader(Offset.zero & size),
    );

    final gridAlpha = scheme.brightness == Brightness.dark ? 0.10 : 0.06;
    final gridPaint = Paint()
      ..color = scheme.outline.withValues(alpha: gridAlpha)
      ..strokeWidth = 0.8;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 0.55,
          colors: [
            scheme.primary.withValues(alpha: 0.08 + 0.04 * pulseT),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _ParchmentPainter old) =>
      old.pulseT != pulseT || old.scheme != scheme;
}

// ── Compass rose ──────────────────────────────────────────
class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    required this.scheme,
    required this.progress,
    required this.opacity,
    required this.centerX,
    required this.centerY,
    required this.radius,
  });

  final ColorScheme scheme;
  final double progress, opacity, centerX, centerY, radius;

  Color get _accentBold => scheme.primary;
  Color get _accentLight => scheme.primaryContainer;
  Color get _accentFaint => Color.lerp(scheme.primary, scheme.surface, 0.35)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || opacity <= 0) return;
    canvas.save();
    canvas.translate(centerX, centerY);

    final p  = progress;

    // Outer ring (draws clockwise)
    _drawArcProgress(canvas, radius,       p,        _accentFaint.withValues(alpha: opacity * 0.4), 1.8);
    _drawArcProgress(canvas, radius * 0.6, (p-0.1).clamp(0,1), _accentFaint.withValues(alpha: opacity * 0.28), 1.2);

    // Cardinal diamond arrows (appear after 0.5)
    if (p > 0.45) {
      final arrowP = Curves.easeOut.transform((p - 0.45) / 0.55);
      _drawCardinals(canvas, radius, arrowP, opacity);
    }

    // Diagonal tick marks (appear after 0.7)
    if (p > 0.68) {
      final tickP = Curves.easeOut.transform((p - 0.68) / 0.32);
      _drawDiagonalTicks(canvas, radius, tickP, opacity);
    }

    // Decorative inner concentric rings
    if (p > 0.55) {
      final ringP = (p - 0.55) / 0.45;
      canvas.drawCircle(
        Offset.zero, radius * 0.15,
        Paint()
          ..color = _accentBold.withValues(alpha: opacity * 0.5 * ringP)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Centre dot
    if (p > 0.72) {
      canvas.drawCircle(
        Offset.zero, 5,
        Paint()..color = _accentBold.withValues(alpha: opacity * (p - 0.72) / 0.28),
      );
    }

    canvas.restore();
  }

  void _drawArcProgress(
      Canvas canvas, double r, double progress, Color color, double strokeW) {
    if (progress <= 0) return;
    final rect   = Rect.fromCircle(center: Offset.zero, radius: r);
    final sweep  = math.pi * 2 * progress;
    canvas.drawArc(
      rect, -math.pi / 2, sweep, false,
      Paint()
        ..color      = color
        ..style      = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap  = StrokeCap.round,
    );
  }

  void _drawCardinals(
      Canvas canvas, double r, double progress, double globalOpacity) {
    final dirs = <_CardinalDir>[
      _CardinalDir(angle: 0,              label: 'N', isMain: true),
      _CardinalDir(angle: math.pi / 2,    label: 'E', isMain: false),
      _CardinalDir(angle: math.pi,        label: 'S', isMain: false),
      _CardinalDir(angle: 3 * math.pi / 2, label: 'W', isMain: false),
    ];

    for (final d in dirs) {
      canvas.save();
      canvas.rotate(d.angle);

      final tipLen  = d.isMain ? r * 0.94 : r * 0.80;
      final baseW   = 7.0 * progress;
      final baseH   = 7.0 * progress;
      final tip     = -tipLen * progress;

      final path = Path()
        ..moveTo(0, tip)
        ..lineTo(-baseW, -baseH)
        ..lineTo(0, 0)
        ..lineTo(baseW, -baseH)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = (d.isMain ? _accentBold : _accentLight)
              .withValues(alpha: globalOpacity * (d.isMain ? 0.80 : 0.50))
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    }
  }

  void _drawDiagonalTicks(
      Canvas canvas, double r, double progress, double globalOpacity) {
    for (int i = 1; i <= 7; i += 2) {
      canvas.save();
      canvas.rotate(i * math.pi / 4);
      canvas.drawLine(
        Offset(0, -r * 0.62 * progress),
        Offset(0, -r * 0.80 * progress),
        Paint()
          ..color = _accentLight.withValues(alpha: globalOpacity * 0.35)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.progress != progress ||
      old.opacity != opacity ||
      old.scheme != scheme;
}

// ── Compass needle ────────────────────────────────────────
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({
    required this.scheme,
    required this.angle,
    required this.opacity,
    required this.cx,
    required this.cy,
  });
  final ColorScheme scheme;
  final double angle, opacity, cx, cy;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // North (red)
    final north = Path()
      ..moveTo(0, -54)
      ..lineTo(-7.5, 0)
      ..lineTo(0, 9)
      ..lineTo(7.5, 0)
      ..close();
    canvas.drawPath(
      north,
      Paint()
        ..color = scheme.error.withValues(alpha: opacity * 0.88)
        ..style = PaintingStyle.fill,
    );

    // South (tan)
    final south = Path()
      ..moveTo(0, 54)
      ..lineTo(-7.5, 0)
      ..lineTo(0, -9)
      ..lineTo(7.5, 0)
      ..close();
    canvas.drawPath(
      south,
      Paint()
        ..color = scheme.tertiary.withValues(alpha: opacity * 0.55)
        ..style = PaintingStyle.fill,
    );

    // Centre pin
    canvas.drawCircle(
      Offset.zero, 5,
      Paint()..color = scheme.onSurface.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      Offset.zero, 2.5,
      Paint()..color = scheme.surface.withValues(alpha: opacity * 0.7),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) =>
      old.angle != angle ||
      old.opacity != opacity ||
      old.scheme != scheme;
}

// ── Ink spread rings (appear when logo stamps) ─────────────
class _InkRingPainter extends CustomPainter {
  const _InkRingPainter({
    required this.scheme,
    required this.progress,
    required this.cx,
    required this.cy,
  });
  final ColorScheme scheme;
  final double progress, cx, cy;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (int i = 0; i < 2; i++) {
      final delay = i * 0.2;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final alpha = (1 - t) * 0.42;
      final radius = 42.0 + t * 88.0;

      canvas.drawCircle(
        Offset(cx, cy), radius,
        Paint()
          ..color = scheme.primary.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2 - t * 1.5).clamp(0.3, 2.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InkRingPainter old) =>
      old.progress != progress || old.scheme != scheme;
}

// ─────────────────────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────────────────────

class _ChipData {
  const _ChipData({
    required this.label,
    required this.icon,
    required this.relX,
    required this.relY,
    required this.offsetX,
  });
  final String  label;
  final IconData icon;
  final double  relX, relY, offsetX;
}

class _CardinalDir {
  const _CardinalDir({
    required this.angle,
    required this.label,
    required this.isMain,
  });
  final double angle;
  final String label;
  final bool   isMain;
}

// ── Elastic-out curve (const-constructible) ────────────────
class _ElasticOutCurve extends Curve {
  const _ElasticOutCurve([this.period = 0.4]);
  final double period;

  @override
  double transformInternal(double t) {
    final s = period / 4.0;
    return math.pow(2.0, -10.0 * t) *
        math.sin((t - s) * (math.pi * 2.0) / period) +
        1.0;
  }
}

// ── Travel Globe — custom icon (no image asset) ────────────
//
//  Draws a stylised globe with:
//   • Brand-tinted circular background (follows ColorScheme)
//   • Latitude / longitude grid lines
//   • A bold location-pin silhouette in the centre
//   • A small sun circle inside the pin head
//   • A tiny suitcase shape bottom-right for travel flavour
// ──────────────────────────────────────────────────────────
class _TravelGlobePainter extends CustomPainter {
  const _TravelGlobePainter({required this.scheme, required this.pulseT});
  final ColorScheme scheme;
  final double pulseT;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  / 2;

    final bgA = scheme.primaryContainer;
    final bgB = Color.lerp(scheme.primary, scheme.primaryContainer, 0.35)!;
    final gridBase = scheme.brightness == Brightness.dark
        ? Colors.white
        : scheme.onPrimary;
    final pin = scheme.onPrimaryContainer;
    final pinSh = Color.lerp(scheme.primary, Colors.black, 0.28)!;
    final sun =
        Color.lerp(scheme.primary, scheme.surfaceContainerLowest, 0.38)!;
    final bag = Color.lerp(scheme.tertiary, scheme.onSurface, 0.55)!;

    // ── 1. Circular background (brand gradient) ──────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [bgA, bgB],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // ── 2. Globe latitude lines ──────────────────────────
    canvas.save();
    canvas.clipPath(Path()..addOval(
      Rect.fromCircle(center: Offset(cx, cy), radius: r - 0.5),
    ));
    final gridP = Paint()
      ..color = gridBase.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizontals (latitudes)
    for (final frac in [-0.45, -0.2, 0.0, 0.2, 0.45]) {
      final y = cy + frac * size.height * 0.85;
      final halfW = math.sqrt(math.max(0, r * r - (y - cy) * (y - cy)));
      final rect = Rect.fromCenter(
        center: Offset(cx, y), width: halfW * 2, height: halfW * 0.28,
      );
      canvas.drawOval(rect, gridP);
    }

    // Verticals (longitudes) — full ellipses rotated
    for (final angleDeg in [-60.0, -25.0, 0.0, 25.0, 60.0]) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angleDeg * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero,
            width: r * 0.28, height: r * 1.92),
        gridP,
      );
      canvas.restore();
    }
    canvas.restore();

    // ── 3. Location pin (body) ───────────────────────────
    final pinCX = cx;
    final pinCY = cy - r * 0.08;   // slightly above centre
    final pinR  = r * 0.34;        // pin-head radius
    final pinTipY = pinCY + pinR * 2.5; // pointed bottom

    final pinPath = Path();
    // Head — full circle
    pinPath.addOval(
      Rect.fromCircle(center: Offset(pinCX, pinCY), radius: pinR),
    );
    // Teardrop tail
    pinPath.moveTo(pinCX - pinR * 0.55, pinCY + pinR * 0.65);
    pinPath.quadraticBezierTo(
      pinCX - pinR * 0.12, pinTipY + pinR * 0.1,
      pinCX, pinTipY,
    );
    pinPath.quadraticBezierTo(
      pinCX + pinR * 0.12, pinTipY + pinR * 0.1,
      pinCX + pinR * 0.55, pinCY + pinR * 0.65,
    );
    pinPath.close();

    // Shadow/depth layer (slightly offset)
    canvas.drawPath(
      pinPath,
      Paint()..color = pinSh.withValues(alpha: 0.35),
    );
    // Main pin
    canvas.drawPath(pinPath, Paint()..color = pin);

    // ── 4. Sun disc inside pin head ──────────────────────
    final sunR = pinR * 0.46;
    // Outer glow ring
    canvas.drawCircle(
      Offset(pinCX, pinCY), sunR + 3 + 1.5 * pulseT,
      Paint()..color = sun.withValues(alpha: 0.28 + 0.10 * pulseT),
    );
    canvas.drawCircle(Offset(pinCX, pinCY), sunR, Paint()..color = sun);

    // Sun rays (8 short dashes)
    final rayP = Paint()
      ..color = sun.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final a   = i * math.pi / 4;
      final rIn = sunR + 4;
      final rOut= sunR + 8 + 1.5 * pulseT;
      canvas.drawLine(
        Offset(pinCX + math.cos(a) * rIn, pinCY + math.sin(a) * rIn),
        Offset(pinCX + math.cos(a) * rOut, pinCY + math.sin(a) * rOut),
        rayP,
      );
    }

    // ── 5. Mini suitcase (bottom-right quadrant) ─────────
    final bx = cx + r * 0.48;
    final by = cy + r * 0.48;
    const bw = 18.0, bh = 14.0, bCorner = 3.0;

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by), width: bw, height: bh),
        const Radius.circular(bCorner),
      ),
      Paint()..color = bag,
    );
    // Centre divider line
    canvas.drawLine(
      Offset(bx, by - bh / 2 + 1), Offset(bx, by + bh / 2 - 1),
      Paint()
        ..color = bag.withValues(alpha: 0.5)
        ..strokeWidth = 1.0,
    );
    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by - bh / 2 - 2.5),
            width: 8, height: 4),
        const Radius.circular(2),
      ),
      Paint()
        ..color = bag.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TravelGlobePainter old) =>
      old.pulseT != pulseT || old.scheme != scheme;
}