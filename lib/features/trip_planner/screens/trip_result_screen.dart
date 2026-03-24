import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';
import '../models/generate_trip_response_model.dart'
    show GenerateTripResponseModel, PlaceModel;
import '../widgets/place_image.dart';

class TripResultScreen extends StatelessWidget {
  const TripResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerBloc, TripPlannerState>(
      buildWhen: (previous, current) => current is TripPlannerSuccess,
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
              child: Text('No trip data. Plan a trip from the home screen.'),
            ),
          );
        }
        return _TripResultContent(data: state.data);
      },
    );
  }
}

class _TripResultContent extends StatelessWidget {
  const _TripResultContent({required this.data});

  final GenerateTripResponseModel data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = data.expenses;
    final heroImageUrl = data.tripPlan
        .expand((d) => d.places)
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .map((p) => p.imageUrl!)
        .firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => NavigationUtils.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(data.city ?? 'Your Trip Plan'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (heroImageUrl != null)
                    PlaceImage(
                      imageUrl: heroImageUrl,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.black54,
                          const Color(0xFF1E3D32),
                        ],
                      ),
                    ),
                  ),
                  if (heroImageUrl == null)
                    Center(
                      child: Icon(
                        Icons.landscape_rounded,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.summary != null && data.summary!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        data.summary!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context, Icons.schedule,
                          '${data.days ?? 0} days'),
                      _chip(context, Icons.person_rounded,
                          '${data.persons ?? 0} persons'),
                      if (expenses != null)
                        _chip(context, Icons.account_balance_wallet_rounded,
                            '₹${expenses.total}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Day-wise itinerary',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...data.tripPlan.map(
                    (day) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ItineraryCard(
                        day: day.day ?? 0,
                        title: day.theme ?? '—',
                        description: day.description,
                        places: day.places,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Map preview',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => NavigationUtils.pushNamed(
                        context,
                        AppRoutes.mapView,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 160,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'View full map with route & spots',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to open',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color:
                                              theme.colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Famous locations',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...data.tripPlan.expand((day) => day.places.take(2)).map(
                        (place) => _LocationTile(
                          name: place.name ?? '—',
                          subtitle:
                              place.category ?? place.description ?? '',
                          imageUrl: place.imageUrl,
                        ),
                      ),
                  const SizedBox(height: 24),
                  Text(
                    'Expense summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (expenses != null) ...[
                            _SummaryRow(
                                'Estimated total', '₹${expenses.total}'),
                            const Divider(height: 20),
                            _SummaryRow('Per person (${data.persons ?? 0})',
                                '₹${expenses.perPerson}'),
                            if (expenses.withinBudget == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 20,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Within budget',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ] else
                            const _SummaryRow('—', '—'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => NavigationUtils.pushNamed(
                              context,
                              AppRoutes.expenseDetail,
                            ),
                            icon: const Icon(
                                Icons.receipt_long_rounded, size: 20),
                            label: const Text('View expense breakdown'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18,
          color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.day,
    required this.title,
    this.description,
    this.places = const [],
  });

  final int day;
  final String title;
  final String? description;
  final List<PlaceModel> places;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(title),
        subtitle: description != null && description!.isNotEmpty
            ? Text(
                description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        children: places.isEmpty
            ? []
            : places
                .map((p) => ListTile(
                      dense: true,
                      leading: p.imageUrl != null &&
                              p.imageUrl!.isNotEmpty
                          ? SizedBox(
                              width: 48,
                              height: 48,
                              child: PlaceImage(
                                imageUrl: p.imageUrl!,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                          : Icon(Icons.place_rounded,
                              size: 24,
                              color: theme.colorScheme.primary),
                      title: Text(p.name ?? '—'),
                    ))
                .toList(),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.name,
    required this.subtitle,
    this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: imageUrl != null && imageUrl!.isNotEmpty
          ? SizedBox(
              width: 56,
              height: 56,
              child: PlaceImage(
                imageUrl: imageUrl!,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          : Icon(Icons.place_rounded, color: theme.colorScheme.primary),
      title: Text(name),
      subtitle: Text(subtitle),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
