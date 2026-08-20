import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system ported from the web app's globals.css.
/// Forest greens + gold + cream, Playfair Display (display) + Inter (body).
///
/// Palette anchors (from the app's design tokens):
///   Primary   #1B5E20 (forest scale — a darker, deeper green)
///   Secondary #4A2E1F (gold700 — the strong/dark accent)
///   Tertiary  #8D6E63 (gold500/goldSoft — the mid/soft accent)
///   Neutral   #F5F1E8 (cream scale)
class AppColors {
  AppColors._();

  // Forest scale — Primary, anchored at #1B5E20
  static const Color forest950 = Color(0xFF081F0A);
  static const Color forest900 = Color(0xFF0F3D12);
  static const Color forest800 = Color(0xFF1B5E20);
  static const Color forest700 = Color(0xFF2E7D32);
  static const Color forest600 = Color(0xFF388E3C);
  static const Color forest500 = Color(0xFF43A047);
  static const Color forest300 = Color(0xFF81C784);

  // Gold / earth — Secondary (#4A2E1F) + Tertiary (#8D6E63)
  static const Color gold700 = Color(0xFF4A2E1F);
  static const Color gold500 = Color(0xFF8D6E63);
  static const Color goldSoft = Color(0xFFBCAAA4);

  // Cream / surfaces — Neutral, anchored at #F5F1E8
  static const Color cream = Color(0xFFF5F1E8);
  static const Color creamDark = Color(0xFFEBE0C9);
  // Warm feed background — posts sit as white cards on this.
  static const Color feedBg = Color(0xFFEFE9DA);

  // Convenient aliases (kept for backwards-compat with legacy screens)
  static const Color forestDark = forest900;
  static const Color forest = forest800;
  static const Color forestLight = forest700;
  static const Color gold = gold500;

  static const Color ink = Color(0xFF1A1A1A);
  static const Color label = Color(0xFF2B2B2B);
  static const Color hint = Color(0xFF7A7A7A);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFDFC5A0);

  static const Color pageBackground = feedBg;
  static const Color cardBackground = Colors.white;
}

class AppGradients {
  AppGradients._();

  static const LinearGradient forest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.forest800, AppColors.forest700],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold700, AppColors.gold500],
  );

  static const LinearGradient sidebar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.forest900, AppColors.forest800, AppColors.forest700],
  );

  static const LinearGradient deepForest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.forest900, AppColors.forest800],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [AppColors.cream, AppColors.creamDark, AppColors.goldSoft],
  );

  static const LinearGradient cream = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.creamDark, AppColors.goldSoft],
  );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.forest800.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.forest800.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> forestGlow = [
    BoxShadow(
      color: AppColors.forest800.withValues(alpha: 0.30),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.gold500.withValues(alpha: 0.30),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Display font (headings) ported from Playfair Display.
TextStyle display(
  double size, {
  FontWeight weight = FontWeight.w700,
  Color color = AppColors.forest900,
  double? height,
  FontStyle? fontStyle,
}) =>
    GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontStyle: fontStyle,
    );

/// Body font (Inter).
TextStyle body(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest800,
        primary: AppColors.forest800,
        secondary: AppColors.gold500,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.forest800,
        elevation: 0,
      ),
    );
  }
}
