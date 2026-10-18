import 'package:flutter/material.dart';

// Swiss Minimalist Financial Terminal - Theme Definition
// Invariant: ZERO half-space characters (\\u200c) allowed.
// Style: High-contrast Swiss design, flat surfaces, crisp micro-borders, brushed gold accents.

class TerminalTheme {
  // Background & Surfaces
  static const Color carbonBlack = Color(0xFF0D0F12);
  static const Color slateDark = Color(0xFF161920);
  static const Color cardDark = Color(0xFF1C202A);
  static const Color cardLight = Color(0xFF222733);
  static const Color surfaceElevated = Color(0xFF272D3B);

  // Borders & Dividers
  static const Color borderColor = Color(0xFF2A303F);
  static const Color borderHighlight = Color(0xFF3D4559);

  // Swiss Terminal Accents
  static const Color goldAccent = Color(0xFFD4AF37); // Metallic gold
  static const Color goldBright = Color(0xFFFFD700); // Bright gold
  static const Color goldMuted = Color(0xFF99812A);

  // Risk / Signal Palette
  static const Color signalEmerald = Color(0xFF00E676); // Safe / Low bubble
  static const Color signalAmber = Color(0xFFFFB300);   // Moderate bubble
  static const Color signalCoral = Color(0xFFFF5252);   // Alert / High bubble
  static const Color signalBlue = Color(0xFF40C4FF);    // Informational

  // Typography Palette
  static const Color textPrimary = Color(0xFFECEFF4);
  static const Color textSecondary = Color(0xFF9099A8);
  static const Color textMuted = Color(0xFF5F687A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: carbonBlack,
      primaryColor: goldAccent,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: goldBright,
        surface: slateDark,
        error: signalCoral,
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: slateDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          fontFamily: 'monospace',
        ),
        iconTheme: IconThemeData(color: goldAccent),
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: goldAccent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: slateDark,
        selectedItemColor: goldAccent,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
