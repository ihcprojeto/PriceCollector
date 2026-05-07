import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF7B2FF7);
  static const secondary = Color(0xFF9D4EFF);
  static const inputBg = Color(0xFFF8F4FF);
  static const border = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      textTheme: TextTheme(
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF1A1A1A),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleSmall: GoogleFonts.interTight(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}