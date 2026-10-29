import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_terms.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T031 (US3): the HR contact sees one invoice per closed month, 20 seats
/// × 99 = 1,980 EGP while 12 are enrolled, the invoice screen carries the
/// transfer reference, bank details and due date, and Goora marking it paid
/// shows the paid state — ar + en.
final _now = at(rideTuesday, 10, 0);

Future<ProviderContainer> _openInvoices(WidgetTester tester, String locale, {TestClock? clock}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(clock ?? TestClock(_now)),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await c
      .read(companyRepositoryProvider)
      .demoSetHrContact(CompanySeed.valeoId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('company-invoices')));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] company home has an Invoices button that opens one row per closed month', (tester) async {
      await _openInvoices(tester, code);
      expect(find.byKey(const Key('company-invoices-screen')), findsOneWidget);
      // The seed approved Valeo on 1 Aug; on 6 Oct, Aug and Sep are closed.
      expect(find.byKey(const Key('invoice-2026-09')), findsOneWidget);
      expect(find.byKey(const Key('invoice-2026-08')), findsOneWidget);
      expect(find.byKey(const Key('invoice-2026-10')), findsNothing);
    });

    testWidgets('[$code] 12 enrolled bill the 20-seat minimum: 20 × 99 = 1,980', (tester) async {
      await _openInvoices(tester, code);
      final row = find.byKey(const Key('invoice-2026-09'));
      expect(
        find.descendant(of: row, matching: find.text(l.companyInvoiceMath(20, CompanyTerms.pricePerSeat, '1,980'))),
        findsOneWidget,
      );
    });

    testWidgets('[$code] the invoice screen shows reference, bank details and due date', (tester) async {
      await _openInvoices(tester, code);
      await tester.tap(find.byKey(const Key('invoice-2026-09')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company-invoice-screen')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('invoice-reference')), matching: find.text('GR-1-202609')),
          findsOneWidget);
      expect(find.text(CompanyTerms.bankDetails), findsOneWidget);
      expect(find.byKey(const Key('invoice-due')), findsOneWidget);
      expect(find.text(l.companyInvoiceMath(20, CompanyTerms.pricePerSeat, '1,980')), findsOneWidget);
    });

    testWidgets('[$code] an unpaid month waits, then shows paid after Goora marks it', (tester) async {
      final clock = TestClock(_now);
      final c = await _openInvoices(tester, code, clock: clock);
      expect(find.descendant(of: find.byKey(const Key('invoice-2026-09')), matching: find.text(l.companyInvoicePaid)),
          findsOneWidget);

      // Demo clock to 2 Nov: October is issued and waiting for payment.
      clock.now = at(CalendarDate(2026, 11, 2), 10, 0);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company-invoices')));
      await tester.pumpAndSettle();
      final october = find.byKey(const Key('invoice-2026-10'));
      expect(october, findsOneWidget);
      expect(find.descendant(of: october, matching: find.text(l.companyInvoiceWaiting)), findsOneWidget);

      c.read(routerProvider).go(Routes.settings);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('demo-mark-invoice-paid')));
      await tester.tap(find.byKey(const Key('demo-mark-invoice-paid')));
      await tester.pumpAndSettle();

      c.read(routerProvider).go(Routes.companyInvoices);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(const Key('invoice-2026-10')), matching: find.text(l.companyInvoicePaid)),
          findsOneWidget);
    });

    testWidgets('[$code] past the due date an unpaid invoice reads overdue and says when coverage pauses', (tester) async {
      // Seeded on 6 Oct (earlier months paid), then the demo clock moves on.
      final clock = TestClock(_now);
      final c = await _openInvoices(tester, code, clock: clock);
      clock.now = at(CalendarDate(2026, 11, 20), 10, 0);
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company-invoices')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invoice-2026-10')));
      await tester.pumpAndSettle();
      expect(find.text(l.companyInvoiceOverdue), findsOneWidget);
      expect(find.byKey(const Key('invoice-suspend-note')), findsOneWidget);
    });
  }
}
