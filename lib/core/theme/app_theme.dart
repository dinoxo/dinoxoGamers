import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  // Dark Gamer Palette
  static const Color background = Color(0xFF050A18);
  static const Color scaffoldBg = Color(0xFF070D1C);
  static const Color surface = Color(0xFF0B1427);
  static const Color surfaceElevated = Color(0xFF101D35);
  static const Color surfaceSubtle = Color(0xFF152541);
  static const Color border = Color(0xFF203658);
  static const Color divider = Color(0xFF182944);

  // Accents & Signals
  static const Color primary = Color(0xFF8B5CF6); // Electric violet
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color secondary = Color(0xFF00C8FF); // Cyber cyan
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
      appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: Color.alphaBlend(color.withAlpha(60), background),
          foregroundColor: Colors.white),
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
        selectedItemColor: secondary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        selectedIconTheme: IconThemeData(
            size: 23, shadows: [Shadow(color: secondary, blurRadius: 12)]),
        unselectedIconTheme: IconThemeData(size: 22),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primary.withAlpha(50),
        disabledColor: surface,
        showCheckmark: false,
        side: const BorderSide(color: border, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIconColor: secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondary.withAlpha(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: divider),
      bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      dialogTheme: DialogThemeData(
          backgroundColor: surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      tabBarTheme: const TabBarThemeData(
          dividerColor: border,
          indicatorColor: secondary,
          labelColor: textPrimary,
          unselectedLabelColor: textSecondary),
    );
  }
}
