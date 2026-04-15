import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const primary = Color(0xFF1F3F9A);
    const secondary = Color(0xFF7A5AF8);
    const tertiary = Color(0xFFFF8A3D);
    const surface = Colors.white;
    const background = Color(0xFFF8F9FD);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE4CC),
      onPrimaryContainer: Color(0xFF3B1E00),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDE9FF),
      onSecondaryContainer: Color(0xFF1E1748),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFE8D6),
      onTertiaryContainer: Color(0xFF462100),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: surface,
      onSurface: Color(0xFF111111),
      surfaceContainerHighest: Color(0xFFF0F2F7),
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
          backgroundColor: tertiary,
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
    const primary = Color(0xFF8AA3FF);
    const secondary = Color(0xFFA98DFF);
    const tertiary = Color(0xFFFFA45E);

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Color(0xFF3A1B00),
      primaryContainer: Color(0xFF7D3900),
      onPrimaryContainer: Color(0xFFFFDCC3),
      secondary: secondary,
      onSecondary: Color(0xFF220E4A),
      secondaryContainer: Color(0xFF332168),
      onSecondaryContainer: Color(0xFFF0E9FF),
      tertiary: tertiary,
      onTertiary: Color(0xFF4A2500),
      tertiaryContainer: Color(0xFF663400),
      onTertiaryContainer: Color(0xFFFFDDC2),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0F1116),
      onSurface: Color(0xFFE7E9EF),
      surfaceContainerHighest: Color(0xFF1A1D25),
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
      scaffoldBackgroundColor: const Color(0xFF0B0D12),
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
          backgroundColor: tertiary,
          foregroundColor: const Color(0xFF2A1500),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: const Color(0xFF111827),
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
