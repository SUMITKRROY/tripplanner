import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/trip_pill_top_bar.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';
import 'expense_detail_screen.dart';
import 'map_view_screen.dart';
import 'trip_result_screen.dart';

class TripDashboardScreen extends StatefulWidget {
  final int initialIndex;

  const TripDashboardScreen({super.key, this.initialIndex = 1});

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerBloc, TripPlannerState>(
      buildWhen: (prev, curr) => curr is TripPlannerSuccess,
      builder: (context, state) {
        if (state is! TripPlannerSuccess) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => NavigationUtils.pop(context),
              ),
            ),
            body: const Center(
              child: Text('No trip data available.'),
            ),
          );
        }

        final data = state.data;
        // Build map view args as raw JSON map equivalent
        final mapArgs = {
          'city': data.city ?? 'Trip',
          'apiKey': '', // MapViewScreen handles fallback to constant
          'tripPlan': data.tripPlan
              .map(
                (day) => {
                  'day': day.day ?? 1,
                  'theme': day.theme ?? '',
                  'description': day.description ?? '',
                  'totalTimeMin': day.totalTimeMin ?? 0,
                  'places': day.places
                      .where((p) => p.lat != null && p.lng != null)
                      .map(
                        (p) => {
                          'name': p.name ?? '',
                          'lat': p.lat!,
                          'lng': p.lng!,
                          'duration': p.duration ?? 60,
                          'category': p.category ?? '',
                          'description': p.description ?? '',
                          'tips': p.tips ?? '',
                          'bestTime': p.bestTime ?? '',
                          'rating': p.rating ?? 0.0,
                          'imageUrl': p.imageUrl ?? '',
                          'openingHours': p.openingHours ?? '',
                        },
                      )
                      .toList(),
                },
              )
              .toList(),
        };

        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: [
                  MapViewScreen.fromJson(mapArgs),
                  const TripResultScreen(showPillTopBar: false),
                  const ExpenseDetailScreen(showPillTopBar: false),
                ],
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: TripPillTopBar(
                  style: TripPillTopBarStyle.floatingOverMedia,
                  forceShowBack: true,
                  onBack: () => NavigationUtils.pop(context),
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note_rounded),
                label: 'Itinerary',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Expenses',
              ),
            ],
          ),
        );
      },
    );
  }
}
