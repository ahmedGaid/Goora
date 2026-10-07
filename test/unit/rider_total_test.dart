import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';

/// 004 v2 per-trip rider price against test/fixtures/pricing_vectors.json — the
/// same file supabase/functions/_shared/pricing.test.ts runs.
/// Regenerate with `python test/fixtures/gen_pricing_vectors.py`.
void main() {
  test('brief example: 40 EGP trip → rider pays 44 (40 to the driver, 4 to Goora)', () {
    expect(PricingService.serviceFee(40, isSubscriber: false, isCashTrial: false), 4);
    expect(PricingService.riderTotal(40, isSubscriber: false, isCashTrial: false), 44);
  });

  test('subscribers and cash trips pay exactly the contribution', () {
    expect(PricingService.riderTotal(40, isSubscriber: true, isCashTrial: false), 40);
    expect(PricingService.riderTotal(40, isSubscriber: false, isCashTrial: true), 40);
  });

  test('halves round up: 45 → 5, 44 → 4, 48 → 5', () {
    expect(PricingService.serviceFee(45, isSubscriber: false, isCashTrial: false), 5);
    expect(PricingService.serviceFee(44, isSubscriber: false, isCashTrial: false), 4);
    expect(PricingService.serviceFee(48, isSubscriber: false, isCashTrial: false), 5);
  });

  test('the fee never reaches the driver: contribution is unchanged inside the total', () {
    for (final c in [32, 40, 48]) {
      final total = PricingService.riderTotal(c, isSubscriber: false, isCashTrial: false);
      expect(total - PricingService.serviceFee(c, isSubscriber: false, isCashTrial: false), c);
    }
  });

  final j = jsonDecode(File('test/fixtures/pricing_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  for (final c in (j['cases'] as List).cast<Map<String, dynamic>>()) {
    test('vector: ${c['name']}', () {
      final contribution = c['contribution'] as int;
      final isSubscriber = c['isSubscriber'] as bool;
      final isCashTrial = c['isCashTrial'] as bool;
      expect(PricingService.serviceFee(contribution, isSubscriber: isSubscriber, isCashTrial: isCashTrial), c['fee']);
      expect(PricingService.riderTotal(contribution, isSubscriber: isSubscriber, isCashTrial: isCashTrial), c['total']);
    });
  }
}
