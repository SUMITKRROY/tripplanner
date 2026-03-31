import 'package:flutter/material.dart';

import '../../features/trip_planner/screens/expense_detail_screen.dart';
import '../../features/trip_planner/screens/home_screen.dart';
import '../../features/trip_planner/screens/loading_screen.dart';
import '../../features/trip_planner/screens/map_view_screen.dart';
import '../../features/trip_planner/screens/splash_screen.dart';
import '../../features/trip_planner/screens/trip_analysis_success_screen.dart';
import '../../features/trip_planner/screens/trip_result_screen.dart';
import '../../features/trip_planner/screens/view_full_plan_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String loading = '/loading';
  static const String tripResult = '/trip-result';
  static const String tripAnalysisSuccess = '/trip-analysis-success';
  static const String mapView = '/map-view';
  static const String expenseDetail = '/expense-detail';
  static const String viewFullPlan = '/view-full-plan';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
      case loading:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoadingScreen(),
        );
      case tripResult:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TripResultScreen(),
        );
      case tripAnalysisSuccess:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TripAnalysisSuccessScreen(),
        );

    // ── Map View ────────────────────────────────────────────────────────
    // Push with either:
    //   (a) a raw trip JSON map  →  Navigator.pushNamed(context, AppRoutes.mapView, arguments: tripJsonMap)
    //   (b) a MapViewArgs object →  Navigator.pushNamed(context, AppRoutes.mapView, arguments: MapViewArgs(...))
      case mapView:
        final args = settings.arguments;

        // (a) Raw JSON map from API response
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => MapViewScreen.fromJson(args),
          );
        }

        // (b) Typed args
        if (args is MapViewArgs) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => MapViewScreen(
              tripDays: args.tripDays,
              apiKey: args.apiKey,
              city: args.city,
            ),
          );
        }

        // Fallback – show an error scaffold instead of a hard crash
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _MissingArgsScreen(route: AppRoutes.mapView),
        );
    // ────────────────────────────────────────────────────────────────────

      case expenseDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ExpenseDetailScreen(),
        );
      case viewFullPlan:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ViewFullPlanScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }
}

// ── Typed argument wrapper for MapViewScreen ──────────────────────────────────

class MapViewArgs {
  final List<TripDay> tripDays;
  final String apiKey;
  final String city;

  const MapViewArgs({
    required this.tripDays,
    required this.apiKey,
    required this.city,
  });
}

// ── Fallback screen shown when arguments are missing ──────────────────────────

class _MissingArgsScreen extends StatelessWidget {
  final String route;
  const _MissingArgsScreen({required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFFF6B35), size: 48),
            const SizedBox(height: 16),
            Text(
              'Missing arguments for\n"$route"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}