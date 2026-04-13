import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/trip_pill_top_bar.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_state.dart';
import '../models/generate_trip_response_model.dart';

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────

String _inr(num? v) {
  if (v == null) return '—';
  final rounded = v.round();
  if (rounded >= 10000000) {
    return '₹${(rounded / 10000000).toStringAsFixed(1)}Cr';
  } else if (rounded >= 100000) {
    return '₹${(rounded / 100000).toStringAsFixed(1)}L';
  } else if (rounded >= 1000) {
    final formatted = rounded.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return '₹$formatted';
  }
  return '₹$rounded';
}

/// Wraps [_inr] with an ≈ prefix to signal approximate values.
String _approxInr(num? v) {
  if (v == null) return '—';
  return '≈ ${_inr(v)}';
}

// ─────────────────────────────────────────────
//  ROOT SCREEN
// ─────────────────────────────────────────────

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, this.showPillTopBar = true});

  /// When false (e.g. inside [TripDashboardScreen]), the shell provides the bar.
  final bool showPillTopBar;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerBloc, TripPlannerState>(
      builder: (context, state) {
        if (state is! TripPlannerSuccess) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => NavigationUtils.pop(context),
              ),
              title: const Text('Expense Breakdown'),
            ),
            body: const Center(
              child: Text('Open a trip plan first to see expenses.'),
            ),
          );
        }
        return _ExpenseBody(
          data: state.data,
          showPillTopBar: showPillTopBar,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  BODY
// ─────────────────────────────────────────────

class _ExpenseBody extends StatefulWidget {
  const _ExpenseBody({
    required this.data,
    required this.showPillTopBar,
  });
  final GenerateTripResponseModel data;
  final bool showPillTopBar;

  @override
  State<_ExpenseBody> createState() => _ExpenseBodyState();
}

class _ExpenseBodyState extends State<_ExpenseBody> {
  int _selectedNav = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final data = widget.data;
    final e = data.expenses;
    final persons = data.persons ?? 1;
    final days = data.days ?? data.tripPlan.length;
    final city = data.city ?? 'Your Trip';
    final total = e?.total;
    final perPerson = e?.perPerson ?? (total != null ? total ~/ persons : null);

    // Build category rows
    final rows = <_CategoryRow>[];
    if (e?.hotel != null) {
      rows.add(
        _CategoryRow(
          icon: Icons.hotel_rounded,
          label: 'Hotel',
          perPerson: (e!.hotel! / persons).round(),
          total: e.hotel!,
        ),
      );
    }
    if (e?.food != null) {
      rows.add(
        _CategoryRow(
          icon: Icons.restaurant_rounded,
          label: 'Food',
          perPerson: (e!.food! / persons).round(),
          total: e.food!,
        ),
      );
    }
    if (e?.travel != null) {
      rows.add(
        _CategoryRow(
          icon: Icons.directions_bus_rounded,
          label: 'Travel',
          perPerson: (e!.travel! / persons).round(),
          total: e.travel!,
        ),
      );
    }
    if (e?.tickets != null) {
      rows.add(
        _CategoryRow(
          icon: Icons.confirmation_number_rounded,
          label: 'Entry\nFees',
          perPerson: (e!.tickets! / persons).round(),
          total: e.tickets!,
        ),
      );
    }

    // Budget health: percentage of total vs. expected (heuristic)
    final budgetPct = total != null && days > 0
        ? math.min(100, ((total / (days * persons * 3000)) * 100).round())
        : 75;

    // Potential savings (heuristic: 10% of food + travel)
    final savings = ((e?.food ?? 0) + (e?.travel ?? 0)) * 0.1;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showPillTopBar) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TripPillTopBar(
                          style: TripPillTopBarStyle.embedded,
                          onBack: () => NavigationUtils.pop(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      const SizedBox(height: 8 + 52),
                      const SizedBox(height: 12),
                    ],

                    // ── PAGE TITLE ───────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense\nBreakdown',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF17395A),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Trip to $city  •  $persons Traveler${persons == 1 ? '' : 's'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── DISCLAIMER CHIP ──────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF997300),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '≈ Average estimates  ·  Actual costs may vary',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF997300),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── CATEGORY TABLE ───────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _CategoryTable(
                        rows: rows,
                        theme: theme,
                        scheme: scheme,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── GRAND TOTAL CARD ─────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _GrandTotalCard(
                        total: total,
                        perPerson: perPerson,
                        theme: theme,
                        scheme: scheme,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── BUDGET HEALTH CARD ───────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _BudgetHealthCard(
                        percent: budgetPct,
                        city: city,
                        theme: theme,
                        scheme: scheme,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── POTENTIAL SAVINGS CARD ────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PotentialSavingsCard(
                        savings: savings,
                        theme: theme,
                        scheme: scheme,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── DONE BUTTON ──────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _DoneButton(
                        onPressed: () => NavigationUtils.pop(context),
                        scheme: scheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────

class _CategoryRow {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.perPerson,
    required this.total,
  });

  final IconData icon;
  final String label;
  final int perPerson;
  final int total;
}

// ─────────────────────────────────────────────
//  CATEGORY TABLE
// ─────────────────────────────────────────────

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({
    required this.rows,
    required this.theme,
    required this.scheme,
  });

  final List<_CategoryRow> rows;
  final ThemeData theme;
  final ColorScheme scheme;

  static const _primary = Color(0xFF17395A);
  static const _iconBg = Color(0xFFE8F4FD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER ROW ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'CATEGORY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PER\nPERSON',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      height: 1.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TOTAL\nAMOUNT',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withOpacity(0.4),
          ),

          // ── DATA ROWS ─────────────────────────
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            final r = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(r.icon, color: _primary, size: 20),
                      ),
                      const SizedBox(width: 10),

                      // Label
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Per person
                      Expanded(
                        flex: 2,
                        child: Text(
                          _inr(r.perPerson),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),

                      // Total — bold primary colour
                      Expanded(
                        flex: 2,
                        child: Text(
                          _inr(r.total),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: scheme.outlineVariant.withOpacity(0.3),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GRAND TOTAL CARD
// ─────────────────────────────────────────────

class _GrandTotalCard extends StatelessWidget {
  const _GrandTotalCard({
    required this.total,
    required this.perPerson,
    required this.theme,
    required this.scheme,
  });

  final int? total;
  final int? perPerson;
  final ThemeData theme;
  final ColorScheme scheme;

  static const _primary = Color(0xFF17395A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GRAND TOTAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Including all regional taxes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Amounts column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _approxInr(total),           // ← ≈ prefix here
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _primary,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_approxInr(perPerson)} per person',   // ← ≈ prefix here
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0077CC),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),

              // ── RANGE DISCLAIMER ────────────────
              Text(
                '< costs may be lower  or  higher >',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BUDGET HEALTH CARD
// ─────────────────────────────────────────────

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({
    required this.percent,
    required this.city,
    required this.theme,
    required this.scheme,
  });

  final int percent;
  final String city;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 6,
                    color: const Color(0xFFE0EAF4),
                  ),
                ),
                // Progress arc
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: const Color(0xFF17395A),
                  ),
                ),
                Text(
                  '$percent%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF17395A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Health',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF17395A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You are under your planned daily average for $city.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
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
//  POTENTIAL SAVINGS CARD
// ─────────────────────────────────────────────

class _PotentialSavingsCard extends StatelessWidget {
  const _PotentialSavingsCard({
    required this.savings,
    required this.theme,
    required this.scheme,
  });

  final double savings;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Piggy bank icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.savings_rounded,
              size: 28,
              color: Color(0xFF17395A),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'POTENTIAL SAVINGS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _inr(savings > 0 ? savings : null),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF17395A),
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DONE BUTTON
// ─────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onPressed, required this.scheme});

  final VoidCallback onPressed;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: const LinearGradient(
          colors: [Color(0xFF17395A), Color(0xFF0077CC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077CC).withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
        ),
        child: const Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
