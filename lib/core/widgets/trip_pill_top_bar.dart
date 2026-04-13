import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Pill-shaped brand bar: logo, title, optional search, avatar, optional back.
///
/// Back chevron:
/// - [forceShowBack] — always show (e.g. [TripDashboardScreen]).
/// - Otherwise, when [adaptiveBack] is true, show only if `Navigator.canPop`.
enum TripPillTopBarStyle {
  /// Solid pill for in-layout / SafeArea usage (scroll pages).
  embedded,

  /// Translucent pill over hero imagery or full-bleed content.
  floatingOverMedia,
}

class TripPillTopBar extends StatelessWidget {
  const TripPillTopBar({
    super.key,
    this.title = AppConstants.topTittle,
    this.onBack,
    this.onSearch,
    this.showSearch = false,
    this.forceShowBack = false,
    this.adaptiveBack = true,
    this.style = TripPillTopBarStyle.embedded,
    this.showAvatar = true,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final bool showSearch;

  /// When true, the back control is always shown (still needs a handler).
  final bool forceShowBack;

  /// When true and [forceShowBack] is false, back is shown only if the
  /// navigator can pop (e.g. after a push).
  final bool adaptiveBack;

  final TripPillTopBarStyle style;
  final bool showAvatar;

  bool _showBackChevron(BuildContext context) {
    if (forceShowBack) return true;
    if (!adaptiveBack) return false;
    return Navigator.maybeOf(context)?.canPop() ?? false;
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final showBack = _showBackChevron(context);

    final EdgeInsets padding;
    final double flightIconSize;
    final double trailingGap;
    if (style == TripPillTopBarStyle.floatingOverMedia) {
      padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
      flightIconSize = 20;
      trailingGap = 4;
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      flightIconSize = 22;
      trailingGap = 0;
    }

    final Color bg;
    final List<BoxShadow> shadows;
    if (style == TripPillTopBarStyle.floatingOverMedia) {
      bg = isDark
          ? const Color(0xFF161E28).withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      bg = isDark ? const Color(0xFF161E28) : Colors.white;
      shadows = [
        BoxShadow(
          color: isDark
              ? const Color(0x55000000)
              : Colors.black.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      ];
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => _handleBack(context),
              icon: Icon(
                Icons.chevron_left_rounded,
                size: 28,
                color: scheme.onSurface,
              ),
            ),
          ],
          Icon(
            Icons.flight_takeoff_rounded,
            color: scheme.primary,
            size: flightIconSize,
          ),
          SizedBox(width: style == TripPillTopBarStyle.floatingOverMedia ? 7 : 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: style == TripPillTopBarStyle.floatingOverMedia
                    ? -0.4
                    : -0.5,
                color: scheme.onSurface,
              ),
            ),
          ),
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
          if (showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 17,
                color: scheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: trailingGap),
          ],
        ],
      ),
    );
  }
}
