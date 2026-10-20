import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/domain/company.dart';
import 'package:goora/features/company/domain/company_log.dart';
import 'package:goora/features/company/domain/company_terms.dart';
import 'package:goora/features/company/domain/enrollment.dart';
import 'package:goora/features/company/domain/invoice.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';

// 010 T013: company model JSON as `company.*` stores it, and the domain rules.

/// Through a real JSON string.
Map<String, Object?> _json(Map<String, Object?> j) => (jsonDecode(jsonEncode(j)) as Map).cast<String, Object?>();

WallTime _at(int y, int m, int d, [int h = 0, int min = 0]) => WallTime(CalendarDate(y, m, d), Clock.hm(h, min));

final _valeo = Company(
  id: 'co-1',
  name: 'Valeo',
  domains: const ['valeo.com', 'valeo.eg'],
  status: CompanyStatus.active,
  hrContactId: 'mona',
  contractStart: CalendarDate(2026, 8, 1),
  contractEnd: CalendarDate(2027, 8, 1),
  minimumSeats: 20,
  pricePerSeat: 99,
  approvedAt: _at(2026, 8, 1, 9),
);

void main() {
  group('JSON round-trip (T013)', () {
    test('Company, full', () => expect(Company.fromJson(_json(_valeo.toJson())), _valeo));

    test('Company, pending with no dates', () {
      const pending = Company(
        id: 'co-2',
        name: 'Orange Business',
        domains: ['orange.com'],
        status: CompanyStatus.pending,
        hrContactId: 'karim',
        minimumSeats: 20,
        pricePerSeat: 99,
      );
      expect(Company.fromJson(_json(pending.toJson())), pending);
    });

    test('Company, ended with no HR contact', () {
      final ended = _valeo.copyWith(status: CompanyStatus.ended, endedAt: _at(2026, 12, 3, 10), hrContactId: null);
      expect(ended.hrContactId, isNull);
      expect(Company.fromJson(_json(ended.toJson())), ended);
    });

    test('a suspended status is never stored (derived from invoices)', () {
      expect(() => _valeo.copyWith(status: CompanyStatus.suspended).toJson(), throwsA(isA<AssertionError>()));
    });

    test('Enrollment, open and left', () {
      final open = Enrollment(
        personId: 'ahmed',
        companyId: 'co-1',
        name: 'Ahmed',
        workEmail: 'ahmed@valeo.com',
        enrolledAt: _at(2026, 10, 3, 8, 15),
      );
      final left = open.leave(_at(2026, 10, 20, 17), LeftWhy.removedByHr);
      expect(Enrollment.fromJson(_json(open.toJson())), open);
      expect(Enrollment.fromJson(_json(left.toJson())), left);
      expect(open.isOpen, isTrue);
      expect(left.isOpen, isFalse);
      expect(left.leftWhy, LeftWhy.removedByHr);
    });

    test('Invoice, issued and paid', () {
      final inv = Invoice.issue(company: _valeo, month: CalendarDate(2026, 10, 1), peakEnrolled: 12);
      final paid = inv.markPaid(at: _at(2026, 11, 10, 11, 30), bankRef: 'CIB-778812');
      expect(Invoice.fromJson(_json(inv.toJson())), inv);
      expect(Invoice.fromJson(_json(paid.toJson())), paid);
      expect(paid.paidOn, CalendarDate(2026, 11, 10));
    });

    test('LogEntry, with and without detail', () {
      final a = LogEntry(companyId: 'co-1', at: _at(2026, 8, 1, 9), actor: LogActor.goora, kind: LogKind.approved);
      final b = LogEntry(
        companyId: 'co-1',
        at: _at(2026, 10, 20, 17),
        actor: LogActor.hr,
        kind: LogKind.employeeRemoved,
        detail: 'Ahmed',
      );
      expect(LogEntry.fromJson(_json(a.toJson())), a);
      expect(LogEntry.fromJson(_json(b.toJson())), b);
    });
  });

  group('domains (FR-002)', () {
    test('lower-cased and trimmed, a leading @ dropped', () {
      expect(CompanyDomains.normalize('  Valeo.COM '), 'valeo.com');
      expect(CompanyDomains.normalize('@valeo.com'), 'valeo.com');
    });

    test('public mail domains are refused, any case', () {
      for (final d in ['gmail.com', 'Yahoo.com', 'outlook.com', 'HOTMAIL.COM', 'icloud.com']) {
        expect(CompanyDomains.isPublic(d), isTrue, reason: d);
      }
      expect(CompanyDomains.isPublic('valeo.com'), isFalse);
    });

    test('the domain of a work email', () {
      expect(CompanyDomains.of('Ahmed.Ali@Valeo.com'), 'valeo.com');
      expect(CompanyDomains.of('not-an-email'), isNull);
      expect(CompanyDomains.of('ahmed@'), isNull);
    });

    test('a company name is 2–60 characters', () {
      expect(Company.nameOk('V'), isFalse);
      expect(Company.nameOk('Valeo'), isTrue);
      expect(Company.nameOk(' ${'x' * 61} '), isFalse);
    });
  });

  group('invoice rules (FR-011, Q1–Q3, Q10)', () {
    test('12 enrolled with a minimum of 20 → 20 × 99 = 1,980, due 16 Nov', () {
      final inv = Invoice.issue(company: _valeo, month: CalendarDate(2026, 10, 1), peakEnrolled: 12);
      expect(inv.id, 'inv-co-1-2026-10');
      expect(inv.month, '2026-10');
      expect(inv.billedSeats, 20);
      expect(inv.total, 1980);
      expect(inv.issuedOn, CalendarDate(2026, 11, 1));
      expect(inv.dueOn, CalendarDate(2026, 11, 16));
      expect(inv.suspendFrom, _at(2026, 11, 24));
      expect(inv.reference, 'GR-1-202610');
    });

    test('34 enrolled → 34 × 99', () {
      final inv = Invoice.issue(company: _valeo, month: CalendarDate(2026, 10, 1), peakEnrolled: 34);
      expect(inv.billedSeats, 34);
      expect(inv.total, 3366);
    });

    test('status: issued, overdue after the due day, paid from the paid moment', () {
      final inv = Invoice.issue(company: _valeo, month: CalendarDate(2026, 10, 1), peakEnrolled: 12);
      expect(inv.statusAt(_at(2026, 11, 16, 23, 59)), InvoiceStatus.issued);
      expect(inv.statusAt(_at(2026, 11, 17)), InvoiceStatus.overdue);
      final paid = inv.markPaid(at: _at(2026, 11, 27, 12), bankRef: 'NBE-1');
      expect(paid.statusAt(_at(2026, 11, 27, 12)), InvoiceStatus.paid);
    });

    test('defaults live in one place (research R0 list)', () {
      expect(CompanyTerms.pricePerSeat, 99);
      expect(CompanyTerms.minimumSeats, 20);
      expect(CompanyTerms.contractMonths, 12);
    });
  });

  test('an enrollment window is on the shared minute scale', () {
    final e = Enrollment(
      personId: 'ahmed',
      companyId: 'co-1',
      name: 'Ahmed',
      workEmail: 'ahmed@valeo.com',
      enrolledAt: _at(2026, 10, 3, 8),
    );
    expect(e.window, (from: SharePolicy.minuteOf(_at(2026, 10, 3, 8)), to: null));
    final left = e.leave(_at(2026, 10, 4, 8), LeftWhy.self);
    expect(left.window, (from: SharePolicy.minuteOf(_at(2026, 10, 3, 8)), to: SharePolicy.minuteOf(_at(2026, 10, 4, 8))));
  });
}
