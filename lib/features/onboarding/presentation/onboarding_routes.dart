import '../../../app/routes.dart';
import '../domain/onboarding_flow.dart';
import 'session_controller.dart';

/// Where a person with this session should be: their resume step, or their
/// destination once onboarding is complete.
String routeForSession(Session session) {
  final profile = session.profile;
  return switch (session.resumeStep) {
    OnboardingStep.welcome => Routes.welcome,
    OnboardingStep.profile => Routes.profile,
    OnboardingStep.role => Routes.role,
    OnboardingStep.frequency => Routes.frequency,
    OnboardingStep.destination =>
      Routes.forDestination(OnboardingFlow.destinationFor(profile!.role!, profile.frequency!)),
  };
}
