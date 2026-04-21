import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Event Sphere Design System
/// A fresh, modern, and vibrant design system for the app

class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY PALETTE - Vibrant Coral & Teal
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color primary = Color(0xFF6366F1);        // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);    // Darker Indigo
  static const Color primaryLight = Color(0xFFE0E7FF);   // Light Indigo

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCENT COLORS - For highlights and CTAs
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color accent = Color(0xFFF472B6);         // Pink
  static const Color accentDark = Color(0xFFEC4899);     // Darker Pink
  static const Color accentLight = Color(0xFFFCE7F3);    // Light Pink

  static const Color secondary = Color(0xFF14B8A6);      // Teal
  static const Color secondaryDark = Color(0xFF0D9488);  // Darker Teal
  static const Color secondaryLight = Color(0xFFCCFBF1); // Light Teal

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF22C55E);        // Green
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);        // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);         // Red
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);           // Blue
  static const Color infoLight = Color(0xFFDBEAFE);

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRAL COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color background = Color(0xFFF8FAFC);     // Slate 50
  static const Color surface = Color(0xFFFFFFFF);        // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0);         // Slate 200
  static const Color divider = Color(0xFFCBD5E1);        // Slate 300

  static const Color textPrimary = Color(0xFF0F172A);    // Slate 900
  static const Color textSecondary = Color(0xFF64748B);  // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8);   // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY COLORS (for events)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color categoryTech = Color(0xFF8B5CF6);      // Violet
  static const Color categorySports = Color(0xFF10B981);    // Emerald
  static const Color categoryCultural = Color(0xFFF97316);  // Orange
  static const Color categoryAcademic = Color(0xFF0EA5E9);  // Sky
  static const Color categoryMusic = Color(0xFFEC4899);     // Pink
  static const Color categoryArt = Color(0xFF6366F1);       // Indigo
}

// ═══════════════════════════════════════════════════════════════════════════
// MARRYMINT DARK PURPLE THEME - Premium Event App Design
// ═══════════════════════════════════════════════════════════════════════════

class DarkColors {
  // Background Colors - Deep Purple Black
  static const Color background = Color(0xFF0D0B14);        // Deepest purple-black
  static const Color backgroundGradientStart = Color(0xFF0D0B14);
  static const Color backgroundGradientEnd = Color(0xFF1A0F2E);
  static const Color surface = Color(0xFF1E1B2E);           // Card surfaces
  static const Color surfaceElevated = Color(0xFF2A2640);   // Pop-ups, Modals
  static const Color surfaceVariant = Color(0xFF352F4D);    // Slightly lighter
  static const Color border = Color(0xFF3D3557);            // Purple-tinted border
  static const Color divider = Color(0xFF4A4363);           // Divider color

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);       // Pure white
  static const Color textSecondary = Color(0xFFB8A9C9);     // Light purple-gray
  static const Color textTertiary = Color(0xFF7A6F8E);      // Muted purple
  static const Color textOnPrimary = Color(0xFFFFFFFF);     // White on colored bg

  // Primary & Accent Colors - Vibrant Purple/Pink
  static const Color primary = Color(0xFF9D4EDD);           // Vibrant purple
  static const Color primaryLight = Color(0xFFBB86FC);      // Lighter purple
  static const Color primaryDark = Color(0xFF7B2CBF);       // Darker purple
  static const Color accent = Color(0xFFE040FB);            // Magenta/Pink
  static const Color accentLight = Color(0xFFEA80FC);       // Light pink
  static const Color secondary = Color(0xFF03DAC6);         // Teal accent (keep for variety)

  // Semantic Colors (adjusted for dark mode)
  static const Color success = Color(0xFF00E676);           // Green
  static const Color warning = Color(0xFFFFD600);           // Yellow
  static const Color danger = Color(0xFFFF5252);            // Red
  static const Color info = Color(0xFF448AFF);              // Blue

  // Glassmorphism Colors
  static const Color glassBackground = Color(0x401E1B2E);   // Semi-transparent card
  static const Color glassBorder = Color(0x40FFFFFF);       // White border at 25%
  static const Color glassHighlight = Color(0x20FFFFFF);    // Subtle highlight
}

class AppGradients {
  // Main gradient for headers and key elements
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9D4EDD),  // Vibrant purple
      Color(0xFF7B2CBF),  // Darker purple
    ],
  );

  // MarryMint style button gradient (purple to pink)
  static const LinearGradient purplePink = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF8B5CF6),  // Purple
      Color(0xFFEC4899),  // Pink
    ],
  );

  // Vibrant gradient for CTAs
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE040FB),  // Magenta
      Color(0xFFAB47BC),  // Purple
    ],
  );

  // Cool gradient for secondary elements
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF14B8A6),  // Teal
      Color(0xFF22D3EE),  // Cyan
    ],
  );

  // Dark background gradient (for pages)
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0B14),  // Deep purple-black
      Color(0xFF1A0F2E),  // Dark purple
    ],
  );

  // Sunset gradient for special cards
  static const LinearGradient sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEC4899),  // Pink
      Color(0xFF8B5CF6),  // Violet
      Color(0xFF6366F1),  // Indigo
    ],
  );

  // Glass effect gradient
  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x30FFFFFF),
      Color(0x10FFFFFF),
    ],
  );

  // Card background gradient (for dark cards)
  static const LinearGradient cardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1B2E),
      Color(0xFF2A2640),
    ],
  );

  // Card background gradient (light mode)
  static const LinearGradient cardLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  // Image overlay gradient (for event cards)
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0xCC0D0B14),
    ],
  );
}

class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: AppColors.accent.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 4),
    ),
  ];

  // Purple glow for dark theme
  static List<BoxShadow> get purpleGlow => [
    BoxShadow(
      color: DarkColors.primary.withOpacity(0.5),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASSMORPHISM DECORATIONS - Premium glass effect
// ═══════════════════════════════════════════════════════════════════════════

class GlassDecoration {
  /// Standard glass card decoration
  static BoxDecoration card({
    double borderRadius = 20,
    Color? backgroundColor,
    double opacity = 0.6,
  }) {
    return BoxDecoration(
      color: (backgroundColor ?? DarkColors.surface).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: DarkColors.glassBorder,
        width: 1,
      ),
    );
  }

  /// Glass card with gradient
  static BoxDecoration gradientCard({
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      gradient: AppGradients.cardDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: DarkColors.glassBorder,
        width: 1,
      ),
    );
  }

  /// Search bar style glass decoration
  static BoxDecoration searchBar({
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: DarkColors.surface.withOpacity(0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: DarkColors.border,
        width: 1,
      ),
    );
  }

  /// Button glass decoration
  static BoxDecoration button({
    double borderRadius = 30,
  }) {
    return BoxDecoration(
      gradient: AppGradients.purplePink,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: AppShadows.purpleGlow,
    );
  }

  /// Ghost button (outline style)
  static BoxDecoration ghostButton({
    double borderRadius = 30,
  }) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: DarkColors.textSecondary,
        width: 1.5,
      ),
    );
  }
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 100.0;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
}

class AppTheme {
  // Legacy support - keeping old names for backward compatibility
  static const Color primaryColor = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color accentColor = AppColors.accent;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color dangerColor = AppColors.danger;
  static const Color bgPrimary = AppColors.background;
  static const Color bgSecondary = AppColors.surfaceVariant;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color borderColor = AppColors.border;

  static const double cornerRadiusSmall = AppRadius.sm;
  static const double cornerRadiusMedium = AppRadius.md;
  static const double cornerRadiusLarge = AppRadius.lg;

  // For onboarding compatibility
  static const LinearGradient primaryGradient = AppGradients.primary;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        onTertiary: AppColors.textOnPrimary,
        tertiaryContainer: AppColors.accentLight,
        error: AppColors.danger,
        onError: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        outline: AppColors.border,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // Typography
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.25,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textTertiary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),

      // Cards
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          color: AppColors.textOnPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME - MarryMint Purple Style
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme - Purple accent
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9D4EDD),           // Vibrant purple
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFF7B2CBF),
        secondary: Color(0xFFE040FB),         // Magenta accent
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFAB47BC),
        tertiary: Color(0xFF03DAC6),          // Teal
        onTertiary: Color(0xFFFFFFFF),
        error: Color(0xFFFF5252),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFF1E1B2E),           // Dark purple surface
        onSurface: Color(0xFFFFFFFF),
        surfaceContainerHighest: Color(0xFF2A2640),
        outline: Color(0xFF3D3557),
      ),

      // Scaffold background - Deep purple-black
      scaffoldBackgroundColor: DarkColors.background,

      // AppBar - Transparent for gradient backgrounds
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),

      // Typography
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: DarkColors.textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: DarkColors.textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: DarkColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: DarkColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: DarkColors.textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: DarkColors.textTertiary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: DarkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DarkColors.border.withOpacity(0.5)),
        ),
      ),

      // Elevated Button - Purple gradient style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button - Ghost style
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DarkColors.textSecondary,
          side: const BorderSide(color: DarkColors.textSecondary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration - Glass style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkColors.surface.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DarkColors.danger),
        ),
        labelStyle: GoogleFonts.poppins(
          color: DarkColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: DarkColors.textTertiary,
          fontSize: 14,
        ),
        prefixIconColor: DarkColors.textSecondary,
        suffixIconColor: DarkColors.textSecondary,
      ),

      // Bottom Navigation - Glassmorphism style
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: DarkColors.surface.withOpacity(0.9),
        selectedItemColor: DarkColors.primary,
        unselectedItemColor: DarkColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DarkColors.surfaceVariant,
        contentTextStyle: GoogleFonts.poppins(
          color: DarkColors.textPrimary,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: DarkColors.surface,
        selectedColor: DarkColors.primary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: DarkColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: DarkColors.border),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: DarkColors.divider,
        thickness: 1,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DarkColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: DarkColors.textSecondary,
        size: 24,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME-AWARE COLOR HELPER
// ═══════════════════════════════════════════════════════════════════════════

/// Helper class to get theme-aware colors based on BuildContext
/// Usage: ThemeColors.background(context), ThemeColors.textPrimary(context), etc.
class ThemeColors {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Backgrounds
  static Color background(BuildContext context) {
    return isDark(context) ? DarkColors.background : AppColors.background;
  }

  static Color surface(BuildContext context) {
    return isDark(context) ? DarkColors.surface : AppColors.surface;
  }

  static Color surfaceVariant(BuildContext context) {
    return isDark(context) ? DarkColors.surfaceVariant : AppColors.surfaceVariant;
  }

  static Color surfaceElevated(BuildContext context) {
    return isDark(context) ? DarkColors.surfaceElevated : AppColors.surface;
  }

  // Text
  static Color textPrimary(BuildContext context) {
    return isDark(context) ? DarkColors.textPrimary : AppColors.textPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? DarkColors.textSecondary : AppColors.textSecondary;
  }

  static Color textTertiary(BuildContext context) {
    return isDark(context) ? DarkColors.textTertiary : AppColors.textTertiary;
  }

  // Borders & Dividers
  static Color border(BuildContext context) {
    return isDark(context) ? DarkColors.border : AppColors.border;
  }

  static Color divider(BuildContext context) {
    return isDark(context) ? DarkColors.divider : AppColors.divider;
  }

  // Primary colors (might be slightly adjusted for dark mode)
  static Color primary(BuildContext context) {
    return isDark(context) ? DarkColors.primary : AppColors.primary;
  }

  // Card gradient
  static LinearGradient cardGradient(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E1E1E),
          Color(0xFF242424),
        ],
      );
    }
    return AppGradients.cardLight;
  }

  // Shadows (minimal in dark mode)
  static List<BoxShadow> cardShadow(BuildContext context) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return AppShadows.small;
  }
}
