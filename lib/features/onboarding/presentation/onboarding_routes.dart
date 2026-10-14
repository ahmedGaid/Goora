import '../../../app/routes.dart';
import '../domain/choices.dart';
import '../domain/onboarding_flow.dart';
import 'session_controller.dart';

/// Where a person with this session should be: their resume step, their
/// group's Today tab once they are a member or have a one-off trip (003, research R1), or their
/// destination once onboarding is complete.
String routeForSession(Session session, {bool isMember = false, bool hasOneOff = false}) {
  final profile = session.profile;
  if (isMember && session.resumeStep == OnboardingStep.destination && profile!.frequency == Frequency.everyDay) {
    return Routes.today;
  }
  // A once user with a live one-off booking, offer or request lands where it
  // shows (005 R12).
  if (hasOneOff && session.resumeStep == OnboardingStep.destination && profile!.frequency == Frequency.once) {
    return Routes.today;
  }
  return switch (session.resumeStep) {
    OnboardingStep.welcome => Routes.welcome,
    OnboardingStep.profile => Routes.profile,
    OnboardingStep.role => Routes.role,
    OnboardingStep.frequency => Routes.frequency,
    OnboardingStep.destination =>
      Routes.forDestination(OnboardingFlow.destinationFor(profile!.role!, profile.frequency!)),
  };
}
