import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/widgets/goora_bottom_nav.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/core/widgets/goora_primary_button.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US6 on the Trust tab (FR-023 – FR-027, FR-036), ar + en.
Future<ProviderContainer> _openTrust(WidgetTester tester, Role role, String locale, {Gender gender = Gender.male}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: role, locale: locale, gender: gender),
    overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
  );
  tester.view.physicalSize = const Size(390, 2600);
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10nFor(Locale(locale)).tabTrust));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    Finder check(String kind, String status) =>
        find.descendant(of: find.byKey(Key('check-$kind')), matching: find.text(status));

    testWidgets('[$code] rider: profile, checklist with "Not needed", 96 % and this month\'s caption', (tester) async {
      await _openTrust(tester, Role.rider, code);
      expect(find.text('Omar'), findsOneWidget);
      expect(find.text(l.verifiedMemberRating('4.9')), findsOneWidget);
      for (final k in ['phone', 'nationalId', 'workEmail']) {
        expect(check(k, l.verified), findsOneWidget, reason: k);
      }
      expect(check('license', l.notNeeded), findsOneWidget);
      expect(check('vehicle', l.notNeeded), findsOneWidget);
      expect(find.text(l.reliability), findsOneWidget);
      expect(find.text(l.percentValue(96)), findsOneWidget, reason: '13.5 kept of 14 booked');
      expect(find.text(l.relLateCancels(1)), findsOneWidget);
      expect(find.text(l.relRule), findsOneWidget);
      expect(find.text(l.toDriver), findsOneWidget);
    });

    testWidgets('[$code] driver: all five verified', (tester) async {
      await _openTrust(tester, Role.driver, code);
      for (final k in ['phone', 'nationalId', 'workEmail', 'license', 'vehicle']) {
        expect(check(k, l.verified), findsOneWidget, reason: k);
      }
      expect(find.text(l.toRider), findsOneWidget);
    });

    testWidgets('[$code] privacy: Women only only for women; compound needs a compound; choice persists',
        (tester) async {
      final c = await _openTrust(tester, Role.rider, code);
      expect(find.byKey(const Key('privacy-womenOnly')), findsNothing, reason: 'a man');
      expect(tester.widget<GooraPill>(find.byKey(const Key('privacy-verifiedUsers'))).selected, isTrue);
      expect(tester.widget<GooraPill>(find.byKey(const Key('privacy-sameCompound'))).onTap, isNull);
      expect(find.text(l.needCompound), findsOneWidget);
      expect(find.text(l.privacyNote), findsOneWidget);

      await tester.tap(find.byKey(const Key('privacy-sameCompany')));
      await tester.pumpAndSettle();
      expect(tester.widget<GooraPill>(find.byKey(const Key('privacy-sameCompany'))).selected, isTrue);
      expect(c.read(sharedPreferencesProvider).getString(FakeTrustRepository.privacyKey), 'sameCompany');
    });

    testWidgets('[$code] a woman sees Women only', (tester) async {
      await _openTrust(tester, Role.rider, code, gender: Gender.female);
      expect(find.byKey(const Key('privacy-womenOnly')), findsOneWidget);
    });

    testWidgets('[$code] rider → driver: setup in driver mode, matching waits for license and vehicle',
        (tester) async {
      final c = await _openTrust(tester, Role.rider, code);
      await tester.tap(find.byKey(const Key('trust-switch-role')));
      await tester.pumpAndSettle();
      expect(c.read(sessionControllerProvider).profile!.role, Role.driver);
      expect(find.text(l.seatsQ), findsOneWidget, reason: 'commute setup in driver mode');
      expect(find.text(l.driverNeedsDocs), findsOneWidget);
      expect(tester.widget<GooraPrimaryButton>(find.byKey(const Key('find-commute'))).onPressed, isNull);
    });

    testWidgets('[$code] driver → rider keeps the saved commute and the shell', (tester) async {
      final c = await _openTrust(tester, Role.driver, code);
      await tester.tap(find.byKey(const Key('trust-switch-role')));
      await tester.pumpAndSettle();
      expect(c.read(sessionControllerProvider).profile!.role, Role.rider);
      expect(find.byType(GooraBottomNav), findsOneWidget);
      expect(find.text(l.toDriver), findsOneWidget);
      final saved = await tester.runAsync(() => FakeCommuteRepository(c.read(sharedPreferencesProvider)).loadProfile());
      expect(saved?.home, isNotNull);
    });

    testWidgets('[$code] trusted contacts: add, validate, max 3, remove', (tester) async {
      await _openTrust(tester, Role.rider, code);
      expect(find.text(l.sosNoContacts), findsOneWidget, reason: 'designed empty state');
      await tester.tap(find.byKey(const Key('open-contacts')));
      await tester.pumpAndSettle();

      Future<void> add(String name, String phone) async {
        await tester.enterText(find.byKey(const Key('contact-name')), name);
        await tester.enterText(find.byKey(const Key('contact-phone')), phone);
        await tester.pump();
        await tester.tap(find.byKey(const Key('add-contact')));
        await tester.pumpAndSettle();
      }

      await tester.enterText(find.byKey(const Key('contact-name')), 'Mona');
      await tester.enterText(find.byKey(const Key('contact-phone')), '0123');
      await tester.pump();
      expect(find.text(l.phoneHint), findsOneWidget);
      expect(tester.widget<GooraPrimaryButton>(find.byKey(const Key('add-contact'))).onPressed, isNull);

      await add('Mona', '01011111111');
      await add('Hany', '01122222222');
      await add('Laila', '01233333333');
      expect(find.text('Mona'), findsOneWidget);
      expect(find.text('Laila'), findsOneWidget);
      expect(find.byKey(const Key('add-contact')), findsNothing, reason: 'max 3');
      expect(find.text(l.trustedMax), findsOneWidget);

      await tester.tap(find.byTooltip(l.removeContact('Hany')));
      await tester.pumpAndSettle();
      expect(find.text('Hany'), findsNothing);
      expect(find.byKey(const Key('add-contact')), findsOneWidget);
    });
  }

  testWidgets('Settings switch for a member works like Trust: driver docs wait (T075)', (tester) async {
    final e = l10nFor(en);
    await pumpGooraApp(
      tester,
      prefs: memberPrefs(role: Role.rider, locale: 'en'),
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    tester.view.physicalSize = const Size(390, 2400);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-role')));
    await tester.pumpAndSettle();
    expect(find.text(e.driverNeedsDocs), findsOneWidget);
    expect(tester.widget<GooraPrimaryButton>(find.byKey(const Key('find-commute'))).onPressed, isNull);
  });

  testWidgets('Reset demo data clears trust data too (T076)', (tester) async {
    final c = await pumpGooraApp(
      tester,
      prefs: {
        ...memberPrefs(role: Role.rider, locale: 'en'),
        FakeTrustRepository.privacyKey: 'sameCompany',
        FakeTrustRepository.contactsKey: '[{"id":"c1","name":"Mona","phone":"+201011111111"}]',
      },
      overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
    );
    tester.view.physicalSize = const Size(390, 2400);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('demo-reset')));
    await tester.tap(find.byKey(const Key('demo-reset')));
    await tester.pumpAndSettle();
    expect(find.text(l10nFor(en).demoResetDone), findsOneWidget);
    final prefs = c.read(sharedPreferencesProvider);
    for (final key in FakeTrustRepository.allKeys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
  });

  // The saved preference reaches matching (FR-024): no corridor group is all Valeo.
  for (final (pref, found) in [('verifiedUsers', true), ('sameCompany', false)]) {
    testWidgets('matching with "$pref" → found: $found', (tester) async {
      await pumpGooraApp(
        tester,
        prefs: {
          ...memberPrefs(role: Role.rider, locale: 'en', member: false),
          FakeTrustRepository.privacyKey: pref,
        },
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      await tester.tap(find.byKey(const Key('find-commute')));
      await tester.pumpAndSettle();
      expect(find.text(l10nFor(en).foundGroup), found ? findsOneWidget : findsNothing);
    });
  }
}
