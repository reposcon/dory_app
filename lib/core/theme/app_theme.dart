import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class DoryTheme {
  static ThemeData get cyberpunkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, 
      primaryColor: DoryColors.primary,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.syne(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: DoryColors.text,
        ),
        titleLarge: GoogleFonts.syne(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: DoryColors.text,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: DoryColors.text,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: DoryColors.textMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DoryColors.primary,
          foregroundColor: DoryColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
