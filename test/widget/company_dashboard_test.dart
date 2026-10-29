import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/format/grouped_number.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_dashboard.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T044 (US5 AC1–AC3; FR-021–FR-023): the HR contact's dashboard shows
/// totals for the chosen month, each estimate with its method, "Fewer than
/// 5" where a number could point at a person, no individual anywhere, and a
/// month picker (current so far + closed months) — ar + en.
final _now = at(rideTuesday, 10, 0);

Future<ProviderContainer> _asHr(WidgetTester tester, String locale, {required String companyId}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(TestClock(_now)),
  );
  tester.view.physicalSize = const Size(390, 4200);
  final repo = c.read(companyRepositoryProvider);
  if (companyId == CompanySeed.orangeId) await repo.demoApprove(companyId, _now);
  await repo.demoSetHrContact(companyId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('company-dashboard')));
  await tester.pumpAndSettle();
  return c;
}

String _value(WidgetTester tester, String id) => (tester.widget(find.byKey(Key('dash-$id-value'))) as Text).data!;

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] shows the month totals in words with the method lines', (tester) async {
      await _asHr(tester, code, companyId: CompanySeed.valeoId);
      expect(find.byKey(const Key('company-dashboard-screen')), findsOneWidget);
      // The first month is the running one, labelled "so far".
      expect(find.text(l.companyDashboardSoFar('10/2026')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dashboard-month-2026-09')));
      await tester.pumpAndSettle();
      expect(_value(tester, 'enrolled'), '12');
      expect(_value(tester, 'active'), '8');
      expect(_value(tester, 'carpool'), l.companyDashboardPercent(67));
      expect(_value(tester, 'groups'), '2');
      expect(_value(tester, 'trips'), '76');
      // N-13: thousands get a comma, Western digits in both languages.
      expect(_value(tester, 'saved'), code == 'ar' ? '15,840 ج' : '15,840 EGP');
      final kg = (132 * CompanySeed.legKm * CompanyDashboardTerms.co2KgPerKm).round();
      expect(_value(tester, 'co2'), code == 'ar' ? '${groupedInt(kg)} كجم' : '${groupedInt(kg)} kg');
      expect(_value(tester, 'parking'), '${66 ~/ CompanyDashboard.workdaysIn('2026-09')}');
      expect(find.text(l.companyDashboardSavedMethod), findsOneWidget);
      expect(find.text(l.companyDashboardCo2Method), findsOneWidget);
      expect(find.text(l.companyDashboardParkingMethod), findsOneWidget);
      expect(find.byKey(const Key('dash-fewer-note')), findsNothing);
    });

    testWidgets('[$code] the picker lists the running month and every closed month since the start', (tester) async {
      await _asHr(tester, code, companyId: CompanySeed.valeoId);
      for (final m in ['2026-10', '2026-09', '2026-08']) {
        expect(find.byKey(Key('dashboard-month-$m')), findsOneWidget);
      }
      expect(find.byKey(const Key('dashboard-month-2026-07')), findsNothing);
    });

    testWidgets('[$code] a route-gap area with fewer than 5 waiting is not listed', (tester) async {
      await _asHr(tester, code, companyId: CompanySeed.valeoId);
      expect(find.text(l.companyDashboardGapsEmpty), findsOneWidget);
      expect(find.byKey(const Key('dash-gap-october')), findsNothing);
    });

    testWidgets('[$code] no name, email or person appears on the dashboard', (tester) async {
      await _asHr(tester, code, companyId: CompanySeed.valeoId);
      final shown = [
        for (final t in find.byType(Text).evaluate().map((e) => e.widget as Text))
          if (t.data != null) t.data!,
      ].join('|');
      for (final p in ['Mona', 'Karim', 'Dina', 'Hossam', 'Bassem', '@valeo.com', 'valeo-0']) {
        expect(shown.contains(p), isFalse, reason: p);
      }
    });

    testWidgets('[$code] figures built from fewer than 5 employees say so instead of a number', (tester) async {
      await _asHr(tester, code, companyId: CompanySeed.orangeId);
      for (final id in ['enrolled', 'active', 'carpool', 'groups', 'trips', 'saved', 'co2', 'parking']) {
        expect(_value(tester, id), l.companyDashboardFewer, reason: id);
      }
      expect(find.byKey(const Key('dash-fewer-note')), findsOneWidget);
      expect(find.text(l.companyDashboardFewerNote), findsOneWidget);
    });
  }
}
