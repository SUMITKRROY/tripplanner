import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class TripPlace {
  final String name;
  final double lat;
  final double lng;
  final int durationMin;
  final String category;
  final String description;
  final String tips;
  final String bestTime;
  final double rating;
  final String imageUrl;
  final String openingHours;

  const TripPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.durationMin,
    required this.category,
    required this.description,
    required this.tips,
    required this.bestTime,
    required this.rating,
    required this.imageUrl,
    required this.openingHours,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory TripPlace.fromJson(Map<String, dynamic> json) => TripPlace(
    name: json['name'] ?? '',
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    durationMin: (json['duration'] as num?)?.toInt() ?? 60,
    category: json['category'] ?? '',
    description: json['description'] ?? '',
    tips: json['tips'] ?? '',
    bestTime: json['bestTime'] ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl'] ?? '',
    openingHours: json['openingHours'] ?? '',
  );
}

class TripDay {
  final int day;
  final String theme;
  final String description;
  final List<TripPlace> places;
  final int totalTimeMin;

  const TripDay({
    required this.day,
    required this.theme,
    required this.description,
    required this.places,
    required this.totalTimeMin,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) => TripDay(
    day: (json['day'] as num).toInt(),
    theme: json['theme'] ?? '',
    description: json['description'] ?? '',
    places: (json['places'] as List)
        .map((p) => TripPlace.fromJson(p))
        .toList(),
    totalTimeMin: (json['totalTimeMin'] as num?)?.toInt() ?? 0,
  );
}

class SegmentInfo {
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> polylinePoints;

  const SegmentInfo({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
  });

  String get durationLabel {
    final mins = (durationSeconds / 60).round();
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }
}

// ─────────────────────────────────────────────
// Map View Screen
// ─────────────────────────────────────────────

class MapViewScreen extends StatefulWidget {
  final List<TripDay> tripDays;
  final String apiKey;
  final String city;

  const MapViewScreen({
    super.key,
    required this.tripDays,
    required this.apiKey,
    required this.city,
  });

  /// Convenience factory – pass raw trip JSON map directly.
  factory MapViewScreen.fromJson(Map<String, dynamic> tripJson) {
    return MapViewScreen(
      tripDays: (tripJson['tripPlan'] as List)
          .map((d) => TripDay.fromJson(d))
          .toList(),
      apiKey:
          (tripJson['apiKey'] as String?) ?? AppConstants.googleMapsApiKey,
      city: tripJson['city'] ?? 'Trip',
    );
  }

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetDragController =
      DraggableScrollableController();
  int _selectedDayIndex = 0;
  int _bottomTabIndex = 1;
  TripPlace? _selectedPlace;

  // Map data
  final Map<String, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  List<SegmentInfo> _segments = [];
  bool _loadingRoute = false;

  // Marker label bitmaps cache
  final Map<String, BitmapDescriptor> _labelCache = {};

  // Animation controller for bottom sheet
  late AnimationController _sheetController;
  late Animation<double> _sheetAnimation;

  // Color palette
  static const Color _bgDark = Color(0xFF0D1117);
  static const Color _accent = Color(0xFF00E5BE);
  static const Color _accentWarm = Color(0xFFFF6B35);
  static const Color _surface = Color(0xFF161B22);
  static const Color _surfaceElevated = Color(0xFF21262D);
  static const Color _textPrimary = Color(0xFFF0F6FC);
  static const Color _textSecondary = Color(0xFF8B949E);

  static const List<Color> _markerColors = [
    Color(0xFF00E5BE),
    Color(0xFFFF6B35),
    Color(0xFFFFD700),
    Color(0xFFBE4BDB),
    Color(0xFF4ECDC4),
  ];

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDay(0));
  }

  @override
  void dispose() {
    _sheetDragController.dispose();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Day loading ────────────────────────────

  Future<void> _loadDay(int dayIndex) async {
    setState(() {
      _selectedDayIndex = dayIndex;
      _selectedPlace = null;
      _markers.clear();
      _polylines.clear();
      _segments = [];
      _loadingRoute = true;
    });
    _sheetController.reverse();

    final day = widget.tripDays[dayIndex];
    await _buildMarkers(day);
    await _fetchRoutes(day);
    _fitBounds(day);
  }

  // ── Marker creation ────────────────────────

  Future<void> _buildMarkers(TripDay day) async {
    final newMarkers = <String, Marker>{};

    for (int i = 0; i < day.places.length; i++) {
      final place = day.places[i];
      final label = '${i + 1}';
      final color = _markerColors[i % _markerColors.length];

      final icon = await _buildMarkerIcon(label, color);

      newMarkers['place_$i'] = Marker(
        markerId: MarkerId('place_$i'),
        position: place.latLng,
        icon: icon,
        onTap: () => _onMarkerTap(place),
        infoWindow: InfoWindow.noText,
        zIndex: (day.places.length - i).toDouble(),
      );
    }

    if (mounted) setState(() => _markers.addAll(newMarkers));
  }

  Future<BitmapDescriptor> _buildMarkerIcon(
      String label, Color color) async {
    if (_labelCache.containsKey('$label${color.value}')) {
      return _labelCache['$label${color.value}']!;
    }

    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 4), 40, shadowPaint);

    // Outer ring
    final ringPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), 40, ringPaint);

    // Fill
    final fillPaint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), 35, fillPaint);

    // Label text
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size / 2 - tp.width / 2, size / 2 - tp.height / 2),
    );

    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes =
    await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.fromBytes(
      bytes!.buffer.asUint8List(),
    );
    _labelCache['$label${color.value}'] = descriptor;
    return descriptor;
  }

  // ── Directions API ─────────────────────────

  Future<void> _fetchRoutes(TripDay day) async {
    if (day.places.length < 2) {
      if (mounted) setState(() => _loadingRoute = false);
      return;
    }

    final List<SegmentInfo> segments = [];
    final List<Polyline> polylines = [];

    for (int i = 0; i < day.places.length - 1; i++) {
      final origin = day.places[i];
      final dest = day.places[i + 1];
      final segColor = const Color(0xFF18C8F6);

      try {
        final info = await _getDirectionsSegment(origin.latLng, dest.latLng);
        segments.add(info);

        polylines.add(Polyline(
          polylineId: PolylineId('seg_$i'),
          points: info.polylinePoints,
          color: segColor,
          width: 5,
          patterns: [],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ));
      } catch (_) {
        // Fallback: straight line
        segments.add(SegmentInfo(
          distanceMeters: _haversineMeters(origin.latLng, dest.latLng),
          durationSeconds: 0,
          polylinePoints: [origin.latLng, dest.latLng],
        ));
        polylines.add(Polyline(
          polylineId: PolylineId('seg_$i'),
          points: [origin.latLng, dest.latLng],
          color: segColor,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _segments = segments;
        for (final p in polylines) {
          _polylines[p.polylineId] = p;
        }
        _loadingRoute = false;
      });

      // Add midpoint duration markers after segments are loaded
      await _addDurationMarkers(day, segments);
    }
  }

  Future<SegmentInfo> _getDirectionsSegment(
      LatLng origin, LatLng dest) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${dest.latitude},${dest.longitude}'
          '&mode=driving'
          '&key=${widget.apiKey}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') throw Exception(data['status']);

    final leg = data['routes'][0]['legs'][0];
    final distanceMeters = leg['distance']['value'] as int;
    final durationSeconds = leg['duration']['value'] as int;

    final encodedPolyline =
    data['routes'][0]['overview_polyline']['points'] as String;
    final points = _decodePolyline(encodedPolyline);

    return SegmentInfo(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      polylinePoints: points,
    );
  }

  Future<void> _addDurationMarkers(
      TripDay day, List<SegmentInfo> segments) async {
    final Map<String, Marker> durationMarkers = {};

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final points = seg.polylinePoints;
      if (points.isEmpty) continue;

      // Pick midpoint of polyline
      final mid = points[points.length ~/ 2];
      final icon =
      await _buildDurationIcon(seg.durationLabel, seg.distanceLabel);

      durationMarkers['dur_$i'] = Marker(
        markerId: MarkerId('dur_$i'),
        position: mid,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 1,
        onTap: () {},
      );
    }

    if (mounted) setState(() => _markers.addAll(durationMarkers));
  }

  Future<BitmapDescriptor> _buildDurationIcon(
      String duration, String distance) async {
    final key = '$duration|$distance';
    if (_labelCache.containsKey(key)) return _labelCache[key]!;

    const double w = 220, h = 70;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(14),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
        rrect.shift(const Offset(0, 3)), shadowPaint);

    // Background
    final bgPaint = Paint()..color = const Color(0xF0161B22);
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5BE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // Duration text
    final tp1 = TextPainter(
      text: TextSpan(
        text: duration,
        style: const TextStyle(
          color: Color(0xFF00E5BE),
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(16, h / 2 - tp1.height / 2));

    // Divider
    final divPaint = Paint()
      ..color = const Color(0xFF8B949E)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(16 + tp1.width + 10, 14),
        Offset(16 + tp1.width + 10, h - 14),
        divPaint);

    // Distance text
    final tp2 = TextPainter(
      text: TextSpan(
        text: distance,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 22,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(
        canvas,
        Offset(16 + tp1.width + 20,
            h / 2 - tp2.height / 2));

    final image = await recorder
        .endRecording()
        .toImage(w.toInt(), h.toInt());
    final bytes =
    await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor =
    BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    _labelCache[key] = descriptor;
    return descriptor;
  }

  // ── Camera ─────────────────────────────────

  void _fitBounds(TripDay day) {
    if (_mapController == null || day.places.isEmpty) return;

    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;

    for (final p in day.places) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        120,
      ),
    );
  }

  // ── Interactions ───────────────────────────

  void _onMarkerTap(TripPlace place) {
    setState(() {
      _selectedPlace = place;
      _bottomTabIndex = _selectedDayIndex + 1;
    });
    _sheetController.forward();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(place.lat - 0.003, place.lng),
          zoom: 15.5,
          tilt: 30,
        ),
      ),
    );
  }

  void _closeSheet() {
    _sheetController.reverse().then((_) {
      if (mounted) setState(() => _selectedPlace = null);
    });
  }

  // ── Utility ────────────────────────────────

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  int _haversineMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLng = _deg2rad(b.longitude - a.longitude);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final c = sinLat * sinLat +
        math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            sinLng *
            sinLng;
    return (r * 2 * math.atan2(math.sqrt(c), math.sqrt(1 - c))).round();
  }

  double _deg2rad(double deg) => deg * math.pi / 180;

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final day = widget.tripDays[_selectedDayIndex];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: scheme.surface,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ── Google Map ──────────────────
            GoogleMap(
              onMapCreated: (ctrl) {
                _mapController = ctrl;
                _fitBounds(day);
              },
              initialCameraPosition: CameraPosition(
                target: day.places.isNotEmpty
                    ? day.places.first.latLng
                    : const LatLng(10.0, 76.2),
                zoom: 12,
              ),
              mapType: MapType.normal,
              markers: Set<Marker>.of(_markers.values),
              polylines: Set<Polyline>.of(_polylines.values),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onTap: (_) => _closeSheet(),
            ),

            // ── Top bar ─────────────────────
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, theme, scheme),
                ],
              ),
            ),

            // // ── Route summary strip ─────────
            // if (_segments.isNotEmpty)
            //   Positioned(
            //     left: 16,
            //     right: 16,
            //     bottom: 190,
            //     child: _buildRouteSummary(day),
            //   ),

            // ── Loading overlay ─────────────
            if (_loadingRoute)
              const Positioned.fill(
                child: _LoadingOverlay(),
              ),

            // ── Bottom sheet with tabs ──────
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomSheet(theme, scheme),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub widgets ────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Material(
            color: scheme.surface.withOpacity(0.92),
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(0.93),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withOpacity(0.45),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: scheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.city,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: scheme.surface.withOpacity(0.92),
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              onPressed: () => _fitBounds(day),
              icon: Icon(Icons.fit_screen_rounded, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  TripDay get day => widget.tripDays[_selectedDayIndex];

  Widget _buildBottomSheet(ThemeData theme, ColorScheme scheme) {
    final tabs = <String>['Overview', ...widget.tripDays.map((d) => 'Day ${d.day}')];

    return DraggableScrollableSheet(
      controller: _sheetDragController,
      initialChildSize: 0.26,
      minChildSize: 0.20,
      maxChildSize: 0.82,
      snap: true,
      snapSizes: const [0.26, 0.5, 0.82],
      builder: (context, scrollController) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_sheetDragController.isAttached) {
            _sheetDragController.animateTo(
              0.82,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final selected = i == _bottomTabIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _bottomTabIndex = i);
                      if (i > 0) _loadDay(i - 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border(
                                bottom: BorderSide(color: scheme.primary, width: 3),
                              )
                            : null,
                      ),
                      child: Text(
                        tabs[i],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemCount: tabs.length,
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withOpacity(0.7)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: _bottomTabIndex == 0
                      ? _buildOverviewContent(theme, scheme, scrollController)
                      : _buildDayContent(
                          theme,
                          scheme,
                          widget.tripDays[_bottomTabIndex - 1],
                          scrollController,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewContent(
    ThemeData theme,
    ColorScheme scheme,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      children: [
        Text(
          'Trip Overview',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.tripDays
              .map(
                (d) => Chip(
                  label: Text('Day ${d.day} • ${d.places.length} stops'),
                  backgroundColor: scheme.surfaceContainerHigh,
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDayContent(
    ThemeData theme,
    ColorScheme scheme,
    TripDay selectedDay,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Day ${selectedDay.day}',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text('Optimize', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedDay.theme,
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        ...List.generate(selectedDay.places.length, (i) {
          final p = selectedDay.places[i];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primaryContainer,
              child: Text('${i + 1}', style: TextStyle(color: scheme.onPrimaryContainer)),
            ),
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              p.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            onTap: () => _onMarkerTap(p),
          );
        }),
      ],
    );
  }

  Widget _buildRouteSummary(TripDay day) {
    double totalKm = 0;
    int totalTravelMins = 0;
    for (final s in _segments) {
      totalKm += s.distanceMeters / 1000;
      totalTravelMins += (s.durationSeconds / 60).round();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop pills
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: day.places.length + (day.places.length - 1),
              itemBuilder: (_, i) {
                if (i.isEven) {
                  final placeIdx = i ~/ 2;
                  final label = '${placeIdx + 1}';
                  final color =
                  _markerColors[placeIdx % _markerColors.length];
                  return _StopPill(label: label, color: color);
                } else {
                  final segIdx = i ~/ 2;
                  if (segIdx < _segments.length) {
                    return _SegmentArrow(
                        label: _segments[segIdx].durationLabel);
                  }
                  return const SizedBox();
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          // Totals
          Row(
            children: [
              _SummaryChip(
                icon: Icons.straighten_rounded,
                value: '${totalKm.toStringAsFixed(1)} km',
                color: _accent,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                icon: Icons.drive_eta_rounded,
                value: _formatDuration(totalTravelMins),
                color: _accentWarm,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                icon: Icons.place_rounded,
                value: '${day.places.length} stops',
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceSheet(TripPlace place, TripDay day) {
    final idx = day.places.indexOf(place);
    final label = idx >= 0 ? '${idx + 1}' : '?';
    final color = idx >= 0
        ? _markerColors[idx % _markerColors.length]
        : _accent;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.category_rounded,
                                  size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                place.category,
                                style: TextStyle(
                                    color: color, fontSize: 11.5),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.star_rounded,
                                  size: 12,
                                  color: Color(0xFFFFD700)),
                              const SizedBox(width: 3),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 11.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _closeSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: _textSecondary, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stat row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      text: _formatDuration(place.durationMin),
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.wb_sunny_rounded,
                      text: place.bestTime,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.attach_money_rounded,
                      text: place.entryFee == 0
                          ? 'Free Entry'
                          : '₹${place.entryFee}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  place.description,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Tip
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accentWarm.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _accentWarm.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded,
                          color: _accentWarm, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.tips,
                          style: const TextStyle(
                            color: _accentWarm,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Coordinates
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        size: 12, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${place.lat.toStringAsFixed(6)}, '
                          '${place.lng.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _accent.withOpacity(0.3)),
                      ),
                      child: Text(
                        place.openingHours,
                        style: TextStyle(
                          color: place.openingHours
                              .contains('Open')
                              ? _accent
                              : _textSecondary,
                          fontSize: 10,
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
// Small composable widgets
// ─────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(child: child),
    ),
  );
}

class _StopPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StopPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      shape: BoxShape.circle,
      border: Border.all(color: color.withOpacity(0.6)),
    ),
    child: Center(
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

class _SegmentArrow extends StatelessWidget {
  final String label;

  const _SegmentArrow({required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.arrow_forward_ios_rounded,
          size: 10, color: Color(0xFF8B949E)),
      const SizedBox(width: 2),
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B949E),
          fontSize: 10.5,
        ),
      ),
      const SizedBox(width: 4),
    ],
  );
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _SummaryChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF21262D),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: const Color(0xFF8B949E), size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
              color: Color(0xFF8B949E), fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black38,
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: Color(0xFF00E5BE), strokeWidth: 2.5),
          SizedBox(height: 12),
          Text(
            'Fetching route…',
            style: TextStyle(
                color: Color(0xFF8B949E), fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// Extension for entryFee access on TripPlace
// ─────────────────────────────────────────────

extension _TripPlaceFee on TripPlace {
  int get entryFee => 0; // already in JSON; extend as needed
}