import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';

/// 004 v2 per-trip rider price against test/fixtures/pricing_vectors.json — the
/// same file supabase/functions/_shared/pricing.test.ts runs.
/// Regenerate with `python test/fixtures/gen_pricing_vectors.py`.
void main() {
  test('brief example: 40 EGP trip → rider pays 44 (40 to the driver, 4 to Goora)', () {
    expect(PricingService.serviceFee(40, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false), 4);
    expect(PricingService.riderTotal(40, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false), 44);
  });

  test('subscribers and cash trips pay exactly the contribution', () {
    expect(PricingService.riderTotal(40, tripCost: 160, riderSeats: 3, isSubscriber: true, isCashTrial: false), 40);
    expect(PricingService.riderTotal(40, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: true), 40);
  });

  test('halves round up: 45 → 5, 44 → 4, 48 → 5', () {
    expect(PricingService.serviceFee(45, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false), 5);
    expect(PricingService.serviceFee(44, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false), 4);
    expect(PricingService.serviceFee(48, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false), 5);
  });

  test('the fee never reaches the driver: contribution is unchanged inside the total', () {
    for (final c in [32, 40, 48]) {
      final total = PricingService.riderTotal(c, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false);
      expect(total - PricingService.serviceFee(c, tripCost: 160, riderSeats: 3, isSubscriber: false, isCashTrial: false), c);
    }
  });

  test('cap: a full car at the top of the range trims the fee to the room left (160/4, 38 → 2)', () {
    expect(PricingService.serviceFee(38, tripCost: 160, riderSeats: 4, isSubscriber: false, isCashTrial: false), 2);
    expect(PricingService.riderTotal(38, tripCost: 160, riderSeats: 4, isSubscriber: false, isCashTrial: false), 40);
  });

  test('cap: a contribution already at the equal share leaves no room (96/4, 24 → 0)', () {
    expect(PricingService.serviceFee(24, tripCost: 96, riderSeats: 4, isSubscriber: false, isCashTrial: false), 0);
    expect(PricingService.riderTotal(24, tripCost: 96, riderSeats: 4, isSubscriber: false, isCashTrial: false), 24);
  });

  final j = jsonDecode(File('test/fixtures/pricing_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  for (final c in (j['cases'] as List).cast<Map<String, dynamic>>()) {
    test('vector: ${c['name']}', () {
      final contribution = c['contribution'] as int;
      final tripCost = c['tripCost'] as int;
      final riderSeats = c['riderSeats'] as int;
      final isSubscriber = c['isSubscriber'] as bool;
      final isCashTrial = c['isCashTrial'] as bool;
      expect(
        PricingService.serviceFee(contribution,
            tripCost: tripCost, riderSeats: riderSeats, isSubscriber: isSubscriber, isCashTrial: isCashTrial),
        c['fee'],
      );
      expect(
        PricingService.riderTotal(contribution,
            tripCost: tripCost, riderSeats: riderSeats, isSubscriber: isSubscriber, isCashTrial: isCashTrial),
        c['total'],
      );
    });
  }
}
