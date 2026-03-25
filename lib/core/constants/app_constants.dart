import 'package:flutter/material.dart';

class AppColors {
  // Primary - Neon Lime Green (gym-track brand color)
  static const Color primary = Color(0xFFA6FF00);
  static const Color primaryDark = Color(0xFF86DB00);
  static const Color primaryLight = Color(0xFFC3FF3F);
  static const Color onPrimary = Color(0xFF000000); // Black text on primary

  // Secondary - Bright Blue
  static const Color secondary = Color(0xFF00A5FF);
  static const Color secondaryDark = Color(0xFF0B62B5);
  static const Color secondaryLight = Color(0xFF4FC8FD);

  // Danger / Error - Red
  static const Color danger = Color(0xFFF11450);
  static const Color error = Color(0xFFF11450);

  // Success - Green
  static const Color success = Color(0xFF62EF6E);

  // Warning - Yellow
  static const Color warning = Color(0xFFFFEA07);

  // Dark Mode Colors (primary mode - matching web app)
  static const Color backgroundDark = Color(0xFF18181B); // zinc-900
  static const Color surfaceDark = Color(0xFF27272A); // zinc-800
  static const Color cardDark = Color(0xFF27272A); // zinc-800
  static const Color surfaceVariantDark = Color(0xFF3F3F46); // zinc-700
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA); // zinc-400
  static const Color textMutedDark = Color(0xFF71717A); // zinc-500
  static const Color borderDark = Color(0xFF3F3F46); // zinc-700

  // Light Mode Colors
  static const Color background = Color(0xFFF4F4F5); // zinc-100
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE4E4E7); // zinc-200
  static const Color textPrimary = Color(0xFF18181B); // zinc-900
  static const Color textSecondary = Color(0xFF71717A); // zinc-500
  static const Color textMuted = Color(0xFFA1A1AA); // zinc-400
  static const Color border = Color(0xFFE4E4E7); // zinc-200

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFFA6FF00),
    Color(0xFF00A5FF),
    Color(0xFF62EF6E),
    Color(0xFFFFEA07),
    Color(0xFFF11450),
    Color(0xFF8B5CF6),
  ];
}

class AppDimensions {
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;
  static const double paddingXXLarge = 24.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  static const double cardElevation = 4.0;

  // Consistent gap matching web app's gap-3 (12px)
  static const double gap = 12.0;
}

class AppTextStyles {
  // Page headings (matching text-2xl md:text-4xl font-semibold)
  static const TextStyle pageHeading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  // Card stat numbers (matching text-4xl)
  static const TextStyle statNumber = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
  );

  // Card titles (matching uppercase text-xs)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}

class AppDurations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}
