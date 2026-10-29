import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T051 + P9 finding C2: every screen of the company area at 1.3× text
/// size still lays out (an overflow or clipped line throws in a widget test),
/// keeps 44 pt tap targets and labels every tappable thing (constitution VII,
/// FR-032), ar + en. Home in each state, register, roster, log, dashboard,
/// invoices, invoice, the HR statement, the consent sheet and the Wallet's
/// "share my trips with HR" switch.
final _now = at(rideTuesday, 10, 0);

/// The signed-in rider's work email is [email] (the company network asks the
/// profile; the daily fakes have none).
Override _workEmail(String email) => companyRepositoryProvider.overrideWith(
      (ref) => FakeCompanyRepository(
        ref.watch(sharedPreferencesProvider),
        person: (_) async => (name: 'Omar Khaled', workEmail: email),
        now: ref.watch(nowProvider),
      ),
    );

/// Opens [route] at 1.3× text. [hrOf] makes the signed-in rider that
/// company's HR contact; [email] gives them a work email; [enrolled] enrolls
/// them with the company plan running (needs [email] on a company domain).
Future<ProviderContainer> _open(
  WidgetTester tester,
  String locale,
  String route, {
  String? hrOf,
  String? email,
  bool enrolled = false,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale, withPlan: false),
    overrides: [...dailyOverrides(TestClock(_now)), if (email != null) _workEmail(email)],
  );
  tester.view.physicalSize = const Size(390, 2400);
  final me = c.read(dailyCommuteRepositoryProvider).meId;
  final company = c.read(companyRepositoryProvider);
  if (hrOf != null) await company.demoSetHrContact(hrOf, me, _now);
  if (enrolled) {
    await company.enroll(me, now: _now);
    await c.read(walletRepositoryProvider).startCompanyPlan(me, _now);
  }
  c.read(routerProvider).go(route);
  await tester.pumpAndSettle();
  return c;
}

/// No overflow, every target at least 44 x 44, every tappable thing labelled.
Future<void> _accessible(WidgetTester tester, String where) async {
  expect(tester.takeException(), isNull, reason: '$where overflowed at 1.3x');
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline), reason: where);
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: where);
  handle.dispose();
}

void main() {
  for (final locale in locales) {
    final code = locale.languageCode;

    group('[$code] company screens at 1.3x text', () {
      testWidgets('home: HR contact of an active company', (tester) async {
        await _open(tester, code, Routes.company, hrOf: CompanySeed.valeoId);
        expect(find.byKey(const Key('company-home')), findsOneWidget);
        await _accessible(tester, 'HR home');
      });

      testWidgets('home: HR contact of a company waiting for Goora', (tester) async {
        await _open(tester, code, Routes.company, hrOf: CompanySeed.orangeId);
        expect(find.byKey(const Key('company-home')), findsOneWidget);
        await _accessible(tester, 'pending home');
      });

      testWidgets('home: an employee who can join, and the register card', (tester) async {
        await _open(tester, code, Routes.company, email: 'omar@valeo.com');
        expect(find.byKey(const Key('company-join')), findsOneWidget);
        expect(find.byKey(const Key('company-register')), findsOneWidget);
        await _accessible(tester, 'employee home, can join');
      });

      testWidgets('home: company not on Goora yet', (tester) async {
        await _open(tester, code, Routes.company, email: 'omar@acme.com');
        expect(find.byKey(const Key('company-not-on-goora')), findsOneWidget);
        await _accessible(tester, 'employee home, not on Goora');
      });

      testWidgets('home: an enrolled employee', (tester) async {
        await _open(tester, code, Routes.company, email: 'omar@valeo.com', enrolled: true);
        expect(find.byKey(const Key('company-enrolled')), findsOneWidget);
        await _accessible(tester, 'employee home, enrolled');
      });

      testWidgets('consent sheet', (tester) async {
        await _open(tester, code, Routes.company, email: 'omar@valeo.com');
        await tester.tap(find.byKey(const Key('company-join')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('consent-agree')), findsOneWidget);
        await _accessible(tester, 'consent sheet');
      });

      testWidgets('register a company', (tester) async {
        await _open(tester, code, Routes.companyRegister, email: 'omar@acme.com');
        expect(find.byKey(const Key('company-register-screen')), findsOneWidget);
        await _accessible(tester, 'register');
      });

      testWidgets('roster', (tester) async {
        await _open(tester, code, Routes.companyRoster, hrOf: CompanySeed.valeoId);
        expect(find.byKey(const Key('company-roster-screen')), findsOneWidget);
        await _accessible(tester, 'roster');
      });

      testWidgets('log', (tester) async {
        await _open(tester, code, Routes.companyLog, hrOf: CompanySeed.valeoId);
        expect(find.byKey(const Key('company-log-screen')), findsOneWidget);
        await _accessible(tester, 'log');
      });

      testWidgets('dashboard', (tester) async {
        await _open(tester, code, Routes.companyDashboard, hrOf: CompanySeed.valeoId);
        expect(find.byKey(const Key('company-dashboard-screen')), findsOneWidget);
        expect(find.byKey(const Key('dash-saved-value')), findsOneWidget);
        await _accessible(tester, 'dashboard');
      });

      testWidgets('invoice list and invoice', (tester) async {
        await _open(tester, code, Routes.companyInvoices, hrOf: CompanySeed.valeoId);
        expect(find.byKey(const Key('company-invoices-screen')), findsOneWidget);
        await _accessible(tester, 'invoice list');
        await tester.tap(find.byKey(const Key('invoice-2026-09')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('company-invoice-screen')), findsOneWidget);
        await _accessible(tester, 'invoice');
      });

      testWidgets('HR statement', (tester) async {
        await _open(tester, code, Routes.companyStatement, hrOf: CompanySeed.valeoId);
        expect(find.byKey(const Key('company-statement-screen')), findsOneWidget);
        await _accessible(tester, 'statement');
      });

      testWidgets('Wallet: the "share my trips with HR" switch', (tester) async {
        await _open(tester, code, Routes.wallet, email: 'omar@valeo.com', enrolled: true);
        expect(find.byKey(const Key('hr-share-toggle')), findsOneWidget);
        await _accessible(tester, 'wallet company card');
      });
    });
  }
}
