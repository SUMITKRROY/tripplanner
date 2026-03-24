import 'package:flutter/material.dart';

import '../models/generate_trip_response_model.dart'
    show GenerateTripResponseModel, TripDayPlanModel;
import 'place_image.dart';

/// Modal that shows a summary of the generated trip; user taps to go to full result.
class TripSuccessModal extends StatelessWidget {
  const TripSuccessModal({
    super.key,
    required this.data,
    required this.onViewFullPlan,
  });

  final GenerateTripResponseModel data;
  final VoidCallback onViewFullPlan;

  static Future<void> show(
    BuildContext context, {
    required GenerateTripResponseModel data,
    required VoidCallback onViewFullPlan,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripSuccessModal(
        data: data,
        onViewFullPlan: () {
          Navigator.of(context).pop();
          onViewFullPlan();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = data.expenses;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Trip plan ready',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.summary != null && data.summary!.isNotEmpty)
                Text(
                  data.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    icon: Icons.place,
                    label: data.city ?? '—',
                  ),
                  _Chip(
                    icon: Icons.calendar_today_rounded,
                    label: '${data.days ?? 0} days',
                  ),
                  _Chip(
                    icon: Icons.person_rounded,
                    label: '${data.persons ?? 0} persons',
                  ),
                  if (expenses?.total != null)
                    _Chip(
                      icon: Icons.account_balance_wallet_rounded,
                      label: '₹${expenses!.total}',
                    ),
                  if (expenses?.withinBudget == true)
                    _Chip(
                      icon: Icons.savings_rounded,
                      label: 'Within budget',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (data.tripPlan.isNotEmpty) ...[
                Text(
                  'Highlights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Horizontal image strip from first places
                _buildImageStrip(context, data.tripPlan),
                const SizedBox(height: 12),
                ...data.tripPlan.take(3).map(
                      (day) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${day.day}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                day.theme ?? '—',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
              ],
              FilledButton.icon(
                onPressed: onViewFullPlan,
                icon: const Icon(Icons.map_rounded, size: 22),
                label: const Text('View full plan'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageStrip(
      BuildContext context, List<TripDayPlanModel> tripPlan) {
    final places = tripPlan
        .expand((d) => d.places)
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .take(6)
        .toList();
    if (places.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final place = places[index];
          return PlaceImage(
            imageUrl: place.imageUrl!,
            width: 120,
            height: 100,
            borderRadius: BorderRadius.circular(12),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
