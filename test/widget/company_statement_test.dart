import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/company/company_flags.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/labels.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/presentation/labels.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T048 (US6; FR-024–FR-028, SC-008): the HR statement lists only the
/// employees who agreed, their paid rider shares, nothing else — and the
/// employee's switch on the Wallet's company card is off by default, says what
/// HR sees, and asks before it stops (already-issued statements stay) — ar + en.
final _now = at(rideTuesday, 10, 0);

Future<ProviderContainer> _asHr(
  WidgetTester tester,
  String locale, {
  TestClock? clock,
  String companyId = CompanySeed.valeoId,
  bool approve = false,
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(clock ?? TestClock(_now)),
  );
  tester.view.physicalSize = const Size(390, 9000);
  final repo = c.read(companyRepositoryProvider);
  if (approve) await repo.demoApprove(companyId, _now);
  await repo.demoSetHrContact(companyId, c.read(dailyCommuteRepositoryProvider).meId, _now);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _openStatement(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('company-statement')));
  await tester.pumpAndSettle();
}

/// The signed-in rider is enrolled at Valeo with the company plan running.
Future<ProviderContainer> _asEmployee(WidgetTester tester, String locale) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, withPlan: false),
    overrides: [
      ...dailyOverrides(TestClock(_now)),
      companyRepositoryProvider.overrideWith(
        (ref) => FakeCompanyRepository(
          ref.watch(sharedPreferencesProvider),
          person: (_) async => (name: 'Omar Khaled', workEmail: 'omar@valeo.com'),
          now: ref.watch(nowProvider),
        ),
      ),
    ],
  );
  tester.view.physicalSize = const Size(390, 2400);
  final meId = c.read(dailyCommuteRepositoryProvider).meId;
  await c.read(companyRepositoryProvider).enroll(meId, now: _now);
  await c.read(walletRepositoryProvider).startCompanyPlan(meId, _now);
  c.read(routerProvider).go(Routes.wallet);
  await tester.pumpAndSettle();
  return c;
}

Future<bool> _consent(ProviderContainer c) =>
    c.read(companyRepositoryProvider).hrConsent(c.read(dailyCommuteRepositoryProvider).meId);

bool _switchOn(WidgetTester tester) => tester.widget<Switch>(find.byKey(const Key('hr-share-toggle'))).value;

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    group('[$code] HR side', () {
      testWidgets('lists only the employees who agreed, with their paid rider shares', (tester) async {
        await _asHr(tester, code);
        await _openStatement(tester);
        expect(find.byKey(const Key('company-statement-screen')), findsOneWidget);
        // The newest closed month first: September (October is still running).
        expect(find.byKey(const Key('statement-month-2026-09')), findsOneWidget);
        expect(find.byKey(const Key('statement-month-2026-10')), findsNothing);
        expect(find.text(l.companyStatementNote), findsOneWidget);
        expect(find.text(l.companyStatementFee(l.egpAmount(0))), findsOneWidget);

        // Dina: 30 trips x 40. Hossam: 24 trips, 3 not on it (didn't pay, disputed, pending) = 21 x 40.
        expect(
          find.descendant(
            of: find.byKey(const Key('statement-Dina Samir')),
            matching: find.text(l.companyStatementPerson(30, '1,200')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('statement-Hossam Nabil')),
            matching: find.text(l.companyStatementPerson(21, '840')),
          ),
          findsOneWidget,
        );
        expect(find.text(l.companyStatementTotal('2,040')), findsOneWidget);

        // Nobody else, not even a name: Yasmin withdrew in September, Karim drives, Mona never agreed.
        for (final name in ['Yasmin Fouad', 'Karim Fawzy', 'Mona Adel', 'Sherif Lotfy']) {
          expect(find.text(name), findsNothing, reason: name);
        }
        expect(find.textContaining('@valeo.com'), findsNothing);
      });

      testWidgets('a line is date, leg and the share paid to the driver', (tester) async {
        await _asHr(tester, code);
        await _openStatement(tester);
        final first = find.byKey(const Key('statement-line-Dina Samir-0'));
        expect(first, findsOneWidget);
        expect(
          find.descendant(
            of: first,
            matching: find.text('${l.shortDateYear(CalendarDate(2026, 9, 1))} · ${l.legName(Leg.going)}'),
          ),
          findsOneWidget,
        );
        expect(find.descendant(of: first, matching: find.text(l.companyStatementShare('40'))), findsOneWidget);
        final second = find.byKey(const Key('statement-line-Dina Samir-1'));
        expect(find.descendant(of: second, matching: find.textContaining(l.legName(Leg.ret))), findsOneWidget);
        // 30 lines for Dina, 21 for Hossam.
        expect(find.byKey(const Key('statement-line-Dina Samir-29')), findsOneWidget);
        expect(find.byKey(const Key('statement-line-Dina Samir-30')), findsNothing);
        expect(find.byKey(const Key('statement-line-Hossam Nabil-20')), findsOneWidget);
        expect(find.byKey(const Key('statement-line-Hossam Nabil-21')), findsNothing);
      });

      testWidgets('an issued month does not change when someone withdrew later: August still has Yasmin', (
        tester,
      ) async {
        await _asHr(tester, code);
        await _openStatement(tester);
        expect(find.text('Yasmin Fouad'), findsNothing);
        await tester.tap(find.byKey(const Key('statement-month-2026-08')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('statement-Yasmin Fouad')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('statement-Yasmin Fouad')),
            matching: find.text(l.companyStatementPerson(20, '800')),
          ),
          findsOneWidget,
        );
        expect(find.text(l.companyStatementTotal('2,840')), findsOneWidget);
      });

      testWidgets('no export control while hrStatementExport is off (constitution VIII)', (tester) async {
        expect(CompanyFlags.hrStatementExport, isFalse);
        await _asHr(tester, code);
        await _openStatement(tester);
        expect(find.byKey(const Key('statement-export')), findsNothing);
      });

      testWidgets('a company with no closed month yet says when the first statement comes', (tester) async {
        await _asHr(tester, code, companyId: CompanySeed.orangeId, approve: true);
        await _openStatement(tester);
        expect(find.byKey(const Key('statement-no-months')), findsOneWidget);
        expect(find.text(l.companyStatementNoMonths), findsOneWidget);
      });

      testWidgets('a closed month where nobody agreed has its own empty state', (tester) async {
        final clock = TestClock(_now);
        final c = await _asHr(tester, code, companyId: CompanySeed.orangeId, clock: clock, approve: true);
        clock.now = at(CalendarDate(2026, 11, 2), 10, 0);
        c.read(routerProvider).go(Routes.settings);
        await tester.pumpAndSettle();
        c.read(routerProvider).go(Routes.company);
        await tester.pumpAndSettle();
        await _openStatement(tester);
        expect(find.byKey(const Key('statement-month-2026-10')), findsOneWidget);
        expect(find.byKey(const Key('statement-empty')), findsOneWidget);
        expect(find.text(l.companyStatementEmpty), findsOneWidget);
      });
    });

    group('[$code] employee side', () {
      testWidgets('the switch is off by default and says exactly what HR sees', (tester) async {
        final c = await _asEmployee(tester, code);
        expect(find.byKey(const Key('hr-share-toggle')), findsOneWidget);
        expect(_switchOn(tester), isFalse);
        expect(find.text(l.companyHrShareTitle), findsOneWidget);
        expect(find.text(l.companyHrShareSees), findsOneWidget);
        expect(find.text(l.companyHrShareOffLine), findsOneWidget);
        expect(await _consent(c), isFalse);
      });

      testWidgets('turning it on is saved and the line says when HR gets it', (tester) async {
        final c = await _asEmployee(tester, code);
        await tester.tap(find.byKey(const Key('hr-share-toggle')));
        await tester.pumpAndSettle();
        expect(_switchOn(tester), isTrue);
        expect(find.text(l.companyHrShareOnLine), findsOneWidget);
        expect(await _consent(c), isTrue);
      });

      testWidgets('turning it off asks first and says issued statements stay; "keep" leaves it on', (tester) async {
        final c = await _asEmployee(tester, code);
        await tester.tap(find.byKey(const Key('hr-share-toggle')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('hr-share-toggle')));
        await tester.pumpAndSettle();
        expect(find.text(l.companyHrShareStopTitle), findsOneWidget);
        expect(find.text(l.companyHrShareStopBody), findsOneWidget);
        await tester.tap(find.text(l.keepIt));
        await tester.pumpAndSettle();
        expect(await _consent(c), isTrue);
        expect(_switchOn(tester), isTrue);

        await tester.tap(find.byKey(const Key('hr-share-toggle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('hr-share-stop-confirm')));
        await tester.pumpAndSettle();
        expect(await _consent(c), isFalse);
        expect(_switchOn(tester), isFalse);
        expect(find.text(l.companyHrShareOffLine), findsOneWidget);
      });

      testWidgets('someone not enrolled has no switch', (tester) async {
        await pumpGooraApp(
          tester,
          prefs: memberPrefs(role: Role.rider, locale: code),
          overrides: dailyOverrides(TestClock(_now)),
        ).then((c) async {
          tester.view.physicalSize = const Size(390, 2400);
          c.read(routerProvider).go(Routes.wallet);
          await tester.pumpAndSettle();
        });
        expect(find.byKey(const Key('hr-share-toggle')), findsNothing);
      });
    });
  }
}
