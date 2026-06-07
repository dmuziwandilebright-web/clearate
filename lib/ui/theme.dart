import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension ColorSchemeExt on ColorScheme {
  Color get surfaceDim => const Color(0xFFD8DADC);
  Color get surfaceBright => const Color(0xFFF7F9FB);
  Color get surfaceContainerLowest => const Color(0xFFFFFFFF);
  Color get surfaceContainerLow => const Color(0xFFF2F4F6);
  Color get surfaceContainer => const Color(0xFFECEEF0);
  Color get surfaceContainerHigh => const Color(0xFFE6E8EA);
  Color get surfaceContainerHighest => const Color(0xFFE0E3E5);

  Color get secondaryFixed => const Color(0xFFD3E4FE);
  Color get secondaryFixedDim => const Color(0xFFB7C8E1);
  Color get onSecondaryFixed => const Color(0xFF0B1C30);
  Color get onSecondaryFixedVariant => const Color(0xFF38485D);

  Color get primaryContainerNavy => const Color(0xFF131B2E);
  Color get onPrimaryContainerNavy => const Color(0xFF7C839B);

  Color get fairGreen => const Color(0xFF1B5E20);
  Color get fairGreenBg => const Color(0xFFE6F4EA);

  Color get overchargeRed => const Color(0xFFB71C1C);
  Color get overchargeRedBg => const Color(0xFFFFDAD6);

  Color get undervaluedAmber => const Color(0xFFF57F17);
  Color get undervaluedAmberBg => const Color(0xFFFFF4D6);
}

extension TextThemeExt on TextTheme {
  TextStyle get displayLg => GoogleFonts.publicSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 48 / 40,
      );

  TextStyle get headlineLg => GoogleFonts.publicSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.32,
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
        letterSpacing: 0.7,
        height: 20 / 14,
      );

  TextStyle get statLg => GoogleFonts.publicSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.72,
        height: 44 / 36,
      );
}

ThemeData buildClearateTheme() {
  const background = Color(0xFFF7F9FB);
  const onSurface = Color(0xFF191C1E);
  const outlineVariant = Color(0xFFC6C6CD);
  const primary = Color(0xFF000000);

  final scheme = ColorScheme.light(
    primary: primary,
    onPrimary: Colors.white,
    secondary: const Color(0xFF505F76),
    onSecondary: Colors.white,
    surface: background,
    onSurface: onSurface,
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF2F4F6),
    surfaceContainer: const Color(0xFFECEEF0),
    surfaceContainerHigh: const Color(0xFFE6E8EA),
    surfaceContainerHighest: const Color(0xFFE0E3E5),
    outline: const Color(0xFF76777D),
    outlineVariant: outlineVariant,
    error: const Color(0xFFB71C1C),
    onError: Colors.white,
    secondaryContainer: const Color(0xFFD0E1FB),
    onSecondaryContainer: const Color(0xFF54647A),
    primaryContainer: const Color(0xFF131B2E),
    onPrimaryContainer: const Color(0xFF7C839B),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF93000A),
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.publicSansTextTheme(),
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 56,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: outlineVariant),
        textStyle: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.publicSans(
        fontSize: 16,
        color: const Color(0xFF45464D).withOpacity(0.6),
      ),
      labelStyle: GoogleFonts.publicSans(
        fontSize: 16,
        color: const Color(0xFF45464D),
      ),
    ),
    dividerTheme: const DividerThemeData(color: outlineVariant, thickness: 1),
  );
}
