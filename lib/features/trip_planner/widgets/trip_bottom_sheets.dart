import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────

String formatBudgetINR(double v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
  return '₹${v.toStringAsFixed(0)}';
}

class TripGradientButton extends StatelessWidget {
  const TripGradientButton({
    super.key,
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

// ═════════════════════════════════════════════
//  DURATION PICKER  (1 – 30 grid)
// ═════════════════════════════════════════════
class DurationSheet extends StatefulWidget {
  const DurationSheet({super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<DurationSheet> {
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
class PersonSheet extends StatefulWidget {
  const PersonSheet({super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<PersonSheet> {
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
            child: TripGradientButton(
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
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({
    super.key,
    required this.range,
    required this.enabled,
    required this.onDone,
  });
  final RangeValues range;
  final bool enabled;
  final void Function(RangeValues, bool) onDone;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
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
                      value: formatBudgetINR(_range.start),
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
                      value: formatBudgetINR(_range.end),
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
            child: TripGradientButton(
              label: _enabled
                  ? 'Set  ${formatBudgetINR(_range.start)} – ${formatBudgetINR(_range.end)}'
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
