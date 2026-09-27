import 'package:flutter/material.dart';

/// Uygulama renk paleti ve Soft Neumorphism teması.
class AppColors {
  AppColors._();
  static const Color background = Color(0xFFF0F4F8);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color mintGreen = Color(0xFFE0F2F1);
  static const Color lavender = Color(0xFFF3E5F5);
  static const Color neumorphicLight = Color(0xFFFFFFFF);
  static const Color neumorphicDark = Color(0xFFD1D9E6);
  static const Color pressed = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textOnDark = Color(0xFFFAFAFA);

  static const Color buttonBlue = Color(0xFF7EB8E0);
  static const Color buttonGreen = Color(0xFF8BC9A0);
  static const Color buttonOrange = Color(0xFFFFBB7C);
  static const Color buttonPink = Color(0xFFF4A0B5);
  static const Color buttonPurple = Color(0xFFC594D8);
  static const Color buttonTeal = Color(0xFF7EC8BF);
  static const Color buttonIndigo = Color(0xFF8898D4);
  static const Color buttonAmber = Color(0xFFE8C96A);
  static const Color positiveGreen = Color(0xFF81C784);
  static const Color streakOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFE53935);
  static const Color cardBackground = Color(0xFFFFFFFF);
}

/// Neumorphism dekorasyon yardımcıları.
class Neu {
  Neu._();
  static BoxDecoration elevated({
    Color base = AppColors.background,
    double radius = 28,
    double blur = 12,
  }) =>
      BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
              color: AppColors.neumorphicLight.withValues(alpha: 0.8),
              blurRadius: blur,
              offset: const Offset(-4, -4)),
          BoxShadow(
              color: AppColors.neumorphicDark.withValues(alpha: 0.5),
              blurRadius: blur,
              offset: const Offset(4, 4)),
        ],
      );

  static BoxDecoration inset({
    Color base = AppColors.pressed,
    double radius = 28,
  }) =>
      BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
              color: AppColors.neumorphicDark.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(-2, -2)),
          BoxShadow(
              color: AppColors.neumorphicLight.withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(2, 2)),
        ],
      );

  static BoxDecoration colored({
    required Color color,
    double radius = 28,
    bool isPressed = false,
  }) =>
      BoxDecoration(
        color: isPressed ? Color.lerp(color, Colors.black, 0.08)! : color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(-1, -1)),
              ]
            : [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(-3, -3)),
                BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(4, 4)),
              ],
      );
}

/// Tema palet tanımı
class AppThemePalette {
  final String name;
  final String emoji;
  final Color primary;
  final Color background;
  final Color surface;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowDark;
  final Color shadowLight;

  const AppThemePalette({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.background,
    required this.surface,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadowDark,
    required this.shadowLight,
  });
}

/// MD3 + Soft Neumorphism teması.
class AppTheme {
  AppTheme._();

  static const List<AppThemePalette> palettes = [
    AppThemePalette(
      name: 'Mavi',
      emoji: '🔵',
      primary: Color(0xFF4A90E2),
      background: Color(0xFFF0F4F8),
      surface: Color(0xFFFFFFFF),
      gradientStart: Color(0xFFF0F4F8),
      gradientEnd: Color(0xFFDDEBFA),
      shadowDark: Color(0xFFD1D9E6),
      shadowLight: Color(0xFFFFFFFF),
    ),
    AppThemePalette(
      name: 'Yeşil',
      emoji: '🟢',
      primary: Color(0xFF43A047),
      background: Color(0xFFF1F8F4),
      surface: Color(0xFFFFFFFF),
      gradientStart: Color(0xFFF1F8F4),
      gradientEnd: Color(0xFFDCF0E2),
      shadowDark: Color(0xFFCCDCCF),
      shadowLight: Color(0xFFFFFFFF),
    ),
    AppThemePalette(
      name: 'Pembe',
      emoji: '🩷',
      primary: Color(0xFFE91E63),
      background: Color(0xFFFDF0F4),
      surface: Color(0xFFFFFFFF),
      gradientStart: Color(0xFFFDF0F4),
      gradientEnd: Color(0xFFFCDDE7),
      shadowDark: Color(0xFFE0CAD1),
      shadowLight: Color(0xFFFFFFFF),
    ),
    AppThemePalette(
      name: 'Turuncu',
      emoji: '🟠',
      primary: Color(0xFFFB8C00),
      background: Color(0xFFFAF3EC),
      surface: Color(0xFFFFFFFF),
      gradientStart: Color(0xFFFAF3EC),
      gradientEnd: Color(0xFFFCE6D0),
      shadowDark: Color(0xFFE2D4C5),
      shadowLight: Color(0xFFFFFFFF),
    ),
  ];

  static AppThemePalette getPalette(int index) {
    if (index < 0 || index >= palettes.length) return palettes[0];
    return palettes[index];
  }

  static LinearGradient getGradient(int index) {
    final p = getPalette(index);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [p.gradientStart, p.gradientEnd],
    );
  }

  static ThemeData get light => getTheme(0);

  static ThemeData getTheme(int index) {
    final p = getPalette(index);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: Brightness.light,
        surface: p.background,
      ),
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
        headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        bodyLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        bodyMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: p.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
