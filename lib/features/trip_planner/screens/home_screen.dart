import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_event.dart';
import '../models/generate_trip_request_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _daysController = TextEditingController(text: '5');
  final _personsController = TextEditingController(text: '2');
  final _budgetController = TextEditingController();
  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _destinationController.dispose();
    _daysController.dispose();
    _personsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _analyzeTrip() {
    if (_formKey.currentState?.validate() ?? false) {
      final city = _destinationController.text.trim();
      final days = int.tryParse(_daysController.text.trim()) ?? 1;
      final persons = int.tryParse(_personsController.text.trim()) ?? 1;
      final budgetStr = _budgetController.text.trim();
      final budget =
          budgetStr.isEmpty ? null : int.tryParse(budgetStr);

      final request = GenerateTripRequestModel(
        city: city,
        days: days,
        persons: persons,
        budget: budget,
      );

      context.read<TripPlannerBloc>().add(
            TripPlannerGenerateTrip(request),
          );
      NavigationUtils.pushNamed(context, AppRoutes.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: greeting + profile + notification
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Good to see you, Traveler',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search / input form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Find your next adventure',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              hintText: 'Destination city',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Enter a destination' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _daysController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Days',
                                    labelText: 'Number of days',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final n = int.tryParse(v);
                                    if (n == null || n < 1) return 'Min 1 day';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _personsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Persons',
                                    labelText: 'Persons',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final n = int.tryParse(v);
                                    if (n == null || n < 1) return 'Min 1';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Optional budget (e.g. 1500)',
                              labelText: 'Budget',
                              prefixIcon: Icon(Icons.attach_money_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('Best by Season'),
                          const SizedBox(width: 8),
                          _chip('Weekend Getaways'),
                          const SizedBox(width: 8),
                          _chip('7 days'),
                          const SizedBox(width: 8),
                          _chip('Budget'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Primary CTA
                    FilledButton(
                      onPressed: _analyzeTrip,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 22),
                          SizedBox(width: 10),
                          Text('Analyze Trip'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (i) => setState(() => _selectedNavIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return FilterChip(
      label: Text(label),
      onSelected: (_) {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
