import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/widgets/goora_bottom_nav.dart';
import 'package:goora/features/design_gallery/presentation/design_gallery_screen.dart';
import 'package:goora/features/onboarding/data/fake_auth_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

import '../helpers/pump_app.dart';

final _phone = PhoneNumber.tryParse('01012345678')!;

Map<String, Object> _signedIn({Role? role, Frequency? frequency}) => {
      'fake_auth.session': _phone.e164,
      'fake_auth.accounts': [_phone.e164],
      'profile': jsonEncode(
        Profile(
          phone: _phone,
          firstName: 'Sara',
          lastName: 'Kamel',
          gender: Gender.female,
          role: role,
          frequency: frequency,
        ).toJson(),
      ),
    };

void main() {
  final a = l10nFor(ar);

  testWidgets('first launch: Arabic welcome → sign-up → role (full flow)', (tester) async {
    await pumpGooraApp(tester);
    expect(find.text(a.tagline), findsOneWidget);
    expect(directionOf(tester, find.text(a.tagline)), TextDirection.rtl);

    await tester.tap(find.text(a.getStarted));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '01012345678');
    await tester.pump();
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp-field')), FakeAuthRepository.testCode);
    await tester.pumpAndSettle();
    expect(find.text(a.profileTitle), findsOneWidget);

    await tester.enterText(find.byKey(const Key('first-name')), 'سارة');
    await tester.enterText(find.byKey(const Key('last-name')), 'كامل');
    await tester.tap(find.byKey(const Key('gender-female')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-continue')));
    await tester.pumpAndSettle();
    expect(find.text(a.howTravel), findsOneWidget);
  });

  const combos = {
    (Role.rider, 'freq-every-day'): 'whereGo',
    (Role.driver, 'freq-every-day'): 'whereGo',
    (Role.driver, 'freq-once'): 'offerTitle',
  };
  for (final MapEntry(key: (role, freqKey), value: titleKey) in combos.entries) {
    testWidgets('${role.name} + $freqKey reaches the right destination; back → frequency', (tester) async {
      await pumpGooraApp(tester, prefs: _signedIn());
      expect(find.text(a.howTravel), findsOneWidget, reason: 'resumes at role');
      await tester.tap(find.byKey(Key(role == Role.driver ? 'role-driver' : 'role-rider')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('role-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(freqKey)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('freq-continue')));
      await tester.pumpAndSettle();
      final title = switch (titleKey) {
        'whereGo' => a.whereGo,
        _ => a.offerTitle,
      };
      expect(find.text(title), findsOneWidget);
      await tester.tap(find.byTooltip(a.back));
      await tester.pumpAndSettle();
      expect(find.text(a.freqTitle), findsOneWidget);
    });
  }

  // Walk N-11: a once rider landed on Empty seats with no tab bar, and Back went
  // to onboarding's step 2. Today is the shell; Empty seats is one tap away.
  testWidgets('rider + once lands on Today with the tab bar; Empty seats is a step on top, Back returns', (tester) async {
    await pumpGooraApp(tester, prefs: _signedIn());
    await tester.tap(find.byKey(const Key('role-rider')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('role-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('freq-once')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('freq-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('no-group-yet')), findsOneWidget, reason: 'Today, not Empty seats');
    expect(find.byType(GooraBottomNav), findsOneWidget, reason: 'the shell: Wallet and Trust are reachable');
    expect(find.text(a.freqTitle), findsNothing);

    await tester.tap(find.byKey(const Key('no-group-action')));
    await tester.pumpAndSettle();
    expect(find.text(a.emptySeatsTitle), findsOneWidget);
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('no-group-yet')), findsOneWidget, reason: 'Back goes to Today');
    expect(find.text(a.freqTitle), findsNothing, reason: 'never to onboarding');
  });

  testWidgets('Empty seats opened with nothing to pop goes Back to Today, not onboarding (N-11)', (tester) async {
    final c = await pumpGooraApp(tester, prefs: _signedIn(role: Role.rider, frequency: Frequency.once));
    c.read(routerProvider).go(Routes.emptySeats);
    await tester.pumpAndSettle();
    expect(find.text(a.emptySeatsTitle), findsOneWidget);
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('no-group-yet')), findsOneWidget);
    expect(find.text(a.freqTitle), findsNothing);
  });

  testWidgets('back from frequency keeps the chosen role', (tester) async {
    await pumpGooraApp(tester, prefs: _signedIn(role: Role.driver));
    expect(find.text(a.freqTitle), findsOneWidget, reason: 'resumes at frequency');
    expect(find.text(a.fRegDriver), findsOneWidget);
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    expect(find.text(a.howTravel), findsOneWidget);
  });

  testWidgets('relaunch resumes at the destination and keeps English', (tester) async {
    await pumpGooraApp(
      tester,
      prefs: {..._signedIn(role: Role.driver, frequency: Frequency.once), 'locale': 'en'},
    );
    expect(find.text(l10nFor(en).offerTitle), findsWidgets);
    expect(directionOf(tester, find.byType(Scaffold).first), TextDirection.ltr);
  });

  testWidgets('log in with an existing complete account skips the profile step', (tester) async {
    final prefs = _signedIn(role: Role.rider, frequency: Frequency.everyDay)..remove('fake_auth.session');
    await pumpGooraApp(tester, prefs: prefs);
    await tester.tap(find.text(a.login));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-field')), '+20 101 234 5678');
    await tester.pump();
    await tester.tap(find.byKey(const Key('phone-continue')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('otp-field')), FakeAuthRepository.testCode);
    await tester.pumpAndSettle();
    expect(find.text(a.whereGo), findsOneWidget);
  });

  testWidgets('settings from a screen: switching role changes frequency sublines', (tester) async {
    // A once driver lands on Offer a trip (005 US2); settings is pushed on top of it.
    final c = await pumpGooraApp(tester, prefs: _signedIn(role: Role.driver, frequency: Frequency.once));
    unawaited(c.read(routerProvider).push(Routes.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    expect(find.text(a.fRegRider), findsOneWidget);
  });

  testWidgets('debug: long-press the welcome logo opens the Design gallery', (tester) async {
    await pumpGooraApp(tester);
    await tester.longPress(find.byKey(const Key('welcome-logo')));
    await tester.pumpAndSettle();
    expect(find.byType(DesignGalleryScreen), findsOneWidget);
  });

  for (final locale in locales) {
    testWidgets('[${locale.languageCode}] Design gallery renders every section', (tester) async {
      await pumpScreen(tester, const DesignGalleryScreen(), locale: locale);
      final l = l10nFor(locale);
      for (final section in [
        l.galleryColors,
        l.galleryType,
        l.galleryShape,
        l.galleryButtons,
        l.galleryCards,
        l.gallerySelection,
        l.galleryFeedback,
        l.galleryPeople,
        l.galleryNav,
      ]) {
        await tester.scrollUntilVisible(find.text(section), 300, scrollable: find.byType(Scrollable).first);
        expect(find.text(section), findsOneWidget);
      }
      expect(find.text(l.tabToday), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
