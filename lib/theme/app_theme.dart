import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system ported from the web app's globals.css.
/// Forest greens + gold + cream, Playfair Display (display) + Inter (body).
class AppColors {
  AppColors._();

  // Forest scale
  static const Color forest950 = Color(0xFF061410);
  static const Color forest900 = Color(0xFF0D2B1E);
  static const Color forest800 = Color(0xFF1B4332);
  static const Color forest700 = Color(0xFF2D6A4F);
  static const Color forest600 = Color(0xFF40916C);
  static const Color forest500 = Color(0xFF52B788);
  static const Color forest300 = Color(0xFF95D5B2);

  // Gold / earth
  static const Color gold700 = Color(0xFF8B5E3C);
  static const Color gold500 = Color(0xFFC4823A);
  static const Color goldSoft = Color(0xFFDFC5A0);

  // Cream / surfaces
  static const Color cream = Color(0xFFFAF7F2);
  static const Color creamDark = Color(0xFFF0E6D3);

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

  static const Color pageBackground = cream;
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
