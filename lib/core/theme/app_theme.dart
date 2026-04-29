import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final bg = isLight ? AppColors.backgroundLight : AppColors.backgroundDark;
    final fg = isLight ? AppColors.foregroundLight : AppColors.foregroundDark;
    final card = isLight ? AppColors.cardLight : AppColors.cardDark;
    final border = isLight ? AppColors.borderLight : AppColors.borderDark;
    final muted = isLight ? AppColors.mutedLight : AppColors.mutedDark;
    final mutedFg = isLight ? AppColors.mutedForegroundLight : AppColors.mutedForegroundDark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary.withValues(alpha: 0.15),
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.primary.withValues(alpha: 0.1),
        onSecondaryContainer: AppColors.primary,
        tertiary: AppColors.info,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.info.withValues(alpha: 0.1),
        onTertiaryContainer: AppColors.info,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.error.withValues(alpha: 0.1),
        onErrorContainer: AppColors.error,
        surface: card,
        onSurface: fg,
        surfaceContainerHighest: muted,
        onSurfaceVariant: mutedFg,
        outline: border,
        outlineVariant: border.withValues(alpha: 0.5),
        shadow: Colors.black.withValues(alpha: isLight ? 0.06 : 0.2),
        scrim: Colors.black.withValues(alpha: 0.5),
        inverseSurface: isLight ? AppColors.backgroundDark : AppColors.backgroundLight,
        onInverseSurface: isLight ? AppColors.foregroundDark : AppColors.foregroundLight,
        inversePrimary: AppColors.primary,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0.8,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: mutedFg),
        labelStyle: TextStyle(color: mutedFg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: AppColors.primary.withValues(alpha: isLight ? 0.12 : 0.18),
        indicatorShape: const StadiumBorder(),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return IconThemeData(color: mutedFg, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return TextStyle(color: mutedFg, fontSize: 11);
        }),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        labelStyle: TextStyle(fontSize: 12, color: fg),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isLight ? AppColors.foregroundLight : AppColors.foregroundDark,
        contentTextStyle: TextStyle(
          color: isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.2,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: mutedFg),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: fg),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: fg),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: fg),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: fg, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fg, letterSpacing: -0.3),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: fg, letterSpacing: -0.2),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.3),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg, letterSpacing: -0.2),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
        bodyLarge: TextStyle(fontSize: 16, color: fg),
        bodyMedium: TextStyle(fontSize: 14, color: fg),
        bodySmall: TextStyle(fontSize: 12, color: mutedFg),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mutedFg),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: mutedFg),
      ),
    );
  }
}
