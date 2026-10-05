import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/theme/app_colors.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  double channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) => 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final (hi, lo) = lum(a) > lum(b) ? (lum(a), lum(b)) : (lum(b), lum(a));
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Every text-on-background pairing the design system uses (constitution VII: ≥ 4.5:1).
  final pairs = <(String, Color, Color)>[
    ('textPrimary / background', AppColors.textPrimary, AppColors.background),
    ('textSecondary / background', AppColors.textSecondary, AppColors.background),
    ('textSecondary / surface', AppColors.textSecondary, AppColors.surface),
    ('white / greenText (selected pill)', AppColors.white, AppColors.greenText),
    ('white / primary', AppColors.white, AppColors.primary),
    ('forest / mint (CTA on dark)', AppColors.forest, AppColors.mint),
    ('greenText / mintSurface (chip)', AppColors.greenText, AppColors.mintSurface),
    ('greenText / surface', AppColors.greenText, AppColors.surface),
    ('primary / surface', AppColors.primary, AppColors.surface),
    ('onDarkSecondary / forest', AppColors.onDarkSecondary, AppColors.forest),
    ('onDarkSecondary / primary', AppColors.onDarkSecondary, AppColors.primary),
    ('onDarkBody / primary', AppColors.onDarkBody, AppColors.primary),
    ('mint / forest (tagline)', AppColors.mint, AppColors.forest),
    ('white / forest', AppColors.white, AppColors.forest),
    ('warningTitle / warningBg', AppColors.warningTitle, AppColors.warningBg),
    ('warningBody / warningBg', AppColors.warningBody, AppColors.warningBg),
    ('infoTitle / infoBg', AppColors.infoTitle, AppColors.infoBg),
    ('infoBody / infoBg', AppColors.infoBody, AppColors.infoBg),
    ('dangerText / surface', AppColors.dangerText, AppColors.surface),
    ('dangerText / background', AppColors.dangerText, AppColors.background),
    ('white / danger (SOS)', AppColors.white, AppColors.danger),
    ('primary / mintSurface (recovery line)', AppColors.primary, AppColors.mintSurface),
    ('textBody / mapLand (map labels)', AppColors.textBody, AppColors.mapLand),
    ('textBody / background (fee line)', AppColors.textBody, AppColors.background),
    ('white / textSecondary (anonymous avatar)', AppColors.white, AppColors.textSecondary),
  ];

  for (final (name, fg, bg) in pairs) {
    test('$name ≥ 4.5:1', () => expect(contrast(fg, bg), greaterThanOrEqualTo(4.5)));
  }

  test('the two §3.4 pairings replaced on 2026-10-05 really fail', () {
    expect(contrast(AppColors.white, AppColors.green), lessThan(4.5));
    expect(contrast(AppColors.textMuted, AppColors.surface), lessThan(4.5));
  });
}
