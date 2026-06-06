import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension ColorSchemeExt on ColorScheme {
  // Tonal Layering / Custom Colors from DESIGN.md
  Color get surfaceDim => const Color(0xFFD8DADC);
  Color get surfaceBright => const Color(0xFFF7F9FB);
  Color get surfaceContainerLowest => const Color(0xFFFFFFFF);
  Color get surfaceContainerLow => const Color(0xFFF2F4F6);
  Color get surfaceContainer => const Color(0xFFECEEF0);
  Color get surfaceContainerHigh => const Color(0xFFE6E8EA);
  Color get surfaceContainerHighest => const Color(0xFFE0E3E5);

  Color get secondaryFixed => const Color(0xFFD3E4FE);
  Color get onSecondaryFixed => const Color(0xFF0B1C30);
  Color get secondaryFixedDim => const Color(0xFFB7C8E1);
  Color get onSecondaryFixedVariant => const Color(0xFF38485D);

  Color get primaryContainerNavy => const Color(0xFF131B2E);
  Color get onPrimaryContainerNavy => const Color(0xFF7C839B);

  // Semantic Status Colors
  Color get fairGreen => const Color(0xFF0A7A34);
  Color get fairGreenBg => const Color(0xFFE6F4EA);

  Color get overchargeRed => const Color(0xFFBA1A1A);
  Color get overchargeRedBg => const Color(0xFFFFDAD6);

  Color get undervaluedAmber => const Color(0xFF8A5A00);
  Color get undervaluedAmberBg => const Color(0xFFFFF4D6);
}

extension TextThemeExt on TextTheme {
  TextStyle get displayLg => GoogleFonts.publicSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 40,
        height: 48 / 40,
      );

  TextStyle get headlineLg => GoogleFonts.publicSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 32,
        height: 40 / 32,
      );

  TextStyle get headlineLgMobile => GoogleFonts.publicSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      );

  TextStyle get headlineMd => GoogleFonts.publicSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  TextStyle get bodyLg => GoogleFonts.publicSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      );

  TextStyle get bodyMd => GoogleFonts.publicSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  TextStyle get labelMd => GoogleFonts.publicSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 14,
        height: 20 / 14,
      );

  TextStyle get statLg => GoogleFonts.publicSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 36,
        height: 44 / 36,
      );
}

ThemeData buildClearateTheme() {
  const surface = Color(0xFFF7F9FB);
  const onSurface = Color(0xFF191C1E);
  const outlineVariant = Color(0xFFC6C6CD);
  const primary = Color(0xFF000000);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    surface: surface,
    onSurface: onSurface,
    outlineVariant: outlineVariant,
    primary: primary,
    primaryContainer: const Color(0xFF131B2E),
    onPrimaryContainer: const Color(0xFF7C839B),
    secondaryContainer: const Color(0xFFD0E1FB),
    onSecondaryContainer: const Color(0xFF54647A),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: surface,
    textTheme: GoogleFonts.publicSansTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC6C6CD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC6C6CD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        fontFamily: GoogleFonts.publicSans().fontFamily,
        fontSize: 16,
        color: const Color(0xFF45464D),
      ),
      hintStyle: TextStyle(
        fontFamily: GoogleFonts.publicSans().fontFamily,
        fontSize: 16,
        color: const Color(0xFF45464D).withOpacity(0.6),
      ),
    ),
  );
}
