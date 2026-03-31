import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_utils.dart';
import '../bloc/trip_planner_bloc.dart';
import '../bloc/trip_planner_event.dart';
import '../bloc/trip_planner_state.dart';
import '../models/generate_trip_request_model.dart';

// ─────────────────────────────────────────────
//  INR formatter
// ─────────────────────────────────────────────
String _formatINR(double v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
  return '₹${v.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────
//  Trending destination model
// ─────────────────────────────────────────────
class _Destination {
  final String name;
  final String tag;
  final List<Color> gradient;
  const _Destination({
    required this.name,
    required this.tag,
    required this.gradient,
  });
}

// ═════════════════════════════════════════════
//  HOME SCREEN
// ═════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();

  int _selectedDays = 2;
  int _selectedPersons = 2;
  RangeValues _budgetRange = const RangeValues(10000, 50000);
  bool _budgetEnabled = true;

  int _selectedNavIndex = 0;
  int _activeFilter = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final _filters = const [
    'Best by Season',
    'Solo Friendly',
    'Luxury Stays',
    'Hidden Gems',
  ];

  final _trending = const [
    _Destination(
      name: 'Maldives Escape',
      tag: 'TRENDING NOW',
      gradient: [Color(0xFF0F4C75), Color(0xFF1B6CA8), Color(0xFF19A7CE)],
    ),
    _Destination(
      name: 'Cinque Terre',
      tag: 'CLASSIC EUROPE',
      gradient: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── snack helper ─────────────────────────────
  void _snack(String msg) {
    final scheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.of(context).padding.top + AppTheme.sp3;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          backgroundColor: scheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.fromLTRB(AppTheme.sp4, topInset, AppTheme.sp4, 0),
        ),
      );
  }

  // ── bottom sheets ─────────────────────────────
  void _openDuration() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DurationSheet(
        selected: _selectedDays,
        onSelected: (d) {
          setState(() => _selectedDays = d);
          Navigator.pop(context);
          _snack('🗓  $d ${d == 1 ? 'Day' : 'Days'} selected');
        },
      ),
    );
  }

  void _openPersons() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PersonSheet(
        selected: _selectedPersons,
        onSelected: (p) {
          setState(() => _selectedPersons = p);
          Navigator.pop(context);
          _snack('👥  $p ${p == 1 ? 'Person' : 'Persons'} selected');
        },
      ),
    );
  }

  void _openBudget() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BudgetSheet(
        range: _budgetRange,
        enabled: _budgetEnabled,
        onDone: (r, e) {
          setState(() {
            _budgetRange = r;
            _budgetEnabled = e;
          });
        },
      ),
    );
  }

  void _analyzeTrip() {
    if (_formKey.currentState?.validate() ?? false) {
      final request = GenerateTripRequestModel(
        city: _destinationController.text.trim(),
        days: _selectedDays,
        persons: _selectedPersons,
        budget: _budgetEnabled ? _budgetRange.end.toInt() : null,
      );
      context.read<TripPlannerBloc>().add(TripPlannerGenerateTrip(request));
      NavigationUtils.pushNamed(context, AppRoutes.loading);
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      final hasTrip =
          context.read<TripPlannerBloc>().state is TripPlannerSuccess;
      if (!hasTrip) {
        _snack('Please analyze trip first');
        setState(() => _selectedNavIndex = 0);
        return;
      }
      setState(() => _selectedNavIndex = index);
      NavigationUtils.pushNamed(context, AppRoutes.tripResult);
      return;
    }
    setState(() => _selectedNavIndex = index);
  }

  // ── build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.sp4),
                      _TopBar(isDark: isDark),
                      const SizedBox(height: AppTheme.sp6),

                      // Greeting
                      Text(
                        'Good to see you, Traveler',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp2),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                          children: [
                            const TextSpan(text: 'Where will your\n'),
                            TextSpan(
                              text: 'curiosity',
                              style: TextStyle(color: scheme.primary),
                            ),
                            const TextSpan(text: ' lead you?'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp6),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Search
                            TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                hintText: 'Find your next adventure',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                  borderSide: BorderSide(
                                    color: scheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF1C2530)
                                    : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.sp4,
                                  vertical: AppTheme.sp3,
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter a destination'
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.sp3),

                            // Duration
                            _StatRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'DURATION',
                              value:
                                  '$_selectedDays ${_selectedDays == 1 ? 'Day' : 'Days'}',
                              isDark: isDark,
                              onTap: _openDuration,
                            ),
                            const SizedBox(height: AppTheme.sp2),

                            // Travelers
                            _StatRow(
                              icon: Icons.people_alt_rounded,
                              label: 'TRAVELERS',
                              value:
                                  '$_selectedPersons ${_selectedPersons == 1 ? 'Person' : 'Persons'}',
                              isDark: isDark,
                              onTap: _openPersons,
                            ),
                            const SizedBox(height: AppTheme.sp2),

                            // Budget
                            _StatRow(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'BUDGET RANGE',
                              value: _budgetEnabled
                                  ? '${_formatINR(_budgetRange.start)} – ${_formatINR(_budgetRange.end)}'
                                  : 'No limit',
                              isDark: isDark,
                              onTap: _openBudget,
                              isOptional: true,
                              optionalActive: _budgetEnabled,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp4),

                      // Filters
                      Text(
                        'Quick Filters:',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp2),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filters.length, (i) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: i < _filters.length - 1
                                    ? AppTheme.sp2
                                    : 0,
                              ),
                              child: _FilterChip(
                                label: _filters[i],
                                selected: _activeFilter == i,
                                onTap: () => setState(() => _activeFilter = i),
                                isDark: isDark,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp6),

                      // CTA
                      _GradientButton(
                        label: 'Analyze Trip',
                        icon: Icons.auto_awesome_rounded,
                        isDark: isDark,
                        onPressed: _analyzeTrip,
                      ),
                      const SizedBox(height: AppTheme.sp6),

                      // Trending
                      Text(
                        'Trending Destinations',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp3),
                      ..._trending.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.sp3),
                          child: _TrendingCard(destination: d),
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  STAT ROW (tappable)
// ═════════════════════════════════════════════
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
    this.isOptional = false,
    this.optionalActive = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;
  final bool isOptional;
  final bool optionalActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp4,
          vertical: AppTheme.sp3 + 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161E28) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE5EAF0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: 20),
            const SizedBox(width: AppTheme.sp3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    if (isOptional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OPTIONAL',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isOptional && !optionalActive
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  DURATION PICKER  (1 – 30 grid)
// ═════════════════════════════════════════════
class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late int _pick;

  @override
  void initState() {
    super.initState();
    _pick = widget.selected;
  }

  void _select(int d) {
    HapticFeedback.lightImpact();
    setState(() => _pick = d);
    Future.delayed(
      const Duration(milliseconds: 140),
      () => widget.onSelected(d),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppTheme.sp3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE5EAF0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.sp3),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp4),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.sp2),
                Text(
                  'Trip Duration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp3,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '$_pick ${_pick == 1 ? 'Day' : 'Days'}',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sp2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap a number to pick your trip length',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp3),

          // 1–30 grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp3),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 30,
              itemBuilder: (_, i) {
                final day = i + 1;
                final sel = day == _pick;
                return GestureDetector(
                  onTap: () => _select(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: sel
                          ? scheme.primary
                          : isDark
                          ? const Color(0xFF1C2530)
                          : const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: sel
                          ? (isDark
                                ? AppTheme.darkPrimaryGlow
                                : AppTheme.lightAquaGlow)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 15,
                          color: sel
                              ? (isDark
                                    ? const Color(0xFF002825)
                                    : Colors.white)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.sp3),

          // Quick-pick labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickDay('Weekend', 3, scheme, _select),
                _QuickDay('1 Week', 7, scheme, _select),
                _QuickDay('2 Weeks', 14, scheme, _select),
                _QuickDay('Month', 30, scheme, _select),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sp6),
        ],
      ),
    );
  }
}

class _QuickDay extends StatelessWidget {
  const _QuickDay(this.label, this.days, this.scheme, this.onTap);
  final String label;
  final int days;
  final ColorScheme scheme;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(days),
      child: Column(
        children: [
          Text(
            '$days',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: scheme.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  PERSON PICKER
// ═════════════════════════════════════════════
class _PersonSheet extends StatefulWidget {
  const _PersonSheet({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<_PersonSheet> {
  late int _count;

  static const _presets = [
    (icon: Icons.person_rounded, label: 'Solo', n: 1),
    (icon: Icons.favorite_rounded, label: 'Couple', n: 2),
    (icon: Icons.family_restroom_rounded, label: 'Family', n: 4),
    (icon: Icons.groups_rounded, label: 'Group', n: 8),
  ];

  @override
  void initState() {
    super.initState();
    _count = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppTheme.sp3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE5EAF0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.sp3),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp4),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: Row(
              children: [
                Icon(Icons.people_alt_rounded, color: scheme.primary, size: 22),
                const SizedBox(width: AppTheme.sp2),
                Text(
                  'Number of Travelers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sp6),

          // ── Counter ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleBtn(
                icon: Icons.remove_rounded,
                enabled: _count > 1,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _count--);
                },
              ),
              const SizedBox(width: AppTheme.sp8),
              Column(
                children: [
                  Text(
                    '$_count',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    _count == 1 ? 'Person' : 'Persons',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.sp8),
              _CircleBtn(
                icon: Icons.add_rounded,
                enabled: _count < 20,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _count++);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp6),

          // ── Presets ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _presets.map((p) {
                final active = _count == p.n;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _count = p.n);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp3,
                      vertical: AppTheme.sp2 + 2,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? scheme.primary.withOpacity(0.12)
                          : isDark
                          ? const Color(0xFF1C2530)
                          : const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: active
                            ? scheme.primary.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          p.icon,
                          size: 22,
                          color: active
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.sp6),

          // Confirm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: _GradientButton(
              label: 'Confirm  $_count ${_count == 1 ? 'Person' : 'Persons'}',
              icon: Icons.check_rounded,
              isDark: isDark,
              onPressed: () => widget.onSelected(_count),
            ),
          ),
          const SizedBox(height: AppTheme.sp6),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? scheme.primary.withOpacity(0.12)
              : (isDark ? const Color(0xFF1C2530) : const Color(0xFFF0F2F5)),
          border: Border.all(
            color: enabled
                ? scheme.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? scheme.primary : scheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  BUDGET SHEET  (INR Range Slider)
// ═════════════════════════════════════════════
class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({
    required this.range,
    required this.enabled,
    required this.onDone,
  });
  final RangeValues range;
  final bool enabled;
  final void Function(RangeValues, bool) onDone;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late RangeValues _range;
  late bool _enabled;

  static const double _min = 5000;
  static const double _max = 500000;

  static const _presets = [
    ('Budget', RangeValues(5000, 25000)),
    ('Mid-range', RangeValues(25000, 100000)),
    ('Luxury', RangeValues(100000, 300000)),
    ('Ultra Luxury', RangeValues(300000, 500000)),
  ];

  @override
  void initState() {
    super.initState();
    _range = widget.range;
    _enabled = widget.enabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(AppTheme.sp3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE5EAF0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.sp3),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sp4),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.sp2),
                Text(
                  'Budget Range (₹)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // No-limit toggle
                Row(
                  children: [
                    Text(
                      'No Limit',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: !_enabled
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: !_enabled
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    Switch(
                      value: !_enabled,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() => _enabled = !v);
                      },
                      activeColor: scheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_enabled) ...[
            const SizedBox(height: AppTheme.sp3),

            // Min / Max pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
              child: Row(
                children: [
                  Expanded(
                    child: _RangePill(
                      label: 'MIN',
                      value: _formatINR(_range.start),
                      scheme: scheme,
                      isDark: isDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp3,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: _RangePill(
                      label: 'MAX',
                      value: _formatINR(_range.end),
                      scheme: scheme,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sp3),

            // Range slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp2),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: scheme.primary,
                  inactiveTrackColor: scheme.primary.withOpacity(0.15),
                  thumbColor: scheme.primary,
                  overlayColor: scheme.primary.withOpacity(0.12),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 11,
                    elevation: 0,
                  ),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                ),
                child: RangeSlider(
                  values: _range,
                  min: _min,
                  max: _max,
                  divisions: 99,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _range = v);
                  },
                ),
              ),
            ),

            // Axis labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['₹5K', '₹1L', '₹2L', '₹5L']
                    .map(
                      (t) => Text(
                        t,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppTheme.sp4),

            // Presets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
              child: Wrap(
                spacing: AppTheme.sp2,
                runSpacing: AppTheme.sp2,
                children: _presets.map((p) {
                  final active =
                      _range.start == p.$2.start && _range.end == p.$2.end;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _range = p.$2);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp3,
                        vertical: AppTheme.sp2,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? scheme.primary
                            : isDark
                            ? const Color(0xFF1C2530)
                            : const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        p.$1,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp4,
                vertical: AppTheme.sp8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.all_inclusive_rounded,
                    color: scheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.sp3),
                  Text(
                    'No budget limit set',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTheme.sp4),

          // Done
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp4),
            child: _GradientButton(
              label: _enabled
                  ? 'Set  ${_formatINR(_range.start)} – ${_formatINR(_range.end)}'
                  : 'Continue without budget',
              icon: Icons.check_rounded,
              isDark: isDark,
              onPressed: () {
                widget.onDone(_range, _enabled);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: AppTheme.sp6),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({
    required this.label,
    required this.value,
    required this.scheme,
    required this.isDark,
  });
  final String label;
  final String value;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp3,
        vertical: AppTheme.sp2,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2530) : const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.sp4,
        vertical: AppTheme.sp3,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: isDark ? AppTheme.darkCardShadow : AppTheme.lightCardShadow,
      ),
      child: Row(
        children: [
          Text(
            'TripPlanner',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerLow,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.sp2),
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              size: 17,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp4,
          vertical: AppTheme.sp2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : (isDark ? const Color(0xFF161E28) : Colors.white),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? const Color(0x1AFFFFFF) : const Color(0xFFDDE3EA)),
          ),
          boxShadow: selected
              ? (isDark ? AppTheme.darkPrimaryGlow : AppTheme.lightAquaGlow)
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? Colors.white : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        gradient: isDark
            ? AppTheme.darkPrimaryButtonGradient
            : AppTheme.lightPrimaryButtonGradient,
        boxShadow: isDark ? AppTheme.darkPrimaryGlow : AppTheme.lightAquaGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          splashColor: Colors.white.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.sp4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: AppTheme.sp2),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.destination});
  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: destination.gradient,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sp3,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: Text(
                        destination.tag,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      destination.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
    (Icons.event_note_outlined, Icons.event_note_rounded, 'Itinerary'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      destinations: _items
          .map(
            (e) => NavigationDestination(
              icon: Icon(e.$1),
              selectedIcon: Icon(e.$2),
              label: e.$3,
            ),
          )
          .toList(),
    );
  }
}
