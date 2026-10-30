import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Device-walk 2026-10-20 nits N-1…N-4 were one-line tests on single keys; the same
/// slips can come back on any new key. This sweeps every Arabic string once, so a
/// new feature's copy cannot reintroduce them (goora-brand lexicon: مشوار, السواق,
/// كرسي; Western digits; ج not ج.م).
void main() {
  final arb = jsonDecode(File('lib/core/l10n/app_ar.arb').readAsStringSync()) as Map<String, Object?>;
  final strings = {
    for (final MapEntry(:key, :value) in arb.entries)
      if (!key.startsWith('@') && value is String) key: value,
  };

  List<String> keysWith(Pattern p) => [for (final e in strings.entries) if (e.value.contains(p)) e.key];

  test('N-3: no Eastern-Arabic digit in any string', () {
    expect(keysWith(RegExp('[٠-٩]')), isEmpty);
  });

  test('N-4: money is ج, never ج.م', () {
    expect(keysWith('ج.م'), isEmpty);
  });

  test('walk 6 F-W5: money is ج, never the spelled-out جنيه (the plan sheet mixed the two)', () {
    expect(keysWith('جنيه'), isEmpty);
  });

  test('lexicon: السواق, never سائق; كرسي, never مقعد', () {
    expect(keysWith('سائق'), isEmpty);
    expect(keysWith('مقعد'), isEmpty);
  });

  test('lexicon: مشوار, never رحلة, except the two leg names and the debt listed here', () {
    // tripGoing / tripReturn name a leg (رحلة الذهاب / الرجوع), which the lexicon allows.
    // The other three are older wallet lines that still say رحلة for a whole trip; they
    // are known debt (walk N-1 class, research R11 addendum) — fix them, then shrink
    // this list. A new key may not join it. (planFuelNote was fixed in walk 6, F-W5.)
    const allowed = {
      'tripGoing',
      'tripReturn',
      'actTripDeduction',
      'actTripIncome',
      'driverBreakdownCost',
    };
    expect(keysWith(RegExp('رحلة|رحلات')).toSet().difference(allowed), isEmpty);
  });
}
