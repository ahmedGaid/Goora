import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/company/domain/company_rules.dart';

/// 010 company money rules + suppression against
/// test/fixtures/company_vectors.json — the same file
/// supabase/functions/_shared/company.test.ts runs.
/// Regenerate with `python test/fixtures/gen_company_vectors.py`.
void main() {
  final j = jsonDecode(File('test/fixtures/company_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> cases(String key) => (j[key] as List).cast<Map<String, dynamic>>();

  group('coverage', () {
    for (final c in cases('coverage')) {
      test(c['name'] as String, () {
        expect(
          CompanyRules.coverage(_windows(c['enrolled']), _windows(c['companyActive'])),
          _windows(c['expect']),
          reason: c['name'] as String,
        );
      });
    }
  });

  group('covered', () {
    for (final c in cases('covered')) {
      test(c['name'] as String, () {
        expect(CompanyRules.covered(_windows(c['windows']), c['minute'] as int), c['expect'], reason: c['name'] as String);
      });
    }
  });

  group('peakEnrolled', () {
    for (final c in cases('peakEnrolled')) {
      test(c['name'] as String, () {
        final byPerson = {
          for (final e in (c['byPerson'] as Map<String, dynamic>).entries) e.key: _windows(e.value),
        };
        expect(
          CompanyRules.peakEnrolled(byPerson, c['monthFromDay'] as int, c['monthToDay'] as int),
          c['expect'],
          reason: c['name'] as String,
        );
      });
    }
  });

  group('billing', () {
    for (final c in cases('billing')) {
      test(c['name'] as String, () {
        final seats = CompanyRules.billedSeats(c['peak'] as int, c['minimumSeats'] as int);
        expect(seats, c['billedSeats'], reason: c['name'] as String);
        expect(CompanyRules.invoiceTotal(seats, c['pricePerSeat'] as int), c['total'], reason: c['name'] as String);
      });
    }
  });

  group('due', () {
    for (final c in cases('due')) {
      test(c['name'] as String, () {
        final due = CompanyRules.dueDay(c['issueDay'] as int);
        expect(due, c['dueDay'], reason: c['name'] as String);
        expect(CompanyRules.suspendFromDay(due), c['suspendFromDay'], reason: c['name'] as String);
      });
    }
  });

  group('activeWindows', () {
    for (final c in cases('activeWindows')) {
      test(c['name'] as String, () {
        final overdue = [
          for (final o in (c['overdue'] as List).cast<Map<String, dynamic>>())
            (suspendFrom: o['suspendFrom'] as int, paidAt: o['paidAt'] as int?),
        ];
        expect(
          CompanyRules.activeWindows(approvedAt: c['approvedAt'] as int, endedAt: c['endedAt'] as int?, overdue: overdue),
          _windows(c['expect']),
          reason: c['name'] as String,
        );
      });
    }
  });

  group('suppress', () {
    for (final c in cases('suppress')) {
      test(c['name'] as String, () {
        expect(CompanyRules.suppress(c['count'] as int), c['expect'], reason: c['name'] as String);
      });
    }
  });
}

List<Window> _windows(Object? list) => [
  for (final w in (list! as List).cast<Map<String, dynamic>>()) (from: w['from'] as int, to: w['to'] as int?),
];
