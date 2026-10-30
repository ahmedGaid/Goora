import 'dart:convert';

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
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/presentation/wallet/wallet_controller.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// Walk 6 F-W1 (and walk 4 N-1): the Wallet's change-plan sheet had a second
/// door to "Through my company" that put the rider on the company plan at
/// once. It must go the same way as Settings → Company account: verify the
/// work email → offer → consent sheet → enroll. Declining changes nothing, and
/// a paid Monthly is paused (not replaced), exactly as the Plan screen does.
final _now = at(rideTuesday, 10, 0);

/// A paid Monthly with 10 days left.
Map<String, Object> _monthly10() => {
      FakeWalletRepository.planKey: jsonEncode(
        Plan(
          personId: DailySeed.meId,
          type: PlanType.monthly,
          status: PlanStatus.active,
          price: 149,
          startDate: at(rideTuesday.addDays(-20), 9, 0),
          untilDate: rideTuesday.addDays(10),
        ).toJson(),
      ),
    };

Override _workEmail(String? email) => companyRepositoryProvider.overrideWith(
      (ref) => FakeCompanyRepository(
        ref.watch(sharedPreferencesProvider),
        person: (_) async => (name: 'Omar Khaled', workEmail: email),
        now: ref.watch(nowProvider),
      ),
    );

/// Wallet → Change → "Through my company" → the sheet's button.
Future<ProviderContainer> _chooseCompany(
  WidgetTester tester,
  String locale, {
  List<Override> overrides = const [],
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.rider, locale: locale, withPlan: false), ..._monthly10()},
    overrides: [...dailyOverrides(TestClock(_now)), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 2600);
  c.read(routerProvider).go(Routes.wallet);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('plan-change')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('change-plan-company')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('change-plan-confirm')));
  await tester.pumpAndSettle();
  return c;
}

String get _meId => DailySeed.meId;

Future<Plan?> _plan(ProviderContainer c) => c.read(walletRepositoryProvider).getPlan(_meId);

Future<EnrollOffer> _offer(ProviderContainer c) => c.read(companyRepositoryProvider).offerFor(_meId, _now);

List<NoticeKind> _noticeKinds(ProviderContainer c) {
  final raw = c.read(sharedPreferencesProvider).getString(FakeDailyCommuteRepository.noticesKey);
  if (raw == null) return const [];
  return [for (final j in jsonDecode(raw) as List) Notice.fromJson((j as Map).cast<String, Object?>()).kind];
}

void main() {
  testWidgets('the wallet controller refuses to make the company plan without consent', (tester) async {
    final c = await pumpGooraApp(
      tester,
      prefs: {...memberPrefs(role: Role.rider, locale: 'en', withPlan: false), ..._monthly10()},
      overrides: dailyOverrides(TestClock(_now)),
    );
    c.read(routerProvider).go(Routes.wallet);
    await tester.pumpAndSettle();
    expect(() => c.read(walletControllerProvider.notifier).changePlan(PlanType.company), throwsAssertionError);
    expect((await _plan(c))!.type, PlanType.monthly);
  });

  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] F-W1: "Through my company" opens the consent sheet and changes nothing yet', (tester) async {
      final c = await _chooseCompany(tester, code);
      expect(find.byKey(const Key('company-join')), findsOneWidget, reason: 'the offer comes first');
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      expect(find.text(l.consentTitle('Valeo')), findsOneWidget, reason: 'consent sheet');
      expect(find.text(l.consentPausedLine(10)), findsOneWidget, reason: 'the paid Monthly is named as paused');

      final plan = (await _plan(c))!;
      expect(plan.type, PlanType.monthly, reason: 'nothing changes before the person agrees');
      expect(await _offer(c), isA<CanEnroll>());
    });

    testWidgets('[$code] F-W1: decline keeps the Monthly plan, enrolls nobody, posts nothing', (tester) async {
      final c = await _chooseCompany(tester, code);
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-decline')));
      await tester.pumpAndSettle();

      final plan = (await _plan(c))!;
      expect(plan.type, PlanType.monthly);
      expect(plan.untilDate, rideTuesday.addDays(10));
      expect(await c.read(walletRepositoryProvider).pausedPlan(_meId), isNull);
      expect(await _offer(c), isA<CanEnroll>());
      final roster = await c.read(companyRepositoryProvider).roster(CompanySeed.valeoId, _now);
      expect(roster.map((r) => r.workEmail), isNot(contains('omar@valeo.com')));
      expect(_noticeKinds(c), isNot(contains(NoticeKind.companyPlanStarted)));
    });

    testWidgets('[$code] F-W1: agree enrolls, starts the company plan and pauses the Monthly', (tester) async {
      final c = await _chooseCompany(tester, code);
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();

      expect(await _offer(c), isA<Enrolled>());
      expect((await _plan(c))!.type, PlanType.company);
      final paused = (await c.read(walletRepositoryProvider).pausedPlan(_meId))!;
      expect(paused.type, PlanType.monthly);
      expect(paused.daysLeft, 10, reason: 'paused, not replaced: the paid days wait');
      expect(_noticeKinds(c), contains(NoticeKind.companyPlanStarted));
      expect(find.byKey(const Key('change-plan-confirm')), findsNothing, reason: 'both sheets closed after joining');
      expect(find.text(l.planCompanyOf('Valeo')), findsOneWidget, reason: 'the Wallet shows the company card');
      expect(find.text(l.planCompanyPaused(10)), findsOneWidget);
    });

    testWidgets('[$code] F-W1: a company that is not on Goora leaves the Monthly alone', (tester) async {
      final c = await _chooseCompany(tester, code, overrides: [_workEmail('omar@acme.com')]);
      expect(find.text(l.companyNotOnGoora), findsOneWidget);
      expect(find.byKey(const Key('consent-agree')), findsNothing);
      expect((await _plan(c))!.type, PlanType.monthly);
    });

    testWidgets('[$code] F-W1: no verified work email leaves the Monthly alone', (tester) async {
      final c = await _chooseCompany(tester, code, overrides: [_workEmail(null)]);
      expect(find.text(l.verifyNotVerified), findsOneWidget);
      expect((await _plan(c))!.type, PlanType.monthly);
    });

    testWidgets('[$code] the sheet says what the company button does, and the Monthly button still changes at once',
        (tester) async {
      final c = await pumpGooraApp(
        tester,
        prefs: {...memberPrefs(role: Role.rider, locale: code, withPlan: false), ..._monthly10()},
        overrides: dailyOverrides(TestClock(_now)),
      );
      tester.view.physicalSize = const Size(390, 2600);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-change')));
      await tester.pumpAndSettle();
      expect(find.text(l.changePlanNote), findsOneWidget);
      expect(find.text(l.changePlanConfirm), findsOneWidget);

      await tester.tap(find.byKey(const Key('change-plan-company')));
      await tester.pumpAndSettle();
      expect(find.text(l.changePlanCompanyNote), findsOneWidget, reason: 'not "takes effect next billing date"');
      expect(find.text(l.changePlanNote), findsNothing);
      expect(find.text(l.planCtaVerify), findsOneWidget);
      expect(find.text(l.changePlanConfirm), findsNothing);

      await tester.tap(find.byKey(const Key('change-plan-yearly')));
      await tester.pumpAndSettle();
      expect(find.text(l.changePlanNote), findsOneWidget);
      expect(find.text(l.changePlanConfirm), findsOneWidget);
    });

    testWidgets('[$code] the sheet fits at 1.3× text on a small phone, company note shown', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await pumpGooraApp(
        tester,
        prefs: {...memberPrefs(role: Role.rider, locale: code, withPlan: false), ..._monthly10()},
        overrides: dailyOverrides(TestClock(_now)),
      );
      tester.view.physicalSize = const Size(360, 700);
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-change')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('change-plan-company')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no overflow at 1.3x');
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
