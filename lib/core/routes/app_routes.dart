import 'package:flutter/material.dart';

import '../../features/trip_planner/screens/expense_detail_screen.dart';
import '../../features/trip_planner/screens/home_screen.dart';
import '../../features/trip_planner/screens/loading_screen.dart';
import '../../features/trip_planner/screens/map_view_screen.dart';
import '../../features/trip_planner/screens/splash_screen.dart';
import '../../features/trip_planner/screens/trip_result_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String loading = '/loading';
  static const String tripResult = '/trip-result';
  static const String mapView = '/map-view';
  static const String expenseDetail = '/expense-detail';

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
      case mapView:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MapViewScreen(),
        );
      case expenseDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ExpenseDetailScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }
}
