import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  // Dark Gamer Palette
  static const Color background = Color(0xFF0A0D14);
  static const Color scaffoldBg = Color(0xFF0D111A);
  static const Color surface = Color(0xFF141923);
  static const Color surfaceElevated = Color(0xFF1B2230);
  static const Color surfaceSubtle = Color(0xFF232B3E);
  static const Color border = Color(0xFF283246);
  static const Color divider = Color(0xFF1E2636);

  // Accents & Signals
  static const Color primary = Color(0xFF8B5CF6); // Electric violet
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF06B6D4); // Cyber cyan
  static const Color success = Color(0xFF10B981); // Emerald (good discount)
  static const Color hotDeal = Color(0xFFF97316); // Neon orange (all-time low)
  static const Color danger =
      Color(0xFFEF4444); // Crimson (ending soon / alert)
  static const Color warning = Color(0xFFF59E0B); // Amber

  // Console Brand Colors
  static const Color playStationColor = Color(0xFF00439C);
  static const Color nintendoColor = Color(0xFFE60012);
  static const Color xboxColor = Color(0xFF107C10);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static Color platformColor(GamePlatform platform) {
    switch (platform) {
      case GamePlatform.playstation:
        return playStationColor;
      case GamePlatform.nintendo:
        return nintendoColor;
      case GamePlatform.xbox:
        return xboxColor;
    }
  }

  static ThemeData forPlatform(ThemeData base, GamePlatform platform) {
    final color = platformColor(platform);
    final bright = Color.lerp(color, Colors.white, .42)!;
    return base.copyWith(
      colorScheme:
          base.colorScheme.copyWith(primary: bright, secondary: bright),
      appBarTheme: base.appBarTheme
          .copyWith(backgroundColor: color, foregroundColor: Colors.white),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: bright, width: 2))),
      chipTheme: base.chipTheme.copyWith(selectedColor: color.withAlpha(85)),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primaryLight,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primary.withAlpha(50),
        disabledColor: surface,
        side: const BorderSide(color: border, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1.2),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
