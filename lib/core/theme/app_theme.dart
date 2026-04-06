import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // InDrive Colors - Adjusted for better contrast
  static const Color primaryColor = Color(0xFF1A1A1A); // Premium Dark
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF333333);
  static const Color accentColor = Color(0xFFC9D420); // Secondary helper color

  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(
    0xFF757575,
  ); // Darkened for better contrast

  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF4CAF50);

  // Dimensions
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double bottomSheetRadius = 24.0;

  // InDrive-style Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get bottomSheetShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 30,
      offset: const Offset(0, -4),
    ),
  ];

  // Text Theme with Google Fonts (Cairo for Arabic)
  static TextTheme get textTheme => GoogleFonts.cairoTextTheme(
    const TextTheme(
      // Extra large for prices
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.2,
      ),
      // Large titles
      displayMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.2,
      ),
      // Section titles
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.3,
      ),
      // Card titles
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.3,
      ),
      // Regular text
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.4,
      ),
      // Secondary text
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.4,
      ),
      // Small text
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        height: 1.3,
      ),
      // Material 3 mappings
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
  );

  static final TextTheme cairoTextTheme = GoogleFonts.cairoTextTheme(textTheme);

  static InputDecoration inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F5F5).withValues(alpha: 0.1),
      hintText: hintText,
      hintStyle: GoogleFonts.cairo(color: Colors.white54, fontSize: 16),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: accentColor,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    textStyle: GoogleFonts.cairo(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white24, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    textStyle: GoogleFonts.cairo(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      platform: TargetPlatform.iOS,
      fontFamily: GoogleFonts.cairo().fontFamily,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,
      cardColor: cardColor,

      textTheme: cairoTextTheme,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: accentColor,
        onSecondary: primaryColor,
        onSurface: textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        barBackgroundColor: surfaceColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: textPrimary,
          textStyle: GoogleFonts.cairo(color: textPrimary),
          actionTextStyle: GoogleFonts.cairo(color: primaryColor),
          navTitleTextStyle: GoogleFonts.cairo(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: elevatedButtonThemeData,
      ),

      inputDecorationTheme: inputDecorationThemeData,
    );
  }

  static ButtonStyle get elevatedButtonThemeData => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: accentColor,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
  );

  static InputDecorationTheme get inputDecorationThemeData => InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    hintStyle: GoogleFonts.cairo(color: textTertiary, fontSize: 17),
  );
}
