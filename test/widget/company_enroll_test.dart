import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/config/env.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/company/data/company_seed.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/company/domain/company_repository.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/daily/presentation/today/today_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/plan.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T023 (US2): an employee joins through their company from the Plan
/// screen — offer states, consent (sees / never sees), decline, agree, the
/// Wallet's company card and its paused personal plan — ar + en.
final _now = at(rideTuesday, 10, 0);

/// A monthly plan paid until 10 days from [_now].
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

/// Overrides the company network's person lookup: the signed-in rider's
/// work email is [email].
Override _workEmail(String email) => companyRepositoryProvider.overrideWith(
      (ref) => FakeCompanyRepository(
        ref.watch(sharedPreferencesProvider),
        person: (_) async => (name: 'Omar Khaled', workEmail: email),
        now: ref.watch(nowProvider),
      ),
    );

Future<ProviderContainer> _openPlan(
  WidgetTester tester,
  String locale, {
  Map<String, Object> extra = const {},
  List<Override> overrides = const [],
  RecordingSharer? sharer,
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.rider, locale: locale, withPlan: false), ...extra},
    overrides: [...dailyOverrides(TestClock(_now), sharer: sharer), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 2400);
  c.read(routerProvider).go(Routes.plan);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('plan-company')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('plan-cta')));
  await tester.pumpAndSettle();
  return c;
}

Future<EnrollOffer> _offer(ProviderContainer c) =>
    c.read(companyRepositoryProvider).offerFor(c.read(dailyCommuteRepositoryProvider).meId, _now);

Future<Plan?> _plan(ProviderContainer c) =>
    c.read(walletRepositoryProvider).getPlan(c.read(dailyCommuteRepositoryProvider).meId);

List<NoticeKind> _noticeKinds(ProviderContainer c) {
  final raw = c.read(sharedPreferencesProvider).getString(FakeDailyCommuteRepository.noticesKey);
  if (raw == null) return const [];
  return [for (final j in jsonDecode(raw) as List) Notice.fromJson((j as Map).cast<String, Object?>()).kind];
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC4: no company on my domain → "not on Goora yet", Tell HR shares, no plan', (tester) async {
      final sharer = RecordingSharer();
      final c = await _openPlan(tester, code, overrides: [_workEmail('omar@acme.com')], sharer: sharer);
      expect(find.text(l.companyNotOnGoora), findsOneWidget);
      expect(find.text(l.companyNotOnGooraBody), findsOneWidget);
      expect(find.byKey(const Key('consent-agree')), findsNothing);
      await tester.tap(find.byKey(const Key('company-tell-hr')));
      await tester.pumpAndSettle();
      expect(sharer.shared, [l.companyShareText(Env.shareBaseUrl)]);
      expect(await _plan(c), isNull);
    });

    testWidgets('[$code] US1 AC5: a pending company reads "not on Goora yet" too', (tester) async {
      final c = await _openPlan(tester, code, overrides: [_workEmail('omar@orange.com')]);
      expect(find.text(l.companyNotOnGoora), findsOneWidget);
      expect(find.byKey(const Key('company-tell-hr')), findsOneWidget);
      expect(await _offer(c), isA<PendingCompany>());
      expect(await _plan(c), isNull);
    });

    testWidgets('[$code] no verified work email → verify in Trust first', (tester) async {
      await _openPlan(tester, code, overrides: [
        companyRepositoryProvider.overrideWith(
          (ref) => FakeCompanyRepository(
            ref.watch(sharedPreferencesProvider),
            person: (_) async => (name: 'Omar Khaled', workEmail: null),
            now: ref.watch(nowProvider),
          ),
        ),
      ]);
      expect(find.text(l.verifyNotVerified), findsOneWidget);
      expect(find.byKey(const Key('company-join')), findsNothing);
    });

    testWidgets('[$code] the consent step lists what Valeo sees and never sees', (tester) async {
      await _openPlan(tester, code);
      expect(find.text(l.companyCanEnrollLine('Valeo')), findsOneWidget);
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      expect(find.text(l.consentTitle('Valeo')), findsOneWidget);
      for (final line in [
        l.consentSeesTitle,
        l.consentSeesName,
        l.consentSeesEmail,
        l.consentSeesSince,
        l.consentNeverTitle,
        l.consentNeverTrips,
        l.consentNeverPlace,
        l.consentNeverWho,
        l.consentNeverMoney,
        l.consentFeeLine,
      ]) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      expect(find.byKey(const Key('consent-paused')), findsNothing, reason: 'no personal plan to pause');
    });

    testWidgets('[$code] AC2: decline enrolls nothing and Valeo sees nothing', (tester) async {
      final c = await _openPlan(tester, code);
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-decline')));
      await tester.pumpAndSettle();
      expect(await _offer(c), isA<CanEnroll>());
      expect(await _plan(c), isNull);
      final roster = await c.read(companyRepositoryProvider).roster(CompanySeed.valeoId, _now);
      expect(roster.map((r) => r.workEmail), isNot(contains('omar@valeo.com')));
    });

    testWidgets('[$code] AC1: agree → enrolled, plan reads "Company · Valeo", started notice', (tester) async {
      final c = await _openPlan(tester, code);
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();
      expect(await _offer(c), isA<Enrolled>());
      final plan = (await _plan(c))!;
      expect(plan.type, PlanType.company);
      expect(plan.coversTrip(_now.plusMinutes(1)), isTrue);
      expect(_noticeKinds(c), contains(NoticeKind.companyPlanStarted));
      expect(find.byType(TodayScreen), findsOneWidget, reason: 'joined: the Plan screen moves on to Today');

      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      expect(find.text(l.planCompanyOf('Valeo')), findsOneWidget);
      expect(find.byKey(const Key('company-leave')), findsOneWidget);
    });

    testWidgets('[$code] AC6: a monthly plan with 10 days left pauses, shown on consent and Wallet', (tester) async {
      final c = await _openPlan(tester, code, extra: _monthly10());
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      expect(find.text(l.consentPausedLine(10)), findsOneWidget);
      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      expect((await c.read(walletRepositoryProvider).pausedPlan(meId))!.daysLeft, 10);

      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      expect(find.text(l.planCompanyPaused(10)), findsOneWidget);
    });

    testWidgets('[$code] Leave (confirmed) ends the company plan and brings the monthly one back', (tester) async {
      final c = await _openPlan(tester, code, extra: _monthly10());
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('company-leave')));
      await tester.pumpAndSettle();
      expect(find.text(l.companyLeaveTitle('Valeo')), findsOneWidget);
      await tester.tap(find.text(l.keepIt));
      await tester.pumpAndSettle();
      expect(await _offer(c), isA<Enrolled>(), reason: 'cancel keeps the plan');

      await tester.tap(find.byKey(const Key('company-leave')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('company-leave-confirm')));
      await tester.pumpAndSettle();
      expect(await _offer(c), isA<CanEnroll>());
      final plan = (await _plan(c))!;
      expect(plan.type, PlanType.monthly);
      expect(plan.untilDate, rideTuesday.addDays(10));
      expect(_noticeKinds(c), containsAll([NoticeKind.companyPlanEnded, NoticeKind.personalPlanBack]));
      expect(find.text(l.planCompanyOf('Valeo')), findsNothing);
    });

    testWidgets('[$code] already enrolled → the sheet says since when', (tester) async {
      final c = await _openPlan(tester, code);
      await tester.tap(find.byKey(const Key('company-join')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('consent-agree')));
      await tester.pumpAndSettle();
      c.read(routerProvider).go(Routes.company);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('company-enrolled')), findsOneWidget);
    });
  }
}
