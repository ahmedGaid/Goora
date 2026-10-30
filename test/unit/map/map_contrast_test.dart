import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/theme/app_colors.dart';

import '../contrast_test.dart' show contrast;

/// 012 pin and attribution pairings (the shared list lives in contrast_test.dart).
void main() {
  test('pickup pin number: white on primary ≥ 4.5:1', () {
    expect(contrast(AppColors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
  });

  test('arrival pin flag icon: white on mapDestination ≥ 3:1 (non-text)', () {
    expect(contrast(AppColors.white, AppColors.mapDestination), greaterThanOrEqualTo(3));
  });

  test('pins stand out from the map: primary and mapDestination on mapLand ≥ 3:1', () {
    expect(contrast(AppColors.primary, AppColors.mapLand), greaterThanOrEqualTo(3));
    expect(contrast(AppColors.mapDestination, AppColors.mapLand), greaterThanOrEqualTo(3));
  });

  test('attribution + sketch note: textSecondary on surface ≥ 4.5:1', () {
    expect(contrast(AppColors.textSecondary, AppColors.surface), greaterThanOrEqualTo(4.5));
  });
}
