import 'package:flutter/material.dart';

import '../../../core/utils/navigation_utils.dart';

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => NavigationUtils.pop(context),
        ),
        title: const Text('Map View'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen map placeholder (replace with Google Map widget)
          Container(
            color: const Color(0xFF1E3A2F),
            child: CustomPaint(
              painter: _MapPlaceholderPainter(),
              size: Size.infinite,
            ),
          ),
          // Distance label overlay example
          Positioned(
            left: 24,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.straighten_rounded, size: 18, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    'Total: ~42 km',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          // Legend / hint
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Text(
              'Integrate google_maps_flutter for route polyline, markers & distances.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a simple route polyline and marker-like circles as placeholder.
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.25);
    path.lineTo(size.width * 0.4, size.height * 0.35);
    path.lineTo(size.width * 0.6, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height * 0.65);
    path.lineTo(size.width * 0.85, size.height * 0.55);

    final linePaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPositions = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.4, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.65),
      Offset(size.width * 0.85, size.height * 0.55),
    ];

    for (final offset in pointPositions) {
      final fillPaint = Paint()
        ..color = Colors.tealAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 12, fillPaint);
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(offset, 12, strokePaint);
    }

    // Small "tourist" labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'A',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (pointPositions.isNotEmpty) {
      textPainter.paint(
        canvas,
        pointPositions.first - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
