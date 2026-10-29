import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Device-walk 2026-10-20 copy nits N-1…N-4: lexicon (مشوار), digits, money unit.
void main() {
  final ar = l10nFor(const Locale('ar'));
  final en = l10nFor(const Locale('en'));

  test('N-1: Arabic says مشوار, never رحلة, in the wallet lines', () {
    for (final n in [0, 1, 3]) {
      expect(ar.coversTrips(n), isNot(contains('رحلة')));
      expect(ar.coversTrips(n), isNot(contains('رحلات')));
    }
    expect(ar.breakdownTitle, isNot(contains('رحلة')));
    expect(ar.breakdownTitle, contains('مشوار'));
  });

  test('N-2: the zero-balance card no longer says it covers no trips', () {
    expect(en.coversTrips(0), isNot(contains('no trips')));
    expect(ar.coversTrips(0), isNot(contains('مش بيغطي')));
  });

  test('N-3: the seat rule uses Western digits like every other screen', () {
    expect(ar.seatRule, isNot(contains('٩')));
    expect(ar.seatRule, contains('9'));
  });

  test('N-4: money is ج, not ج.م', () {
    expect(ar.feeOwed(30), isNot(contains('ج.م')));
    expect(ar.feeOwed(30), contains('30 ج'));
    expect(ar.feeSavings(160), isNot(contains('ج.م')));
    expect(ar.owesDriver(40, 'Ahmed'), isNot(contains('ج.م')));
  });

  test('wallet caption: Arabic count agrees with the noun (25 مشوار, not 25 مشاوير)', () {
    expect(ar.coversTrips(2), contains('مشوارين'));
    expect(ar.coversTrips(5), 'بيغطي حوالي 5 مشاوير');
    expect(ar.coversTrips(25), 'بيغطي حوالي 25 مشوار');
    expect(ar.coversTrips(100), 'بيغطي حوالي 100 مشوار');
    expect(en.coversTrips(25), 'Covers about 25 trips');
  });
}
