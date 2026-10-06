import 'package:flutter/material.dart';

// Colores de la marca
const kBlue = Color(0xFF1F6BB5);
const kNavy = Color(0xFF12203A);
const kBg = Color(0xFFF5F8FC);
const kBorder = Color(0xFFD5DEEA);
const kMuted = Color(0xFF5B6B80);
const kGreen = Color(0xFF0F7B3F);
const kAmber = Color(0xFFB45309);
const kRed = Color(0xFFC62828);
const kTeal = Color(0xFF4FB0CC);

// Tema general: botones, campos de texto y barra superior
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kBlue, primary: kBlue, surface: Colors.white);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat',
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: kNavy, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBlue,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBlue,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: kBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBlue, width: 2)),
      hintStyle: const TextStyle(color: Color(0xFF8A97A8)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
