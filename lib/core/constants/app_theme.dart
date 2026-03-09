import 'package:flutter/material.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.scaffoldBg,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.accentColor,
          secondary: AppConstants.accentColor,
          surface: AppConstants.cardColor,
          error: AppConstants.errorColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: AppConstants.textPrimary),
          titleTextStyle: TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.cardColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.accentColor, width: 2),
          ),
          hintStyle: const TextStyle(color: AppConstants.textSecondary),
          labelStyle: const TextStyle(color: AppConstants.textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppConstants.primaryColor,
          selectedItemColor: AppConstants.accentColor,
          unselectedItemColor: AppConstants.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppConstants.textPrimary),
          bodyLarge: TextStyle(color: AppConstants.textPrimary),
          bodyMedium: TextStyle(color: AppConstants.textSecondary),
          labelSmall: TextStyle(color: AppConstants.textSecondary),
        ),
      );
}
