import '../../../app/routes.dart';
import '../domain/choices.dart';
import '../domain/onboarding_flow.dart';
import 'session_controller.dart';

/// Where a person with this session should be: their resume step, their
/// group's Today tab once they are a member (003, research R1), or their
/// destination once onboarding is complete.
String routeForSession(Session session, {bool isMember = false}) {
  final profile = session.profile;
  if (isMember && session.resumeStep == OnboardingStep.destination && profile!.frequency == Frequency.everyDay) {
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
