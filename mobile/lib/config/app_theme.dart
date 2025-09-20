import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color scheme
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: darkBackground,
      cardColor: cardBackground,
      
      // Define text theme with Google Fonts
      textTheme: TextTheme(
        // Large headings (restaurant names, page titles)
        headlineLarge: GoogleFonts.robotoCondensed(
          fontSize: 32,
          fontWeight: FontWeight.w300, // Light 300
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineMedium: GoogleFonts.robotoCondensed(
          fontSize: 28,
          fontWeight: FontWeight.w300, // Light 300
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.robotoCondensed(
          fontSize: 24,
          fontWeight: FontWeight.w400, // Regular for smaller headings
          color: textPrimary,
        ),
        
        // Titles (section headers, card titles)
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w500, // Lighter than bold
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400, // Lighter than w600
          color: primaryOrange,
          letterSpacing: -0.1,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400, // Lighter than w600
          color: textPrimary,
        ),
        
        // Body text (descriptions, content)
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        
        // Labels (buttons, chips, navigation)
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400, // Lighter than w600
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400, // Lighter than w500
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w400, // Lighter than w500
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400, // Lighter than bold
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400, // Lighter than w600
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: primaryOrange,
        surface: cardBackground,
        background: darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
    );
  }
}
