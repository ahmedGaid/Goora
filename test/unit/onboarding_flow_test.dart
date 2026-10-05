import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/onboarding_flow.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

void main() {
  final phone = PhoneNumber.tryParse('01012345678')!;
  Profile profile({Role? role, Frequency? frequency}) => Profile(
        phone: phone,
        firstName: 'Omar',
        lastName: 'Adel',
        gender: Gender.male,
        role: role,
        frequency: frequency,
      );

  group('resumeStep', () {
    test('not signed in → welcome', () {
      expect(OnboardingFlow.resumeStep(signedIn: false), OnboardingStep.welcome);
    });
    test('signed in, no profile → profile', () {
      expect(OnboardingFlow.resumeStep(signedIn: true), OnboardingStep.profile);
    });
    test('no role → role', () {
      expect(OnboardingFlow.resumeStep(signedIn: true, profile: profile()), OnboardingStep.role);
    });
    test('no frequency → frequency', () {
      expect(
        OnboardingFlow.resumeStep(signedIn: true, profile: profile(role: Role.rider)),
        OnboardingStep.frequency,
      );
    });
    test('complete → destination', () {
      expect(
        OnboardingFlow.resumeStep(
          signedIn: true,
          profile: profile(role: Role.rider, frequency: Frequency.once),
        ),
        OnboardingStep.destination,
      );
    });
  });

  group('destinationFor (brief 001 §6 routing)', () {
    test('every day → commute setup, for both roles', () {
      expect(OnboardingFlow.destinationFor(Role.rider, Frequency.everyDay), Destination.commuteSetup);
      expect(OnboardingFlow.destinationFor(Role.driver, Frequency.everyDay), Destination.commuteSetup);
    });
    test('rider + once → Empty seats today', () {
      expect(OnboardingFlow.destinationFor(Role.rider, Frequency.once), Destination.emptySeatsToday);
    });
    test('driver + once → Offer a trip', () {
      expect(OnboardingFlow.destinationFor(Role.driver, Frequency.once), Destination.offerTrip);
    });
  });

  test('progress dots cover role → frequency → commute setup only', () {
    expect(OnboardingFlow.progressIndex(step: OnboardingStep.role), 0);
    expect(OnboardingFlow.progressIndex(step: OnboardingStep.frequency), 1);
    expect(OnboardingFlow.progressIndex(destination: Destination.commuteSetup), 2);
    expect(OnboardingFlow.progressIndex(destination: Destination.offerTrip), isNull);
    expect(OnboardingFlow.progressIndex(step: OnboardingStep.welcome), isNull);
  });

  test('profile JSON round-trip and name rules', () {
    final p = profile(role: Role.driver, frequency: Frequency.everyDay);
    final back = Profile.fromJson(p.toJson())!;
    expect(back.phone, phone);
    expect(back.role, Role.driver);
    expect(back.frequency, Frequency.everyDay);
    expect(Profile.isValidName('  '), isFalse);
    expect(Profile.isValidName('a' * 41), isFalse);
    expect(Profile.isValidName('سارة'), isTrue);
  });
}
