import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/material.dart';

// ─── Option 3: The Gloom — Color Tokens ───────────────────────────────────
// Dark-first. Monochromatic near-blacks + F3 Red accent only.
// Designed for pre-dawn workouts: cold hands, dark-adjusted eyes.
//
// Dark surfaces:
//   bg-page    #080808   scaffold background
//   bg-surface #0D0D0D   cards, list items, settings cards
//   bg-raised  #141414   elevated rows, borders
//   border     #1E1E1E   dividers, outlines
//   text-pri   #F0F0F0   primary text
//   text-sec   #808080   secondary / subtitle text (4.54:1 on #080808)
//   accent     #E53935   F3 Red — all active states, labels, buttons
//
// Light surfaces:
//   scaffold   #F5F5F5
//   surface    #FFFFFF   cards, list items
//   border     #E8E8E8
//   text-pri   #121212
//   text-sec   #6F6F6F   secondary text (5.02:1 on #FFFFFF)
//   accent     #D32F2F   darker red (4.98:1 on #FFFFFF)

const _f3Red = Color(0xFFE53935);
const _f3RedLight = Color(0xFFD32F2F); // WCAG AA on white
const _errorRed = Color(0xFFCF6679);

// ─── Timer tile colors ─────────────────────────────────────────────────────
// Resolved per-brightness. Dark uses tinted near-black backgrounds with bright
// saturated text — easier on dark-adjusted eyes than solid color fills.
// Light uses pastel backgrounds with rich dark text for outdoor readability.
//
// Usage:  final tc = TimerColors.of(context);
//         tile bg  → tc.workBg,   text → tc.workFg
abstract final class TimerColors {
  // Dark-mode colors
  static const _workBgDark = Color(0xFF071409);
  static const _workFgDark = Color(0xFF69F07A); // bright green
  static const _workLabelDark = Color(0xFF4CAF50);
  static const _prepareBgDark = Color(0xFF140B02);
  static const _prepareFgDark = Color(0xFFFFA726); // bright amber
  static const _prepareLabelDark = Color(0xFFEF6C00);
  static const _restBgDark = Color(0xFF140404);
  static const _restFgDark = Color(0xFFEF5350); // bright red
  static const _restLabelDark = Color(0xFFE53935);
  static const _statusBgDark = Color(0xFF111111);

  // Light-mode colors
  static const _workBgLight = Color(0xFFE8F5E9);
  static const _workFgLight = Color(0xFF2E7D32); // dark green (7.09:1 on bg)
  static const _prepareBgLight = Color(0xFFFFF3E0);
  static const _prepareFgLight = Color(0xFFBF360C); // 5.11:1 on #FFF3E0
  static const _restBgLight = Color(0xFFFFEBEE);
  static const _restFgLight = Color(0xFFC62828); // dark red (5.4:1 on bg)
  static const _statusBgLight = Color(0xFFF0F0F0);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color workBg(BuildContext context) =>
      _isDark(context) ? _workBgDark : _workBgLight;
  static Color workFg(BuildContext context) =>
      _isDark(context) ? _workFgDark : _workFgLight;
  static Color workLabel(BuildContext context) =>
      _isDark(context) ? _workLabelDark : _workFgLight;

  static Color prepareBg(BuildContext context) =>
      _isDark(context) ? _prepareBgDark : _prepareBgLight;
  static Color prepareFg(BuildContext context) =>
      _isDark(context) ? _prepareFgDark : _prepareFgLight;
  static Color prepareLabel(BuildContext context) =>
      _isDark(context) ? _prepareLabelDark : _prepareFgLight;

  static Color restBg(BuildContext context) =>
      _isDark(context) ? _restBgDark : _restBgLight;
  static Color restFg(BuildContext context) =>
      _isDark(context) ? _restFgDark : _restFgLight;
  static Color restLabel(BuildContext context) =>
      _isDark(context) ? _restLabelDark : _restFgLight;

  static Color statusBg(BuildContext context) =>
      _isDark(context) ? _statusBgDark : _statusBgLight;

  // Control tile: pause/play button and labels
  static Color controlFg(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF0F0F0) : const Color(0xFF121212);

  // Rounds/cycles counter value color
  static Color counterFg(BuildContext context) =>
      _isDark(context) ? const Color(0xFFE53935) : const Color(0xFFD32F2F);
}

/// App-wide color helpers for custom UI elements
abstract final class ThemeColors {
  /// Returns a color for drag handles that is visible in both light and dark modes.
  static Color dragHandle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.outline;
  }
}

// ─── Typography helpers ────────────────────────────────────────────────────
// Option 3 uses a heavier, larger scale than stock Material for glanceability
// at arm's length in pre-dawn conditions.
//
//   displayLarge   → timer primary time (72–80 px / 900)
//   displayMedium  → timer secondary time (48 px / 900)
//   displaySmall   → timer setup values (28 px / 900)
//   headlineLarge  → beatdown hero title (32 px / 900)
//   headlineMedium → section / modal title (24 px / 800)
//   headlineSmall  → screen subtitle (20 px / 700)
//   titleLarge     → navbar title (19 px / 900)
//   titleMedium    → list item title (18 px / 800)
//   titleSmall     → settings row label (16 px / 400)
//   bodyLarge      → body / primary body (16 px / 400)
//   bodyMedium     → list subtitle (13 px / 400)
//   bodySmall      → chips, section previews (12 px / 400)
//   labelLarge     → button labels (16 px / 800)
//   labelMedium    → tab bar labels (10 px / 600)
//   labelSmall     → section header labels (10 px / 800 uppercase)

TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
  displayLarge: TextStyle(
    color: primary,
    fontSize: 80,
    fontWeight: FontWeight.w900,
    letterSpacing: -3,
    fontFeatures: [FontFeature.tabularFigures()],
  ),
  displayMedium: TextStyle(
    color: primary,
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -2,
    fontFeatures: [FontFeature.tabularFigures()],
  ),
  displaySmall: TextStyle(
    color: primary,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    fontFeatures: [FontFeature.tabularFigures()],
  ),
  headlineLarge: TextStyle(
    color: primary,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  ),
  headlineMedium: TextStyle(
    color: primary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  ),
  headlineSmall: TextStyle(
    color: primary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
  titleLarge: TextStyle(
    color: primary,
    fontSize: 19,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.4,
  ),
  titleMedium: TextStyle(
    color: primary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  ),
  titleSmall: TextStyle(
    color: primary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  ),
  bodyLarge: TextStyle(color: primary, fontSize: 16),
  bodyMedium: TextStyle(color: secondary, fontSize: 13),
  bodySmall: TextStyle(color: secondary, fontSize: 12),
  labelLarge: TextStyle(
    color: primary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  ),
  labelMedium: TextStyle(
    color: secondary,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  ),
  labelSmall: TextStyle(
    color: primary,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
  ),
);

// ─── Dark theme ────────────────────────────────────────────────────────────
ThemeData darkTheme() {
  const bgPage = Color(0xFF080808);
  const bgSurface = Color(0xFF0D0D0D);
  const bgRaised = Color(0xFF141414);
  const border = Color(0xFF1E1E1E);
  const textPrimary = Color(0xFFF0F0F0);
  const textSecondary = Color(0xFF808080);
  const iconColor = textPrimary;

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _f3Red,
      onPrimary: Colors.white,
      secondary: _f3Red,
      onSecondary: Colors.white,
      surface: bgSurface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: bgRaised,
      error: _errorRed,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: bgPage,
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: textPrimary),
    iconTheme: const IconThemeData(color: textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _textTheme(textPrimary, textSecondary).titleLarge,
      iconTheme: const IconThemeData(color: iconColor, size: 26, weight: 700),
      actionsIconTheme: const IconThemeData(
        color: iconColor,
        size: 26,
        weight: 700,
      ),
      toolbarHeight: 54,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
    cardTheme: const CardThemeData(
      color: bgSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: border),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: bgPage,
      minVerticalPadding: 14,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bgPage,
      indicatorColor: Colors.transparent,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: textPrimary);
        }
        return const IconThemeData(color: textSecondary);
      }),
      labelTextStyle: WidgetStatePropertyAll(
        _textTheme(textPrimary, textSecondary).labelMedium,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgPage,
      selectedItemColor: textPrimary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _f3Red,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD0D0D0),
        side: const BorderSide(color: Color(0xFF252525)),
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _f3Red,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF101010),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF222222)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF222222)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      hintStyle: TextStyle(color: Color(0xFF3A3A3A)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _f3Red;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF7A7A7A);
        }),
        side: WidgetStatePropertyAll(
          const BorderSide(color: Color(0xFF252525)),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: bgSurface,
      side: const BorderSide(color: Color(0xFF252525)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      labelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF606060),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? _f3Red : null,
      ),
    ),
    textTheme: _textTheme(textPrimary, textSecondary),
  );
}

// ─── Light theme ───────────────────────────────────────────────────────────
ThemeData lightTheme() {
  const bgPage = Color(0xFFF5F5F5);
  const bgSurface = Color(0xFFFFFFFF);
  const border = Color(0xFFE8E8E8);
  const textPrimary = Color(0xFF121212);
  const textSecondary = Color(0xFF6F6F6F); // 5.02:1 on #FFFFFF
  const iconColor = textPrimary;

  return ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _f3RedLight,
      onPrimary: Colors.white,
      secondary: _f3RedLight,
      onSecondary: Colors.white,
      surface: bgSurface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: Color(0xFFF0F0F0),
      error: Color(0xFFB00020),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: bgPage,
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: textPrimary),
    iconTheme: const IconThemeData(color: textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: bgSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _textTheme(textPrimary, textSecondary).titleLarge,
      iconTheme: const IconThemeData(color: iconColor, size: 26, weight: 700),
      actionsIconTheme: const IconThemeData(
        color: iconColor,
        size: 26,
        weight: 700,
      ),
      toolbarHeight: 54,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
    cardTheme: const CardThemeData(
      color: bgSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: border),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: bgSurface,
      minVerticalPadding: 14,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bgPage,
      indicatorColor: Colors.transparent,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: textPrimary);
        }
        return const IconThemeData(color: textSecondary);
      }),
      labelTextStyle: WidgetStatePropertyAll(
        _textTheme(textPrimary, textSecondary).labelMedium,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgPage,
      selectedItemColor: textPrimary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _f3RedLight,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF444444),
        side: const BorderSide(color: Color(0xFFCCCCCC)),
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _f3RedLight,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      hintStyle: TextStyle(color: Color(0xFF6F6F6F)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _f3RedLight;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF6F6F6F);
        }),
        side: const WidgetStatePropertyAll(
          BorderSide(color: Color(0xFFDDDDDD)),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0F0F0),
      side: const BorderSide(color: Color(0xFFE0E0E0)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      labelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF666666),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? _f3RedLight : null,
      ),
    ),
    textTheme: _textTheme(textPrimary, textSecondary),
  );
}
