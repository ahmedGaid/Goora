import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/l10n/app_localizations.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company.dart';
import 'package:goora/features/company/domain/company_terms.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/presentation/labels.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T022 (US1): a company signs up from Settings → Company account, waits
/// for Goora, and shows its minimum and price once approved — ar + en.
Future<ProviderContainer> _openCompany(WidgetTester tester, String locale) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(TestClock(at(rideTuesday, 10, 0))),
  );
  tester.view.physicalSize = const Size(390, 2400);
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
  return c;
}

Future<void> _fillForm(WidgetTester tester, {required String name, required String email}) async {
  await tester.tap(find.byKey(const Key('company-register')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('company-name')), name);
  await tester.enterText(find.byKey(const Key('company-email')), email);
  await tester.tap(find.byKey(const Key('company-send-code')));
  await tester.pumpAndSettle();
}

Future<void> _register(WidgetTester tester, AppLocalizations l, {String code = '123456'}) async {
  await _fillForm(tester, name: 'Acme Egypt', email: 'hr@acme.com');
  expect(find.text(l.companyCodeSent('hr@acme.com')), findsOneWidget);
  await tester.enterText(find.byKey(const Key('company-code')), code);
  await tester.tap(find.byKey(const Key('company-submit')));
  await tester.pumpAndSettle();
}

Future<void> _demo(WidgetTester tester, ProviderContainer c, String key) async {
  c.read(routerProvider).push(Routes.settings);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  c.read(routerProvider).go(Routes.company);
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] Settings has a Company account row that opens the company area', (tester) async {
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 10, 0))),
      );
      tester.view.physicalSize = const Size(390, 2400);
      c.read(routerProvider).push(Routes.settings);
      await tester.pumpAndSettle();
      expect(find.text(l.companyAccountTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings-company')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company-home')), findsOneWidget);
      expect(find.text(l.companyRegisterIntro), findsOneWidget);
    });

    testWidgets('[$code] AC2: a public mail domain is refused with a reason, no code sent', (tester) async {
      await _openCompany(tester, code);
      await _fillForm(tester, name: 'Acme Egypt', email: 'hr@gmail.com');
      expect(find.text(l.companyPublicDomain('gmail.com')), findsOneWidget);
      expect(find.byKey(const Key('company-code')), findsNothing);
    });

    testWidgets("[$code] AC3: a domain another company holds is refused", (tester) async {
      await _openCompany(tester, code);
      await _fillForm(tester, name: 'Acme Egypt', email: 'someone@valeo.com');
      expect(find.text(l.companyDomainTaken('valeo.com')), findsOneWidget);
      expect(find.byKey(const Key('company-code')), findsNothing);
    });

    testWidgets('[$code] a short name and a bad email are caught before anything is sent', (tester) async {
      await _openCompany(tester, code);
      await _fillForm(tester, name: 'A', email: 'not-an-email');
      expect(find.text(l.companyNameError), findsOneWidget);
      expect(find.text(l.companyEmailInvalid), findsOneWidget);
    });

    testWidgets('[$code] a wrong code keeps the request unsent', (tester) async {
      final c = await _openCompany(tester, code);
      await _register(tester, l, code: '000000');
      expect(find.text(l.otpWrong), findsOneWidget);
      expect(await c.read(companyRepositoryProvider).companyForDomain('acme.com'), isNull);
    });

    testWidgets('[$code] AC1: registered → pending, I am its HR contact, "waiting for Goora"', (tester) async {
      final c = await _openCompany(tester, code);
      await _register(tester, l);
      expect(find.byKey(const Key('company-home')), findsOneWidget);
      expect(find.text(l.companyStatusPending), findsOneWidget);
      expect(find.text(l.companyPendingBody('Acme Egypt')), findsOneWidget);
      expect(find.text(l.companyDomainsLine('acme.com')), findsOneWidget);
      final acme = (await c.read(companyRepositoryProvider).companyForDomain('acme.com'))!;
      expect(acme.status, CompanyStatus.pending);
      expect(acme.hrContactId, c.read(dailyCommuteRepositoryProvider).meId);
      expect(find.byKey(const Key('company-register')), findsNothing, reason: 'one company per HR contact');
    });

    testWidgets('[$code] AC4: Goora approves (demo) → active, with minimum seats and price', (tester) async {
      final c = await _openCompany(tester, code);
      await _register(tester, l);
      await _demo(tester, c, 'demo-approve-company');
      expect(find.text(l.companyStatusActive), findsOneWidget);
      expect(find.text(l.companyMinSeats(CompanyTerms.minimumSeats)), findsOneWidget);
      expect(find.text(l.companyPriceLine(CompanyTerms.pricePerSeat)), findsOneWidget);
      expect(find.byKey(const Key('company-contract')), findsOneWidget);
      expect(find.text(l.companyHomeNote), findsOneWidget);
    });

    testWidgets('[$code] F-1: the contract line carries the year, so 12 months never reads 21/10 to 21/10',
        (tester) async {
      final c = await _openCompany(tester, code);
      await _register(tester, l);
      await _demo(tester, c, 'demo-approve-company');
      final acme = (await c.read(companyRepositoryProvider).companyForDomain('acme.com'))!;
      final start = acme.contractStart!;
      final end = acme.contractEnd!;
      expect(l.shortDateYear(start), isNot(l.shortDateYear(end)));
      expect(find.text(l.companyContractLine(l.shortDateYear(start), l.shortDateYear(end))), findsOneWidget);
    });

    testWidgets("[$code] demo: Make me Valeo's HR contact → Valeo's home", (tester) async {
      final c = await _openCompany(tester, code);
      await _demo(tester, c, 'demo-make-me-hr');
      expect(find.text(l.companyStatusActive), findsOneWidget);
      expect(find.text(l.companyDomainsLine('valeo.com')), findsOneWidget);
      final valeo = (await c.read(companyRepositoryProvider).companyForDomain('valeo.com'))!;
      expect(valeo.id, CompanySeed.valeoId);
      expect(valeo.hrContactId, c.read(dailyCommuteRepositoryProvider).meId);
    });
  }
}
