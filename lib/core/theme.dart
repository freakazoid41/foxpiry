import 'package:flutter/material.dart';

/// Foxpiry den theme — fox sniffing vibe. Light only.
class FoxColors {
  static const foxOrange = Color(0xFFF59E0B);
  static const foxDeep = Color(0xFFEA580C);
  static const tealGround = Color(0xFF0F766E);
  static const leafGreen = Color(0xFF22C55E);
  static const cream = Color(0xFFFFF7ED);
}

class FoxTheme {
  // Built once — the getter used to rebuild ThemeData on every notify.
  static final ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    final scheme = ColorScheme.fromSeed(
      seedColor: FoxColors.tealGround,
      secondary: FoxColors.foxOrange,
      tertiary: FoxColors.leafGreen,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFFFBF3),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFFBF3),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFBF3),
        foregroundColor: Color(0xFF1C1917),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Colors.brown.withValues(alpha: 0.12)),
        ),
        color: Colors.white,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: Colors.brown.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: Colors.brown.withValues(alpha: 0.2))),
        prefixIconColor: FoxColors.tealGround,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FoxColors.foxOrange,
        foregroundColor: Color(0xFF1C1917),
        extendedTextStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFBF3),
        indicatorColor: FoxColors.foxOrange.withValues(alpha: 0.25),
      ),
    );
  }

  /// Warm den gradient — light only. Const, no rebuild garbage.
  static const LinearGradient denGradient = LinearGradient(
    colors: [Color(0xFFFFF7ED), Color(0xFFCCFBF1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
