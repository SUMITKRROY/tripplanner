import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class CommonTopBar extends StatelessWidget {
  const CommonTopBar({
    super.key,
    this.title = AppConstants.topTittle,
    this.onBack,
    this.onSearch,
    this.showSearch = true,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x55000000)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onBack,
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 28,
                color: scheme.onSurface,
              ),
            ),
          ],
          Icon(Icons.flight_takeoff_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          if (showSearch)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onSearch ?? () {},
              icon: Icon(
                Icons.search_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ),
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
