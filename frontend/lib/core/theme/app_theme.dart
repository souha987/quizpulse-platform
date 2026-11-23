import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- PALETTE PROFESSIONNELLE WEB BLEU & BLANC ---
  // Bleu Primaire & Déclinaisons
  static const Color primary = Color(0xFF2563EB);       // Bleu royal moderne
  static const Color primaryDark = Color(0xFF1D4ED8);   // Bleu foncé
  static const Color primaryNavy = Color(0xFF1E3A8A);   // Bleu marine
  static const Color primaryLight = Color(0xFF3B82F6);  // Bleu clair
  static const Color primarySoft = Color(0xFFEFF6FF);   // Teinte bleue ultra-douce
  static const Color primaryBorder = Color(0xFFBFDBFE); // Bordure bleue subtile

  // Neutres, Arrière-plans & Typographie Web
  static const Color backgroundLight = Color(0xFFF8FAFC); // Fond web propre (Slate 50)
  static const Color surfaceLight = Color(0xFFFFFFFF);    // Blanc pur
  static const Color textMain = Color(0xFF0F172A);        // Slate 900 (Titres et texte fort)
  static const Color textSecondary = Color(0xFF334155);   // Slate 700 (Corps de texte)
  static const Color textMuted = Color(0xFF64748B);       // Slate 500 (Labels et secondaires)
  static const Color borderLight = Color(0xFFE2E8F0);     // Slate 200 (Bordures web nettes)
  static const Color borderSubtle = Color(0xFFF1F5F9);    // Slate 100

  // Couleurs Sémantiques & Statuts (Professionnelles)
  static const Color secondary = Color(0xFF0D9488); // Sarcelle / Vert d'eau professionnel
  static const Color success = Color(0xFF059669);   // Vert validation
  static const Color warning = Color(0xFFD97706);   // Ambre professionnel
  static const Color danger = Color(0xFFDC2626);    // Rouge sobre
  static const Color info = Color(0xFF0284C7);      // Cyan / Bleu d'information

  // Alias rétrocompatibilité
  static const Color tealBanner = Color(0xFF1E40AF);
  static const Color tealBannerDark = Color(0xFF1E3A8A);
  static const Color tealBannerLight = Color(0xFF2563EB);

  static const Color pastelPeach = Color(0xFFEFF6FF);
  static const Color pastelPeachBorder = Color(0xFFDBEAFE);
  static const Color pastelPeachText = Color(0xFF1D4ED8);

  static const Color pastelSky = Color(0xFFF0FDF4);
  static const Color pastelSkyBorder = Color(0xFFDCFCE7);
  static const Color pastelSkyText = Color(0xFF15803D);

  static const Color pastelLime = Color(0xFFFEF3C7);
  static const Color pastelLimeBorder = Color(0xFFFDE68A);
  static const Color pastelLimeText = Color(0xFFB45309);

  static const Color pastelBeige = Color(0xFFF8FAFC);
  static const Color pastelBeigeBorder = Color(0xFFE2E8F0);
  static const Color pastelBeigeText = Color(0xFF334155);

  static const Color chartOrange = Color(0xFF2563EB);
  static const Color chartSky = Color(0xFF38BDF8);
  static const Color chartLime = Color(0xFF10B981);

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final fontTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryDark,
        error: danger,
        surface: surfaceLight,
        background: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: fontTheme.apply(
        bodyColor: textSecondary,
        displayColor: textMain,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        shape: const Border(bottom: BorderSide(color: borderLight, width: 1)),
        titleTextStyle: GoogleFonts.inter(
          color: textMain,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      // Cartes Web épurées : fond blanc pur, bordure fine 1px, coins arrondis 10px
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        color: surfaceLight,
      ),
      // Boutons Web professionnels (coins 8px, sans biseaux ni ombres lourdes)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          backgroundColor: Colors.white,
          side: const BorderSide(color: borderLight, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
        backgroundColor: textMain,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
