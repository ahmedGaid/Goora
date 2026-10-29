import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/onboarding_routes.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

/// 005 R12: where a signed-in person lands.
void main() {
  final phone = PhoneNumber.tryParse('01012345678')!;
  Session session(Role role, Frequency frequency) => Session(
        phone: phone,
        profile: Profile(
          phone: phone,
          firstName: 'Omar',
          lastName: 'Adel',
          gender: Gender.male,
          role: role,
          frequency: frequency,
        ),
      );

  test('a once rider with a live one-off goes to Today', () {
    expect(routeForSession(session(Role.rider, Frequency.once), hasOneOff: true), Routes.today);
  });

  test('a once driver with a live one-off (open offer) goes to Today', () {
    expect(routeForSession(session(Role.driver, Frequency.once), hasOneOff: true), Routes.today);
  });

  test('a once rider with nothing booked lands on Today, which offers Empty seats (walk N-11)', () {
    expect(routeForSession(session(Role.rider, Frequency.once)), Routes.today);
  });

  test('an every-day rider is not sent to Today by a one-off alone', () {
    expect(routeForSession(session(Role.rider, Frequency.everyDay), hasOneOff: true), Routes.commuteSetup);
  });

  test('a member still lands on Today', () {
    expect(routeForSession(session(Role.rider, Frequency.everyDay), isMember: true), Routes.today);
  });
}
