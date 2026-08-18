import 'package:flutter/material.dart';

import 'theme_controller.dart';

abstract final class AppTheme {
  static ThemeData light(VonoThemeColor themeColor) =>
      _build(themeColor, Brightness.light);

  static ThemeData dark(VonoThemeColor themeColor) =>
      _build(themeColor, Brightness.dark);

  static ThemeData _build(VonoThemeColor themeColor, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: themeColor.seed,
      brightness: brightness,
      surface: dark ? const Color(0xFF17131D) : Colors.white,
    );

    final background = dark ? const Color(0xFF100D14) : const Color(0xFFF8F6FA);
    final surface = dark ? const Color(0xFF1B1721) : Colors.white;
    final soft = Color.alphaBlend(
      themeColor.seed.withValues(alpha: dark ? .22 : .13),
      surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        primary: themeColor.seed,
        secondary: themeColor.secondary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: 'Arial',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: soft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? themeColor.seed
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? themeColor.seed
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF211C28) : Colors.white,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: themeColor.seed, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: themeColor.seed,
          foregroundColor: Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? themeColor.seed : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: themeColor.seed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFF332C3A)
            : const Color(0xFF2F2933),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0xFF312A38) : const Color(0xFFEDE8F0),
      ),
    );
  }
}
