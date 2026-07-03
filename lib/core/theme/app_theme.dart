import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand palette
  static const primary = Color(0xFF6366F1);       // Indigo
  static const primaryLight = Color(0xFFEEF2FF);
  static const secondary = Color(0xFF10B981);      // Emerald
  static const secondaryLight = Color(0xFFD1FAE5);
  static const danger = Color(0xFFEF4444);         // Red
  static const dangerLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFF59E0B);        // Amber
  static const warningLight = Color(0xFFFEF3C7);

  // Notes category colors
  static const noteWork = Color(0xFF6366F1);
  static const noteIdea = Color(0xFFF59E0B);
  static const notePersonal = Color(0xFF10B981);
  static const noteJournal = Color(0xFFEC4899);

  // Finance colors
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);

  // Neutral
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8F9FD);
  static const surfaceDark = Color(0xFF1E1E2E);
  static const backgroundDark = Color(0xFF13131F);

  // Task priority
  static const priorityLow = Color(0xFF10B981);
  static const priorityMedium = Color(0xFFF59E0B);
  static const priorityHigh = Color(0xFFEF4444);

  // Chart colors
  static const chartColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
  ];
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A),
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A),
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF334155),
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: const Color(0xFF334155),
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF64748B),
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF334155)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: const Color(0xFF94A3B8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 22);
        }),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFFF1F5F9),
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFFF1F5F9),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF1F5F9),
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1),
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: const Color(0xFFCBD5E1),
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8),
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFCBD5E1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFF1F5F9),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFCBD5E1)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252536),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: const Color(0xFF475569),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: const Color(0xFF312E81),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF475569),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF475569), size: 22);
        }),
      ),
    );
  }
}