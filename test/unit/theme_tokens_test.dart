import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/theme/app_colors.dart';
import 'package:goora/core/theme/app_radii.dart';
import 'package:goora/core/theme/app_spacing.dart';
import 'package:goora/core/theme/app_theme.dart';
import 'package:goora/core/theme/app_typography.dart';

void main() {
  test('brand and status colors match brief §3.1', () {
    final expected = <(Color, int)>[
      (AppColors.forest, 0xFF0B3B2E),
      (AppColors.primary, 0xFF0E3B2F),
      (AppColors.green, 0xFF1FA463),
      (AppColors.mint, 0xFF2BC275),
      (AppColors.greenText, 0xFF0E6B45),
      (AppColors.mintSurface, 0xFFE7F5EC),
      (AppColors.background, 0xFFF5F4EF),
      (AppColors.border, 0xFFE6E8E2),
      (AppColors.borderStrong, 0xFFD7DCD6),
      (AppColors.textPrimary, 0xFF10231C),
      (AppColors.textSecondary, 0xFF56645E),
      (AppColors.disabled, 0xFFB8C2BC),
      (AppColors.danger, 0xFFC93A3A),
      (AppColors.dangerText, 0xFFA33030),
      (AppColors.mapDestination, 0xFFD64545),
    ];
    for (final (color, argb) in expected) {
      expect(color.toARGB32(), argb);
    }
    expect(AppColors.avatarPalette.map((c) => c.toARGB32()), [0xFFC9A27A, 0xFF5B7C99, 0xFFB5677D, 0xFF7A8F55]);
  });

  test('radii and spacing match brief §3.3', () {
    expect([AppRadii.pill, AppRadii.button, AppRadii.card, AppRadii.hero, AppRadii.chip, AppRadii.tile],
        [12.0, 16.0, 20.0, 22.0, 999.0, 18.0]);
    expect([AppSpacing.pageH, AppSpacing.tabH, AppSpacing.gap, AppSpacing.cardPad, AppSpacing.heroPad],
        [24.0, 20.0, 14.0, 16.0, 20.0]);
  });

  test('type scale matches brief §3.2', () {
    expect(AppTypography.wordmark.fontFamily, AppTypography.englishFamily);
    expect(AppTypography.wordmark.letterSpacing, -2);
    expect(AppTypography.wordmark.fontSize, 56);
    expect(AppTypography.display.fontSize, 38);
    expect(AppTypography.h1.fontSize, 28);
    expect(AppTypography.h2.fontSize, 24);
    expect(AppTypography.caption.fontSize, 12.5);
    expect(AppTypography.body.height, 1.5);
    expect(AppTypography.h1.height, 1.2);
  });

  test('theme: Material 3, background, font by locale', () {
    final arTheme = AppTheme.light(const Locale('ar'));
    final enTheme = AppTheme.light(const Locale('en'));
    expect(arTheme.useMaterial3, isTrue);
    expect(arTheme.scaffoldBackgroundColor, AppColors.background);
    expect(arTheme.colorScheme.primary, AppColors.primary);
    expect(arTheme.textTheme.bodyMedium!.fontFamily, 'Cairo');
    expect(enTheme.textTheme.bodyMedium!.fontFamily, 'PlusJakartaSans');
  });
}
