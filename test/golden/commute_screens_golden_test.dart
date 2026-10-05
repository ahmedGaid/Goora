import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/presentation/commute_controller.dart';
import 'package:goora/features/commute/presentation/commute_setup_screen.dart';
import 'package:goora/features/commute/presentation/match_result_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

import '../helpers/pump_app.dart';

final _phone = PhoneNumber.tryParse('01012345678')!;

Session _session(Role role) => Session(
      phone: _phone,
      profile: Profile(phone: _phone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: role),
    );

class _Seeded extends LastMatch {
  _Seeded(this.outcome);

  final MatchOutcome outcome;

  @override
  MatchOutcome? build() => outcome;
}

/// Full-screen goldens, taller than a phone so the whole scroll body shows.
void main() {
  const profile = CommuteProfile(
    home: CorridorSeed.sheikhZayed,
    work: CorridorSeed.smartVillage,
    departure: CommuteProfile.defaultDeparture,
    ret: CommuteProfile.defaultReturn,
    days: CommuteProfile.defaultDays,
  );

  for (final locale in locales) {
    final dir = locale == ar ? 'rtl' : 'ltr';

    testWidgets('commute setup (driver) [$dir]', (tester) async {
      final c = await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.driver));
      c.read(commuteControllerProvider.notifier)
        ..setHome(CorridorSeed.sheikhZayed)
        ..setWork(CorridorSeed.smartVillage);
      tester.view.physicalSize = const Size(390, 1700);
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/screen_setup_driver_$dir.png'));
    });

    testWidgets('match result (rider) [$dir]', (tester) async {
      final result = MatchingService.match(
        Seeker(
          role: MemberRole.rider,
          home: profile.home!.point,
          work: profile.work!.point,
          departure: profile.departure,
          ret: profile.ret,
          days: profile.days,
          legs: const {Leg.going, Leg.ret},
        ),
        CorridorSeed.groups,
      );
      await pumpScreen(
        tester,
        const MatchResultScreen(),
        locale: locale,
        session: _session(Role.rider),
        overrides: [
          lastMatchProvider.overrideWith(
            () => _Seeded(MatchOutcome(profile: profile, viewerIsDriver: false, result: result)),
          ),
        ],
      );
      tester.view.physicalSize = const Size(390, 1300);
      await tester.tap(find.byKey(const Key('toggle-others')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold).first, matchesGoldenFile('goldens/screen_match_$dir.png'));
    });
  }
}
