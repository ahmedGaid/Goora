import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

/// 007 direct-pay rules against test/fixtures/direct_pay_vectors.json — the
/// same file supabase/functions/_shared/direct_pay.test.ts runs.
void main() {
  final j = jsonDecode(File('test/fixtures/direct_pay_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> cases(String k) => (j[k] as List).cast<Map<String, dynamic>>();
  CashOutcome? outcome(Object? s) => s == null ? null : CashOutcome.values.byName(s as String);

  group('status', () {
    for (final c in cases('status')) {
      test(c['name'] as String, () {
        expect(
          SharePolicy.status(
            mark: outcome(c['mark']),
            markedAt: c['markedAt'] as int?,
            claimAt: c['claimAt'] as int?,
            tripEnd: c['tripEnd'] as int,
            now: c['now'] as int,
          ).name,
          c['expect'],
        );
      });
    }
  });

  group('canMark', () {
    for (final c in cases('canMark')) {
      test(c['name'] as String, () {
        expect(
          SharePolicy.canMark(
            current: ShareStatus.values.byName(c['current'] as String),
            outcome: outcome(c['outcome'])!,
            tripEnd: c['tripEnd'] as int,
            now: c['now'] as int,
            reversedOnce: c['reversedOnce'] as bool,
          ),
          c['expect'],
        );
      });
    }
  });

  group('flag', () {
    for (final c in cases('flag')) {
      test(c['name'] as String, () {
        expect(SharePolicy.disputeFlagged((c['days'] as List).cast<int>(), c['today'] as int), c['expect']);
      });
    }
  });

  group('share', () {
    for (final c in cases('share')) {
      test(c['name'] as String, () {
        expect(
          DirectPay.share(c['contribution'] as int,
              method: PaymentMethod.values.byName(c['method'] as String),
              tripCost: c['tripCost'] as int,
              riderSeats: c['riderSeats'] as int),
          c['expect'],
        );
      });
    }
  });

  group('fee', () {
    for (final c in cases('fee')) {
      test(c['name'] as String, () {
        expect(
          DirectPay.fee(c['contribution'] as int,
              share: c['share'] as int,
              tripCost: c['tripCost'] as int,
              riderSeats: c['riderSeats'] as int,
              feeFree: c['feeFree'] as bool),
          c['expect'],
        );
      });
    }
  });

  test('isOpenDebt', () {
    expect([for (final s in ShareStatus.values) if (s.isOpenDebt) s.name], ['notReceived', 'disputed']);
  });
}
