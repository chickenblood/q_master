import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoThemeData;
import 'package:material_ui/material_ui.dart';

// Keep these definitions in sync with the legacy themes during migration.
const _f3Red = Color(0xFFD45B3B);
const _f3RedLight = Color(0xFFC25135); // WCAG AA on white

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
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.4,
  ),
  titleMedium: TextStyle(
    color: primary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  ),
  titleSmall: TextStyle(
    color: primary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  ),
  bodyLarge: TextStyle(color: primary, fontSize: 18),
  bodyMedium: TextStyle(color: secondary, fontSize: 16),
  bodySmall: TextStyle(color: secondary, fontSize: 12),
  labelLarge: TextStyle(
    color: primary,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  ),
  labelMedium: TextStyle(
    color: secondary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  ),
  labelSmall: TextStyle(
    color: primary,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
  ),
);

// ─── Dark theme ────────────────────────────────────────────────────────────
ThemeData darkTheme() {
  const bgPage = Color(0xFF080808);
  const bgSurface = Color(0xFF0D0D0D);
  const border = Color(0xFF252525);
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
      outlineVariant: Color(0xFF373737),
      error: _f3Red,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: bgPage,
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: textPrimary),
    iconTheme: const IconThemeData(color: textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: bgSurface.withAlpha(179),
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
    bottomSheetTheme: const BottomSheetThemeData(
      dragHandleSize: Size(60, 4),
      dragHandleColor: textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
  const border = Color(0xFFDDDDDD); // Match outlineVariant for consistency
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
      outlineVariant: Color(0xFFDDDDDD),
      error: _f3RedLight,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: bgPage,
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: textPrimary),
    iconTheme: const IconThemeData(color: textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: bgSurface.withAlpha(179),
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
    bottomSheetTheme: const BottomSheetThemeData(
      dragHandleSize: Size(60, 4),
      dragHandleColor: textSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
