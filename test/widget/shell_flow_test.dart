import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/locale_controller.dart';
import 'package:goora/core/widgets/goora_bottom_nav.dart';
import 'package:goora/features/onboarding/data/fake_auth_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// FR-001, FR-002: members land on the four-tab shell with Today selected.
void main() {
  final a = l10nFor(ar);
  final e = l10nFor(en);

  int selectedTab(WidgetTester tester) => tester.widget<GooraBottomNav>(find.byType(GooraBottomNav)).currentIndex;

  testWidgets('driver: Join this group → shell with Today selected', (tester) async {
    await pumpGooraApp(
      tester,
      prefs: memberPrefs(role: Role.driver, member: false),
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    expect(find.byType(GooraBottomNav), findsNothing, reason: 'not a member yet: commute setup');
    await tester.tap(find.byKey(const Key('find-commute')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('join-group')));
    await tester.pumpAndSettle();
    expect(find.byType(GooraBottomNav), findsOneWidget);
    expect(selectedTab(tester), 0);
    expect(find.text(a.goodMorning('Omar')), findsOneWidget);
  });

  testWidgets('rider: Join → plan screen → Start free month → shell', (tester) async {
    await pumpGooraApp(
      tester,
      prefs: memberPrefs(role: Role.rider, member: false),
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    await tester.tap(find.byKey(const Key('find-commute')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('join-group')));
    await tester.pumpAndSettle();
    expect(find.text(a.planTitle), findsWidgets);
    await tester.tap(find.byKey(const Key('plan-cta')));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
    expect(find.text(a.todaySub), findsOneWidget);
  });

  testWidgets('restart with a membership → shell, Today selected', (tester) async {
    await pumpGooraApp(
      tester,
      prefs: memberPrefs(role: Role.rider),
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    expect(find.byType(GooraBottomNav), findsOneWidget);
    expect(selectedTab(tester), 0);
  });

  testWidgets('returning member logs in by OTP → shell, Today selected', (tester) async {
    final prefs = memberPrefs(role: Role.rider)..remove('fake_auth.session');
    await pumpGooraApp(tester, prefs: prefs, overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))));
    expect(find.byType(GooraBottomNav), findsNothing, reason: 'signed out: welcome');
    await tester.tap(find.text(a.login));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '01012345678');
    await tester.pump();
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('otp-field')), FakeAuthRepository.testCode);
    await tester.pumpAndSettle();
    expect(find.byType(GooraBottomNav), findsOneWidget);
    expect(selectedTab(tester), 0);
    expect(find.text(a.todaySub), findsOneWidget);
  });

  testWidgets('tabs switch, and a language switch keeps the current tab', (tester) async {
    final c = await pumpGooraApp(
      tester,
      prefs: memberPrefs(role: Role.rider),
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    await tester.tap(find.text(a.tabWeek));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);
    expect(find.text(a.scheduleTitle), findsOneWidget);
    await tester.tap(find.text(a.tabWallet));
    await tester.pumpAndSettle();
    expect(find.text(a.walletSoon), findsOneWidget);

    await c.read(localeControllerProvider.notifier).set(LocaleController.english);
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);
    expect(find.text(e.walletSoon), findsOneWidget);
    expect(find.text(e.tabWallet), findsWidgets);
  });
}
