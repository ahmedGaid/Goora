import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/fee_balance.dart';

/// 008 pay-later rules against test/fixtures/fee_balance_vectors.json — the
/// same file supabase/functions/_shared/fee_balance.test.ts runs.
void main() {
  final j = jsonDecode(File('test/fixtures/fee_balance_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> cases(String k) => (j[k] as List).cast<Map<String, dynamic>>();
  CalendarDate? date(Object? s) => s == null ? null : CalendarDate.parse(s as String);

  group('due', () {
    for (final c in cases('due')) {
      test(c['name'] as String, () {
        final days = [
          for (final d in (c['days'] as List).cast<Map<String, dynamic>>())
            (date: date(d['date'])!, balance: d['balance'] as int),
        ];
        expect(FeeBalancePolicy.dueDate(days, date(c['today'])!)?.toIso(), c['expect']);
      });
    }
  });

  group('overdue', () {
    for (final c in cases('overdue')) {
      test(c['name'] as String, () {
        expect(FeeBalancePolicy.isOverdue(date(c['due']), date(c['today'])!), c['expect']);
      });
    }
  });

  group('bundle', () {
    for (final c in cases('bundle')) {
      test(c['name'] as String, () {
        expect(TripBundle.useBundle(c['fee'] as int, c['left'] as int), c['expect']);
      });
    }
  });
}
