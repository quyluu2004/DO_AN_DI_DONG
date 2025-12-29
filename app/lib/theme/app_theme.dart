import 'package:flutter/material.dart';

/// Bộ màu chủ đạo theo yêu cầu: trắng sứ, đen than, xám ghi.
class AppColors {
  static const ceramicWhite = Color(0xFFF8F9FB);
  static const charcoal = Color(0xFF0F1115);
  static const slate = Color(0xFF6C7077);
  static const border = Color(0xFFE1E3E6);
  static const card = Colors.white;
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ceramicWhite,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.charcoal,
        onPrimary: Colors.white,
        secondary: AppColors.slate,
        onSecondary: Colors.white,
        error: Colors.red.shade600,
        onError: Colors.white,
        background: AppColors.ceramicWhite,
        onBackground: AppColors.charcoal,
        surface: AppColors.card,
        onSurface: AppColors.charcoal,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ceramicWhite,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.charcoal, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.slate),
        labelStyle: const TextStyle(color: AppColors.slate),
        prefixIconColor: AppColors.slate,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          color: AppColors.slate,
          height: 1.5,
        ),
      ),
      // Dùng CardThemeData để tương thích các version Flutter cũ hơn.
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerColor: AppColors.border,
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: AppColors.charcoal,
        brightness: Brightness.light,
        labelStyle: const TextStyle(),
      ).copyWith(
        backgroundColor: AppColors.border,
        selectedColor: AppColors.charcoal,
        secondarySelectedColor: AppColors.charcoal,
        labelStyle: const TextStyle(color: AppColors.charcoal),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

