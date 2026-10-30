import 'choices.dart';
import 'profile.dart';

enum OnboardingStep { welcome, profile, role, frequency, destination }

enum Destination { commuteSetup, offerTrip, today }

/// Pure onboarding rules (data-model.md).
abstract final class OnboardingFlow {
  static const progressSteps = 3;

  static OnboardingStep resumeStep({required bool signedIn, Profile? profile}) {
    if (!signedIn) return OnboardingStep.welcome;
    if (profile == null) return OnboardingStep.profile;
    if (profile.role == null) return OnboardingStep.role;
    if (profile.frequency == null) return OnboardingStep.frequency;
    return OnboardingStep.destination;
  }

  static Destination destinationFor(Role role, Frequency frequency) => switch ((role, frequency)) {
        (_, Frequency.everyDay) => Destination.commuteSetup,
        // Today is the shell (tab bar, Wallet, Trust); its "no group yet" state
        // offers Empty seats to a rider (walk N-11) and Offer a trip to a driver
        // (walk 6), so Back from there never reaches onboarding.
        (_, Frequency.once) => Destination.today,
      };

  /// Index in the role → frequency → commute setup progress dots.
  static int? progressIndex({OnboardingStep? step, Destination? destination}) {
    if (step == OnboardingStep.role) return 0;
    if (step == OnboardingStep.frequency) return 1;
    if (destination == Destination.commuteSetup) return 2;
    return null;
  }
}
