import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet monokrom: hitam, putih, dan gradasi abu-abu di antaranya.
/// Dark theme dominan hitam, button putih. Glassmorphism untuk card.
class AppColors {
  // Skala abu-abu (terang → gelap)
  static const white = Color(0xFFFFFFFF);
  static const gray100 = Color(0xFFF5F5F5);
  static const gray200 = Color(0xFFE5E5E5);
  static const gray300 = Color(0xFFD4D4D4);
  static const gray400 = Color(0xFFA3A3A3);
  static const gray500 = Color(0xFF737373);
  static const gray600 = Color(0xFF525252);
  static const gray700 = Color(0xFF3D3D3D);
  static const gray800 = Color(0xFF262626);
  static const gray900 = Color(0xFF161616);
  static const black = Color(0xFF000000);
  static const nearBlack = Color(0xFF0A0A0A);

  // Alias semantik (monokrom) — nama tetap agar kompatibel dengan kode lama
  static const primary = white;
  static const primaryLight = gray800;
  static const secondary = gray300;
  static const secondaryLight = gray800;
  static const danger = gray500;
  static const dangerLight = gray800;
  static const warning = gray400;
  static const warningLight = gray800;

  // Notes category colors
  static const noteWork = gray400;
  static const noteIdea = gray300;
  static const notePersonal = gray500;
  static const noteJournal = gray300;

  // Finance colors (pembeda via tingkat kecerahan)
  static const income = white;
  static const expense = gray400;

  // Neutral
  static const surface = Color(0xFFFAFAFA);
  static const background = Color(0xFFF0F0F0);
  static const surfaceDark = Color(0xFF121212);
  static const backgroundDark = Color(0xFF050505);

  // Task priority (pembeda via kecerahan)
  static const priorityLow = gray600;
  static const priorityMedium = gray400;
  static const priorityHigh = white;

  // Chart colors (grayscale)
  static const chartColors = [
    Color(0xFFE5E5E5),
    Color(0xFFA3A3A3),
    Color(0xFF737373),
    Color(0xFF525252),
    Color(0xFF3D3D3D),
    Color(0xFFD4D4D4),
    Color(0xFF9A9A9A),
    Color(0xFF6B6B6B),
  ];

  // Glassmorphism
  static const glassLight = Color(0x10000000); // hitam 6%
  static const glassDark = Color(0x16FFFFFF); // putih 9%
  static const glassBorderLight = Color(0x14000000);
  static const glassBorderDark = Color(0x24FFFFFF);

  // Icon box
  static const iconBoxBg = Color(0xFF0A0A0A);
  static const iconBoxBgLight = Color(0xFF1C1C1C);
  static const iconColor = Color(0xFFA3A3A3);

  // Gradien untuk glow
  static const glowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFD4D4D4)],
  );
  static const glowGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF262626), Color(0xFF000000)],
  );
}

class AppTheme {
  static ThemeData get light {
    return _buildTheme(brightness: Brightness.light);
  }

  static ThemeData get dark {
    return _buildTheme(brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final cardBorder = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;
    final fillColor = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFEFEFEF);
    final dividerC = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    final textColor = isDark ? const Color(0xFFF2F2F2) : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF555555);
    final textHint = isDark ? const Color(0xFF666666) : const Color(0xFF999999);

    final baseScheme = ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.white : AppColors.black,
      secondary: AppColors.gray400,
      surface: surfaceColor,
      error: AppColors.gray500,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w800, color: textColor,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w800, color: textColor,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: textColor,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: textColor,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: textSecondary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: textHint,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w800, color: textColor,
        ),
        iconTheme: IconThemeData(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.white : AppColors.black,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: textHint,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.white : AppColors.black,
          foregroundColor: isDark ? AppColors.black : AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.white : AppColors.black,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.white : AppColors.black,
        foregroundColor: isDark ? AppColors.black : AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fillColor,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: cardBorder, width: 1),
      ),
      dividerTheme: DividerThemeData(
        color: dividerC,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF0C0C0C)
            : AppColors.surface,
        indicatorColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFE8E8E8),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.black,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? AppColors.white : AppColors.black,
              size: 22,
            );
          }
          return const IconThemeData(color: AppColors.gray500, size: 22);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? AppColors.white : AppColors.black,
        unselectedLabelColor: AppColors.gray500,
        indicatorColor: isDark ? AppColors.white : AppColors.black,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.white : AppColors.black,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.black : AppColors.white;
          }
          return AppColors.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.white : AppColors.black;
          }
          return AppColors.gray700;
        }),
      ),
    );
  }
}
