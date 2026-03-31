import 'package:flutter/material.dart';

// ============================================================
//  ETHEREAL VOYAGER  ×  PRISTINE AVIATOR
//  Design System – AppTheme
// ============================================================

class AppTheme {
  AppTheme._();

  // ----------------------------------------------------------
  //  SHARED CONSTANTS
  // ----------------------------------------------------------

  // Radii
  static const double radiusSm   = 8.0;   // 0.5rem  – inputs, chips
  static const double radiusMd   = 16.0;  // 1rem    – small cards
  static const double radiusLg   = 24.0;  // 1.5rem  – glass cards
  static const double radiusXl   = 32.0;  // 2rem    – large cards
  static const double radiusFull = 999.0; // pill    – buttons, docks

  // Spacing scale (multiples of 4 pt)
  static const double sp1  = 4.0;
  static const double sp2  = 8.0;
  static const double sp3  = 12.0;
  static const double sp4  = 16.0;  // "Spacing 4" – card gap
  static const double sp6  = 24.0;
  static const double sp8  = 32.0;  // "Spacing 8" – section end
  static const double sp10 = 40.0;
  static const double sp16 = 64.0;  // "white space as a feature"

  // Blur – used in BackdropFilter / ShaderMask wrappers
  static const double blurCard   = 20.0;
  static const double blurInput  = 20.0;
  static const double blurDock   = 30.0;

  // ----------------------------------------------------------
  //  DARK PALETTE  –  "Ethereal Voyager"
  // ----------------------------------------------------------

  static const Color _dkSurface              = Color(0xFF0A0F14);
  static const Color _dkSurfaceDim           = Color(0xFF0D1319);
  static const Color _dkSurfaceContainerLow  = Color(0xFF111820);
  static const Color _dkSurfaceContainer     = Color(0xFF161E28);
  static const Color _dkSurfaceContainerHigh = Color(0xFF1C2530);
  static const Color _dkSurfaceContainerHighest = Color(0xFF212C38);
  static const Color _dkSurfaceBright        = Color(0xFF1E2A36);

  static const Color _dkPrimary              = Color(0xFF79F0E6); // teal accent
  static const Color _dkOnPrimary            = Color(0xFF002825);
  static const Color _dkPrimaryContainer     = Color(0xFF2EB2A9);
  static const Color _dkOnPrimaryContainer   = Color(0xFF002825);

  static const Color _dkTertiary             = Color(0xFF5FC2FF); // cool blue
  static const Color _dkOnTertiary           = Color(0xFF00344F);

  static const Color _dkOnSurface            = Color(0xFFEAEEF6);
  static const Color _dkOnSurfaceVariant     = Color(0xFFA7ABB2);
  static const Color _dkOutlineVariant       = Color(0x1AFFFFFF); // 10% white ghost border

  // Ambient shadow – used in custom paint / decoration helpers
  static const List<BoxShadow> darkCardShadow = [
    BoxShadow(
      color: Color(0x66000000),          // rgba(0,0,0,0.40)
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> darkPrimaryGlow = [
    BoxShadow(
      color: Color(0x4D79F0E6),          // primary @ 30%
      blurRadius: 15,
      spreadRadius: -2,
    ),
  ];

  // ----------------------------------------------------------
  //  LIGHT PALETTE  –  "Pristine Aviator"
  // ----------------------------------------------------------

  static const Color _ltSurface              = Color(0xFFF7F9FB);
  static const Color _ltSurfaceContainerLow  = Color(0xFFF2F4F6);
  static const Color _ltSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _ltSurfaceContainerHigh = Color(0xFFE8EDF2);
  static const Color _ltSurfaceContainerHighest = Color(0xFFDDE3EA);

  static const Color _ltPrimary              = Color(0xFF006591); // deep-sea navy
  static const Color _ltOnPrimary            = Color(0xFFFFFFFF);
  static const Color _ltPrimaryContainer     = Color(0xFF0EA5E9); // vibrant aqua
  static const Color _ltOnPrimaryContainer   = Color(0xFFFFFFFF);
  static const Color _ltPrimaryFixed         = Color(0xFFC9E6FF); // focus fill

  static const Color _ltOnSurface           = Color(0xFF191C1E); // dark slate
  static const Color _ltOnSurfaceVariant    = Color(0xFF42474E);
  static const Color _ltOutlineVariant      = Color(0x33BEC8D2); // 20% ghost border

  // Sky shadow – blue-tinted ambient for light cards
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x0D006591),          // primary @ 5%
      blurRadius: 40,
      offset: Offset(0, 20),
    ),
  ];

  static const List<BoxShadow> lightAquaGlow = [
    BoxShadow(
      color: Color(0x330EA5E9),          // primaryContainer @ 20%
      blurRadius: 15,
      spreadRadius: -2,
    ),
  ];

  // Gradient helpers exposed for widgets
  static const LinearGradient darkPrimaryButtonGradient = LinearGradient(
    colors: [_dkPrimaryContainer, _dkPrimary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient lightPrimaryButtonGradient = LinearGradient(
    colors: [_ltPrimary, _ltPrimaryContainer],
    begin: Alignment.topLeft,    // 135°
    end: Alignment.bottomRight,
  );

  // ----------------------------------------------------------
  //  DARK THEME  –  "Ethereal Voyager"
  // ----------------------------------------------------------

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,

      // Core surfaces
      surface:              _dkSurface,
      surfaceDim:           _dkSurfaceDim,
      surfaceContainerLowest: _dkSurfaceContainerLow,
      surfaceContainerLow:  _dkSurfaceContainerLow,
      surfaceContainer:     _dkSurfaceContainer,
      surfaceContainerHigh: _dkSurfaceContainerHigh,
      surfaceContainerHighest: _dkSurfaceContainerHighest,
      surfaceBright:        _dkSurfaceBright,

      // Primary – teal compass glow
      primary:              _dkPrimary,
      onPrimary:            _dkOnPrimary,
      primaryContainer:     _dkPrimaryContainer,
      onPrimaryContainer:   _dkOnPrimaryContainer,

      // Secondary (mirrors primary family for M3 slots)
      secondary:            _dkPrimaryContainer,
      onSecondary:          _dkOnPrimary,
      secondaryContainer:   Color(0xFF1A4A47),
      onSecondaryContainer: _dkPrimary,

      // Tertiary – cool blue
      tertiary:             _dkTertiary,
      onTertiary:           _dkOnTertiary,
      tertiaryContainer:    Color(0xFF004F77),
      onTertiaryContainer:  _dkTertiary,

      // Error
      error:                Color(0xFFFFB4AB),
      onError:              Color(0xFF690005),
      errorContainer:       Color(0xFF93000A),
      onErrorContainer:     Color(0xFFFFDAD6),

      // Text / icons
      onSurface:            _dkOnSurface,
      onSurfaceVariant:     _dkOnSurfaceVariant,
      outline:              Color(0xFF3A4550),
      outlineVariant:       _dkOutlineVariant,

      // Inverse
      inverseSurface:       Color(0xFFE1E3EB),
      onInverseSurface:     Color(0xFF2E3138),
      inversePrimary:       Color(0xFF006A63),

      // Scrim / shadow
      scrim:                Color(0xFF000000),
      shadow:               Color(0xFF000000),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _dkSurface,

      // ---- Typography ----------------------------------------
      // Plus Jakarta Sans for display/headlines, Manrope for body
      textTheme: _buildDarkTextTheme(base.textTheme),

      // ---- AppBar --------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: _dkOnSurface,
          letterSpacing: -0.02 * 20,
        ),
        iconTheme: IconThemeData(color: _dkOnSurface),
      ),

      // ---- Cards ---------------------------------------------
      // Base tokens; apply darkCardShadow + ghost border in widget
      cardTheme: CardThemeData(
        color: _dkSurfaceContainerHigh,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: sp4 / 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(
            color: Color(0x1AFFFFFF), // ghost border – 10% white
            width: 1,
          ),
        ),
      ),

      // ---- Elevated / Filled / Outlined Buttons ---------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(_dkOnPrimary),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(
            _dkPrimary.withOpacity(0.12),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: sp8, vertical: sp3),
          ),
          shape: const WidgetStatePropertyAll(
            StadiumBorder(), // pill
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(_dkPrimaryContainer),
          foregroundColor: const WidgetStatePropertyAll(_dkOnPrimary),
          overlayColor: WidgetStatePropertyAll(
            _dkPrimary.withOpacity(0.12),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: sp8, vertical: sp3),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(_dkPrimary),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Color(0x4D79F0E6), width: 1),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: sp8, vertical: sp3),
          ),
        ),
      ),

      // ---- Text Button ----------------------------------------
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(_dkPrimary),
          overlayColor: WidgetStatePropertyAll(
            _dkPrimary.withOpacity(0.08),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),

      // ---- Input Decoration -----------------------------------
      // Glass capsule – no bottom line, ghost border on focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _dkSurfaceContainerHighest.withOpacity(0.40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          borderSide: const BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          borderSide: const BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          borderSide: const BorderSide(
            color: Color(0x6679F0E6), // ghost border at 40% + teal hint
            width: 1,
          ),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: _dkOnSurfaceVariant,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: _dkOnSurfaceVariant,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: _dkPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: sp4,
          vertical: sp3,
        ),
      ),

      // ---- Chip / Filter Pills --------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: _dkSurfaceContainerLow,
        selectedColor: _dkPrimary.withOpacity(0.20),
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          color: _dkOnSurfaceVariant,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _dkPrimary,
        ),
        side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: sp3, vertical: sp1),
        elevation: 0,
        pressElevation: 0,
      ),

      // ---- Divider --------------------------------------------
      // No dividers – use spacing + tonal shifts per spec
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),

      // ---- Dialog / Bottom Sheet ------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: _dkSurfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _dkSurfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusXl),
            topRight: Radius.circular(radiusXl),
          ),
        ),
      ),

      // ---- Navigation Bar (Floating Dock style) ---------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _dkSurfaceContainerHigh.withOpacity(0.80),
        elevation: 0,
        height: 64,
        indicatorColor: _dkPrimary.withOpacity(0.15),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? _dkPrimary : _dkOnSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? _dkPrimary : _dkOnSurfaceVariant,
            size: 24,
          );
        }),
        shadowColor: Colors.transparent,
      ),

      // ---- List Tile ------------------------------------------
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: sp4,
          vertical: sp2,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: _dkOnSurface,
        ),
        subtitleTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          color: _dkOnSurfaceVariant,
        ),
      ),

      // ---- Tab Bar --------------------------------------------
      tabBarTheme: const TabBarThemeData(
        labelColor: _dkPrimary,
        unselectedLabelColor: _dkOnSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _dkPrimary, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // ---- Snack Bar ------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _dkSurfaceContainerHighest,
        contentTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: _dkOnSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ---- Progress Indicator ---------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _dkPrimary,
        linearTrackColor: Color(0xFF1C2530),
        circularTrackColor: Color(0xFF1C2530),
      ),

      // ---- Switch / Checkbox / Radio --------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? _dkOnPrimary : _dkOnSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? _dkPrimary
            : _dkSurfaceContainerHigh),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? _dkPrimary
            : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(_dkOnPrimary),
        side: const BorderSide(color: _dkOnSurfaceVariant, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? _dkPrimary
            : _dkOnSurfaceVariant),
      ),

      // ---- Floating Action Button -----------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _dkPrimary,
        foregroundColor: _dkOnPrimary,
        elevation: 0,
        shape: StadiumBorder(),
      ),

      // ---- Tooltip --------------------------------------------
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _dkSurfaceContainerHighest,
          borderRadius: BorderRadius.circular(radiusMd),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          color: _dkOnSurface,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  //  LIGHT THEME  –  "Pristine Aviator"
  // ----------------------------------------------------------

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final colorScheme = const ColorScheme(
      brightness: Brightness.light,

      // Core surfaces
      surface:              _ltSurface,
      surfaceDim:           Color(0xFFD8DBE0),
      surfaceContainerLowest: _ltSurfaceContainerLowest,
      surfaceContainerLow:  _ltSurfaceContainerLow,
      surfaceContainer:     Color(0xFFECEFF3),
      surfaceContainerHigh: _ltSurfaceContainerHigh,
      surfaceContainerHighest: _ltSurfaceContainerHighest,
      surfaceBright:        Color(0xFFF7F9FB),

      // Primary – deep-sea navy
      primary:              _ltPrimary,
      onPrimary:            _ltOnPrimary,
      primaryContainer:     _ltPrimaryContainer,
      onPrimaryContainer:   _ltOnPrimaryContainer,
      primaryFixed:         _ltPrimaryFixed,
      primaryFixedDim:      Color(0xFF9DD0F0),

      // Secondary
      secondary:            Color(0xFF4A6375),
      onSecondary:          Color(0xFFFFFFFF),
      secondaryContainer:   Color(0xFFCDE7F8),
      onSecondaryContainer: Color(0xFF061E2C),

      // Tertiary
      tertiary:             Color(0xFF4A6375),
      onTertiary:           Color(0xFFFFFFFF),
      tertiaryContainer:    Color(0xFFCFE5F5),
      onTertiaryContainer:  Color(0xFF041E2C),

      // Error
      error:                Color(0xFFBA1A1A),
      onError:              Color(0xFFFFFFFF),
      errorContainer:       Color(0xFFFFDAD6),
      onErrorContainer:     Color(0xFF410002),

      // Text / icons
      onSurface:            _ltOnSurface,
      onSurfaceVariant:     _ltOnSurfaceVariant,
      outline:              Color(0xFF6C7580),
      outlineVariant:       _ltOutlineVariant,

      // Inverse
      inverseSurface:       Color(0xFF2E3138),
      onInverseSurface:     Color(0xFFEFF0F8),
      inversePrimary:       Color(0xFF90CEED),

      // Scrim / shadow
      scrim:                Color(0xFF000000),
      shadow:               Color(0xFF000000),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _ltSurface,

      // ---- Typography ----------------------------------------
      textTheme: _buildLightTextTheme(base.textTheme),

      // ---- AppBar --------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: _ltOnSurface,
          letterSpacing: -0.02 * 20,
        ),
        iconTheme: IconThemeData(color: _ltOnSurface),
      ),

      // ---- Cards ---------------------------------------------
      cardTheme: CardThemeData(
        color: _ltSurfaceContainerLowest,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: sp4 / 2),
        shadowColor: const Color(0x0D006591),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(
            color: Color(0x33BEC8D2), // ghost border 20%
            width: 1,
          ),
        ),
      ),

      // ---- Elevated Button ------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(_ltOnPrimary),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(
            _ltPrimary.withOpacity(0.08),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: sp8, vertical: sp3),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(_ltPrimary),
          foregroundColor: const WidgetStatePropertyAll(_ltOnPrimary),
          overlayColor: WidgetStatePropertyAll(
            _ltPrimaryContainer.withOpacity(0.20),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: sp8, vertical: sp3),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(_ltPrimary),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Color(0x4D006591), width: 1),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: sp8, vertical: sp3),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(_ltPrimary),
          overlayColor: WidgetStatePropertyAll(
            _ltPrimary.withOpacity(0.08),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),

      // ---- Input Decoration -----------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _ltSurfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: _ltPrimaryContainer, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: _ltOnSurfaceVariant,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: _ltOnSurfaceVariant,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          color: _ltPrimary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: sp4,
          vertical: sp3,
        ),
      ),

      // ---- Chip / Filter Pills --------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: _ltSurfaceContainerLow,
        selectedColor: _ltPrimaryContainer.withOpacity(0.15),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: _ltOnSurfaceVariant,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _ltPrimary,
        ),
        side: const BorderSide(color: Color(0x33BEC8D2), width: 1),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: sp3, vertical: sp1),
        elevation: 0,
        pressElevation: 0,
      ),

      // ---- Divider (none) ------------------------------------
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),

      // ---- Dialog / Bottom Sheet -----------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: _ltSurfaceContainerLowest,
        elevation: 0,
        shadowColor: const Color(0x0D006591),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: Color(0x33BEC8D2), width: 1),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _ltSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusXl),
            topRight: Radius.circular(radiusXl),
          ),
        ),
      ),

      // ---- Navigation Bar ------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _ltSurfaceContainerLowest.withOpacity(0.85),
        elevation: 0,
        height: 64,
        indicatorColor: _ltPrimaryContainer.withOpacity(0.15),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? _ltPrimary : _ltOnSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? _ltPrimary : _ltOnSurfaceVariant,
            size: 24,
          );
        }),
        shadowColor: const Color(0x0D006591),
      ),

      // ---- List Tile -----------------------------------------
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: sp4,
          vertical: sp2,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: _ltOnSurface,
        ),
        subtitleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: _ltOnSurfaceVariant,
        ),
      ),

      // ---- Tab Bar -------------------------------------------
      tabBarTheme: const TabBarThemeData(
        labelColor: _ltPrimary,
        unselectedLabelColor: _ltOnSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: _ltPrimaryContainer, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // ---- Snack Bar -----------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ltSurfaceContainerHighest,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: _ltOnSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ---- Progress Indicator --------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _ltPrimaryContainer,
        linearTrackColor: Color(0xFFDDE3EA),
        circularTrackColor: Color(0xFFDDE3EA),
      ),

      // ---- Switch / Checkbox / Radio -------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? _ltOnPrimary : _ltOnSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? _ltPrimary
            : _ltSurfaceContainerHigh),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? _ltPrimary
            : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(_ltOnPrimary),
        side: const BorderSide(color: _ltOnSurfaceVariant, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected)
            ? _ltPrimary
            : _ltOnSurfaceVariant),
      ),

      // ---- FAB -----------------------------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _ltPrimary,
        foregroundColor: _ltOnPrimary,
        elevation: 0,
        shape: StadiumBorder(),
      ),

      // ---- Tooltip -------------------------------------------
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _ltSurfaceContainerHighest,
          borderRadius: BorderRadius.circular(radiusMd),
          border: Border.all(color: const Color(0x33BEC8D2)),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: _ltOnSurface,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  //  TYPOGRAPHY HELPERS
  // ----------------------------------------------------------

  static TextTheme _buildDarkTextTheme(TextTheme base) {
    // Display + Headlines → Plus Jakarta Sans  (editorial)
    // Body + Labels      → Manrope             (functional)
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w800,
        fontSize: 56, color: _dkOnSurface, letterSpacing: -0.02 * 56,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w800,
        fontSize: 45, color: _dkOnSurface, letterSpacing: -0.02 * 45,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700,
        fontSize: 36, color: _dkOnSurface, letterSpacing: -0.01 * 36,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700,
        fontSize: 32, color: _dkOnSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700,
        fontSize: 28, color: _dkOnSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600,
        fontSize: 24, color: _dkOnSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600,
        fontSize: 22, color: _dkOnSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w600,
        fontSize: 16, color: _dkOnSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w600,
        fontSize: 14, color: _dkOnSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w400,
        fontSize: 16, color: _dkOnSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w400,
        fontSize: 14, color: _dkOnSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w400,
        fontSize: 12, color: _dkOnSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w600,
        fontSize: 14, color: _dkOnSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w600,
        fontSize: 12, color: _dkOnSurfaceVariant,
        letterSpacing: 0.8, // table headers – tracked out
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: 'Manrope', fontWeight: FontWeight.w500,
        fontSize: 11, color: _dkOnSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme _buildLightTextTheme(TextTheme base) {
    // Display + Headlines → Plus Jakarta Sans  (editorial)
    // Body + Labels      → Inter               (precision)
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w800,
        fontSize: 56, color: _ltOnSurface, letterSpacing: -0.02 * 56,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w800,
        fontSize: 45, color: _ltOnSurface, letterSpacing: -0.02 * 45,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700,
        fontSize: 36, color: _ltOnSurface, letterSpacing: -0.01 * 36,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700,
        fontSize: 32, color: _ltOnSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700,
        fontSize: 28, color: _ltOnSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600,
        fontSize: 24, color: _ltOnSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600,
        fontSize: 22, color: _ltOnSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w600,
        fontSize: 16, color: _ltOnSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w600,
        fontSize: 14, color: _ltOnSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w400,
        fontSize: 16, color: _ltOnSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w400,
        fontSize: 14, color: _ltOnSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w400,
        fontSize: 12, color: _ltOnSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w600,
        fontSize: 14, color: _ltOnSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w600,
        fontSize: 12, color: _ltOnSurfaceVariant,
        letterSpacing: 0.8,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: 'Inter', fontWeight: FontWeight.w500,
        fontSize: 11, color: _ltOnSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}