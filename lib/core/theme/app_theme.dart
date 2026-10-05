import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

extension LocaleFont on TextStyle {
  /// Button styles replace the theme text style wholesale, dropping the
  /// locale font; this puts the current locale's family back.
  TextStyle withLocaleFont(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium;
    return copyWith(fontFamily: body?.fontFamily, fontFamilyFallback: body?.fontFamilyFallback);
  }
}

abstract final class AppTheme {
  static ThemeData light(Locale locale) {
    final family = AppTypography.familyFor(locale.languageCode);
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: family,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.danger,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: family,
        fontFamilyFallback: AppTypography.fallbackFor(locale.languageCode),
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
