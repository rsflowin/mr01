import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Color Palette
  static const Color backgroundPrimary = Color(0xFF0B0B14);
  static const Color backgroundSecondary = Color(0xFF1E293B);
  static const Color backgroundTertiary = Color(0xFF334155);
  
  static const Color accentPrimary = Color(0xFF6366F1);
  static const Color accentSecondary = Color(0xFF8B5CF6);
  
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textTertiary = Color(0xFF64748B);
  
  static const Color borderPrimary = Color(0xFF475569);
  static const Color borderSecondary = Color(0xFF334155);

  // Typography Scale
  static const List<String> _kFontFallback = [
    'Noto Sans KR',
    'Noto Sans',
    'Apple SD Gothic Neo',
    'Malgun Gothic',
    'Roboto',
  ];

  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    // Headlines
    displayLarge: GoogleFonts.inter(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.02,
      color: textPrimary,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01,
      color: textPrimary,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: textPrimary,
    ),
    
    // Headings
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: textPrimary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: textPrimary,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: textPrimary,
    ),
    
    // Body Text
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.01,
      color: textSecondary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.01,
      color: textSecondary,
      height: 1.4,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.02,
      color: textTertiary,
      height: 1.3,
    ),
    
    // Labels
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.02,
      color: textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.02,
      color: textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.03,
      color: textTertiary,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: accentPrimary,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF4338CA),
      onPrimaryContainer: Color(0xFFDDD6FE),
      
      secondary: accentSecondary,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF7C3AED),
      onSecondaryContainer: Color(0xFFDDD6FE),
      
      tertiary: warningColor,
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFFD97706),
      onTertiaryContainer: Color(0xFFFEF3C7),
      
      error: dangerColor,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFDC2626),
      onErrorContainer: Color(0xFFFEE2E2),
      
      surface: backgroundSecondary,
      onSurface: textPrimary,
      surfaceContainerHighest: backgroundTertiary,
      onSurfaceVariant: textSecondary,
      
      outline: borderPrimary,
      outlineVariant: borderSecondary,
      
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      
      inverseSurface: Color(0xFFF8FAFC),
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: Color(0xFF4338CA),
    ),
    
    // Background
    scaffoldBackgroundColor: backgroundPrimary,
    
    // Typography
    textTheme: textTheme,
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundPrimary,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderSecondary, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: borderPrimary, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPrimary,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderSecondary, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderSecondary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: dangerColor, width: 1),
      ),
      labelStyle: GoogleFonts.inter(color: textSecondary),
      hintStyle: GoogleFonts.inter(color: textTertiary),
    ),
    
    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: backgroundSecondary,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderSecondary, width: 1),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
        height: 1.4,
      ),
    ),
    
    // Slider Theme
    sliderTheme: SliderThemeData(
      activeTrackColor: accentPrimary,
      inactiveTrackColor: backgroundTertiary,
      thumbColor: accentPrimary,
      overlayColor: accentPrimary.withOpacity(0.1),
      valueIndicatorColor: accentPrimary,
      valueIndicatorTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return accentPrimary;
        }
        return backgroundTertiary;
      }),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: borderSecondary,
      thickness: 1,
    ),
  );

  // Stat Colors
  static const Color hpColor = dangerColor;
  static const Color sanColor = accentSecondary;
  static const Color fitnessColor = successColor;
  static const Color hungerColor = warningColor;

  // Utility Methods
  static Color getStatColor(String statType) {
    switch (statType.toLowerCase()) {
      case 'hp':
        return hpColor;
      case 'san':
        return sanColor;
      case 'fitness':
        return fitnessColor;
      case 'hunger':
        return hungerColor;
      default:
        return textSecondary;
    }
  }

  // Glass morphism effect for cards
  static BoxDecoration get glassMorphism => BoxDecoration(
    color: backgroundSecondary.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: borderSecondary.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Gradient for special elements
  static LinearGradient get mysteriousGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C1D95),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}