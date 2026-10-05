import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

import '../helpers/pump_app.dart';

final _phone = PhoneNumber.tryParse('01012345678')!;

Map<String, Object> _prefs(Role role, {CommuteProfile? commute}) => {
      'fake_auth.session': _phone.e164,
      'fake_auth.accounts': [_phone.e164],
      'profile': jsonEncode(
        Profile(
          phone: _phone,
          firstName: 'Omar',
          lastName: 'Khaled',
          gender: Gender.male,
          role: role,
          frequency: Frequency.everyDay,
        ).toJson(),
      ),
      if (commute != null) 'commute.profile': jsonEncode(commute.toJson()),
    };

const _corridor = CommuteProfile(
  home: CorridorSeed.sheikhZayed,
  work: CorridorSeed.smartVillage,
  departure: CommuteProfile.defaultDeparture,
  ret: CommuteProfile.defaultReturn,
  days: CommuteProfile.defaultDays,
);

Future<void> _tapFind(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('find-commute')));
  await tester.pumpAndSettle();
}

void main() {
  final a = l10nFor(ar);

  testWidgets('rider: pick places → find → result → join → plan placeholder', (tester) async {
    await pumpGooraApp(tester, prefs: _prefs(Role.rider));
    expect(find.text(a.whereGo), findsOneWidget, reason: 'resumes at commute setup');
    await tester.tap(find.byKey(const Key('pick-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('place-home-sz')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-work')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('place-work-sv')));
    await tester.pumpAndSettle();
    await _tapFind(tester);

    expect(find.text(a.foundGroup), findsOneWidget);
    expect(find.byKey(const Key('match-chip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('join-group')));
    await tester.pumpAndSettle();
    expect(find.text(a.planTitle), findsWidgets);
  });

  testWidgets('driver: find → join → Today placeholder', (tester) async {
    await pumpGooraApp(tester, prefs: _prefs(Role.driver, commute: _corridor));
    expect(find.text(a.areaSheikhZayed), findsWidgets, reason: 'saved profile is restored');
    await _tapFind(tester);
    expect(find.text(a.foundGroup), findsOneWidget);
    await tester.tap(find.byKey(const Key('join-group')));
    await tester.pumpAndSettle();
    expect(find.text(a.tabToday), findsWidgets);
  });

  testWidgets('no match: 10:00 AM departure → waitlist #7 → post a trip', (tester) async {
    await pumpGooraApp(
      tester,
      prefs: _prefs(Role.rider, commute: _corridor.copyWith(departure: const Clock.hm(10, 0), ret: const Clock.hm(19, 0))),
    );
    await _tapFind(tester);
    expect(find.text(a.noMatch(7, a.areaSheikhZayed, a.areaSmartVillage)), findsOneWidget);
    await tester.tap(find.byKey(const Key('post-trip')));
    await tester.pumpAndSettle();
    expect(find.text(a.postReq), findsWidgets);
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('no-match-text')), findsOneWidget);
  });

  testWidgets('back from the result returns to the filled setup', (tester) async {
    await pumpGooraApp(tester, prefs: _prefs(Role.rider, commute: _corridor));
    await _tapFind(tester);
    await tester.tap(find.byTooltip(a.back));
    await tester.pumpAndSettle();
    expect(find.text(a.whereGo), findsOneWidget);
    expect(find.text(a.areaSmartVillage), findsWidgets);
  });
}
