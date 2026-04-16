import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const primary = BrandColors.logoNavy;
    const secondary = BrandColors.logoViolet;
    const tertiary = BrandColors.logoGold;
    const surface = Colors.white;
    const background = BrandColors.lightBg;

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE3FF),
      onPrimaryContainer: Color(0xFF0F1D4D),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEAE4FF),
      onSecondaryContainer: Color(0xFF2A1F66),
      tertiary: tertiary,
      onTertiary: Color(0xFF2D1600),
      tertiaryContainer: Color(0xFFFFE4C5),
      onTertiaryContainer: Color(0xFF4A2800),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: surface,
      onSurface: BrandColors.logoNavy,
      surfaceContainerHighest: Color(0xFFEEF1FB),
      onSurfaceVariant: Color(0xFF6B7280),
      outline: Color(0xFFD6DAE3),
      outlineVariant: Color(0xFFE5E7EE),
      shadow: Color(0x1A000000),
      scrim: Color(0x1A000000),
      inverseSurface: Color(0xFF1E1F24),
      onInverseSurface: Color(0xFFF5F5F7),
      inversePrimary: Color(0xFFB9C9FF),
      surfaceTint: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }

  static ThemeData darkTheme() {
    const primary = Color(0xFF9AB0FF);
    const secondary = Color(0xFFC0B0FF);
    const tertiary = Color(0xFFF0BD7C);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Color(0xFF0E1B4A),
      primaryContainer: Color(0xFF243E92),
      onPrimaryContainer: Color(0xFFDDE5FF),
      secondary: secondary,
      onSecondary: Color(0xFF261B63),
      secondaryContainer: Color(0xFF3B2B86),
      onSecondaryContainer: Color(0xFFEAE4FF),
      tertiary: tertiary,
      onTertiary: Color(0xFF1A2B6B),
      tertiaryContainer: Color(0xFF5C390B),
      onTertiaryContainer: Color(0xFFFFE3C4),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0E142E),
      onSurface: Color(0xFFE7E9EF),
      surfaceContainerHighest: Color(0xFF161F42),
      onSurfaceVariant: Color(0xFFAAB1C0),
      outline: Color(0xFF8A93A6),
      outlineVariant: Color(0xFF2A2F3B),
      shadow: Color(0x40000000),
      scrim: Color(0x40000000),
      inverseSurface: Color(0xFFE7E9EF),
      onInverseSurface: Color(0xFF11131A),
      inversePrimary: Color(0xFF1F3F9A),
      surfaceTint: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BrandColors.darkBg,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF12151D),
        elevation: 4,
        shadowColor: const Color(0x24000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: const Color(0xFF0F1838),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }
}
