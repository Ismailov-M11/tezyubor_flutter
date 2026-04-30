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
        outlineVariant: border.withValues(alpha: isLight ? 0.5 : 1),
        shadow: Colors.black.withValues(alpha: isLight ? 0.06 : 0.25),
        scrim: Colors.black.withValues(alpha: 0.5),
        inverseSurface: isLight ? AppColors.backgroundDark : AppColors.backgroundLight,
        onInverseSurface: isLight ? AppColors.foregroundDark : AppColors.foregroundLight,
        inversePrimary: AppColors.primary,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? bg : AppColors.backgroundDark.withValues(alpha: 0.95),
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: mutedFg),
        labelStyle: TextStyle(color: mutedFg),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 22);
          }
          return IconThemeData(color: mutedFg, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return TextStyle(color: mutedFg, fontSize: 11);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(fontSize: 12.5, color: fg, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isLight ? AppColors.foregroundLight : AppColors.cardDark,
        contentTextStyle: TextStyle(
          color: isLight ? AppColors.backgroundLight : AppColors.foregroundDark,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? bg : AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: -0.3,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: mutedFg),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: fg, letterSpacing: -1.5),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: fg, letterSpacing: -1),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: fg, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: fg, letterSpacing: -0.6),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fg, letterSpacing: -0.4),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: fg, letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.4),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg, letterSpacing: -0.2),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg, letterSpacing: -0.1),
        bodyLarge: TextStyle(fontSize: 16, color: fg, letterSpacing: 0),
        bodyMedium: TextStyle(fontSize: 14, color: fg, letterSpacing: 0),
        bodySmall: TextStyle(fontSize: 12, color: mutedFg, letterSpacing: 0),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.05),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedFg, letterSpacing: 0.5),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: mutedFg, letterSpacing: 0.6),
      ),
    );
  }
}
