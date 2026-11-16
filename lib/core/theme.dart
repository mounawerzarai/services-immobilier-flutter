import 'package:flutter/material.dart';

const Color kGreen = Color(0xFF0B6B5B);

/// Système de design commun aux deux versions (mêmes valeurs que src/theme.ts).
class AppColors {
  static const Color primary = Color(0xFF0B6B5B);
  static const Color primaryDark = Color(0xFF074B40);
  static const Color primaryLight = Color(0xFFD4E4DE);
  static const Color primarySoft = Color(0xFFEAF4F0);
  static const Color accent = Color(0xFFF2A541);
  static const Color accentSoft = Color(0xFFFDF1DE);
  static const Color accentText = Color(0xFFA2620B);
  static const Color text = Color(0xFF14212B);
  static const Color muted = Color(0xFF64707B);
  static const Color subtle = Color(0xFF98A2AB);
  static const Color border = Color(0xFFE3E8EB);
  static const Color background = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF4F6F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFC4362C);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color success = Color(0xFF1F8A5B);
  static const Color segment = Color(0xFFE6EBE9);
}

class AppRadius {
  static const double sm = 10;
  static const double input = 14;
  static const double md = 14;
  static const double card = 18;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

/// Ombres douces (niveau 1 à 3).
class AppShadows {
  static List<BoxShadow> level(int level) => [
        BoxShadow(
          color: AppColors.text.withValues(alpha: 0.05 + level * 0.02),
          blurRadius: level * 10.0,
          offset: Offset(0, level * 2.0),
        ),
      ];

  static final List<BoxShadow> soft = level(1);
  static final List<BoxShadow> card = level(2);
  static final List<BoxShadow> raised = level(3);
}

OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.surface,
    error: AppColors.danger,
  ),
  scaffoldBackgroundColor: AppColors.canvas,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.canvas,
    surfaceTintColor: Colors.transparent,
    foregroundColor: AppColors.text,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.text,
      fontSize: 19,
      fontWeight: FontWeight.w800,
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
    titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
    bodyMedium: TextStyle(color: AppColors.text),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: const TextStyle(color: AppColors.subtle),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: _border(AppColors.border),
    enabledBorder: _border(AppColors.border),
    focusedBorder: _border(AppColors.primary, 1.5),
    errorBorder: _border(AppColors.danger),
    focusedErrorBorder: _border(AppColors.danger, 1.5),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(0, 48),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: StadiumBorder(),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.text,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.primarySoft,
    elevation: 3,
    shadowColor: Colors.black26,
    height: 68,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.subtle,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.muted,
      ),
    ),
  ),
);
