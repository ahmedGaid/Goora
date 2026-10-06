import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/locale_controller.dart';
import 'package:goora/core/widgets/goora_bottom_nav.dart';
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

  testWidgets('rider: Join → plan placeholder → Continue → shell', (tester) async {
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
    await tester.tap(find.byKey(const Key('plan-continue')));
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
