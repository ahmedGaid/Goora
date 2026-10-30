import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/features/commute/data/providers.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/presentation/welcome_screen.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 010 T021: Settings → Reset demo data starts the company network over —
/// every `company.*` key goes (companies, enrollments, invoices, log, the
/// paused personal plans), and the next read re-seeds.
void main() {
  testWidgets('Reset demo data clears every company.* key', (tester) async {
    final c = await pumpGooraApp(
      tester,
      prefs: {
        ...memberPrefs(role: Role.rider, locale: 'en'),
        FakeWalletRepository.pausedKey('me'): '{"daysLeft":10}',
      },
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    // Seed the company network (first read writes its keys).
    await tester.runAsync(() => c.read(companyRepositoryProvider).companyForDomain('valeo.com'));
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getKeys().where((k) => k.startsWith(FakeCompanyRepository.keyPrefix)), isNotEmpty);

    tester.view.physicalSize = const Size(390, 2400);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('demo-reset')));
    await tester.tap(find.byKey(const Key('demo-reset')));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(prefs.getKeys().where((k) => k.startsWith(FakeCompanyRepository.keyPrefix)), isEmpty);
  });

  // Walk 6 F-W4: Reset wiped sign-in and the company but kept the demo clock, so a
  // company registered after it got a contract starting on the old jumped date.
  testWidgets('F-W4: Reset demo data also puts the demo clock back to real time', (tester) async {
    final jumped = at(rideTuesday.addDays(49), 10, 4);
    final c = await pumpGooraApp(
      tester,
      prefs: {
        ...memberPrefs(role: Role.rider, locale: 'en'),
        DemoClock.storageKey: jsonEncode({'at': jumped.toJson(), 'setAt': 0}),
      },
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    final prefs = c.read(sharedPreferencesProvider);
    expect(DemoClock.read(prefs)?.at, jumped, reason: 'the clock starts jumped');

    tester.view.physicalSize = const Size(390, 2400);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('demo-reset')));
    await tester.tap(find.byKey(const Key('demo-reset')));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(prefs.containsKey(DemoClock.storageKey), isFalse, reason: 'real time again');
    expect(DemoClock.read(prefs), isNull);
  });

  testWidgets('Demo corridor switch flips the active corridor; cycles through the corridors', (tester) async {
    final c = await pumpGooraApp(
      tester,
      prefs: memberPrefs(role: Role.rider, locale: 'en'),
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    final first = c.read(activeCorridorProvider).id;
    tester.view.physicalSize = const Size(390, 2400);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('demo-corridor')));
    await tester.tap(find.byKey(const Key('demo-corridor')));
    await tester.pumpAndSettle();
    expect(c.read(activeCorridorProvider).id, isNot(first));
    await tester.ensureVisible(find.byKey(const Key('demo-corridor')));
    await tester.tap(find.byKey(const Key('demo-corridor')));
    await tester.pumpAndSettle();
    expect(c.read(activeCorridorProvider).id, first);
  });
}
