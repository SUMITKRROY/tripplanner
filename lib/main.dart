import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/trip_planner/bloc/trip_planner_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeModeController = ThemeModeController();
  await themeModeController.loadThemeMode();
  runApp(TripPlannerApp(themeModeController: themeModeController));
}

class TripPlannerApp extends StatelessWidget {
  const TripPlannerApp({required this.themeModeController, super.key});

  final ThemeModeController themeModeController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripPlannerBloc(),
      child: AnimatedBuilder(
        animation: themeModeController,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeModeController.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}
