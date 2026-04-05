import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.deepBlue,
          brightness: Brightness.light,
          primary: AppColors.deepBlue,
          secondary: AppColors.gold,
          surface: AppColors.cream,
        ),
        scaffoldBackgroundColor: AppColors.warmWhite,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.rubik(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.rubik(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
          headlineMedium: GoogleFonts.rubik(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
          titleLarge: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
          bodyLarge: GoogleFonts.rubik(
            fontSize: 16,
            color: AppColors.darkBrown,
          ),
          bodyMedium: GoogleFonts.rubik(
            fontSize: 14,
            color: AppColors.darkBrown,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
