import 'package:flutter/material.dart';
const Color kGreen = Color(0xFF0B6B5D);

/// Mêmes valeurs que src/theme.ts (version React Native).
class AppColors {
  static const Color primary = Color(0xFF0B6B5B);
  static const Color primaryLight = Color(0xFFD4E4DE);
  static const Color text = Color(0xFF16212B);
  static const Color muted = Color(0xFF5F6B76);
  static const Color border = Color(0xFFD0D5D9);
  static const Color background = Color(0xFFFFFFFF);
}

class AppRadius {
  static const double input = 14;
  static const double pill = 999;
  static const double card = 16;
}

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0B6B5B),
    primary: const Color(0xFF0B6B5B),
  ),
  scaffoldBackgroundColor: Colors.white,
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),

  navigationBarTheme: NavigationBarThemeData(
  backgroundColor: Colors.white,
  indicatorColor: const Color(0xFFD4E4DE),
  labelTextStyle: WidgetStatePropertyAll(
    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  ),
),
);