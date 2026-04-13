import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../widgets/place_category_visual.dart';

// ─────────────────────────────────────────────
// Models (unchanged, kept intact)
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
    places:
    (json['places'] as List).map((p) => TripPlace.fromJson(p)).toList(),
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

  factory MapViewScreen.fromJson(Map<String, dynamic> tripJson) {
    return MapViewScreen(
      tripDays: (tripJson['tripPlan'] as List)
          .map((d) => TripDay.fromJson(d))
          .toList(),
      apiKey: (tripJson['apiKey'] as String?) ?? AppConstants.googleMapsApiKey,
      city: tripJson['city'] ?? 'Trip',
    );
  }

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetCtrl =
  DraggableScrollableController();

  int _selectedDayIndex = 0;
  TripPlace? _selectedPlace;
  int _selectedPlaceIndex = -1;

  // Map data
  final Map<String, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  List<SegmentInfo> _segments = [];
  bool _loadingRoute = false;

  // Caches
  final Map<String, BitmapDescriptor> _markerCache = {};

  // Animation for place card
  late AnimationController _cardAnim;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;

  // Scroll controller for horizontal place list
  final PageController _placePageCtrl = PageController(viewportFraction: 0.88);

  // Route colors per day
  static const List<Color> _routeColors = [
    Color(0xFF14B8A6),
    Color(0xFFFF6B35),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _cardScale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutBack));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDay(0));
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _cardAnim.dispose();
    _placePageCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Day loading ────────────────────────────

  Future<void> _loadDay(int dayIndex) async {
    setState(() {
      _selectedDayIndex = dayIndex;
      _selectedPlace = null;
      _selectedPlaceIndex = -1;
      _markers.clear();
      _polylines.clear();
      _segments = [];
      _loadingRoute = true;
    });
    _cardAnim.reverse();

    final day = widget.tripDays[dayIndex];
    await _buildMarkers(day);
    await _fetchRoutes(day);
    _fitBounds(day);
  }

  // ── Marker creation (category icon) ────────

  Future<void> _buildMarkers(TripDay day) async {
    final newMarkers = <String, Marker>{};
    for (int i = 0; i < day.places.length; i++) {
      final place = day.places[i];
      final style = placeCategoryStyle(place.category);
      final icon = await _buildCategoryMarker(style, i == 0, i == day.places.length - 1);
      newMarkers['place_$i'] = Marker(
        markerId: MarkerId('place_$i'),
        position: place.latLng,
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        onTap: () => _onMarkerTap(place, i),
        infoWindow: InfoWindow.noText,
        zIndex: (day.places.length - i).toDouble(),
      );
    }
    if (mounted) setState(() => _markers.addAll(newMarkers));
  }

  Future<BitmapDescriptor> _buildCategoryMarker(
      PlaceCategoryStyle style, bool isFirst, bool isLast) async {
    final cacheKey =
        '${style.imageAsset ?? style.emoji}_${style.color.value}_${isFirst}_$isLast';
    if (_markerCache.containsKey(cacheKey)) return _markerCache[cacheKey]!;

    ui.Image? assetImage;
    final assetPath = style.imageAsset;
    if (assetPath != null) {
      try {
        final data = await rootBundle.load(assetPath);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        assetImage = (await codec.getNextFrame()).image;
      } catch (_) {
        assetImage = null;
      }
    }

    const double w = 130, h = 160;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // ── Pin shape ──────────────────────────────────────────
    final pinPath = Path();
    const cx = w / 2;
    const bubbleR = 52.0;
    const tipY = h - 8.0;

    // Circle bubble
    pinPath.addOval(Rect.fromCircle(
        center: const Offset(cx, bubbleR + 6), radius: bubbleR));
    // Triangle pointer
    pinPath
      ..moveTo(cx - 18, bubbleR * 2 - 12)
      ..lineTo(cx, tipY)
      ..lineTo(cx + 18, bubbleR * 2 - 12)
      ..close();

    // Drop shadow
    final shadowPaint = Paint()
      ..color = style.color.withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(pinPath.shift(const Offset(0, 6)), shadowPaint);

    // White halo
    final haloPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
        const Offset(cx, bubbleR + 6), bubbleR + 5, haloPaint);

    // Coloured background
    final bgPaint = Paint()..color = style.bg;
    canvas.drawPath(pinPath, bgPaint);

    // Coloured border
    final borderPaint = Paint()
      ..color = style.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(pinPath, borderPaint);

    // First/last indicator ring
    if (isFirst || isLast) {
      final ringPaint = Paint()
        ..color = isFirst ? const Color(0xFF14B8A6) : const Color(0xFFFF6B35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(
          const Offset(cx, bubbleR + 6), bubbleR - 2, ringPaint);
    }

    if (assetImage != null) {
      const iconSide = 72.0;
      final src = Rect.fromLTWH(
          0, 0, assetImage.width.toDouble(), assetImage.height.toDouble());
      final dst = Rect.fromCenter(
        center: const Offset(cx, bubbleR + 6),
        width: iconSide,
        height: iconSide,
      );
      canvas.drawImageRect(
        assetImage,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );
      assetImage.dispose();
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: style.emoji,
          style: const TextStyle(fontSize: 44),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(cx - tp.width / 2, bubbleR + 6 - tp.height / 2));
    }

    final image = await recorder
        .endRecording()
        .toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor =
    BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  // ── Directions API ─────────────────────────

  Future<void> _fetchRoutes(TripDay day) async {
    if (day.places.length < 2) {
      if (mounted) setState(() => _loadingRoute = false);
      return;
    }

    final routeColor = _routeColors[_selectedDayIndex % _routeColors.length];
    final List<SegmentInfo> segments = [];
    final List<Polyline> polylines = [];

    for (int i = 0; i < day.places.length - 1; i++) {
      final origin = day.places[i];
      final dest = day.places[i + 1];
      try {
        final info = await _getDirectionsSegment(origin.latLng, dest.latLng);
        segments.add(info);
        // Glow effect: thick transparent + thin solid
        polylines.add(Polyline(
          polylineId: PolylineId('glow_$i'),
          points: info.polylinePoints,
          color: routeColor.withOpacity(0.18),
          width: 14,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
        polylines.add(Polyline(
          polylineId: PolylineId('seg_$i'),
          points: info.polylinePoints,
          color: routeColor,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ));
      } catch (_) {
        final straight = SegmentInfo(
          distanceMeters:
          _haversineMeters(origin.latLng, dest.latLng),
          durationSeconds: 0,
          polylinePoints: [origin.latLng, dest.latLng],
        );
        segments.add(straight);
        polylines.add(Polyline(
          polylineId: PolylineId('seg_$i'),
          points: [origin.latLng, dest.latLng],
          color: routeColor.withOpacity(0.6),
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(8)],
        ));
      }
    }

    if (mounted) {
      setState(() {
        _segments = segments;
        for (final p in polylines) _polylines[p.polylineId] = p;
        _loadingRoute = false;
      });
      await _addMidpointLabels(day, segments);
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
    if (response.statusCode != 200)
      throw Exception('HTTP ${response.statusCode}');
    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') throw Exception(data['status']);
    final leg = data['routes'][0]['legs'][0];
    return SegmentInfo(
      distanceMeters: leg['distance']['value'] as int,
      durationSeconds: leg['duration']['value'] as int,
      polylinePoints:
      _decodePolyline(data['routes'][0]['overview_polyline']['points']),
    );
  }

  Future<void> _addMidpointLabels(
      TripDay day, List<SegmentInfo> segments) async {
    final Map<String, Marker> dMarkers = {};
    for (int i = 0; i < segments.length; i++) {
      final pts = segments[i].polylinePoints;
      if (pts.isEmpty) continue;
      final mid = pts[pts.length ~/ 2];
      final icon = await _buildTravelChip(
          segments[i].durationLabel, segments[i].distanceLabel);
      dMarkers['dur_$i'] = Marker(
        markerId: MarkerId('dur_$i'),
        position: mid,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 1,
        onTap: () {},
      );
    }
    if (mounted) setState(() => _markers.addAll(dMarkers));
  }

  Future<BitmapDescriptor> _buildTravelChip(
      String duration, String distance) async {
    final key = 'chip_$duration|$distance';
    if (_markerCache.containsKey(key)) return _markerCache[key]!;
    const double w = 200, h = 60;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rrect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, w, h), const Radius.circular(30));
    // Shadow
    canvas.drawRRect(
        rrect.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // White pill
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    // Left accent
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 8, 60), const Radius.circular(30)),
        Paint()..color = const Color(0xFF14B8A6));
    // Duration
    final tp1 = TextPainter(
      text: TextSpan(
          text: duration,
          style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(18, h / 2 - tp1.height / 2));
    // Separator
    canvas.drawLine(
        Offset(22 + tp1.width, 14),
        Offset(22 + tp1.width, h - 14),
        Paint()
          ..color = const Color(0xFFE2E8F0)
          ..strokeWidth = 1.5);
    // Distance
    final tp2 = TextPainter(
      text: TextSpan(
          text: distance,
          style: const TextStyle(
              color: Color(0xFF64748B), fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(
        canvas, Offset(30 + tp1.width, h / 2 - tp2.height / 2));
    final image = await recorder
        .endRecording()
        .toImage(w.toInt(), h.toInt());
    final bytes =
    await image.toByteData(format: ui.ImageByteFormat.png);
    final d = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    _markerCache[key] = d;
    return d;
  }

  // ── Camera ─────────────────────────────────

  void _fitBounds(TripDay day) {
    if (_mapController == null || day.places.isEmpty) return;
    double minLat = double.infinity,
        maxLat = -double.infinity,
        minLng = double.infinity,
        maxLng = -double.infinity;
    for (final p in day.places) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - 0.012, minLng - 0.012),
        northeast: LatLng(maxLat + 0.012, maxLng + 0.012),
      ),
      110,
    ));
  }

  // ── Interactions ───────────────────────────

  void _onMarkerTap(TripPlace place, int index) {
    setState(() {
      _selectedPlace = place;
      _selectedPlaceIndex = index;
    });
    _cardAnim.forward(from: 0);
    // Snap sheet to mid
    if (_sheetCtrl.isAttached) {
      _sheetCtrl.animateTo(0.48,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
    // Scroll page view
    _placePageCtrl.animateToPage(index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic);
    // Move camera
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
          target: LatLng(place.lat - 0.004, place.lng),
          zoom: 15.5,
          tilt: 35,
          bearing: 10),
    ));
  }

  void _dismissSelection() {
    setState(() {
      _selectedPlace = null;
      _selectedPlaceIndex = -1;
    });
    _cardAnim.reverse();
  }

  // ── Utility ────────────────────────────────

  TripDay get _currentDay => widget.tripDays[_selectedDayIndex];

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
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
    final s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return (r * 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s))).round();
  }

  double _deg2rad(double d) => d * math.pi / 180;

  // ── Build ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = _currentDay;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: scheme.surface,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onTap: _dismissSelection,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── Google Map ──────────────────────
              Positioned.fill(
                child: GoogleMap(
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
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  onTap: (_) => _dismissSelection(),
                ),
              ),

              // ── Top gradient scrim ───────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.92),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top bar ─────────────────────────
              SafeArea(child: _TopBar(city: widget.city, onBack: () => Navigator.of(context).maybePop(), onRecenter: () => _fitBounds(day))),

              // ── Day selector pills ───────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 0,
                right: 0,
                child: _DayPills(
                  days: widget.tripDays,
                  selectedIndex: _selectedDayIndex,
                  onSelect: _loadDay,
                  routeColors: _routeColors,
                ),
              ),

              // ── Loading overlay ──────────────────
              if (_loadingRoute) const _LoadingOverlay(),

              // ── Bottom draggable sheet ───────────
              DraggableScrollableSheet(
                controller: _sheetCtrl,
                initialChildSize: 0.28,
                minChildSize: 0.14,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [0.14, 0.28, 0.48, 0.85],
                builder: (ctx, scrollCtrl) =>
                    _BottomSheet(
                      scrollController: scrollCtrl,
                      sheetController: _sheetCtrl,
                      day: _currentDay,
                      selectedPlace: _selectedPlace,
                      selectedIndex: _selectedPlaceIndex,
                      placePageCtrl: _placePageCtrl,
                      cardAnim: _cardAnim,
                      cardScale: _cardScale,
                      cardFade: _cardFade,
                      segments: _segments,
                      onPlaceTap: _onMarkerTap,
                      formatDuration: _formatDuration,
                      onDismiss: _dismissSelection,
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
// Top Bar
// ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String city;
  final VoidCallback onBack;
  final VoidCallback onRecenter;

  const _TopBar({
    required this.city,
    required this.onBack,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _MapButton(onTap: onBack, icon: Icons.arrow_back_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.09),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFF14B8A6), size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      city,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _MapButton(onTap: onRecenter, icon: Icons.my_location_rounded),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _MapButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
    ),
  );
}

// ─────────────────────────────────────────────
// Day Selector Pills
// ─────────────────────────────────────────────

class _DayPills extends StatelessWidget {
  final List<TripDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<Color> routeColors;

  const _DayPills({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.routeColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          final color = routeColors[i % routeColors.length];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? color.withOpacity(0.35)
                        : Colors.black.withOpacity(0.07),
                    blurRadius: selected ? 14 : 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!selected)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  Text(
                    'Day ${days[i].day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· ${days[i].places.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white.withOpacity(0.75)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheet
// ─────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final DraggableScrollableController sheetController;
  final TripDay day;
  final TripPlace? selectedPlace;
  final int selectedIndex;
  final PageController placePageCtrl;
  final AnimationController cardAnim;
  final Animation<double> cardScale;
  final Animation<double> cardFade;
  final List<SegmentInfo> segments;
  final void Function(TripPlace, int) onPlaceTap;
  final String Function(int) formatDuration;
  final VoidCallback onDismiss;

  const _BottomSheet({
    required this.scrollController,
    required this.sheetController,
    required this.day,
    required this.selectedPlace,
    required this.selectedIndex,
    required this.placePageCtrl,
    required this.cardAnim,
    required this.cardScale,
    required this.cardFade,
    required this.segments,
    required this.onPlaceTap,
    required this.formatDuration,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 40, offset: Offset(0, -8))
        ],
      ),
      child: Column(
        children: [
          // ── Handle + header ──────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (sheetController.isAttached) {
                final current = sheetController.size;
                sheetController.animateTo(
                  current < 0.45 ? 0.85 : 0.28,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day.theme.isNotEmpty ? day.theme : 'Day ${day.day}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${day.places.length} destinations  ·  ${segments.isNotEmpty ? _totalTime() : "–"} drive',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Category legend dots
                      Wrap(
                        spacing: 4,
                        children: day.places
                            .take(4)
                            .map((p) {
                          final style = placeCategoryStyle(p.category);
                          return Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: style.bg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: style.color.withOpacity(0.3),
                                    width: 1.5)),
                            child: Center(
                              child: PlaceCategoryGlyph(style: style, size: 15),
                            ),
                          );
                        })
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // ── Scrollable body ────────────────────────
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Selected place big card ──────────
                if (selectedPlace != null)
                  AnimatedBuilder(
                    animation: cardAnim,
                    builder: (_, __) => Opacity(
                      opacity: cardFade.value,
                      child: Transform.scale(
                        scale: cardScale.value,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _PlaceDetailCard(
                            place: selectedPlace!,
                            index: selectedIndex,
                            formatDuration: formatDuration,
                            onDismiss: onDismiss,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Horizontal place card strip ──────
                SizedBox(
                  height: 130,
                  child: PageView.builder(
                    controller: placePageCtrl,
                    physics: const BouncingScrollPhysics(),
                    itemCount: day.places.length,
                    onPageChanged: (i) =>
                        onPlaceTap(day.places[i], i),
                    itemBuilder: (_, i) {
                      final p = day.places[i];
                      final style = placeCategoryStyle(p.category);
                      final isSelected = i == selectedIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? style.bg : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? style.color.withOpacity(0.4)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                                color: style.color.withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4))
                          ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      color: style.color.withOpacity(0.12),
                                      borderRadius:
                                      BorderRadius.circular(10)),
                                  child: Center(
                                    child:
                                        PlaceCategoryGlyph(style: style, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p.category,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: style.color,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 12, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(formatDuration(p.durationMin),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B))),
                                const SizedBox(width: 10),
                                const Icon(Icons.star_rounded,
                                    size: 12, color: Color(0xFFFBBF24)),
                                const SizedBox(width: 3),
                                Text(p.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Full stop list ───────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(day.places.length, (i) {
                      final p = day.places[i];
                      final style = placeCategoryStyle(p.category);
                      final isLast = i == day.places.length - 1;
                      return _StopRow(
                        place: p,
                        index: i,
                        style: style,
                        isLast: isLast,
                        segment: i < segments.length ? segments[i] : null,
                        isSelected: i == selectedIndex,
                        onTap: () => onPlaceTap(p, i),
                        formatDuration: formatDuration,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _totalTime() {
    int total = 0;
    for (final s in segments) total += (s.durationSeconds / 60).round();
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ─────────────────────────────────────────────
// Stop Row (timeline style)
// ─────────────────────────────────────────────

class _StopRow extends StatelessWidget {
  final TripPlace place;
  final int index;
  final PlaceCategoryStyle style;
  final bool isLast;
  final SegmentInfo? segment;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(int) formatDuration;

  const _StopRow({
    required this.place,
    required this.index,
    required this.style,
    required this.isLast,
    required this.segment,
    required this.isSelected,
    required this.onTap,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? style.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                  color: style.color.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                // Timeline dot
                Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: style.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: style.color.withOpacity(0.35),
                            width: 1.5),
                      ),
                      child: Center(
                        child: PlaceCategoryGlyph(style: style, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? style.color
                              : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            place.category,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: style.color,
                                fontWeight: FontWeight.w600),
                          ),
                          const Text('  ·  ',
                              style: TextStyle(
                                  color: Color(0xFFCBD5E1), fontSize: 12)),
                          const Icon(Icons.schedule_rounded,
                              size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            formatDuration(place.durationMin),
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 3),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Travel connector between stops
        if (!isLast && segment != null)
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                        width: 2,
                        height: 8,
                        color: const Color(0xFFE2E8F0)),
                    const Icon(Icons.directions_car_rounded,
                        size: 13, color: Color(0xFF94A3B8)),
                    Container(
                        width: 2,
                        height: 8,
                        color: const Color(0xFFE2E8F0)),
                  ],
                ),
                const SizedBox(width: 14),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${segment!.durationLabel}  ·  ${segment!.distanceLabel}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Place Detail Card (shown on marker tap)
// ─────────────────────────────────────────────

class _PlaceDetailCard extends StatelessWidget {
  final TripPlace place;
  final int index;
  final String Function(int) formatDuration;
  final VoidCallback onDismiss;

  const _PlaceDetailCard({
    required this.place,
    required this.index,
    required this.formatDuration,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final style = placeCategoryStyle(place.category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: style.color.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: style.color.withOpacity(0.2),
                            blurRadius: 10)
                      ]),
                  child: Center(
                    child: PlaceCategoryGlyph(style: style, size: 28),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.category,
                          style: TextStyle(
                              fontSize: 11,
                              color: style.color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _StatBadge(
                  icon: Icons.access_time_rounded,
                  text: formatDuration(place.durationMin),
                  color: style.color,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  icon: Icons.star_rounded,
                  text: place.rating.toStringAsFixed(1),
                  color: const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  icon: Icons.wb_sunny_outlined,
                  text: place.bestTime.isNotEmpty
                      ? place.bestTime
                      : 'Anytime',
                  color: const Color(0xFFF97316),
                ),
              ],
            ),
          ),

          // Description
          if (place.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                place.description,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.55),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Tip
          if (place.tips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFED7AA), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place.tips,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFC2410C),
                            fontWeight: FontWeight.w500,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// Loading overlay
// ─────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      color: Colors.white.withOpacity(0.55),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: Color(0xFF14B8A6), strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('Planning your route…',
                style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// Extension
// ─────────────────────────────────────────────

extension _TripPlaceFee on TripPlace {
  int get entryFee => 0;
}