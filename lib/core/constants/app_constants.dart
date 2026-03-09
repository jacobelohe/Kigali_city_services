import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Kigali City Services';
  static const String appVersion = '1.0.0';

  // Kigali default coordinates
  static const double kigaliLat = -1.9441;
  static const double kigaliLng = 30.0619;

  // Colors
  static const Color primaryColor = Color(0xFF0D2137);
  static const Color accentColor = Color(0xFF1A73E8);
  static const Color scaffoldBg = Color(0xFF0D2137);
  static const Color cardColor = Color(0xFF162B40);
  static const Color surfaceColor = Color(0xFF1E3A52);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4DE);
  static const Color starColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF4CAF50);

  // Categories
  static const List<String> categories = [
    'All',
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
  ];

  static const Map<String, IconData> categoryIcons = {
    'All': Icons.apps,
    'Hospital': Icons.local_hospital,
    'Police Station': Icons.local_police,
    'Library': Icons.local_library,
    'Restaurant': Icons.restaurant,
    'Café': Icons.coffee,
    'Park': Icons.park,
    'Tourist Attraction': Icons.photo_camera,
  };

  static const Map<String, Color> categoryColors = {
    'Hospital': Color(0xFFE53935),
    'Police Station': Color(0xFF1565C0),
    'Library': Color(0xFF6A1B9A),
    'Restaurant': Color(0xFFEF6C00),
    'Café': Color(0xFF4E342E),
    'Park': Color(0xFF2E7D32),
    'Tourist Attraction': Color(0xFF00838F),
  };

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';

  // Shared Preferences Keys
  static const String prefsThemeKey = 'theme_mode';
}
