import 'package:flutter/material.dart';

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