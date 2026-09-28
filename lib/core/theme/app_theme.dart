import 'package:flutter/material.dart';

/// Central design tokens. Change the look of the whole app here; feature
/// widgets should use `Theme.of(context)` and these constants only.
abstract final class AppColors {
  static const seed = Color(0xFF2563EB);
  static const folder = Color(0xFFF59E0B);
  static const pdf = Color(0xFFDC2626);
  static const board = Color(0xFF059669);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// Width at which layouts switch from phone to tablet/desktop.
abstract final class Breakpoints {
  static const medium = 600.0;
  static const expanded = 900.0;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 600),
      ),
    );
  }
}
