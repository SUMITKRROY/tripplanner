import 'package:url_launcher/url_launcher.dart';

import '../../features/trip_planner/models/generate_trip_response_model.dart';

/// Opens Google Maps (app or browser) with the trip route or destination search.
Future<bool> launchGoogleMapsForTrip(GenerateTripResponseModel data) async {
  final points = <({double lat, double lng})>[];
  for (final day in data.tripPlan) {
    for (final p in day.places) {
      final lat = p.lat;
      final lng = p.lng;
      if (lat != null && lng != null) {
        points.add((lat: lat, lng: lng));
      }
    }
  }

  final Uri uri;
  if (points.isEmpty) {
    final q = (data.city != null && data.city!.trim().isNotEmpty)
        ? data.city!.trim()
        : 'travel destination';
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
  } else if (points.length == 1) {
    final p = points.first;
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}',
    );
  } else {
    final path = points.map((e) => '${e.lat},${e.lng}').join('/');
    uri = Uri.parse('https://www.google.com/maps/dir/$path');
  }

  try {
    // Some Android/plugin states can throw PlatformException on channel setup.
    // Keep this path safe and report failure to UI instead of crashing.
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
